/*`timescale 1ns/1ps

interface intf(input logic soc_clk);

  // ============================================================
  // Reset
  // ============================================================
  logic soc_rst;

  // ============================================================
  // MMR write interface from core
  // ============================================================
  logic        soc_mmr_write_en_i;
  logic [15:0] soc_mmr_write_addr_i;
  logic [31:0] soc_mmr_write_data_i;

  // ============================================================
  // MMR read interface from core
  // ============================================================
  logic        soc_mmr_read_en_i;
  logic [15:0] soc_mmr_read_addr_i;
  logic [31:0] soc_mmr_read_data_o;

  // ============================================================
  // ACK interface
  // ============================================================
  logic       soc_ack_read_valid_en;
  logic [7:0] soc_ack_int_id_o;

  // ============================================================
  // EOI interface
  // ============================================================
  logic       soc_eoi_valid_i;
  logic [7:0] soc_eoi_id_i;

  // ============================================================
  // Interrupt priority/status interface
  // ============================================================
  logic [7:0] active_lvl_pr_i;
  logic       interrupt_request_o;
  logic [7:0] highest_pending_lvl_pr_o;

  // ============================================================
  // Global interrupt enable
  // 16 interrupts only
  // ============================================================
  logic [15:0] global_int_enable_bit_i;
  logic        global_int_enable_valid_i;

  // ============================================================
  // External interrupt inputs
  // 16 interrupts only
  // ext_int[0]  -> ext_int0_i
  // ext_int[15] -> ext_int15_i
  // ============================================================
  logic [15:0] ext_int;

  // ============================================================
  // Debug / reset related signals
  // ============================================================
  logic debug_mode_valid_i;
  logic debug_mode_reset_i;
  logic debug_ndm_reset_i;
  logic wdt_reset_o;

endinterface*/


`timescale 1ns/1ps

interface intf(input logic soc_clk);

  logic soc_rst;

  logic        soc_mmr_write_en_i;
  logic [15:0] soc_mmr_write_addr_i;
  logic [31:0] soc_mmr_write_data_i;

  logic        soc_mmr_read_en_i;
  logic [15:0] soc_mmr_read_addr_i;
  logic [31:0] soc_mmr_read_data_o;

  logic       soc_ack_read_valid_en;
  logic [7:0] soc_ack_int_id_o;

  logic       soc_eoi_valid_i;
  logic [7:0] soc_eoi_id_i;

  logic [7:0] active_lvl_pr_i;
  logic       interrupt_request_o;
  logic [7:0] highest_pending_lvl_pr_o;

  logic [15:0] global_int_enable_bit_i;
  logic        global_int_enable_valid_i;

  logic [15:0] ext_int;

  logic debug_mode_valid_i;
  logic debug_mode_reset_i;
  logic debug_ndm_reset_i;
  logic wdt_reset_o;

  // ============================================================
  // ASSERTIONS
  // ============================================================

  // Reset active-low: when reset is active, outputs must be clean
  property p_reset_outputs_zero;
    @(posedge soc_clk)
    (soc_rst == 1'b0)
    |->
    (
      interrupt_request_o      == 1'b0 &&
      soc_ack_int_id_o         == 8'h00 &&
      highest_pending_lvl_pr_o == 8'h00
    );
  endproperty

  a_reset_outputs_zero:
  assert property(p_reset_outputs_zero)
  else
    $error("[ASSERT_FAIL] Reset outputs are not zero");


  // No X/Z on important DUT outputs after reset
  property p_no_x_on_outputs;
    @(posedge soc_clk)
    disable iff(soc_rst == 1'b0)

    !$isunknown({
      interrupt_request_o,
      soc_ack_int_id_o,
      highest_pending_lvl_pr_o,
      soc_mmr_read_data_o,
      wdt_reset_o
    });
  endproperty

  a_no_x_on_outputs:
  assert property(p_no_x_on_outputs)
  else
    $error("[ASSERT_FAIL] X/Z detected on DUT outputs");


  // ACK ID must be legal when non-zero
  property p_ack_id_valid_range;
    @(posedge soc_clk)
    disable iff(soc_rst == 1'b0)

    (soc_ack_int_id_o != 8'h00)
    |->
    (soc_ack_int_id_o inside {[8'h10:8'h1F]});
  endproperty

  a_ack_id_valid_range:
  assert property(p_ack_id_valid_range)
  else
    $error("[ASSERT_FAIL] ACK ID out of range");


  // EOI ID must be legal when EOI valid is high
  property p_eoi_id_valid_range;
    @(posedge soc_clk)
    disable iff(soc_rst == 1'b0)

    soc_eoi_valid_i
    |->
    (soc_eoi_id_i inside {[8'h10:8'h1F]});
  endproperty

  a_eoi_id_valid_range:
  assert property(p_eoi_id_valid_range)
  else
    $error("[ASSERT_FAIL] EOI ID out of range");




  // MMR write address must be IRQ CTL address
  property p_mmr_write_ctl_addr_legal;
    @(posedge soc_clk)
    disable iff(soc_rst == 1'b0)

    soc_mmr_write_en_i
    |->
    (
      (soc_mmr_write_addr_i >= 16'h1003) &&
      (soc_mmr_write_addr_i <= 16'h103F) &&
      (((soc_mmr_write_addr_i - 16'h1003) % 4) == 0)
    );
  endproperty

  a_mmr_write_ctl_addr_legal:
  assert property(p_mmr_write_ctl_addr_legal)
  else
    $error("[ASSERT_FAIL] Illegal MMR write address");


  // MMR read address must be IRQ CTL address
  property p_mmr_read_ctl_addr_legal;
    @(posedge soc_clk)
    disable iff(soc_rst == 1'b0)

    soc_mmr_read_en_i
    |->
    (
      (soc_mmr_read_addr_i >= 16'h1003) &&
      (soc_mmr_read_addr_i <= 16'h103F) &&
      (((soc_mmr_read_addr_i - 16'h1003) % 4) == 0)
    );
  endproperty

  a_mmr_read_ctl_addr_legal:
  assert property(p_mmr_read_ctl_addr_legal)
  else
    $error("[ASSERT_FAIL] Illegal MMR read address");


  // If all global enables are 0, interrupt request must stay low
  property p_no_irq_when_all_disabled;
    @(posedge soc_clk)
    disable iff(soc_rst == 1'b0)

    (global_int_enable_bit_i == 16'h0000)
    |->
    !interrupt_request_o;
  endproperty

  a_no_irq_when_all_disabled:
  assert property(p_no_irq_when_all_disabled)
  else
    $error("[ASSERT_FAIL] IRQ request asserted when all interrupts disabled");


  // Threshold blocking:
  // if highest pending level/priority is <= active threshold,
  // interrupt_request_o must be low.
  property p_threshold_blocks_irq;
    @(posedge soc_clk)
    disable iff(soc_rst == 1'b0)

    ((highest_pending_lvl_pr_o != 8'h00) &&
     (highest_pending_lvl_pr_o <= active_lvl_pr_i))
    |->
    !interrupt_request_o;
  endproperty

  a_threshold_blocks_irq:
  assert property(p_threshold_blocks_irq)
  else
    $error("[ASSERT_FAIL] Threshold did not block IRQ");


  // If external interrupt and enable are both present,
  // interrupt_request_o should assert within 1 to 10 cycles.
  property p_irq_generation_when_ext_enabled;
    @(posedge soc_clk)
    disable iff(soc_rst == 1'b0)

    ((ext_int & global_int_enable_bit_i) != 16'h0000)
    |->
    ##[1:10]
    interrupt_request_o;
  endproperty

  a_irq_generation_when_ext_enabled:
  assert property(p_irq_generation_when_ext_enabled)
  else
    $error("[ASSERT_FAIL] Enabled external IRQ did not generate interrupt_request_o");


  // ACK output should never be X when ACK request is made
  property p_ack_output_not_x_during_ack;
    @(posedge soc_clk)
    disable iff(soc_rst == 1'b0)

    soc_ack_read_valid_en
    |->
    ##[0:10]
    !$isunknown(soc_ack_int_id_o);
  endproperty

  a_ack_output_not_x_during_ack:
  assert property(p_ack_output_not_x_during_ack)
  else
    $error("[ASSERT_FAIL] ACK output became X/Z during ACK response window");


  // EOI valid should be only one cycle pulse
  property p_eoi_one_cycle_pulse;
    @(posedge soc_clk)
    disable iff(soc_rst == 1'b0)

    soc_eoi_valid_i
    |->
    ##1 !soc_eoi_valid_i;
  endproperty

  a_eoi_one_cycle_pulse:
  assert property(p_eoi_one_cycle_pulse)
  else
    $error("[ASSERT_FAIL] EOI valid is not one-cycle pulse");


  // ACK read valid should be only one cycle pulse
  property p_ack_read_one_cycle_pulse;
    @(posedge soc_clk)
    disable iff(soc_rst == 1'b0)

    soc_ack_read_valid_en
    |->
    ##1 !soc_ack_read_valid_en;
  endproperty

  a_ack_read_one_cycle_pulse:
  assert property(p_ack_read_one_cycle_pulse)
  else
    $error("[ASSERT_FAIL] ACK read valid is not one-cycle pulse");


  // ============================================================
  // ASSERTION COVERAGE
  // ============================================================

  c_reset_outputs_zero:
  cover property(p_reset_outputs_zero);

  c_no_x_on_outputs:
  cover property(p_no_x_on_outputs);

  c_ack_id_valid_range:
  cover property(p_ack_id_valid_range);

  c_eoi_id_valid_range:
  cover property(p_eoi_id_valid_range);



  c_mmr_write_ctl_addr_legal:
  cover property(p_mmr_write_ctl_addr_legal);

  c_mmr_read_ctl_addr_legal:
  cover property(p_mmr_read_ctl_addr_legal);

  c_no_irq_when_all_disabled:
  cover property(p_no_irq_when_all_disabled);

  c_threshold_blocks_irq:
  cover property(p_threshold_blocks_irq);

  c_irq_generation_when_ext_enabled:
  cover property(p_irq_generation_when_ext_enabled);

  c_ack_output_not_x_during_ack:
  cover property(p_ack_output_not_x_during_ack);

  c_eoi_one_cycle_pulse:
  cover property(p_eoi_one_cycle_pulse);

  c_ack_read_one_cycle_pulse:
  cover property(p_ack_read_one_cycle_pulse);

endinterface
