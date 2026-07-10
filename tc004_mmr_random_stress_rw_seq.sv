class tc004_mmr_random_stress_rw_seq extends uvm_sequence #(int_seq_item);

  `uvm_object_utils(tc004_mmr_random_stress_rw_seq)

  int_seq_item tr;

  rand bit        rw_sel;
  rand bit [3:0]  irq_num;
  rand bit [31:0] wr_data;

  rand int unsigned idle_cycles;
  rand int unsigned random_transactions;

  bit [15:0] addr;

  function new(string name="tc004_mmr_random_stress_rw_seq");
    super.new(name);
  endfunction

    //--------------------------------------------
  // IRQ Number
  //--------------------------------------------

  constraint irq_c
  {
      irq_num inside {[0:15]};
  }

  //--------------------------------------------
  // Read / Write Selection
  //--------------------------------------------

  constraint rw_c
  {
      rw_sel dist
      {
          0 := 50,
          1 := 50
      };
  }

  //--------------------------------------------
  // Idle Cycles
  //--------------------------------------------

  constraint idle_c
  {
      idle_cycles inside {[0:3]};
  }

  //--------------------------------------------
  // Number of Random Transactions
  //--------------------------------------------

  constraint trans_c
  {
      random_transactions inside {[100:300]};
  }

  task body();

  //--------------------------------------------------------
  // Apply Reset
  //--------------------------------------------------------

  tr = int_seq_item::type_id::create("reset");

  start_item(tr);

  tr.soc_rst = 1'b0;

  tr.ext_int = 16'h0000;

  tr.soc_mmr_write_en_i   = 0;
  tr.soc_mmr_write_addr_i = 0;
  tr.soc_mmr_write_data_i = 0;

  tr.soc_mmr_read_en_i    = 0;
  tr.soc_mmr_read_addr_i  = 0;

  tr.global_int_enable_valid_i = 0;
  tr.global_int_enable_bit_i   = 0;

  tr.soc_ack_read_valid_en = 0;

  tr.soc_eoi_valid_i = 0;
  tr.soc_eoi_id_i    = 0;

  tr.active_lvl_pr_i = 0;

  finish_item(tr);

    //--------------------------------------------------------
  // Release Reset
  //--------------------------------------------------------

  tr = int_seq_item::type_id::create("release_reset");

  start_item(tr);

  tr.soc_rst = 1'b1;

  tr.ext_int = 16'h0000;

  tr.soc_mmr_write_en_i = 0;
  tr.soc_mmr_read_en_i  = 0;

  tr.global_int_enable_valid_i = 0;
  tr.global_int_enable_bit_i   = 0;

  tr.soc_ack_read_valid_en = 0;

  tr.soc_eoi_valid_i = 0;
  tr.soc_eoi_id_i    = 0;

  tr.active_lvl_pr_i = 0;

  finish_item(tr);

    //--------------------------------------------------------
  // Phase-1 : Cover All IRQ Registers Once
  //--------------------------------------------------------

  for (int i = 0; i < 16; i++) begin

    assert(this.randomize() with {
      irq_num == i;
    });

    addr = 16'h1003 + (irq_num * 4);

    //----------------------------------------------------
    // Random WRITE or READ
    //----------------------------------------------------

    if (rw_sel == 1'b0) begin

      tr = int_seq_item::type_id::create($sformatf("write_irq%0d", i));

      start_item(tr);

      tr.soc_rst = 1'b1;

      tr.ext_int = 16'h0000;

      //-----------------------------
      // MMR Write
      //-----------------------------
      tr.soc_mmr_write_en_i   = 1'b1;
      tr.soc_mmr_write_addr_i = addr;
      tr.soc_mmr_write_data_i = wr_data;

      //-----------------------------
      // MMR Read
      //-----------------------------
      tr.soc_mmr_read_en_i   = 1'b0;
      tr.soc_mmr_read_addr_i = 16'h0000;

      //-----------------------------
      // Global Enable
      //-----------------------------
      tr.global_int_enable_valid_i = 1'b0;
      tr.global_int_enable_bit_i   = 16'h0000;

      //-----------------------------
      // ACK / EOI
      //-----------------------------
      tr.soc_ack_read_valid_en = 1'b0;

      tr.soc_eoi_valid_i = 1'b0;
      tr.soc_eoi_id_i    = 8'h00;

      //-----------------------------
      // Active Priority
      //-----------------------------
      tr.active_lvl_pr_i = 8'h00;

      finish_item(tr);

    end
    else begin

      tr = int_seq_item::type_id::create($sformatf("read_irq%0d", i));

      start_item(tr);

      tr.soc_rst = 1'b1;

      tr.ext_int = 16'h0000;

      //-----------------------------
      // MMR Write
      //-----------------------------
      tr.soc_mmr_write_en_i   = 1'b0;
      tr.soc_mmr_write_addr_i = 16'h0000;
      tr.soc_mmr_write_data_i = 32'h00000000;

      //-----------------------------
      // MMR Read
      //-----------------------------
      tr.soc_mmr_read_en_i   = 1'b1;
      tr.soc_mmr_read_addr_i = addr;

      //-----------------------------
      // Global Enable
      //-----------------------------
      tr.global_int_enable_valid_i = 1'b0;
      tr.global_int_enable_bit_i   = 16'h0000;

      //-----------------------------
      // ACK / EOI
      //-----------------------------
      tr.soc_ack_read_valid_en = 1'b0;

      tr.soc_eoi_valid_i = 1'b0;
      tr.soc_eoi_id_i    = 8'h00;

      //-----------------------------
      // Active Priority
      //-----------------------------
      tr.active_lvl_pr_i = 8'h00;

      finish_item(tr);

    end

    //----------------------------------------------------
    // Random Idle Cycles
    //----------------------------------------------------

    repeat (idle_cycles) begin

      tr = int_seq_item::type_id::create("idle");

      start_item(tr);

      tr.soc_rst = 1'b1;

      tr.ext_int = 16'h0000;

      tr.soc_mmr_write_en_i = 1'b0;
      tr.soc_mmr_read_en_i  = 1'b0;

      tr.global_int_enable_valid_i = 1'b0;
      tr.global_int_enable_bit_i   = 16'h0000;

      tr.soc_ack_read_valid_en = 1'b0;

      tr.soc_eoi_valid_i = 1'b0;
      tr.soc_eoi_id_i    = 8'h00;

      tr.active_lvl_pr_i = 8'h00;

      finish_item(tr);

    end

  end

    //--------------------------------------------------------
  // Phase-2 : Random Stress Read / Write
  //--------------------------------------------------------

  repeat (random_transactions) begin

    assert(this.randomize());

    addr = 16'h1003 + (irq_num * 4);

    //----------------------------------------------------
    // Random WRITE
    //----------------------------------------------------
    if (rw_sel == 1'b0) begin

      tr = int_seq_item::type_id::create($sformatf("random_write_irq%0d", irq_num));

      start_item(tr);

      tr.soc_rst = 1'b1;

      tr.ext_int = 16'h0000;

      // MMR WRITE
      tr.soc_mmr_write_en_i   = 1'b1;
      tr.soc_mmr_write_addr_i = addr;
      tr.soc_mmr_write_data_i = wr_data;

      // MMR READ
      tr.soc_mmr_read_en_i    = 1'b0;
      tr.soc_mmr_read_addr_i  = 16'h0000;

      // Global Enable
      tr.global_int_enable_valid_i = 1'b0;
      tr.global_int_enable_bit_i   = 16'h0000;

      // ACK / EOI
      tr.soc_ack_read_valid_en = 1'b0;
      tr.soc_eoi_valid_i       = 1'b0;
      tr.soc_eoi_id_i          = 8'h00;

      tr.active_lvl_pr_i = 8'h00;

      finish_item(tr);

    end

    //----------------------------------------------------
    // Random READ
    //----------------------------------------------------
    else begin

      tr = int_seq_item::type_id::create($sformatf("random_read_irq%0d", irq_num));

      start_item(tr);

      tr.soc_rst = 1'b1;

      tr.ext_int = 16'h0000;

      // MMR WRITE
      tr.soc_mmr_write_en_i   = 1'b0;
      tr.soc_mmr_write_addr_i = 16'h0000;
      tr.soc_mmr_write_data_i = 32'h00000000;

      // MMR READ
      tr.soc_mmr_read_en_i    = 1'b1;
      tr.soc_mmr_read_addr_i  = addr;

      // Global Enable
      tr.global_int_enable_valid_i = 1'b0;
      tr.global_int_enable_bit_i   = 16'h0000;

      // ACK / EOI
      tr.soc_ack_read_valid_en = 1'b0;
      tr.soc_eoi_valid_i       = 1'b0;
      tr.soc_eoi_id_i          = 8'h00;

      tr.active_lvl_pr_i = 8'h00;

      finish_item(tr);

    end

    //----------------------------------------------------
    // Random Idle Cycles
    //----------------------------------------------------
    repeat (idle_cycles) begin

      tr = int_seq_item::type_id::create("random_idle");

      start_item(tr);

      tr.soc_rst = 1'b1;

      tr.ext_int = 16'h0000;

      tr.soc_mmr_write_en_i   = 1'b0;
      tr.soc_mmr_write_addr_i = 16'h0000;
      tr.soc_mmr_write_data_i = 32'h00000000;

      tr.soc_mmr_read_en_i    = 1'b0;
      tr.soc_mmr_read_addr_i  = 16'h0000;

      tr.global_int_enable_valid_i = 1'b0;
      tr.global_int_enable_bit_i   = 16'h0000;

      tr.soc_ack_read_valid_en = 1'b0;

      tr.soc_eoi_valid_i = 1'b0;
      tr.soc_eoi_id_i    = 8'h00;

      tr.active_lvl_pr_i = 8'h00;

      finish_item(tr);

    end

  end

endtask

endclass
