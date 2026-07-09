class zic_common_base_seq extends uvm_sequence #(int_seq_item);

  `uvm_object_utils(zic_common_base_seq)

  localparam int NUM_IRQ = 16;
  localparam bit [15:0] VALID_IRQ_MASK = 16'hFFFF;

  function new(string name = "zic_common_base_seq");
    super.new(name);
  endfunction

  // ---------------------------------------------------------
  // Convert IRQ number to CTL register address
  // ---------------------------------------------------------
  function automatic bit [15:0] ctl_addr(int irq);
    return 16'h1003 + (irq * 4);
  endfunction

  // ---------------------------------------------------------
  // Universal transaction task
  // ---------------------------------------------------------
  task send_tr(

      string      name,

      bit         soc_rst,

      bit [15:0]  ext_int,

      bit         wr_en,
      bit [15:0]  wr_addr,
      bit [31:0]  wr_data,

      bit         rd_en,
      bit [15:0]  rd_addr,

      bit         eoi_valid,
      bit [7:0]   eoi_id,

      bit [15:0]  enable_bits,
      bit         enable_valid,

      bit [7:0]   active_lvl,

      bit         ack_valid
  );

      int_seq_item tr;

      tr = int_seq_item::type_id::create(name);

      start_item(tr);

      //------------------------------------
      // Reset / External Interrupt
      //------------------------------------
      tr.soc_rst = soc_rst;
      tr.ext_int = ext_int;

      //------------------------------------
      // MMR Write
      //------------------------------------
      tr.soc_mmr_write_en_i   = wr_en;
      tr.soc_mmr_write_addr_i = wr_addr;
      tr.soc_mmr_write_data_i = wr_data;

      //------------------------------------
      // MMR Read
      //------------------------------------
      tr.soc_mmr_read_en_i    = rd_en;
      tr.soc_mmr_read_addr_i  = rd_addr;

      //------------------------------------
      // ACK
      //------------------------------------
      tr.soc_ack_read_valid_en = ack_valid;

      //------------------------------------
      // EOI
      //------------------------------------
      tr.soc_eoi_valid_i = eoi_valid;
      tr.soc_eoi_id_i    = eoi_id;

      //------------------------------------
      // Global Enable
      //------------------------------------
      tr.global_int_enable_bit_i   = enable_bits;
      tr.global_int_enable_valid_i = enable_valid;

      //------------------------------------
      // Active Level
      //------------------------------------
      tr.active_lvl_pr_i = active_lvl;

      //------------------------------------
      // Debug Signals
      //------------------------------------
      tr.debug_mode_valid_i = 1'b0;
      tr.debug_mode_reset_i = 1'b0;
      tr.debug_ndm_reset_i  = 1'b0;

      finish_item(tr);

  endtask


  // ---------------------------------------------------------
  // Idle cycles
  // ---------------------------------------------------------
  task idle(

      int n,

      bit [15:0] ext = 16'h0000,

      bit [15:0] en  = VALID_IRQ_MASK

  );

      repeat(n) begin

          send_tr(

              "idle",

              1'b1,
              ext,

              1'b0,
              16'h0000,
              32'h00000000,

              1'b0,
              16'h0000,

              1'b0,
              8'h00,

              en,
              1'b0,

              8'h00,

              1'b0

          );

      end

  endtask


  // ---------------------------------------------------------
  // Write IRQ CTL Register
  // ---------------------------------------------------------
  task write_ctl(

      int irq,

      bit [7:0] ctl

  );

      send_tr(

          $sformatf("write_ctl_irq%0d", irq),

          1'b1,
          16'h0000,

          1'b1,
          ctl_addr(irq),
          {24'h0,ctl},

          1'b0,
          16'h0000,

          1'b0,
          8'h00,

          VALID_IRQ_MASK,
          1'b0,

          8'h00,

          1'b0

      );

  endtask

endclass

///==========================================================
// MMR READ SEQUENCE
//==========================================================
class mmr_read_seq extends zic_common_base_seq;

  `uvm_object_utils(mmr_read_seq)

  rand int unsigned num_ops;

  constraint c_num_ops {
    num_ops inside {[20:50]};
  }

  function new(string name = "mmr_read_seq");
    super.new(name);
  endfunction

  task body();

    int irq;
    bit [15:0] rd_addr;

    if(!randomize())
      `uvm_fatal(get_type_name(),"Randomization failed")

    `uvm_info(get_type_name(),
              "Starting MMR READ Sequence",
              UVM_LOW)

    repeat(num_ops) begin

      irq = $urandom_range(0,15);

      rd_addr = ctl_addr(irq);

      //----------------------------------------
      // Read CTL Register
      //----------------------------------------
      send_tr(

          "mmr_read",

          1'b1,
          16'h0000,

          1'b0,
          16'h0000,
          32'h00000000,

          1'b1,
          rd_addr,

          1'b0,
          8'h00,

          VALID_IRQ_MASK,
          1'b0,

          8'h00,

          1'b0

      );

      idle($urandom_range(1,3));

    end

    `uvm_info(get_type_name(),
              "MMR READ Sequence Completed",
              UVM_LOW)

  endtask

endclass
