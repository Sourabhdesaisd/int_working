class mmr_write_single_seq extends uvm_sequence #(int_seq_item);

  `uvm_object_utils(mmr_write_single_seq)

  function new(string name = "mmr_write_single_seq");
    super.new(name);
  endfunction

  task body();

    int_seq_item tr;

    // ------------------------------------------------------------
    // 1. RESET
    // ------------------------------------------------------------
    tr = int_seq_item::type_id::create("reset_tr");
    start_item(tr);

    tr.soc_rst = 1'b1;
    tr.ext_int = 16'h0000;

    tr.soc_mmr_write_en_i   = 1'b0;
    tr.soc_mmr_write_addr_i = 16'h0000;
    tr.soc_mmr_write_data_i = 32'h00000000;

    tr.soc_mmr_read_en_i    = 1'b0;
    tr.soc_mmr_read_addr_i  = 16'h0000;

    tr.soc_ack_read_valid_en = 1'b0;

    tr.soc_eoi_valid_i = 1'b0;
    tr.soc_eoi_id_i    = 8'h00;

    tr.global_int_enable_bit_i   = 16'h0000;
    tr.global_int_enable_valid_i = 1'b0;

    tr.active_lvl_pr_i = 8'h00;

    tr.debug_mode_valid_i = 1'b0;
    tr.debug_mode_reset_i = 1'b0;
    tr.debug_ndm_reset_i  = 1'b0;

    finish_item(tr);


    // ------------------------------------------------------------
    // 2. WRITE IRQ0 CONTROL REGISTER
    // Address : 0x1003
    // Data    : 0x55
    // ------------------------------------------------------------
    tr = int_seq_item::type_id::create("write_irq0_ctl");
    start_item(tr);

    tr.soc_rst = 1'b0;
    tr.ext_int = 16'h0000;

    tr.soc_mmr_write_en_i   = 1'b1;
    tr.soc_mmr_write_addr_i = 16'h1003;
    tr.soc_mmr_write_data_i = 32'h00000055;

    tr.soc_mmr_read_en_i    = 1'b0;
    tr.soc_mmr_read_addr_i  = 16'h0000;

    tr.soc_ack_read_valid_en = 1'b0;

    tr.soc_eoi_valid_i = 1'b0;
    tr.soc_eoi_id_i    = 8'h00;

    tr.global_int_enable_bit_i   = 16'h0000;
    tr.global_int_enable_valid_i = 1'b0;

    tr.active_lvl_pr_i = 8'h00;

    tr.debug_mode_valid_i = 1'b0;
    tr.debug_mode_reset_i = 1'b0;
    tr.debug_ndm_reset_i  = 1'b0;

    finish_item(tr);


    // ------------------------------------------------------------
    // 3. IDLE
    // ------------------------------------------------------------
    tr = int_seq_item::type_id::create("idle");
    start_item(tr);

    tr.soc_rst = 1'b0;
    tr.ext_int = 16'h0000;

    tr.soc_mmr_write_en_i   = 1'b0;
    tr.soc_mmr_write_addr_i = 16'h0000;
    tr.soc_mmr_write_data_i = 32'h00000000;

    tr.soc_mmr_read_en_i    = 1'b0;
    tr.soc_mmr_read_addr_i  = 16'h0000;

    tr.soc_ack_read_valid_en = 1'b0;

    tr.soc_eoi_valid_i = 1'b0;
    tr.soc_eoi_id_i    = 8'h00;

    tr.global_int_enable_bit_i   = 16'h0000;
    tr.global_int_enable_valid_i = 1'b0;

    tr.active_lvl_pr_i = 8'h00;

    tr.debug_mode_valid_i = 1'b0;
    tr.debug_mode_reset_i = 1'b0;
    tr.debug_ndm_reset_i  = 1'b0;

    finish_item(tr);

  endtask

endclass
