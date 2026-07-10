class tc003_mmr_random_rw_seq extends uvm_sequence #(int_seq_item);

  `uvm_object_utils(tc003_mmr_random_rw_seq)

  int_seq_item tr;

  rand int unsigned irq_id;
  rand bit [31:0] wr_data;

  function new(string name="tc003_mmr_random_rw_seq");
    super.new(name);
  endfunction

  constraint irq_c
  {
    irq_id inside {[0:15]};
  }

  task body();

    bit [15:0] addr;

    //----------------------------------------------------------
    // Reset
    //----------------------------------------------------------
    tr = int_seq_item::type_id::create("reset");
    start_item(tr);

    tr.soc_rst = 1'b0;

    tr.ext_int = 16'h0000;

    tr.soc_mmr_write_en_i = 0;
    tr.soc_mmr_read_en_i  = 0;

    tr.global_int_enable_valid_i = 0;
    tr.global_int_enable_bit_i   = 16'h0000;

    tr.soc_ack_read_valid_en = 0;

    tr.soc_eoi_valid_i = 0;
    tr.soc_eoi_id_i    = 0;

    tr.active_lvl_pr_i = 0;

    finish_item(tr);

    //----------------------------------------------------------
    // Release Reset
    //----------------------------------------------------------
    tr = int_seq_item::type_id::create("release_reset");
    start_item(tr);

    tr.soc_rst = 1'b1;

    tr.ext_int = 16'h0000;

    tr.soc_mmr_write_en_i = 0;
    tr.soc_mmr_read_en_i  = 0;

    tr.global_int_enable_valid_i = 0;
    tr.global_int_enable_bit_i   = 16'h0000;

    tr.soc_ack_read_valid_en = 0;

    tr.soc_eoi_valid_i = 0;
    tr.soc_eoi_id_i    = 0;

    tr.active_lvl_pr_i = 0;

    finish_item(tr);

    //----------------------------------------------------------
    // Random MMR Read / Write
    //----------------------------------------------------------

    repeat (25)
    begin

      assert(this.randomize());

      addr = 16'h1003 + (irq_id * 4);

      //------------------------------------------------------
      // Write
      //------------------------------------------------------

      tr = int_seq_item::type_id::create($sformatf("write_irq%0d",irq_id));
      start_item(tr);

      tr.soc_rst = 1'b1;

      tr.ext_int = 16'h0000;

      tr.soc_mmr_write_en_i   = 1'b1;
      tr.soc_mmr_write_addr_i = addr;
      tr.soc_mmr_write_data_i = wr_data;

      tr.soc_mmr_read_en_i = 1'b0;

      finish_item(tr);

      //------------------------------------------------------
      // Idle
      //------------------------------------------------------

      tr = int_seq_item::type_id::create("idle");
      start_item(tr);

      tr.soc_rst = 1'b1;

      tr.soc_mmr_write_en_i = 0;
      tr.soc_mmr_read_en_i  = 0;

      finish_item(tr);

      //------------------------------------------------------
      // Read
      //------------------------------------------------------

      tr = int_seq_item::type_id::create($sformatf("read_irq%0d",irq_id));
      start_item(tr);

      tr.soc_rst = 1'b1;

      tr.soc_mmr_write_en_i = 0;

      tr.soc_mmr_read_en_i   = 1'b1;
      tr.soc_mmr_read_addr_i = addr;

      finish_item(tr);

      //------------------------------------------------------
      // Idle
      //------------------------------------------------------

      tr = int_seq_item::type_id::create("idle2");
      start_item(tr);

      tr.soc_rst = 1'b1;

      tr.soc_mmr_write_en_i = 0;
      tr.soc_mmr_read_en_i  = 0;

      finish_item(tr);

    end

  endtask

endclass
