
module tb_top;

  import uvm_pkg::*;
  import int_pkg::*;

  bit soc_clk;

  always #5 soc_clk = ~soc_clk;

  intf vif(soc_clk);

  initial begin
    uvm_config_db#(virtual intf)::set(null, "*", "vif", vif);
    run_test("int_base_test");
  end

  zilla_interrupt_control dut (
    .soc_clk                  (soc_clk),
    .soc_rst                  (vif.soc_rst),

    .soc_mmr_write_en_i       (vif.soc_mmr_write_en_i),
    .soc_mmr_write_addr_i     (vif.soc_mmr_write_addr_i),
    .soc_mmr_write_data_i     (vif.soc_mmr_write_data_i),

    .soc_mmr_read_en_i        (vif.soc_mmr_read_en_i),
    .soc_mmr_read_addr_i      (vif.soc_mmr_read_addr_i),
    .soc_mmr_read_data_o      (vif.soc_mmr_read_data_o),

    .soc_ack_read_valid_en    (vif.soc_ack_read_valid_en),
    .soc_ack_int_id_o         (vif.soc_ack_int_id_o),

    .soc_eoi_valid_i          (vif.soc_eoi_valid_i),
    .soc_eoi_id_i             (vif.soc_eoi_id_i),

    .active_lvl_pr_i          (vif.active_lvl_pr_i),
    .interrupt_request_o      (vif.interrupt_request_o),

    .global_int_enable_bit_i  (vif.global_int_enable_bit_i),
    .global_int_enable_valid_i(vif.global_int_enable_valid_i),

    .highest_pending_lvl_pr_o (vif.highest_pending_lvl_pr_o),

    .ext_int0_i               (vif.ext_int[0]),
    .ext_int1_i               (vif.ext_int[1]),
    .ext_int2_i               (vif.ext_int[2]),
    .ext_int3_i               (vif.ext_int[3]),
    .ext_int4_i               (vif.ext_int[4]),
    .ext_int5_i               (vif.ext_int[5]),
    .ext_int6_i               (vif.ext_int[6]),
    .ext_int7_i               (vif.ext_int[7]),
    .ext_int8_i               (vif.ext_int[8]),
    .ext_int9_i               (vif.ext_int[9]),
    .ext_int10_i              (vif.ext_int[10]),
    .ext_int11_i              (vif.ext_int[11]),
    .ext_int12_i              (vif.ext_int[12]),
    .ext_int13_i              (vif.ext_int[13]),
    .ext_int14_i              (vif.ext_int[14]),
    .ext_int15_i              (vif.ext_int[15]),
    
    

    .debug_mode_valid_i       (vif.debug_mode_valid_i),
    .debug_mode_reset_i       (vif.debug_mode_reset_i),
    .debug_ndm_reset_i        (vif.debug_ndm_reset_i),
    .wdt_reset_o              (vif.wdt_reset_o)
  );

//assign vif.soc_ack_int_id_w =   dut.soc_ack_int_id_w;
 
 initial begin
    $shm_open("wave.shm");
    $shm_probe("ACTMF");
  end

endmodule
