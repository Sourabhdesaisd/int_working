class tc020_random_interrupt_seq extends uvm_sequence #(int_seq_item);

  `uvm_object_utils(tc020_random_interrupt_seq)

  int_seq_item tr;

  bit [15:0] rand_irq;

  function new(string name="tc020_random_interrupt_seq");
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
    // Transaction-3 : Configure IRQ0 Priority = FF
    //------------------------------------------------------------
    tr = int_seq_item::type_id::create("cfg_irq0");

    start_item(tr);

    tr.soc_rst = 1'b1;
    tr.ext_int = 16'h0000;

    tr.soc_mmr_write_en_i   = 1'b1;
    tr.soc_mmr_write_addr_i = 16'h1003;
    tr.soc_mmr_write_data_i = 32'h000000FF;

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
    // Transaction-4 : Configure IRQ1 Priority = F7
    //------------------------------------------------------------
    tr = int_seq_item::type_id::create("cfg_irq1");

    start_item(tr);

    tr.soc_rst = 1'b1;
    tr.ext_int = 16'h0000;

    tr.soc_mmr_write_en_i   = 1'b1;
    tr.soc_mmr_write_addr_i = 16'h1007;
    tr.soc_mmr_write_data_i = 32'h000000F7;

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
    // Transaction-5 : Configure IRQ2 Priority = EB
    //------------------------------------------------------------
    tr = int_seq_item::type_id::create("cfg_irq2");

    start_item(tr);

    tr.soc_rst = 1'b1;
    tr.ext_int = 16'h0000;

    tr.soc_mmr_write_en_i   = 1'b1;
    tr.soc_mmr_write_addr_i = 16'h100B;
    tr.soc_mmr_write_data_i = 32'h000000EB;

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
    // Transaction-6 : Configure IRQ3 Priority = D0
    //------------------------------------------------------------
    tr = int_seq_item::type_id::create("cfg_irq3");

    start_item(tr);

    tr.soc_rst = 1'b1;
    tr.ext_int = 16'h0000;

    tr.soc_mmr_write_en_i   = 1'b1;
    tr.soc_mmr_write_addr_i = 16'h100F;
    tr.soc_mmr_write_data_i = 32'h000000D0;

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
    // Transaction-7 : Configure IRQ4 Priority = C0
    //------------------------------------------------------------
    tr = int_seq_item::type_id::create("cfg_irq4");

    start_item(tr);

    tr.soc_rst = 1'b1;
    tr.ext_int = 16'h0000;

    tr.soc_mmr_write_en_i   = 1'b1;
    tr.soc_mmr_write_addr_i = 16'h1013;
    tr.soc_mmr_write_data_i = 32'h000000C0;

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
    // Transaction-8 : Enable IRQ0-IRQ4
    //------------------------------------------------------------
    tr = int_seq_item::type_id::create("enable_irq0_4");

    start_item(tr);

    tr.soc_rst = 1'b1;
    tr.ext_int = 16'h0000;

    tr.soc_mmr_write_en_i   = 1'b0;
    tr.soc_mmr_write_addr_i = 16'h0000;
    tr.soc_mmr_write_data_i = 32'h00000000;

    tr.soc_mmr_read_en_i    = 1'b0;
    tr.soc_mmr_read_addr_i  = 16'h0000;

    tr.global_int_enable_valid_i = 1'b1;
    tr.global_int_enable_bit_i   = 16'h001F;

    tr.soc_ack_read_valid_en = 1'b0;

    tr.soc_eoi_valid_i = 1'b0;
    tr.soc_eoi_id_i    = 8'h00;

    tr.active_lvl_pr_i = 8'h00;

    finish_item(tr);

        //------------------------------------------------------------
    // Random Interrupt Verification
    // 20 Random Iterations
    //------------------------------------------------------------
    repeat (20) begin

      rand_irq = $urandom_range(1, 16'h001F);

      //------------------------------------------------------------
      // Random Transaction-1 : Assert Random Interrupt(s)
      //------------------------------------------------------------
      tr = int_seq_item::type_id::create("random_assert");

      start_item(tr);

      tr.soc_rst = 1'b1;

      tr.ext_int = rand_irq;

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
      // Random Transaction-2 : Wait One Transaction
      //------------------------------------------------------------
      tr = int_seq_item::type_id::create("random_wait");

      start_item(tr);

      tr.soc_rst = 1'b1;

      tr.ext_int = rand_irq;

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
      // Random Transaction-3 : ACK
      //------------------------------------------------------------
      tr = int_seq_item::type_id::create("random_ack");

      start_item(tr);

      tr.soc_rst = 1'b1;

      tr.ext_int = rand_irq;

      tr.soc_mmr_write_en_i   = 1'b0;
      tr.soc_mmr_write_addr_i = 16'h0000;
      tr.soc_mmr_write_data_i = 32'h00000000;

      tr.soc_mmr_read_en_i    = 1'b0;
      tr.soc_mmr_read_addr_i  = 16'h0000;

      tr.global_int_enable_valid_i = 1'b0;
      tr.global_int_enable_bit_i   = 16'h0000;

      tr.soc_ack_read_valid_en = 1'b1;

      tr.soc_eoi_valid_i = 1'b0;
      tr.soc_eoi_id_i    = 8'h00;

      tr.active_lvl_pr_i = 8'h00;

      finish_item(tr);

      //------------------------------------------------------------
      // Random Transaction-4 : ACK Low
      //------------------------------------------------------------
      tr = int_seq_item::type_id::create("random_ack_low");

      start_item(tr);

      tr.soc_rst = 1'b1;

      tr.ext_int = rand_irq;

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
      // Random Transaction-5 : Remove All Random Interrupts
      //------------------------------------------------------------
      tr = int_seq_item::type_id::create("random_remove");

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

    end // repeat(20)

    //------------------------------------------------------------
    // Transaction-9 : Disable Global Interrupt Enable
    //------------------------------------------------------------
    tr = int_seq_item::type_id::create("disable_global_enable");

    start_item(tr);

    tr.soc_rst = 1'b1;

    tr.ext_int = 16'h0000;

    tr.soc_mmr_write_en_i   = 1'b0;
    tr.soc_mmr_write_addr_i = 16'h0000;
    tr.soc_mmr_write_data_i = 32'h00000000;

    tr.soc_mmr_read_en_i    = 1'b0;
    tr.soc_mmr_read_addr_i  = 16'h0000;

    tr.global_int_enable_valid_i = 1'b1;
    tr.global_int_enable_bit_i   = 16'h0000;

    tr.soc_ack_read_valid_en = 1'b0;

    tr.soc_eoi_valid_i = 1'b0;
    tr.soc_eoi_id_i    = 8'h00;

    tr.active_lvl_pr_i = 8'h00;

    finish_item(tr);

  endtask

endclass
