`ifndef WDT_INTF_SV
`define WDT_INTF_SV

interface wdt_intf(input logic wdt_clk);

  // Direct DUT inputs
  logic        wdt_rstn;
  logic        cpu_dbg_halt;
  logic        dbg_freeze;
  logic [31:0] cpu_commit_pc;
  logic        cpu_commit_valid;

  // DUT outputs
  logic        wdt_reset;
  logic        wdt_timeout;
  logic [1:0]  reset_scope;

  // Observed DUT internal signals for monitor/scoreboard only
  logic [31:0] watchdog_counter;
  logic [31:0] timeout_value;
  logic [31:0] window_value;
  logic [15:0] reset_cycles;
  logic [15:0] reset_counter;

  logic        enable;
  logic        window_en;
  logic        dbg_freeze_en;
  logic        refresh_valid;
  logic        refresh_error;
  logic        window_violation;
  logic        timeout_flag;
  logic [31:0] last_pc;
  logic         lock_en;

endinterface

`endif
