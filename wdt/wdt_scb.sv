`ifndef WDT_SCB_SV
`define WDT_SCB_SV

class wdt_scb;

  virtual wdt_intf vif;

  int pass_count;
  int fail_count;

  bit [31:0] prev_counter;
  bit [31:0] prev_cpu_commit_pc;
  bit        prev_cpu_commit_valid;
  bit        prev_wdt_reset;

  bit timeout_pending;
  int timeout_wait_count;

  int max_reset_counter;

  // Debug freeze reference-model variables
  bit        exp_freeze_req;
  bit        freeze_tracking;
  bit        freeze_locked;
  int        freeze_wait_count;
  bit [31:0] freeze_ref_counter;

  // Refresh/window variables
  bit        refresh_violation_pending;
  int        refresh_violation_wait;
  bit [31:0] refresh_counter_sample;
  bit [31:0] refresh_window_sample;

  bit        refresh_reload_pending;
  int        refresh_reload_wait;
  bit [31:0] refresh_expected_reload;

  function new(virtual wdt_intf vif);
    this.vif = vif;

    pass_count = 0;
    fail_count = 0;

    prev_counter          = 32'h0;
    prev_cpu_commit_pc    = 32'h0;
    prev_cpu_commit_valid = 1'b0;
    prev_wdt_reset        = 1'b0;

    timeout_pending    = 1'b0;
    timeout_wait_count = 0;

    max_reset_counter = 0;

    exp_freeze_req     = 1'b0;
    freeze_tracking    = 1'b0;
    freeze_locked      = 1'b0;
    freeze_wait_count  = 0;
    freeze_ref_counter = 32'h0;

    refresh_violation_pending = 1'b0;
    refresh_violation_wait    = 0;
    refresh_counter_sample    = 32'h0;
    refresh_window_sample     = 32'h0;

    refresh_reload_pending  = 1'b0;
    refresh_reload_wait     = 0;
    refresh_expected_reload = 32'h0;
  endfunction


  task run();

    forever begin
      @(posedge vif.wdt_clk);

      if (vif.wdt_rstn) begin

        //=====================================================
        // LAST_PC CHECK
        //=====================================================
        if (prev_cpu_commit_valid) begin
          if (vif.last_pc !== prev_cpu_commit_pc) begin
            fail_count++;
            `uvm_error("WDT_SCB",
              $sformatf("LAST_PC FAIL expected_last_pc=0x%08h actual_last_pc=0x%08h",
                        prev_cpu_commit_pc,
                        vif.last_pc))
          end
          else begin
            pass_count++;
            `uvm_info("WDT_SCB",
              $sformatf("LAST_PC PASS expected_last_pc=0x%08h actual_last_pc=0x%08h",
                        prev_cpu_commit_pc,
                        vif.last_pc),
              UVM_LOW)
          end
        end


        //=====================================================
        // DEBUG FREEZE CHECK - SCOREBOARD MODEL
        //
        // Spec/reference condition:
        // enable && dbg_freeze_en && (cpu_dbg_halt || dbg_freeze)
        //
        // Important:
        // Do not capture counter immediately when request becomes 1.
        // Wait until counter actually holds for one sampled cycle.
        // Then lock reference counter and compare.
        //=====================================================
        exp_freeze_req = vif.enable &&
                         vif.dbg_freeze_en &&
                         (vif.cpu_dbg_halt || vif.dbg_freeze);

        freeze_locked  = vif.lock_en ;

        if (exp_freeze_req) begin

          if (!freeze_tracking) begin
            freeze_tracking   = 1'b1;
            freeze_locked     = 1'b0;
            freeze_wait_count = 0;

            `uvm_info("WDT_SCB",
              $sformatf("DEBUG_FREEZE REQUEST expected_freeze_req=1 actual_freeze_req=%0b expected_halt_or_dbg_freeze=1 actual_halt_or_dbg_freeze=%0b actual_counter=%0d halt=%0b dbg_freeze=%0b",
                        exp_freeze_req,
                        (vif.cpu_dbg_halt || vif.dbg_freeze),
                        vif.watchdog_counter,
                        vif.cpu_dbg_halt,
                        vif.dbg_freeze),
              UVM_LOW)
          end

          // Wait until counter stops changing. This avoids false expected=old value.
          if (freeze_tracking && !freeze_locked) begin
            freeze_wait_count++;

            if (vif.watchdog_counter == prev_counter) begin
              freeze_locked      = 1'b1;
              freeze_ref_counter = vif.watchdog_counter;

              `uvm_info("WDT_SCB",
                $sformatf("DEBUG_FREEZE LOCK expected_counter_hold=%0d actual_counter=%0d expected_freeze_req=1 actual_freeze_req=%0b",
                          freeze_ref_counter,
                          vif.watchdog_counter,
                          exp_freeze_req),
                UVM_LOW)
            end
            else if (freeze_wait_count > 4) begin
              fail_count++;

              `uvm_error("WDT_SCB",
                $sformatf("DEBUG_FREEZE FAIL expected_counter_hold_after_freeze_req=1 actual_counter_changed prev_counter=%0d actual_counter=%0d expected_freeze_req=1 actual_freeze_req=%0b",
                          prev_counter,
                          vif.watchdog_counter,
                          exp_freeze_req))

              freeze_tracking   = 1'b0;
              freeze_locked     = 1'b0;
              freeze_wait_count = 0;
            end
          end

          // Once locked, counter must remain same while freeze request stays active.
          else if (freeze_locked) begin
            if (vif.watchdog_counter !== freeze_ref_counter) begin
              fail_count++;

              `uvm_error("WDT_SCB",
                $sformatf("DEBUG_FREEZE FAIL expected_counter=%0d actual_counter=%0d expected_freeze_req=1 actual_freeze_req=%0b halt=%0b dbg_freeze=%0b",
                          freeze_ref_counter,
                          vif.watchdog_counter,
                          exp_freeze_req,
                          vif.cpu_dbg_halt,
                          vif.dbg_freeze))
            end
            else begin
              pass_count++;

              `uvm_info("WDT_SCB",
                $sformatf("DEBUG_FREEZE PASS expected_counter=%0d actual_counter=%0d expected_freeze_req=1 actual_freeze_req=%0b halt=%0b dbg_freeze=%0b",
                          freeze_ref_counter,
                          vif.watchdog_counter,
                          exp_freeze_req,
                          vif.cpu_dbg_halt,
                          vif.dbg_freeze),
                UVM_LOW)
            end
          end

        end
        else begin
          freeze_tracking   = 1'b0;
          freeze_locked     = 1'b0;
          freeze_wait_count = 0;
          freeze_ref_counter = vif.watchdog_counter;
        end


        //=====================================================
        // TIMEOUT CHECK
        //=====================================================
        if ((prev_counter == 32'd1) &&
            (vif.watchdog_counter == 32'd0)) begin
          timeout_pending    = 1'b1;
          timeout_wait_count = 0;
        end

        if (timeout_pending) begin
          if (vif.timeout_flag || vif.wdt_timeout) begin
            pass_count++;

            `uvm_info("WDT_SCB",
              $sformatf("TIMEOUT PASS expected_timeout=1 actual_timeout=%0b expected_timeout_flag=1 actual_timeout_flag=%0b expected_counter=0 actual_counter=%0d",
                        vif.wdt_timeout,
                        vif.timeout_flag,
                        vif.watchdog_counter),
              UVM_LOW)

            timeout_pending    = 1'b0;
            timeout_wait_count = 0;
          end
          else begin
            timeout_wait_count++;

            if (timeout_wait_count > 1) begin
              fail_count++;

              `uvm_error("WDT_SCB",
                $sformatf("TIMEOUT FAIL expected_timeout=1 actual_timeout=%0b expected_timeout_flag=1 actual_timeout_flag=%0b expected_counter=0 actual_counter=%0d",
                          vif.wdt_timeout,
                          vif.timeout_flag,
                          vif.watchdog_counter))

              timeout_pending    = 1'b0;
              timeout_wait_count = 0;
            end
          end
        end


        //=====================================================
        // REFRESH EVENT CLASSIFICATION
        //=====================================================
        if (vif.refresh_valid) begin

          if (vif.wdt_reset || (vif.watchdog_counter == 32'd0)) begin
            `uvm_info("WDT_SCB",
              $sformatf("REFRESH IGNORE expected_check=0 actual_check=0 expected_reason=late_refresh_or_reset_active actual_counter=%0d actual_wdt_reset=%0b",
                        vif.watchdog_counter,
                        vif.wdt_reset),
              UVM_LOW)
          end

          else if (vif.window_en &&
                   (vif.watchdog_counter > vif.window_value)) begin

            refresh_violation_pending = 1'b1;
            refresh_violation_wait    = 0;
            refresh_counter_sample    = vif.watchdog_counter;
            refresh_window_sample     = vif.window_value;

            `uvm_info("WDT_SCB",
              $sformatf("REFRESH_VALID observed expected_refresh_valid=1 actual_refresh_valid=%0b expected_counter_greater_than_window=1 actual_counter_greater_than_window=%0b expected_counter=%0d actual_counter=%0d expected_window=%0d actual_window=%0d",
                        vif.refresh_valid,
                        (vif.watchdog_counter > vif.window_value),
                        refresh_counter_sample,
                        vif.watchdog_counter,
                        refresh_window_sample,
                        vif.window_value),
              UVM_LOW)
          end

          else begin
            refresh_reload_pending  = 1'b1;
            refresh_reload_wait     = 0;
            refresh_expected_reload = vif.timeout_value;

            `uvm_info("WDT_SCB",
              $sformatf("REFRESH_VALID observed expected_refresh_valid=1 actual_refresh_valid=%0b expected_reload=%0d actual_counter_now=%0d",
                        vif.refresh_valid,
                        refresh_expected_reload,
                        vif.watchdog_counter),
              UVM_LOW)
          end
        end


        //=====================================================
        // DELAYED WINDOW VIOLATION CHECK
        //=====================================================
        if (refresh_violation_pending) begin

          if (vif.window_violation) begin
            pass_count++;

            `uvm_info("WDT_SCB",
              $sformatf("REFRESH WINDOW_VIOLATION PASS expected_window_violation=1 actual_window_violation=%0b expected_counter=%0d actual_counter=%0d expected_window=%0d actual_window=%0d",
                        vif.window_violation,
                        refresh_counter_sample,
                        vif.watchdog_counter,
                        refresh_window_sample,
                        vif.window_value),
              UVM_LOW)

            refresh_violation_pending = 1'b0;
            refresh_violation_wait    = 0;
          end
          else begin
            refresh_violation_wait++;

            if (refresh_violation_wait > 3) begin
              fail_count++;

              `uvm_error("WDT_SCB",
                $sformatf("REFRESH WINDOW_VIOLATION FAIL expected_window_violation=1 actual_window_violation=%0b expected_counter=%0d actual_counter=%0d expected_window=%0d actual_window=%0d",
                          vif.window_violation,
                          refresh_counter_sample,
                          vif.watchdog_counter,
                          refresh_window_sample,
                          vif.window_value))

              refresh_violation_pending = 1'b0;
              refresh_violation_wait    = 0;
            end
          end
        end


        //=====================================================
        // DELAYED REFRESH RELOAD CHECK
        //=====================================================
        if (refresh_reload_pending) begin

          if ((vif.watchdog_counter == refresh_expected_reload) ||
              (vif.watchdog_counter == refresh_expected_reload - 1)) begin
            pass_count++;

            `uvm_info("WDT_SCB",
              $sformatf("REFRESH RELOAD PASS expected_reload=%0d actual_counter=%0d",
                        refresh_expected_reload,
                        vif.watchdog_counter),
              UVM_LOW)

            refresh_reload_pending = 1'b0;
            refresh_reload_wait    = 0;
          end
          else begin
            refresh_reload_wait++;

            if (refresh_reload_wait > 3) begin
              fail_count++;

              `uvm_error("WDT_SCB",
                $sformatf("REFRESH RELOAD FAIL expected_reload=%0d actual_counter=%0d",
                          refresh_expected_reload,
                          vif.watchdog_counter))

              refresh_reload_pending = 1'b0;
              refresh_reload_wait    = 0;
            end
          end
        end


        //=====================================================
        // RESET WIDTH CHECK
        //=====================================================
        if (!prev_wdt_reset && vif.wdt_reset) begin
          max_reset_counter = vif.reset_counter;
        end
        else if (vif.wdt_reset) begin
          if (vif.reset_counter > max_reset_counter)
            max_reset_counter = vif.reset_counter;
        end
        else if (prev_wdt_reset && !vif.wdt_reset) begin

          if (max_reset_counter == vif.reset_cycles) begin
            pass_count++;

            `uvm_info("WDT_SCB",
              $sformatf("RESET_WIDTH PASS expected_reset_cycles=%0d actual_reset_cycles=%0d",
                        vif.reset_cycles,
                        max_reset_counter),
              UVM_LOW)
          end
          else begin
            fail_count++;

            `uvm_error("WDT_SCB",
              $sformatf("RESET_WIDTH FAIL expected_reset_cycles=%0d actual_reset_cycles=%0d",
                        vif.reset_cycles,
                        max_reset_counter))
          end

          max_reset_counter = 0;
        end


        //=====================================================
        // UPDATE PREVIOUS VALUES
        //=====================================================
        prev_counter          = vif.watchdog_counter;
        prev_cpu_commit_pc    = vif.cpu_commit_pc;
      #30  prev_cpu_commit_valid = vif.cpu_commit_valid;
        prev_wdt_reset        = vif.wdt_reset;

      end
      else begin

        prev_counter          = 32'h0;
        prev_cpu_commit_pc    = 32'h0;
        prev_cpu_commit_valid = 1'b0;
        prev_wdt_reset        = 1'b0;

        timeout_pending       = 1'b0;
        timeout_wait_count    = 0;

        max_reset_counter     = 0;

        exp_freeze_req        = 1'b0;
        freeze_tracking       = 1'b0;
        freeze_locked         = 1'b0;
        freeze_wait_count     = 0;
        freeze_ref_counter    = 32'h0;

        refresh_violation_pending = 1'b0;
        refresh_violation_wait    = 0;
        refresh_counter_sample    = 32'h0;
        refresh_window_sample     = 32'h0;

        refresh_reload_pending  = 1'b0;
        refresh_reload_wait     = 0;
        refresh_expected_reload = 32'h0;

      end
    end

  endtask


  function void report();

    `uvm_info("WDT_SCB",
      $sformatf("FINAL SCOREBOARD expected_fail_count=0 actual_fail_count=%0d pass_count=%0d",
                fail_count,
                pass_count),
      UVM_LOW)

    if (fail_count == 0)
      `uvm_info("WDT_SCB",
        $sformatf("WDT SCOREBOARD RESULT PASS expected_fail_count=0 actual_fail_count=%0d",
                  fail_count),
        UVM_LOW)
    else
      `uvm_error("WDT_SCB",
        $sformatf("WDT SCOREBOARD RESULT FAIL expected_fail_count=0 actual_fail_count=%0d",
                  fail_count))

  endfunction

endclass

`endif
