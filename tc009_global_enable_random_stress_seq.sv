class tc009_global_enable_random_stress_seq extends uvm_sequence #(int_seq_item);

  `uvm_object_utils(tc009_global_enable_random_stress_seq)

  int_seq_item tr;

  rand bit [15:0] enable_mask;

  rand int unsigned idle_cycles;

  rand int unsigned iterations;

  function new(string name="tc009_global_enable_random_stress_seq");
    super.new(name);
  endfunction

    constraint iter_c
  {
      iterations inside {[500:1000]};
  }

  constraint idle_c
  {
      idle_cycles inside {[0:5]};
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

    assert(this.randomize());

repeat(iterations)
begin

    assert(this.randomize());

    //--------------------------------------------------
    // Every 100th iteration enable all
    //--------------------------------------------------

    if(($urandom%100)==0)
        enable_mask = 16'hFFFF;

    //--------------------------------------------------
    // Every 150th iteration disable all
    //--------------------------------------------------

    if(($urandom%150)==0)
        enable_mask = 16'h0000;

    //--------------------------------------------------
    // Every 200th iteration AAAA
    //--------------------------------------------------

    if(($urandom%200)==0)
        enable_mask = 16'hAAAA;

    //--------------------------------------------------
    // Every 250th iteration 5555
    //--------------------------------------------------

    if(($urandom%250)==0)
        enable_mask = 16'h5555;

    //--------------------------------------------------
    // Program Random Mask
    //--------------------------------------------------

    tr = int_seq_item::type_id::create("random_enable");

    start_item(tr);

    tr.soc_rst = 1'b1;

    tr.ext_int = 16'h0000;

    tr.soc_mmr_write_en_i = 0;
    tr.soc_mmr_read_en_i  = 0;

    tr.global_int_enable_valid_i = 1'b1;
    tr.global_int_enable_bit_i   = enable_mask;

    tr.soc_ack_read_valid_en = 0;

    tr.soc_eoi_valid_i = 0;

    tr.active_lvl_pr_i = 0;

    finish_item(tr);

    //--------------------------------------------------
    // Random Idle
    //--------------------------------------------------

    repeat(idle_cycles)
    begin

        tr = int_seq_item::type_id::create("idle");

        start_item(tr);

        tr.soc_rst = 1'b1;

        tr.ext_int = 0;

        tr.soc_mmr_write_en_i = 0;
        tr.soc_mmr_read_en_i  = 0;

        tr.global_int_enable_valid_i = 0;

        tr.soc_ack_read_valid_en = 0;

        tr.soc_eoi_valid_i = 0;

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
