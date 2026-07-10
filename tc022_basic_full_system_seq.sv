class tc022_basic_full_system_seq extends uvm_sequence #(int_seq_item);

  `uvm_object_utils(tc022_basic_full_system_seq)

  int_seq_item tr;

  function new(string name="tc022_basic_full_system_seq");
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
  // Transaction-3 : Program IRQ0 Control Register
  //------------------------------------------------------------
  tr = int_seq_item::type_id::create("write_irq0_priority");
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
  // Transaction-4 : Idle
  //------------------------------------------------------------
  tr = int_seq_item::type_id::create("idle_after_write");
  start_item(tr);

  tr.soc_rst = 1'b1;
  tr.ext_int = 16'h0000;

  tr.soc_mmr_write_en_i=0;
  tr.soc_mmr_read_en_i =0;

  tr.global_int_enable_valid_i=0;
  tr.global_int_enable_bit_i  =16'h0000;

  tr.soc_ack_read_valid_en=0;

  tr.soc_eoi_valid_i=0;
  tr.soc_eoi_id_i=0;

  tr.active_lvl_pr_i=0;

  finish_item(tr);


  //------------------------------------------------------------
  // Transaction-5 : Read Back IRQ0 Register
  //------------------------------------------------------------
  tr = int_seq_item::type_id::create("read_irq0");
  start_item(tr);

  tr.soc_rst = 1'b1;

  tr.ext_int = 16'h0000;

  tr.soc_mmr_write_en_i=0;

  tr.soc_mmr_read_en_i=1;
  tr.soc_mmr_read_addr_i=16'h1003;

  tr.global_int_enable_valid_i=0;
  tr.global_int_enable_bit_i=16'h0000;

  tr.soc_ack_read_valid_en=0;

  tr.soc_eoi_valid_i=0;
  tr.soc_eoi_id_i=0;

  tr.active_lvl_pr_i=0;

  finish_item(tr);


  //------------------------------------------------------------
  // Transaction-6 : Enable IRQ0
  //------------------------------------------------------------
  tr = int_seq_item::type_id::create("enable_irq0");
  start_item(tr);

  tr.soc_rst=1;

  tr.ext_int=16'h0000;

  tr.soc_mmr_write_en_i=0;
  tr.soc_mmr_read_en_i=0;

  tr.global_int_enable_valid_i=1;
  tr.global_int_enable_bit_i=16'h0001;

  tr.soc_ack_read_valid_en=0;

  tr.soc_eoi_valid_i=0;
  tr.soc_eoi_id_i=0;

  tr.active_lvl_pr_i=0;

  finish_item(tr);


  //------------------------------------------------------------
  // Transaction-7 : Idle after Enable
  //------------------------------------------------------------
  tr = int_seq_item::type_id::create("idle_enable");
  start_item(tr);

  tr.soc_rst=1;

  tr.ext_int=16'h0000;

  tr.soc_mmr_write_en_i=0;
  tr.soc_mmr_read_en_i=0;

  tr.global_int_enable_valid_i=0;

  // Keep enable value alive
  tr.global_int_enable_bit_i=16'h0001;

  tr.soc_ack_read_valid_en=0;

  tr.soc_eoi_valid_i=0;
  tr.soc_eoi_id_i=0;

  tr.active_lvl_pr_i=0;

  finish_item(tr);


  //------------------------------------------------------------
  // Transaction-8 : Assert IRQ0
  //------------------------------------------------------------
  tr = int_seq_item::type_id::create("assert_irq0");
  start_item(tr);

  tr.soc_rst=1;

  tr.ext_int=16'h0001;

  tr.soc_mmr_write_en_i=0;
  tr.soc_mmr_read_en_i=0;

  tr.global_int_enable_valid_i=0;

  // KEEP IRQ ENABLED
  tr.global_int_enable_bit_i=16'h0001;

  tr.soc_ack_read_valid_en=0;

  tr.soc_eoi_valid_i=0;
  tr.soc_eoi_id_i=0;

  tr.active_lvl_pr_i=0;

  finish_item(tr);


    //------------------------------------------------------------
  // Transaction-9 : Wait-1
  //------------------------------------------------------------
  tr = int_seq_item::type_id::create("wait1");
  start_item(tr);

  tr.soc_rst = 1'b1;
  tr.ext_int = 16'h0001;

  tr.soc_mmr_write_en_i = 1'b0;
  tr.soc_mmr_read_en_i  = 1'b0;

  tr.global_int_enable_valid_i = 1'b0;
  tr.global_int_enable_bit_i   = 16'h0001;

  tr.soc_ack_read_valid_en = 1'b0;

  tr.soc_eoi_valid_i = 1'b0;
  tr.soc_eoi_id_i    = 8'h00;

  tr.active_lvl_pr_i = 8'h00;

  finish_item(tr);


  //------------------------------------------------------------
  // Transaction-10 : Wait-2
  //------------------------------------------------------------
  tr = int_seq_item::type_id::create("wait2");
  start_item(tr);

  tr.soc_rst = 1'b1;
  tr.ext_int = 16'h0001;

  tr.soc_mmr_write_en_i = 1'b0;
  tr.soc_mmr_read_en_i  = 1'b0;

  tr.global_int_enable_valid_i = 1'b0;
  tr.global_int_enable_bit_i   = 16'h0001;

  tr.soc_ack_read_valid_en = 1'b0;

  tr.soc_eoi_valid_i = 1'b0;
  tr.soc_eoi_id_i    = 8'h00;

  tr.active_lvl_pr_i = 8'h00;

  finish_item(tr);


  //------------------------------------------------------------
  // Transaction-11 : Wait-3
  //------------------------------------------------------------
  tr = int_seq_item::type_id::create("wait3");
  start_item(tr);

  tr.soc_rst = 1'b1;
  tr.ext_int = 16'h0001;

  tr.soc_mmr_write_en_i = 1'b0;
  tr.soc_mmr_read_en_i  = 1'b0;

  tr.global_int_enable_valid_i = 1'b0;
  tr.global_int_enable_bit_i   = 16'h0001;

  tr.soc_ack_read_valid_en = 1'b0;

  tr.soc_eoi_valid_i = 1'b0;
  tr.soc_eoi_id_i    = 8'h00;

  tr.active_lvl_pr_i = 8'h00;

  finish_item(tr);


  //------------------------------------------------------------
  // Transaction-12 : Wait-4
  //------------------------------------------------------------
  tr = int_seq_item::type_id::create("wait4");
  start_item(tr);

  tr.soc_rst = 1'b1;
  tr.ext_int = 16'h0001;

  tr.soc_mmr_write_en_i = 1'b0;
  tr.soc_mmr_read_en_i  = 1'b0;

  tr.global_int_enable_valid_i = 1'b0;
  tr.global_int_enable_bit_i   = 16'h0001;

  tr.soc_ack_read_valid_en = 1'b0;

  tr.soc_eoi_valid_i = 1'b0;
  tr.soc_eoi_id_i    = 8'h00;

  tr.active_lvl_pr_i = 8'h00;

  finish_item(tr);


  //------------------------------------------------------------
  // Transaction-13 : ACK IRQ0
  //------------------------------------------------------------
  tr = int_seq_item::type_id::create("ack_irq0");
  start_item(tr);

  tr.soc_rst = 1'b1;

  // KEEP INTERRUPT ASSERTED
  tr.ext_int = 16'h0001;

  tr.soc_mmr_write_en_i = 1'b0;
  tr.soc_mmr_read_en_i  = 1'b0;

  tr.global_int_enable_valid_i = 1'b0;
  tr.global_int_enable_bit_i   = 16'h0001;

  tr.soc_ack_read_valid_en = 1'b1;

  tr.soc_eoi_valid_i = 1'b0;
  tr.soc_eoi_id_i    = 8'h00;

  tr.active_lvl_pr_i = 8'h00;

  finish_item(tr);


  //------------------------------------------------------------
  // Transaction-14 : ACK LOW
  //------------------------------------------------------------
  tr = int_seq_item::type_id::create("ack_low");
  start_item(tr);

  tr.soc_rst = 1'b1;

  // STILL KEEP IRQ ASSERTED
  tr.ext_int = 16'h0001;

  tr.soc_mmr_write_en_i = 1'b0;
  tr.soc_mmr_read_en_i  = 1'b0;

  tr.global_int_enable_valid_i = 1'b0;
  tr.global_int_enable_bit_i   = 16'h0001;

  tr.soc_ack_read_valid_en = 1'b0;

  tr.soc_eoi_valid_i = 1'b0;
  tr.soc_eoi_id_i    = 8'h00;

  tr.active_lvl_pr_i = 8'h00;

  finish_item(tr);


  //------------------------------------------------------------
  // Transaction-15 : Wait After ACK
  //------------------------------------------------------------
  tr = int_seq_item::type_id::create("wait_after_ack");
  start_item(tr);

  tr.soc_rst = 1'b1;

  tr.ext_int = 16'h0001;

  tr.soc_mmr_write_en_i = 1'b0;
  tr.soc_mmr_read_en_i  = 1'b0;

  tr.global_int_enable_valid_i = 1'b0;
  tr.global_int_enable_bit_i   = 16'h0001;

  tr.soc_ack_read_valid_en = 1'b0;

  tr.soc_eoi_valid_i = 1'b0;
  tr.soc_eoi_id_i    = 8'h00;

  tr.active_lvl_pr_i = 8'h00;

  finish_item(tr);

    //------------------------------------------------------------
  // Transaction-16 : Remove IRQ0
  //------------------------------------------------------------
  tr = int_seq_item::type_id::create("remove_irq0");

  start_item(tr);

  tr.soc_rst = 1'b1;

  tr.ext_int = 16'h0000;

  tr.soc_mmr_write_en_i   = 1'b0;
  tr.soc_mmr_write_addr_i = 16'h0000;
  tr.soc_mmr_write_data_i = 32'h00000000;

  tr.soc_mmr_read_en_i    = 1'b0;
  tr.soc_mmr_read_addr_i  = 16'h0000;

  tr.global_int_enable_valid_i = 1'b0;
  tr.global_int_enable_bit_i   = 16'h0001;

  tr.soc_ack_read_valid_en = 1'b0;

  tr.soc_eoi_valid_i = 1'b0;
  tr.soc_eoi_id_i    = 8'h00;

  tr.active_lvl_pr_i = 8'h00;

  finish_item(tr);


  //------------------------------------------------------------
  // Transaction-17 : Wait After Remove
  //------------------------------------------------------------
  tr = int_seq_item::type_id::create("wait_after_remove");

  start_item(tr);

  tr.soc_rst = 1'b1;

  tr.ext_int = 16'h0000;

  tr.soc_mmr_write_en_i   = 1'b0;
  tr.soc_mmr_write_addr_i = 16'h0000;
  tr.soc_mmr_write_data_i = 32'h00000000;

  tr.soc_mmr_read_en_i    = 1'b0;
  tr.soc_mmr_read_addr_i  = 16'h0000;

  tr.global_int_enable_valid_i = 1'b0;
  tr.global_int_enable_bit_i   = 16'h0001;

  tr.soc_ack_read_valid_en = 1'b0;

  tr.soc_eoi_valid_i = 1'b0;
  tr.soc_eoi_id_i    = 8'h00;

  tr.active_lvl_pr_i = 8'h00;

  finish_item(tr);


  //------------------------------------------------------------
  // Transaction-18 : Send EOI
  //------------------------------------------------------------
  tr = int_seq_item::type_id::create("send_eoi");

  start_item(tr);

  tr.soc_rst = 1'b1;

  tr.ext_int = 16'h0000;

  tr.soc_mmr_write_en_i   = 1'b0;
  tr.soc_mmr_write_addr_i = 16'h0000;
  tr.soc_mmr_write_data_i = 32'h00000000;

  tr.soc_mmr_read_en_i    = 1'b0;
  tr.soc_mmr_read_addr_i  = 16'h0000;

  tr.global_int_enable_valid_i = 1'b0;
  tr.global_int_enable_bit_i   = 16'h0001;

  tr.soc_ack_read_valid_en = 1'b0;

  tr.soc_eoi_valid_i = 1'b1;
  tr.soc_eoi_id_i    = 8'h10;

  tr.active_lvl_pr_i = 8'h00;

  finish_item(tr);


  //------------------------------------------------------------
  // Transaction-19 : EOI Low
  //------------------------------------------------------------
  tr = int_seq_item::type_id::create("eoi_low");

  start_item(tr);

  tr.soc_rst = 1'b1;

  tr.ext_int = 16'h0000;

  tr.soc_mmr_write_en_i   = 1'b0;
  tr.soc_mmr_write_addr_i = 16'h0000;
  tr.soc_mmr_write_data_i = 32'h00000000;

  tr.soc_mmr_read_en_i    = 1'b0;
  tr.soc_mmr_read_addr_i  = 16'h0000;

  tr.global_int_enable_valid_i = 1'b0;
  tr.global_int_enable_bit_i   = 16'h0001;

  tr.soc_ack_read_valid_en = 1'b0;

  tr.soc_eoi_valid_i = 1'b0;
  tr.soc_eoi_id_i    = 8'h00;

  tr.active_lvl_pr_i = 8'h00;

  finish_item(tr);


  //------------------------------------------------------------
  // Transaction-20 : Read ACK Register
  //------------------------------------------------------------
  tr = int_seq_item::type_id::create("read_ack");

  start_item(tr);

  tr.soc_rst = 1'b1;

  tr.ext_int = 16'h0000;

  tr.soc_mmr_write_en_i   = 1'b0;
  tr.soc_mmr_write_addr_i = 16'h0000;
  tr.soc_mmr_write_data_i = 32'h00000000;

  tr.soc_mmr_read_en_i    = 1'b1;

  // Replace with actual ACK register address if different
  tr.soc_mmr_read_addr_i  = 16'h0000;

  tr.global_int_enable_valid_i = 1'b0;
  tr.global_int_enable_bit_i   = 16'h0001;

  tr.soc_ack_read_valid_en = 1'b0;

  tr.soc_eoi_valid_i = 1'b0;
  tr.soc_eoi_id_i    = 8'h00;

  tr.active_lvl_pr_i = 8'h00;

  finish_item(tr);


  //------------------------------------------------------------
  // Transaction-21 : Disable Global Enable
  //------------------------------------------------------------
  tr = int_seq_item::type_id::create("disable_global");

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
