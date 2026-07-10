class tc008_global_enable_random_seq extends uvm_sequence #(int_seq_item);

  `uvm_object_utils(tc008_global_enable_random_seq)

  int_seq_item tr;

  rand bit [15:0] enable_mask;

  rand int unsigned idle_cycles;

  rand int unsigned iterations;

  function new(string name="tc008_global_enable_random_seq");
    super.new(name);
  endfunction

    //------------------------------------------------------------
  // Random Iterations
  //------------------------------------------------------------

  constraint iter_c
  {
      iterations inside {[50:100]};
  }

  //------------------------------------------------------------
  // Random Idle
  //------------------------------------------------------------

  constraint idle_c
  {
      idle_cycles inside {[0:3]};
  }

  task body();

      tr = int_seq_item::type_id::create("reset");
    start_item(tr);

    tr.soc_rst = 1'b0;

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

        tr = int_seq_item::type_id::create("release_reset");
    start_item(tr);

    tr.soc_rst = 1'b1;

    tr.ext_int = 16'h0000;

    tr.soc_mmr_write_en_i   = 1'b0;
    tr.soc_mmr_read_en_i    = 1'b0;

    tr.global_int_enable_valid_i = 1'b0;
    tr.global_int_enable_bit_i   = 16'h0000;

    tr.soc_ack_read_valid_en = 1'b0;

    tr.soc_eoi_valid_i = 1'b0;

    tr.active_lvl_pr_i = 8'h00;

    finish_item(tr);

        tr = int_seq_item::type_id::create("enable_all");
    start_item(tr);

    tr.soc_rst = 1'b1;

    tr.ext_int = 16'h0000;

    tr.soc_mmr_write_en_i = 1'b0;
    tr.soc_mmr_read_en_i  = 1'b0;

    tr.global_int_enable_valid_i = 1'b1;
    tr.global_int_enable_bit_i   = 16'hFFFF;

    tr.soc_ack_read_valid_en = 1'b0;

    tr.soc_eoi_valid_i = 1'b0;

    tr.active_lvl_pr_i = 8'h00;

    finish_item(tr);

        tr = int_seq_item::type_id::create("disable_all");
    start_item(tr);

    tr.soc_rst = 1'b1;

    tr.ext_int = 16'h0000;

    tr.soc_mmr_write_en_i = 1'b0;
    tr.soc_mmr_read_en_i  = 1'b0;

    tr.global_int_enable_valid_i = 1'b1;
    tr.global_int_enable_bit_i   = 16'h0000;

    tr.soc_ack_read_valid_en = 1'b0;

    tr.soc_eoi_valid_i = 1'b0;

    tr.active_lvl_pr_i = 8'h00;

    finish_item(tr);

        //------------------------------------------------------------
    // Random Global Enable
    //------------------------------------------------------------
    assert(this.randomize());

    repeat(iterations)
    begin

      assert(this.randomize());

      //----------------------------------------------------------
      // Random Global Enable Transaction
      //----------------------------------------------------------

      tr = int_seq_item::type_id::create("random_enable");

      start_item(tr);

      tr.soc_rst = 1'b1;

      tr.ext_int = 16'h0000;

      //-----------------------------
      // No MMR
      //-----------------------------
      tr.soc_mmr_write_en_i   = 1'b0;
      tr.soc_mmr_write_addr_i = 16'h0000;
      tr.soc_mmr_write_data_i = 32'h00000000;

      tr.soc_mmr_read_en_i    = 1'b0;
      tr.soc_mmr_read_addr_i  = 16'h0000;

      //-----------------------------
      // Random Global Enable
      //-----------------------------
      tr.global_int_enable_valid_i = 1'b1;
      tr.global_int_enable_bit_i   = enable_mask;

      //-----------------------------
      // No ACK
      //-----------------------------
      tr.soc_ack_read_valid_en = 1'b0;

      //-----------------------------
      // No EOI
      //-----------------------------
      tr.soc_eoi_valid_i = 1'b0;
      tr.soc_eoi_id_i    = 8'h00;

      //-----------------------------
      // Active Priority
      //-----------------------------
      tr.active_lvl_pr_i = 8'h00;

      finish_item(tr);

      //----------------------------------------------------------
      // Random Idle Cycles
      //----------------------------------------------------------

      repeat(idle_cycles)
      begin

        tr = int_seq_item::type_id::create("idle");

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

        //------------------------------------------------------------
    // End Transaction
    //------------------------------------------------------------

    tr = int_seq_item::type_id::create("end");

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

  endtask

endclass
