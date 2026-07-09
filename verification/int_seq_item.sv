class int_seq_item extends uvm_sequence_item;

  //============================================================
  // DUT OUTPUTS SAMPLED BY MONITOR
  //============================================================
  logic [31:0] soc_mmr_read_data_o;
  logic [7:0]  soc_ack_int_id_o;
  logic        interrupt_request_o;
  logic [7:0]  highest_pending_lvl_pr_o;

  //============================================================
  // DUT INPUTS / DRIVER FIELDS
  //============================================================
  rand logic        soc_rst;

  rand logic        soc_mmr_write_en_i;
  rand logic [15:0] soc_mmr_write_addr_i;
  rand logic [31:0] soc_mmr_write_data_i;

  rand logic        soc_mmr_read_en_i;
  rand logic [15:0] soc_mmr_read_addr_i;

  rand logic        soc_ack_read_valid_en;

  rand logic        soc_eoi_valid_i;
  rand logic [7:0]  soc_eoi_id_i;

  rand logic [7:0]  active_lvl_pr_i;

  // Changed from 48-bit to 16-bit
  rand logic [15:0] global_int_enable_bit_i;
  rand logic        global_int_enable_valid_i;

  //============================================================
  // EXTERNAL INTERRUPTS
  // New RTL supports only ext_int0_i to ext_int15_i
  //============================================================
  rand logic ext_int0_i;
  rand logic ext_int1_i;
  rand logic ext_int2_i;
  rand logic ext_int3_i;
  rand logic ext_int4_i;
  rand logic ext_int5_i;
  rand logic ext_int6_i;
  rand logic ext_int7_i;
  rand logic ext_int8_i;
  rand logic ext_int9_i;
  rand logic ext_int10_i;
  rand logic ext_int11_i;
  rand logic ext_int12_i;
  rand logic ext_int13_i;
  rand logic ext_int14_i;
  rand logic ext_int15_i;

  // Packed vector used by monitor/scoreboard for simple loops
  logic [15:0] ext_int;

  longint unsigned mon_cycle;

  //============================================================
  // DEBUG INPUTS
  //============================================================
  rand logic debug_mode_valid_i;
  rand logic debug_mode_reset_i;
  rand logic debug_ndm_reset_i;

  //============================================================
  // EXPECTED VALUES CALCULATED BY MONITOR / REF MODEL
  //============================================================
  logic        exp_valid;
  logic        exp_irq_req;
  logic [7:0]  exp_ack_id;
  logic [7:0]  exp_highest_lvl_pr;

  bit        exp_mmr_read_valid;
  bit [31:0] exp_mmr_read_data;

 
  //============================================================
  // HELPER FUNCTION
  // Converts individual interrupt pins into packed vector.
  //============================================================
  function void pack_ext_int();

    ext_int[0]  = ext_int0_i;
    ext_int[1]  = ext_int1_i;
    ext_int[2]  = ext_int2_i;
    ext_int[3]  = ext_int3_i;
    ext_int[4]  = ext_int4_i;
    ext_int[5]  = ext_int5_i;
    ext_int[6]  = ext_int6_i;
    ext_int[7]  = ext_int7_i;
    ext_int[8]  = ext_int8_i;
    ext_int[9]  = ext_int9_i;
    ext_int[10] = ext_int10_i;
    ext_int[11] = ext_int11_i;
    ext_int[12] = ext_int12_i;
    ext_int[13] = ext_int13_i;
    ext_int[14] = ext_int14_i;
    ext_int[15] = ext_int15_i;

  endfunction

  //============================================================
  // FACTORY REGISTRATION
  //============================================================
  `uvm_object_utils_begin(int_seq_item)

    `uvm_field_int(soc_mmr_read_data_o,       UVM_ALL_ON)
    `uvm_field_int(soc_ack_int_id_o,          UVM_ALL_ON)
    `uvm_field_int(interrupt_request_o,       UVM_ALL_ON)
    `uvm_field_int(highest_pending_lvl_pr_o,  UVM_ALL_ON)

    `uvm_field_int(soc_rst,                   UVM_ALL_ON)

    `uvm_field_int(soc_mmr_write_en_i,        UVM_ALL_ON)
    `uvm_field_int(soc_mmr_write_addr_i,      UVM_ALL_ON)
    `uvm_field_int(soc_mmr_write_data_i,      UVM_ALL_ON)

    `uvm_field_int(soc_mmr_read_en_i,         UVM_ALL_ON)
    `uvm_field_int(soc_mmr_read_addr_i,       UVM_ALL_ON)

    `uvm_field_int(soc_ack_read_valid_en,     UVM_ALL_ON)

    `uvm_field_int(soc_eoi_valid_i,           UVM_ALL_ON)
    `uvm_field_int(soc_eoi_id_i,              UVM_ALL_ON)

    `uvm_field_int(active_lvl_pr_i,           UVM_ALL_ON)

    `uvm_field_int(global_int_enable_bit_i,   UVM_ALL_ON)
    `uvm_field_int(global_int_enable_valid_i, UVM_ALL_ON)

    `uvm_field_int(ext_int0_i,                UVM_ALL_ON)
    `uvm_field_int(ext_int1_i,                UVM_ALL_ON)
    `uvm_field_int(ext_int2_i,                UVM_ALL_ON)
    `uvm_field_int(ext_int3_i,                UVM_ALL_ON)
    `uvm_field_int(ext_int4_i,                UVM_ALL_ON)
    `uvm_field_int(ext_int5_i,                UVM_ALL_ON)
    `uvm_field_int(ext_int6_i,                UVM_ALL_ON)
    `uvm_field_int(ext_int7_i,                UVM_ALL_ON)
    `uvm_field_int(ext_int8_i,                UVM_ALL_ON)
    `uvm_field_int(ext_int9_i,                UVM_ALL_ON)
    `uvm_field_int(ext_int10_i,               UVM_ALL_ON)
    `uvm_field_int(ext_int11_i,               UVM_ALL_ON)
    `uvm_field_int(ext_int12_i,               UVM_ALL_ON)
    `uvm_field_int(ext_int13_i,               UVM_ALL_ON)
    `uvm_field_int(ext_int14_i,               UVM_ALL_ON)
    `uvm_field_int(ext_int15_i,               UVM_ALL_ON)

    `uvm_field_int(ext_int,                   UVM_ALL_ON)

    `uvm_field_int(debug_mode_valid_i,        UVM_ALL_ON)
    `uvm_field_int(debug_mode_reset_i,        UVM_ALL_ON)
    `uvm_field_int(debug_ndm_reset_i,         UVM_ALL_ON)

    `uvm_field_int(exp_valid,                 UVM_ALL_ON)
    `uvm_field_int(exp_irq_req,               UVM_ALL_ON)
    `uvm_field_int(exp_ack_id,                UVM_ALL_ON)
    `uvm_field_int(exp_highest_lvl_pr,        UVM_ALL_ON)
    `uvm_field_int(mon_cycle,                 UVM_ALL_ON)

  `uvm_object_utils_end

  function new(string name = "int_seq_item");
    super.new(name);
  endfunction

endclass
