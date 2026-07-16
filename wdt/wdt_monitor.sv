`ifndef WDT_MONITOR_SV
`define WDT_MONITOR_SV

class wdt_monitor;

  virtual wdt_intf vif;

  int timeout_seen;
  int reset_seen;
  int refresh_valid_seen;
  int refresh_error_seen;
  int window_violation_seen;

  bit prev_timeout;
  bit prev_reset;
  bit prev_refresh_valid;
  bit prev_refresh_error;
  bit prev_window_violation;

  function new(virtual wdt_intf vif);
    this.vif = vif;

    timeout_seen          = 0;
    reset_seen            = 0;
    refresh_valid_seen    = 0;
    refresh_error_seen    = 0;
    window_violation_seen = 0;

    prev_timeout          = 0;
    prev_reset            = 0;
    prev_refresh_valid    = 0;
    prev_refresh_error    = 0;
    prev_window_violation = 0;
  endfunction

  task run();
    forever begin
      @(posedge vif.wdt_clk);

      if (vif.wdt_rstn) begin

        if (!prev_timeout && vif.wdt_timeout) begin
          timeout_seen++;
          `uvm_info("WDT_MON", "wdt_timeout observed", UVM_LOW)
        end

        if (!prev_reset && vif.wdt_reset) begin
          reset_seen++;
          `uvm_info("WDT_MON", "wdt_reset observed", UVM_LOW)
        end

        if (!prev_refresh_valid && vif.refresh_valid) begin
          refresh_valid_seen++;
          `uvm_info("WDT_MON", "refresh_valid observed", UVM_LOW)
        end

        if (!prev_refresh_error && vif.refresh_error) begin
          refresh_error_seen++;
          `uvm_info("WDT_MON", "refresh_error observed", UVM_LOW)
        end

        if (!prev_window_violation && vif.window_violation) begin
          window_violation_seen++;
          `uvm_info("WDT_MON", "window_violation observed", UVM_LOW)
        end

        prev_timeout          = vif.wdt_timeout;
        prev_reset            = vif.wdt_reset;
        prev_refresh_valid    = vif.refresh_valid;
        prev_refresh_error    = vif.refresh_error;
        prev_window_violation = vif.window_violation;

      end
      else begin
        prev_timeout          = 0;
        prev_reset            = 0;
        prev_refresh_valid    = 0;
        prev_refresh_error    = 0;
        prev_window_violation = 0;
      end
    end
  endtask

  function void report();
    `uvm_info("WDT_MON",
      $sformatf("MON SUMMARY: timeout=%0d reset=%0d refresh_valid=%0d refresh_error=%0d window_violation=%0d",
                timeout_seen,
                reset_seen,
                refresh_valid_seen,
                refresh_error_seen,
                window_violation_seen),
      UVM_LOW)
  endfunction

endclass

`endif
