class tc001_mmr_single_rw_seq extends uvm_sequence #(int_seq_item);

  `uvm_object_utils(tc001_mmr_single_rw_seq)

  int_seq_item tr;

  function new(string name = "tc001_mmr_single_rw_seq");
    super.new(name);
  endfunction

  task body();

    //------------------------------------------------------------
    // Transaction-1 : Apply Reset
    //------------------------------------------------------------
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

    //------------------------------------------------------------
    // Transaction-2 : Release Reset
    //------------------------------------------------------------
    tr = int_seq_item::type_id::create("release_reset");
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

    //------------------------------------------------------------
    // Transaction-3 : Write IRQ0 MMR
    //------------------------------------------------------------
    tr = int_seq_item::type_id::create("write_irq0");
    start_item(tr);

    tr.soc_rst = 1'b1;

    tr.ext_int = 16'h0000;

    tr.soc_mmr_write_en_i   = 1'b1;
    tr.soc_mmr_write_addr_i = 16'h1003;
    tr.soc_mmr_write_data_i = 32'h12345678;

    tr.soc_mmr_read_en_i    = 1'b0;
    tr.soc_mmr_read_addr_i  = 16'h0000;

    tr.global_int_enable_valid_i = 1'b0;
    tr.global_int_enable_bit_i   = 16'h0000;

    tr.soc_ack_read_valid_en = 1'b0;

    tr.soc_eoi_valid_i = 1'b0;
    tr.soc_eoi_id_i    = 8'h00;

    tr.active_lvl_pr_i = 8'h00;

    finish_item(tr);

    //------------------------------------------------------------
    // Transaction-4 : Idle
    //------------------------------------------------------------
    tr = int_seq_item::type_id::create("idle");
    start_item(tr);

    tr.soc_rst = 1'b1;

    tr.ext_int = 16'h0000;

    tr.soc_mmr_write_en_i = 1'b0;
    tr.soc_mmr_read_en_i  = 1'b0;

    tr.global_int_enable_valid_i = 1'b0;
    tr.soc_ack_read_valid_en      = 1'b0;
    tr.soc_eoi_valid_i            = 1'b0;

    finish_item(tr);

    //------------------------------------------------------------
    // Transaction-5 : Read IRQ0 MMR
    //------------------------------------------------------------
    tr = int_seq_item::type_id::create("read_irq0");
    start_item(tr);

    tr.soc_rst = 1'b1;

    tr.ext_int = 16'h0000;

    tr.soc_mmr_write_en_i = 1'b0;

    tr.soc_mmr_read_en_i   = 1'b1;
    tr.soc_mmr_read_addr_i = 16'h1003;

    tr.global_int_enable_valid_i = 1'b0;
    tr.soc_ack_read_valid_en      = 1'b0;
    tr.soc_eoi_valid_i            = 1'b0;

    finish_item(tr);

    //------------------------------------------------------------
    // Transaction-6 : Idle
    //------------------------------------------------------------
    tr = int_seq_item::type_id::create("end");
    start_item(tr);

    tr.soc_rst = 1'b1;

    tr.ext_int = 16'h0000;

    tr.soc_mmr_write_en_i = 1'b0;
    tr.soc_mmr_read_en_i  = 1'b0;

    tr.global_int_enable_valid_i = 1'b0;
    tr.soc_ack_read_valid_en      = 1'b0;
    tr.soc_eoi_valid_i            = 1'b0;

    finish_item(tr);

  endtask

endclass
