`ifndef APB_MASTER_32B_WRITE_SEQ_INCLUDE_
`define APB_MASTER_32B_WRITE_SEQ_INCLUDE_



//--------------------------------------------------------------------------------------------
// Class: apb_master_32b_write_seq
//  Extends the apb_master_base_seq and randomises the req item
//--------------------------------------------------------------------------------------------
class apb_master_32b_write_seq extends apb_master_base_seq;
  `uvm_object_utils(apb_master_32b_write_seq)

  virtual wdt_intf wdt_vintf;

  rand bit [31:0] timeout_data;
  rand bit [31:0] window_data;
  rand bit [15:0] reset_width_data;
  rand bit [1:0]  reset_scope_data;

  rand bit        reset_en_data;
  rand bit        window_en_data;
  rand bit        dbg_freeze_en_data;

  rand bit [31:0] pc_data;
  rand bit        cpu_dbg_halt_data;
  rand bit        dbg_freeze_data;
  rand bit        cpu_commit_valid_data;

  rand bit        do_debug_freeze;
  rand bit        do_refresh;
  rand int unsigned freeze_delay;
  rand int unsigned freeze_width;
  rand int unsigned refresh_delay;

  bit [31:0] ctrl_data;

  constraint wdt_stress_c {
    timeout_data      inside {[80:160]};
    window_data       inside {[20:60]};
    window_data       < timeout_data;

    reset_width_data  inside {[1:30]};
    reset_scope_data  inside {[0:3]};

    reset_en_data     inside {0,1};
    window_en_data    inside {0,1};
    dbg_freeze_en_data inside {0,1};

    pc_data inside {[32'h8000_0000:32'h8000_FFFF]};

    cpu_dbg_halt_data     inside {0,1};
    dbg_freeze_data       inside {0,1};
    cpu_commit_valid_data inside {0,1};

    do_debug_freeze inside {0,1};
    do_refresh      inside {0,1};

    freeze_delay inside {[2:8]};
    freeze_width inside {[2:8]};

    refresh_delay inside {[5:30]};
    refresh_delay < timeout_data;
  }
  

  //-------------------------------------------------------
  // Externally defined Tasks and Functions
  //-------------------------------------------------------
  extern function new(string name ="apb_master_32b_write_seq");
  extern task body();
  
endclass : apb_master_32b_write_seq

//--------------------------------------------------------------------------------------------
// Construct: new
//
// Parameters:
//  name - apb_master_32b_write_seq
//--------------------------------------------------------------------------------------------
function apb_master_32b_write_seq::new(string name="apb_master_32b_write_seq");
  super.new(name);
endfunction : new

  

task apb_master_32b_write_seq::body();


  super.body();

    if (!uvm_config_db#(virtual wdt_intf)::get(null, "", "wdt_vintf", wdt_vintf)) begin
    `uvm_fatal("WDT_SEQ", "Failed to get wdt_vintf from config_db")
  end

  if (wdt_vintf == null) begin
    `uvm_fatal("WDT_SEQ", "wdt_vintf is NULL")
  end

/*  //=========================================================
// TC_BOOT_STATUS_01 : BOOT_STATUS REGISTER CHECK
//
// Goal:
//
// Verify BOOT_STATUS Register.
//
// Bit0 : PREV_RESET_WDT (RW1C)
// Bit1 : RECOVERY_BOOT_REQ (RW)
//
// Test Flow:
//
// 1. Unlock WDT
// 2. Clear STATUS
// 3. Program TIMEOUT = 5
// 4. Enable WDT + RESET_EN
// 5. Wait Timeout
// 6. Read BOOT_STATUS
// 7. Clear PREV_RESET_WDT
// 8. Read BOOT_STATUS
// 9. Set RECOVERY_BOOT_REQ
// 10.Read BOOT_STATUS
//=========================================================


//=========================================================
// 1. RESET WDT DOMAIN
//=========================================================

wdt_vintf.wdt_rstn         = 1'b0;
wdt_vintf.cpu_dbg_halt     = 1'b0;
wdt_vintf.dbg_freeze       = 1'b0;
wdt_vintf.cpu_commit_valid = 1'b0;
wdt_vintf.cpu_commit_pc    = 32'h0;

repeat(5)
  @(posedge wdt_vintf.wdt_clk);

wdt_vintf.wdt_rstn = 1'b1;

repeat(5)
  @(posedge wdt_vintf.wdt_clk);


//=========================================================
// 2. UNLOCK WDT
//=========================================================

req = apb_master_tx::type_id::create("boot_unlock");
req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

start_item(req);

if(!req.randomize() with{
    req.pselx         == SLAVE_0;
    req.transfer_size == BIT_32;
    req.pwrite        == WRITE;
})
`uvm_fatal("APB","Randomization Failed")

req.paddr  = 32'h0000_0014;
req.pwdata = 32'h1ACCE551;

finish_item(req);

repeat(5)
@(posedge wdt_vintf.wdt_clk);


//=========================================================
// 3. CLEAR STATUS
//=========================================================

req = apb_master_tx::type_id::create("clear_status");
req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

start_item(req);

if(!req.randomize() with{
    req.pselx         == SLAVE_0;
    req.transfer_size == BIT_32;
    req.pwrite        == WRITE;
})
`uvm_fatal("APB","Randomization Failed")

req.paddr  = 32'h0000_0010;
req.pwdata = 32'h0000_000F;

finish_item(req);

repeat(5)
@(posedge wdt_vintf.wdt_clk);


//=========================================================
// 4. PROGRAM TIMEOUT = 5
//=========================================================

req = apb_master_tx::type_id::create("timeout_program");
req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

start_item(req);

if(!req.randomize() with{
    req.pselx         == SLAVE_0;
    req.transfer_size == BIT_32;
    req.pwrite        == WRITE;
})
`uvm_fatal("APB","Randomization Failed")

req.paddr  = 32'h0000_0004;
req.pwdata = 32'd5;

finish_item(req);

repeat(5)
@(posedge wdt_vintf.wdt_clk);


//=========================================================
// 5. ENABLE WATCHDOG
//
// CTRL
// bit0 ENABLE
// bit1 RESET_EN
//=========================================================

req = apb_master_tx::type_id::create("ctrl_enable");
req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

start_item(req);

if(!req.randomize() with{
    req.pselx         == SLAVE_0;
    req.transfer_size == BIT_32;
    req.pwrite        == WRITE;
})
`uvm_fatal("APB","Randomization Failed")

req.paddr  = 32'h0000_0000;
req.pwdata = 32'h0000_0003;

finish_item(req);


#10

//=========================================================
// 7. READ BOOT_STATUS
//
// Expected:
// Bit0 = PREV_RESET_WDT = 1
//=========================================================

req = apb_master_tx::type_id::create("boot_status_read_1");
req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

start_item(req);

if (!req.randomize() with {
    req.pselx         == SLAVE_0;
    req.transfer_size == BIT_32;
    req.pwrite        == READ;
})
  `uvm_fatal("APB","Randomization Failed")

req.paddr = 32'h0000_0024;

finish_item(req);

repeat(5)
  @(posedge wdt_vintf.wdt_clk);


//=========================================================
// 8. CLEAR PREV_RESET_WDT
//
// Write 0x1
//=========================================================

req = apb_master_tx::type_id::create("boot_status_clear_prev_reset");
req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

start_item(req);

if (!req.randomize() with {
    req.pselx         == SLAVE_0;
    req.transfer_size == BIT_32;
    req.pwrite        == WRITE;
})
  `uvm_fatal("APB","Randomization Failed")

req.paddr  = 32'h0000_0024;
req.pwdata = 32'h0000_0001;

finish_item(req);

#20

//=========================================================
// 9. READ BOOT_STATUS
//
// Expected:
// Bit0 = 0
//=========================================================

req = apb_master_tx::type_id::create("boot_status_read_2");
req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

start_item(req);

if (!req.randomize() with {
    req.pselx         == SLAVE_0;
    req.transfer_size == BIT_32;
    req.pwrite        == READ;
})
  `uvm_fatal("APB","Randomization Failed")

req.paddr = 32'h0000_0024;

finish_item(req);

#20

//=========================================================
// 10. WRITE RECOVERY_BOOT_REQ
//
// Write 0x2
//=========================================================

req = apb_master_tx::type_id::create("boot_status_set_recovery");
req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

start_item(req);

if (!req.randomize() with {
    req.pselx         == SLAVE_0;
    req.transfer_size == BIT_32;
    req.pwrite        == WRITE;
})
  `uvm_fatal("APB","Randomization Failed")

req.paddr  = 32'h0000_0024;
req.pwdata = 32'h0000_0002;

finish_item(req);


#20

//=========================================================
// 11. READ BOOT_STATUS
//
// Expected:
// Bit0 = 0
// Bit1 = 1
//=========================================================

req = apb_master_tx::type_id::create("boot_status_read_3");
req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

start_item(req);

if (!req.randomize() with {
    req.pselx         == SLAVE_0;
    req.transfer_size == BIT_32;
    req.pwrite        == READ;
})
  `uvm_fatal("APB","Randomization Failed")

req.paddr = 32'h0000_0024;

finish_item(req);

#20

//=========================================================
// 12. CLEAR BOOT_STATUS
//
// Write 0x0
//=========================================================

req = apb_master_tx::type_id::create("boot_status_clear");
req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

start_item(req);

if (!req.randomize() with {
    req.pselx         == SLAVE_0;
    req.transfer_size == BIT_32;
    req.pwrite        == WRITE;
})
  `uvm_fatal("APB","Randomization Failed")

req.paddr  = 32'h0000_0024;
req.pwdata = 32'h0000_0000;

finish_item(req);

#20

//=========================================================
// 13. FINAL READ
//
// Expected:
// BOOT_STATUS = 0
//=========================================================

req = apb_master_tx::type_id::create("boot_status_read_final");
req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

start_item(req);

if (!req.randomize() with {
    req.pselx         == SLAVE_0;
    req.transfer_size == BIT_32;
    req.pwrite        == READ;
})
  `uvm_fatal("APB","Randomization Failed")

req.paddr = 32'h0000_0024;

finish_item(req);

repeat(10)
  @(posedge wdt_vintf.wdt_clk);

`uvm_info("BOOT_STATUS_TEST",
          "TC_BOOT_STATUS_01 COMPLETED",
          UVM_LOW)

#300;


/*
  repeat (50) begin

    if (!this.randomize()) begin
      `uvm_fatal("WDT_SEQ", "WDT stress randomization failed")
    end

    ctrl_data        = 32'h0;
    ctrl_data[0]     = 1'b1;                // ENABLE
    ctrl_data[1]     = reset_en_data;       // RESET_EN
    ctrl_data[2]     = window_en_data;      // WINDOW_EN
    ctrl_data[3]     = dbg_freeze_en_data;  // DBG_FREEZE_EN
    ctrl_data[4]     = 1'b0;                // LOCK_EN
    ctrl_data[7:6]   = reset_scope_data;    // RESET_SCOPE

    //=====================================================
    // 1. RESET WDT DOMAIN
    //=====================================================
    wdt_vintf.wdt_rstn          = 1'b0;
    wdt_vintf.cpu_dbg_halt      = 1'b0;
    wdt_vintf.dbg_freeze        = 1'b0;
    wdt_vintf.cpu_commit_pc     = 32'h0;
    wdt_vintf.cpu_commit_valid  = 1'b0;

    repeat (5) @(posedge wdt_vintf.wdt_clk);

    wdt_vintf.wdt_rstn = 1'b1;

    repeat (5) @(posedge wdt_vintf.wdt_clk);

    //=====================================================
    // 2. DRIVE CPU COMMIT PC INPUTS
    //=====================================================
    wdt_vintf.cpu_commit_pc    = pc_data;
    wdt_vintf.cpu_commit_valid = cpu_commit_valid_data;

    repeat (1) @(posedge wdt_vintf.wdt_clk);

    wdt_vintf.cpu_commit_valid = 1'b0;

    //=====================================================
    // 3. UNLOCK
    //=====================================================
    req = apb_master_tx::type_id::create("stress_unlock");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if (!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    }) begin
      `uvm_fatal("APB", "Rand failed")
    end

    req.paddr  = 32'h0000_0014;
    req.pwdata = 32'h1ACCE551;

    finish_item(req);

    repeat (5) @(posedge wdt_vintf.wdt_clk);

    //=====================================================
    // 4. CLEAR STATUS
    //=====================================================
    req = apb_master_tx::type_id::create("stress_clear_status");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if (!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    }) begin
      `uvm_fatal("APB", "Rand failed")
    end

    req.paddr  = 32'h0000_0010;
    req.pwdata = 32'h0000_000F;

    finish_item(req);

    repeat (5) @(posedge wdt_vintf.wdt_clk);

    //=====================================================
    // 5. PROGRAM TIMEOUT
    //=====================================================
    req = apb_master_tx::type_id::create("stress_timeout");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if (!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    }) begin
      `uvm_fatal("APB", "Rand failed")
    end

    req.paddr  = 32'h0000_0004;
    req.pwdata = timeout_data;

    finish_item(req);

    repeat (5) @(posedge wdt_vintf.wdt_clk);

    //=====================================================
    // 6. PROGRAM WINDOW
    //=====================================================
    req = apb_master_tx::type_id::create("stress_window");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if (!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    }) begin
      `uvm_fatal("APB", "Rand failed")
    end

    req.paddr  = 32'h0000_0008;
    req.pwdata = window_data;

    finish_item(req);

    repeat (5) @(posedge wdt_vintf.wdt_clk);

    //=====================================================
    // 7. PROGRAM RESET WIDTH
    //=====================================================
    req = apb_master_tx::type_id::create("stress_reset_width");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if (!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    }) begin
      `uvm_fatal("APB", "Rand failed")
    end

    req.paddr  = 32'h0000_0028;
    req.pwdata = {16'h0, reset_width_data};

    finish_item(req);

    repeat (5) @(posedge wdt_vintf.wdt_clk);

    //=====================================================
    // 8. PROGRAM CTRL LAST
    //=====================================================
    req = apb_master_tx::type_id::create("stress_ctrl");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if (!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    }) begin
      `uvm_fatal("APB", "Rand failed")
    end

    req.paddr  = 32'h0000_0000;
    req.pwdata = ctrl_data;

    finish_item(req);

    repeat (20) @(posedge wdt_vintf.wdt_clk);

    //=====================================================
    // 9.  DEBUG FREEZE INPUT STIMULUS
    //=====================================================
    if (do_debug_freeze && dbg_freeze_en_data) begin

      repeat (freeze_delay) @(posedge wdt_vintf.wdt_clk);

      wdt_vintf.cpu_dbg_halt = cpu_dbg_halt_data;
      wdt_vintf.dbg_freeze   = dbg_freeze_data;

      repeat (freeze_width) @(posedge wdt_vintf.wdt_clk);

      wdt_vintf.cpu_dbg_halt = 1'b0;
      wdt_vintf.dbg_freeze   = 1'b0;

    end

    //=====================================================
    // 10.  VALID REFRESH SEQUENCE
    //=====================================================
    if (do_refresh) begin

      repeat (refresh_delay) @(posedge wdt_vintf.wdt_clk);

      req = apb_master_tx::type_id::create("stress_refresh_a5");
      req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

      start_item(req);

      if (!req.randomize() with {
        req.pselx         == SLAVE_0;
        req.transfer_size == BIT_32;
        req.pwrite        == WRITE;
      }) begin
        `uvm_fatal("APB", "Rand failed")
      end

      req.paddr  = 32'h0000_000C;
      req.pwdata = 32'h0000_00A5;

      finish_item(req);

      repeat (2) @(posedge wdt_vintf.wdt_clk);

      req = apb_master_tx::type_id::create("stress_refresh_5a");
      req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

      start_item(req);

      if (!req.randomize() with {
        req.pselx         == SLAVE_0;
        req.transfer_size == BIT_32;
        req.pwrite        == WRITE;
      }) begin
        `uvm_fatal("APB", "Rand failed")
      end

      req.paddr  = 32'h0000_000C;
      req.pwdata = 32'h0000_005A;

      finish_item(req);

      repeat (10) @(posedge wdt_vintf.wdt_clk);

    end

    //=====================================================
    // 11. OBSERVE
    //=====================================================
    repeat (timeout_data + reset_width_data + 50)
      @(posedge wdt_vintf.wdt_clk);

    `uvm_info("TC_RANDOM_09",
      $sformatf("iteration completed TIMEOUT=%0d WINDOW=%0d RESET_WIDTH=%0d CTRL=0x%08h PC=0x%08h REFRESH=%0b DBG_FREEZE=%0b",
                timeout_data,
                window_data,
                reset_width_data,
                ctrl_data,
                pc_data,
                do_refresh,
                do_debug_freeze),
      UVM_LOW)

  end

  `uvm_info("WDT_SEQ",
    "TC_RANDOM_09 : FULL MIXED WDT RANDOM STRESS COMPLETED",
    UVM_LOW)  
    
    


*/

    
    
    //=========================================================
  // TC_RANDOM_09 : FULL MIXED WDT RANDOM STRESS
  //
  // Goal:
  // Randomize multiple WDT features together.
  //
  // Randomized:
  // TIMEOUT
  // WINDOW
  // RESET_WIDTH
  // RESET_SCOPE
  // WINDOW_EN
  // RESET_EN
  // DBG_FREEZE_EN
  // CPU LAST_PC
  // DEBUG FREEZE input
  //
  // Expected:
  // No simulation hang
  // No X propagation
  // Counter counts/reloads/resets cleanly
  // Status flags behave according to stimulus
  //=========================================================

  repeat (50) begin

    timeout_data       = $urandom_range(30, 120);
    window_data        = $urandom_range(5, timeout_data/2);
    reset_width_data   = $urandom_range(1, 30);
    reset_scope_data         = $urandom_range(0, 3);
    window_en_data     = $urandom_range(0, 1);
    reset_en_data      = $urandom_range(0, 1);
    dbg_freeze_en_data = $urandom_range(0, 1);
    pc_data            = $urandom_range(32'h8000_0000, 32'h8000_FFFF);

    ctrl_data = 32'h0;
    ctrl_data[0]   = 1'b1;                 // ENABLE
    ctrl_data[1]   = reset_en_data;        // RESET_EN
    ctrl_data[2]   = window_en_data;       // WINDOW_EN
    ctrl_data[3]   = dbg_freeze_en_data;   // DBG_FREEZE_EN
    ctrl_data[7:6] = reset_scope_data;           // RESET_SCOPE

    //=======================================================
    // 1. RESET WDT DOMAIN
    //=======================================================
    wdt_vintf.wdt_rstn = 1'b0;
    repeat (5) @(posedge wdt_vintf.wdt_clk);

    wdt_vintf.wdt_rstn = 1'b1;
    repeat (5) @(posedge wdt_vintf.wdt_clk);


    //=======================================================
    // 2. DRIVE RANDOM CPU COMMIT PC
    //=======================================================
    wdt_vintf.cpu_commit_pc    = pc_data;
    wdt_vintf.cpu_commit_valid = 1'b1;

    repeat (1) @(posedge wdt_vintf.wdt_clk);

    wdt_vintf.cpu_commit_valid = 1'b0;


    //=======================================================
    // 3. UNLOCK WDT
    //=======================================================
    req = apb_master_tx::type_id::create("stress_unlock");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    })
      `uvm_fatal("APB","Randomization Failed")

    req.paddr  = 32'h0000_0014;
    req.pwdata = 32'h1ACCE551;

    finish_item(req);

    #50;


    //=======================================================
    // 4. CLEAR STATUS
    //=======================================================
    req = apb_master_tx::type_id::create("stress_clear_status");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    })
      `uvm_fatal("APB","Randomization Failed")

    req.paddr  = 32'h0000_0010;
    req.pwdata = 32'h0000_000F;

    finish_item(req);

    #50;


    //=======================================================
    // 5. PROGRAM TIMEOUT
    //=======================================================
    req = apb_master_tx::type_id::create("stress_timeout");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    })
      `uvm_fatal("APB","Randomization Failed")

    req.paddr  = 32'h0000_0004;
    req.pwdata = timeout_data;

    finish_item(req);

    #50;


    //=======================================================
    // 6. PROGRAM WINDOW
    //=======================================================
    req = apb_master_tx::type_id::create("stress_window");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    })
      `uvm_fatal("APB","Randomization Failed")

    req.paddr  = 32'h0000_0008;
    req.pwdata = window_data;

    finish_item(req);

    #50;


    //=======================================================
    // 7. PROGRAM RESET_WIDTH
    //=======================================================
    req = apb_master_tx::type_id::create("stress_reset_width");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    })
      `uvm_fatal("APB","Randomization Failed")

    req.paddr  = 32'h0000_0028;
    req.pwdata = {16'h0, reset_width_data};

    finish_item(req);

    #50;


    //=======================================================
    // 8. PROGRAM CTRL
    //=======================================================
    req = apb_master_tx::type_id::create("stress_ctrl");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    })
      `uvm_fatal("APB","Randomization Failed")

    req.paddr  = 32'h0000_0000;
    req.pwdata = ctrl_data;

    finish_item(req);


    //=======================================================
    // 9. RANDOM DEBUG FREEZE PULSE
    //=======================================================
    if (dbg_freeze_en_data) begin
      repeat ($urandom_range(2, 8)) @(posedge wdt_vintf.wdt_clk);

      wdt_vintf.cpu_dbg_halt = $urandom_range(0, 1);
      wdt_vintf.dbg_freeze   = $urandom_range(0, 1);

      repeat ($urandom_range(2, 8)) @(posedge wdt_vintf.wdt_clk);

      wdt_vintf.cpu_dbg_halt = 1'b0;
      wdt_vintf.dbg_freeze   = 1'b0;
    end


    //=======================================================
    // 10. RANDOM OPTIONAL REFRESH
    //=======================================================
    if ($urandom_range(0, 1)) begin

      repeat ($urandom_range(3, timeout_data/2))
        @(posedge wdt_vintf.wdt_clk);

      req = apb_master_tx::type_id::create("stress_refresh_a5");
      req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

      start_item(req);

      if(!req.randomize() with {
        req.pselx         == SLAVE_0;
        req.transfer_size == BIT_32;
        req.pwrite        == WRITE;
      })
        `uvm_fatal("APB","Randomization Failed")

      req.paddr  = 32'h0000_000C;
      req.pwdata = 32'h0000_00A5;

      finish_item(req);

      #20;

      req = apb_master_tx::type_id::create("stress_refresh_5a");
      req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

      start_item(req);

      if(!req.randomize() with {
        req.pselx         == SLAVE_0;
        req.transfer_size == BIT_32;
        req.pwrite        == WRITE;
      })
        `uvm_fatal("APB","Randomization Failed")

      req.paddr  = 32'h0000_000C;
      req.pwdata = 32'h0000_005A;

      finish_item(req);

    end


    //=======================================================
    // 11. OBSERVE UNTIL COMPLETION
    //=======================================================
    repeat (timeout_data + reset_width_data + 30)
      @(posedge wdt_vintf.wdt_clk);


    `uvm_info("TC_RANDOM_09",
              $sformatf("iter done TIMEOUT=%0d WINDOW=%0d RESET_WIDTH=%0d SCOPE=%0d CTRL=0x%08h PC=0x%08h",
                        timeout_data,
                        window_data,
                        reset_width_data,
                        reset_scope_data,
                        ctrl_data,
                        pc_data),
              UVM_LOW)

  end


  //=========================================================
  // 12. TEST COMPLETED
  //=========================================================
  `uvm_info("WDT_SEQ",
            "TC_RANDOM_09 : FULL MIXED WDT RANDOM STRESS COMPLETED",
            UVM_LOW)

  #500;



  /*


    //=========================================================
  // TC_RANDOM_08 : RANDOM LOCK PROTECTION CHECK
  //
  // Goal:
  // Randomize protected register write before and after lock.
  //
  // Protected register:
  // WDT_TIMEOUT = 0x00000004
  //
  // Lock register:
  // WDT_LOCK = 0x00000014
  //
  // Unlock key:
  // 0x1ACCE551
  //
  // Lock value:
  // 0x00000000
  //
  // Expected:
  // Before lock:
  //   TIMEOUT write accepted.
  //
  // After lock:
  //   TIMEOUT overwrite ignored.
  //   timeout_value remains original value.
  //=========================================================

  repeat (10) begin

    timeout_data_a = $urandom_range(20, 100);
    timeout_data_b = $urandom_range(101, 200);

    //=======================================================
    // 1. RESET WDT DOMAIN
    //=======================================================
    wdt_vintf.wdt_rstn = 1'b0;
    repeat (5) @(posedge wdt_vintf.wdt_clk);

    wdt_vintf.wdt_rstn = 1'b1;
    repeat (5) @(posedge wdt_vintf.wdt_clk);


    //=======================================================
    // 2. UNLOCK WDT
    //=======================================================
    req = apb_master_tx::type_id::create("rand_lock_unlock");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    })
      `uvm_fatal("APB","Randomization Failed")

    req.paddr  = 32'h0000_0014;
    req.pwdata = 32'h1ACCE551;

    finish_item(req);

    #50;


    //=======================================================
    // 3. WRITE TIMEOUT BEFORE LOCK
    //=======================================================
    req = apb_master_tx::type_id::create("rand_lock_timeout_a");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    })
      `uvm_fatal("APB","Randomization Failed")

    req.paddr  = 32'h0000_0004;
    req.pwdata = timeout_data_a;

    finish_item(req);

    #50;


    //=======================================================
    // 4. READ TIMEOUT BEFORE LOCK
    //=======================================================
    req = apb_master_tx::type_id::create("rand_lock_timeout_a_read");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
    })
      `uvm_fatal("APB","Randomization Failed")

    req.paddr = 32'h0000_0004;

    finish_item(req);

    #50;


    //=======================================================
    // 5. LOCK WDT
    //=======================================================
    req = apb_master_tx::type_id::create("rand_lock_apply");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    })
      `uvm_fatal("APB","Randomization Failed")

    req.paddr  = 32'h0000_0014;
    req.pwdata = 32'h00000000;

    finish_item(req);

    #50;


    //=======================================================
    // 6. TRY TO OVERWRITE TIMEOUT AFTER LOCK
    //=======================================================
    req = apb_master_tx::type_id::create("rand_lock_timeout_b");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    })
      `uvm_fatal("APB","Randomization Failed")

    req.paddr  = 32'h0000_0004;
    req.pwdata = timeout_data_b;

    finish_item(req);

    #50;


    //=======================================================
    // 7. READ TIMEOUT AFTER LOCK
    // Expected:
    // Readback should still show timeout_data_a.
    //=======================================================
    req = apb_master_tx::type_id::create("rand_lock_timeout_after_read");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
    })
      `uvm_fatal("APB","Randomization Failed")

    req.paddr = 32'h0000_0004;

    finish_item(req);

    #50;


    `uvm_info("TC_RANDOM_08",
              $sformatf("LOCK CHECK: original_timeout=%0d attempted_overwrite=%0d",
                        timeout_data_a, timeout_data_b),
              UVM_LOW)

  end


  //=========================================================
  // 8. TEST COMPLETED
  //=========================================================
  `uvm_info("WDT_SEQ",
            "TC_RANDOM_08 : RANDOM LOCK PROTECTION CHECK COMPLETED",
            UVM_LOW)

  #300;


  

    //=========================================================
  // TC_RANDOM_07 : RANDOM WINDOW WATCHDOG CHECK
  //
  // Goal:
  // Randomize TIMEOUT and WINDOW.
  // Randomly perform legal or early refresh.
  //
  // Registers:
  // WDT_CTRL    = 0x00000000
  // WDT_TIMEOUT = 0x00000004
  // WDT_WINDOW  = 0x00000008
  // WDT_REFRESH = 0x0000000C
  // WDT_STATUS  = 0x00000010
  // WDT_LOCK    = 0x00000014
  //
  // CTRL:
  // bit0 ENABLE    = 1
  // bit2 WINDOW_EN = 1
  // CTRL = 0x00000005
  //
  // Expected:
  // Legal refresh:
  //   counter <= window_value
  //   refresh_valid = 1
  //
  // Early refresh:
  //   counter > window_value
  //   window_violation = 1
  //=========================================================

  repeat (10) begin

    timeout_data          = $urandom_range(40, 120);
    window_data           = $urandom_range(5, timeout_data/2);
    legal_window_refresh  = $urandom_range(0, 1);

    //=======================================================
    // 1. RESET WDT DOMAIN
    //=======================================================
    wdt_vintf.wdt_rstn = 1'b0;
    repeat (5) @(posedge wdt_vintf.wdt_clk);

    wdt_vintf.wdt_rstn = 1'b1;
    repeat (5) @(posedge wdt_vintf.wdt_clk);


    //=======================================================
    // 2. UNLOCK WDT
    //=======================================================
    req = apb_master_tx::type_id::create("window_data_unlock");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    })
      `uvm_fatal("APB","Randomization Failed")

    req.paddr  = 32'h0000_0014;
    req.pwdata = 32'h1ACCE551;

    finish_item(req);

    #50;


    //=======================================================
    // 3. CLEAR STATUS FLAGS
    //=======================================================
    req = apb_master_tx::type_id::create("window_data_clear_status");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    })
      `uvm_fatal("APB","Randomization Failed")

    req.paddr  = 32'h0000_0010;
    req.pwdata = 32'h0000_000F;

    finish_item(req);

    #50;


    //=======================================================
    // 4. WRITE RANDOM TIMEOUT
    //=======================================================
    req = apb_master_tx::type_id::create("window_data_timeout");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    })
      `uvm_fatal("APB","Randomization Failed")

    req.paddr  = 32'h0000_0004;
    req.pwdata = timeout_data;

    finish_item(req);

    #50;


    //=======================================================
    // 5. WRITE RANDOM WINDOW VALUE
    //=======================================================
    req = apb_master_tx::type_id::create("window_data_value");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    })
      `uvm_fatal("APB","Randomization Failed")

    req.paddr  = 32'h0000_0008;
    req.pwdata = window_data;

    finish_item(req);

    #50;


    //=======================================================
    // 6. ENABLE WDT + WINDOW_EN
    //=======================================================
    req = apb_master_tx::type_id::create("window_en_dataable");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    })
      `uvm_fatal("APB","Randomization Failed")

    req.paddr  = 32'h0000_0000;
    req.pwdata = 32'h0000_0005;

    finish_item(req);


    //=======================================================
    // 7. WAIT FOR LEGAL OR EARLY WINDOW REGION
    //
    // Early refresh:
    //   wait small cycles, counter still > window
    //
    // Legal refresh:
    //   wait until counter should be <= window
    //=======================================================
    if (legal_window_refresh) begin
      repeat (timeout_data - window_data + 2)
        @(posedge wdt_vintf.wdt_clk);

      `uvm_info("TC_RANDOM_07",
                $sformatf("LEGAL refresh: TIMEOUT=%0d WINDOW=%0d",
                          timeout_data, window_data),
                UVM_LOW)
    end
    else begin
      repeat ($urandom_range(1, window_data))
        @(posedge wdt_vintf.wdt_clk);

      `uvm_info("TC_RANDOM_07",
                $sformatf("EARLY refresh: TIMEOUT=%0d WINDOW=%0d",
                          timeout_data, window_data),
                UVM_LOW)
    end


    //=======================================================
    // 8. APPLY REFRESH SEQUENCE A5 -> 5A
    //=======================================================
    req = apb_master_tx::type_id::create("window_data_refresh_a5");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    })
      `uvm_fatal("APB","Randomization Failed")

    req.paddr  = 32'h0000_000C;
    req.pwdata = 32'h0000_00A5;

    finish_item(req);

    #20;

    req = apb_master_tx::type_id::create("window_data_refresh_5a");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    })
      `uvm_fatal("APB","Randomization Failed")

    req.paddr  = 32'h0000_000C;
    req.pwdata = 32'h0000_005A;

    finish_item(req);


    //=======================================================
    // 9. OBSERVATION DELAY
    //=======================================================
    repeat (10) @(posedge wdt_vintf.wdt_clk);

  end


  //=========================================================
  // 10. TEST COMPLETED
  //=========================================================
  `uvm_info("WDT_SEQ",
            "TC_RANDOM_07 : RANDOM WINDOW WATCHDOG CHECK COMPLETED",
            UVM_LOW)

  #300;


  

    //=========================================================
  // TC_RANDOM_06 : RANDOM REFRESH VALID / INVALID CHECK
  //
  // Goal:
  // Randomly apply valid and invalid refresh sequences.
  //
  // REFRESH Register:
  // WDT_REFRESH = 0x0000000C
  //
  // Valid sequence:
  // 0xA5 followed by 0x5A
  //
  // Invalid sequence:
  // wrong key or incomplete key sequence
  //
  // Expected:
  // Valid refresh   -> refresh_valid = 1, counter reloads
  // Invalid refresh -> refresh_error = 1
  //=========================================================

  repeat (10) begin

    timeout_data  = $urandom_range(20, 100);
    valid_refresh = $urandom_range(0, 1);
    wrong_key     = $urandom_range(1, 255);

    if (wrong_key == 32'hA5 || wrong_key == 32'h5A)
      wrong_key = 32'h33;

    //=======================================================
    // 1. RESET WDT DOMAIN
    //=======================================================
    wdt_vintf.wdt_rstn = 1'b0;
    repeat (5) @(posedge wdt_vintf.wdt_clk);

    wdt_vintf.wdt_rstn = 1'b1;
    repeat (5) @(posedge wdt_vintf.wdt_clk);


    //=======================================================
    // 2. UNLOCK WDT
    //=======================================================
    req = apb_master_tx::type_id::create("rand_refresh_unlock");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    })
      `uvm_fatal("APB","Randomization Failed")

    req.paddr  = 32'h0000_0014;
    req.pwdata = 32'h1ACCE551;

    finish_item(req);

    #50;


    //=======================================================
    // 3. CLEAR STATUS FLAGS
    //=======================================================
    req = apb_master_tx::type_id::create("rand_refresh_clear_status");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    })
      `uvm_fatal("APB","Randomization Failed")

    req.paddr  = 32'h0000_0010;
    req.pwdata = 32'h0000_000F;

    finish_item(req);

    #50;


    //=======================================================
    // 4. WRITE RANDOM TIMEOUT
    //=======================================================
    req = apb_master_tx::type_id::create("rand_refresh_timeout");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    })
      `uvm_fatal("APB","Randomization Failed")

    req.paddr  = 32'h0000_0004;
    req.pwdata = timeout_data;

    finish_item(req);

    #50;


    //=======================================================
    // 5. ENABLE WDT
    //=======================================================
    req = apb_master_tx::type_id::create("rand_refresh_enable");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    })
      `uvm_fatal("APB","Randomization Failed")

    req.paddr  = 32'h0000_0000;
    req.pwdata = 32'h0000_0001;

    finish_item(req);

    repeat (timeout_data/2) @(posedge wdt_vintf.wdt_clk);


    //=======================================================
    // 6. RANDOM REFRESH OPERATION
    //=======================================================
    if (valid_refresh) begin

      req = apb_master_tx::type_id::create("rand_refresh_key1");
      req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

      start_item(req);

      if(!req.randomize() with {
        req.pselx         == SLAVE_0;
        req.transfer_size == BIT_32;
        req.pwrite        == WRITE;
      })
        `uvm_fatal("APB","Randomization Failed")

      req.paddr  = 32'h0000_000C;
      req.pwdata = 32'h0000_00A5;

      finish_item(req);

      #20;

      req = apb_master_tx::type_id::create("rand_refresh_key2");
      req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

      start_item(req);

      if(!req.randomize() with {
        req.pselx         == SLAVE_0;
        req.transfer_size == BIT_32;
        req.pwrite        == WRITE;
      })
        `uvm_fatal("APB","Randomization Failed")

      req.paddr  = 32'h0000_000C;
      req.pwdata = 32'h0000_005A;

      finish_item(req);

      `uvm_info("TC_RANDOM_06",
                $sformatf("VALID refresh applied TIMEOUT=%0d", timeout_data),
                UVM_LOW)

    end
    else begin

      req = apb_master_tx::type_id::create("rand_refresh_wrong_key");
      req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

      start_item(req);

      if(!req.randomize() with {
        req.pselx         == SLAVE_0;
        req.transfer_size == BIT_32;
        req.pwrite        == WRITE;
      })
        `uvm_fatal("APB","Randomization Failed")

      req.paddr  = 32'h0000_000C;
      req.pwdata = wrong_key;

      finish_item(req);

      `uvm_info("TC_RANDOM_06",
                $sformatf("INVALID refresh applied wrong_key=0x%08h TIMEOUT=%0d",
                          wrong_key, timeout_data),
                UVM_LOW)

    end

    repeat (10) @(posedge wdt_vintf.wdt_clk);

  end


  //=========================================================
  // 7. TEST COMPLETED
  //=========================================================
  `uvm_info("WDT_SEQ",
            "TC_RANDOM_06 : RANDOM REFRESH VALID / INVALID CHECK COMPLETED",
            UVM_LOW)

  #300;


  



    //=========================================================
  // TC_RANDOM_05 : RANDOM RESET_SCOPE CHECK
  //
  // Goal:
  // Randomly program CTRL[7:6] RESET_SCOPE.
  //
  // Scope Encoding:
  // 00 = Core Reset
  // 01 = Cluster Reset
  // 10 = Subsystem Reset
  // 11 = Full SoC Reset
  //
  // Expected:
  // reset_scope register matches programmed value.
  //=========================================================

  repeat (10) begin

    timeout_data = $urandom_range(10,80);
    reset_scope_data   = $urandom_range(0,3);

    //-------------------------------------------------------
    // Build CTRL value
    //
    // bit0 = ENABLE
    // bit1 = RESET_EN
    // bits[7:6] = RESET_SCOPE
    //-------------------------------------------------------
    ctrl_value = (reset_scope_data << 6) | 32'h3;

    //-------------------------------------------------------
    // Reset WDT domain
    //-------------------------------------------------------
    wdt_vintf.wdt_rstn = 1'b0;

    repeat(5)
      @(posedge wdt_vintf.wdt_clk);

    wdt_vintf.wdt_rstn = 1'b1;

    repeat(5)
      @(posedge wdt_vintf.wdt_clk);


    //-------------------------------------------------------
    // Unlock
    //-------------------------------------------------------
    req = apb_master_tx::type_id::create("scope_unlock");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    })
      `uvm_fatal("APB","Randomization Failed")

    req.paddr  = 32'h14;
    req.pwdata = 32'h1ACCE551;

    finish_item(req);

    #50;


    //-------------------------------------------------------
    // Clear status
    //-------------------------------------------------------
    req = apb_master_tx::type_id::create("scope_clear");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    })
      `uvm_fatal("APB","Randomization Failed")

    req.paddr  = 32'h10;
    req.pwdata = 32'hF;

    finish_item(req);

    #50;


    //-------------------------------------------------------
    // Random timeout
    //-------------------------------------------------------
    req = apb_master_tx::type_id::create("scope_timeout");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    })
      `uvm_fatal("APB","Randomization Failed")

    req.paddr  = 32'h4;
    req.pwdata = timeout_data;

    finish_item(req);

    #50;


    //-------------------------------------------------------
    // Program CTRL
    //-------------------------------------------------------
    req = apb_master_tx::type_id::create("scope_ctrl");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    })
      `uvm_fatal("APB","Randomization Failed")

    req.paddr  = 32'h0;
    req.pwdata = ctrl_value;

    finish_item(req);


    `uvm_info("TC_RANDOM_05",
      $sformatf("TIMEOUT=%0d RESET_SCOPE=%0d CTRL=0x%08h",
                timeout_data,
                reset_scope_data,
                ctrl_value),
      UVM_LOW)


    //-------------------------------------------------------
    // Read CTRL back
    //-------------------------------------------------------
    req = apb_master_tx::type_id::create("scope_ctrl_read");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
    })
      `uvm_fatal("APB","Randomization Failed")

    req.paddr = 32'h0;

    finish_item(req);


    //-------------------------------------------------------
    // Wait for timeout sequence
    //-------------------------------------------------------
    repeat(timeout_data + 30)
      @(posedge wdt_vintf.wdt_clk);


    `uvm_info("TC_RANDOM_05",
      $sformatf("Completed RESET_SCOPE=%0d", reset_scope_data),
      UVM_LOW)

  end


  `uvm_info("WDT_SEQ",
            "TC_RANDOM_05 RANDOM RESET_SCOPE CHECK COMPLETED",
            UVM_LOW)

  #300;

  

    //=========================================================
  // TC_RANDOM_04 : RANDOM RESET_WIDTH CHECK
  //
  // Goal:
  // Randomize WDT_RESET_WIDTH through APB.
  // Verify reset_counter/reset pulse width in waveform.
  //
  // Registers:
  // WDT_CTRL        = 0x00000000
  // WDT_TIMEOUT     = 0x00000004
  // WDT_STATUS      = 0x00000010
  // WDT_LOCK        = 0x00000014
  // WDT_RESET_WIDTH = 0x00000028
  //
  // Expected:
  // reset_cycles = reset_width_data
  // After timeout, wdt_reset remains high for programmed width.
  //
  // Random range:
  // TIMEOUT     = 10 to 80
  // RESET_WIDTH = 1 to 50
  //=========================================================

  repeat (10) begin

    timeout_data     = $urandom_range(10, 80);
    reset_width_data = $urandom_range(1, 50);

    //=======================================================
    // 1. RESET WDT DOMAIN BEFORE EACH ITERATION
    //=======================================================
    wdt_vintf.wdt_rstn = 1'b0;
    repeat (5) @(posedge wdt_vintf.wdt_clk);

    wdt_vintf.wdt_rstn = 1'b1;
    repeat (5) @(posedge wdt_vintf.wdt_clk);


    //=======================================================
    // 2. UNLOCK WDT
    //=======================================================
    req = apb_master_tx::type_id::create("reset_width_data_unlock");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    })
      `uvm_fatal("APB","Randomization Failed")

    req.paddr  = 32'h0000_0014;
    req.pwdata = 32'h1ACCE551;

    finish_item(req);

    #50;


    //=======================================================
    // 3. CLEAR STATUS FLAGS
    //=======================================================
    req = apb_master_tx::type_id::create("reset_width_data_clear_status");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    })
      `uvm_fatal("APB","Randomization Failed")

    req.paddr  = 32'h0000_0010;
    req.pwdata = 32'h0000_000F;

    finish_item(req);

    #50;


    //=======================================================
    // 4. WRITE RANDOM RESET_WIDTH
    //=======================================================
    req = apb_master_tx::type_id::create("reset_width_data_write");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    })
      `uvm_fatal("APB","Randomization Failed")

    req.paddr  = 32'h0000_0028;
    req.pwdata = {16'h0000, reset_width_data};

    finish_item(req);

    #50;


    //=======================================================
    // 5. WRITE RANDOM TIMEOUT
    //=======================================================
    req = apb_master_tx::type_id::create("reset_width_data_timeout");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    })
      `uvm_fatal("APB","Randomization Failed")

    req.paddr  = 32'h0000_0004;
    req.pwdata = timeout_data;

    finish_item(req);

    #50;


    //=======================================================
    // 6. ENABLE WDT + RESET_EN
    //
    // CTRL bit0 ENABLE   = 1
    // CTRL bit1 RESET_EN = 1
    // CTRL = 0x3
    //=======================================================
    req = apb_master_tx::type_id::create("reset_width_data_enable");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    })
      `uvm_fatal("APB","Randomization Failed")

    req.paddr  = 32'h0000_0000;
    req.pwdata = 32'h0000_0003;

    finish_item(req);


    `uvm_info("TC_RANDOM_04",
              $sformatf("TIMEOUT=%0d RESET_WIDTH=%0d",
                        timeout_data, reset_width_data),
              UVM_LOW)


    //=======================================================
    // 7. WAIT FOR TIMEOUT + RESET WIDTH COMPLETION
    //=======================================================
    repeat (timeout_data + reset_width_data + 20)
      @(posedge wdt_vintf.wdt_clk);


    `uvm_info("TC_RANDOM_04",
              $sformatf("Completed iteration TIMEOUT=%0d RESET_WIDTH=%0d",
                        timeout_data, reset_width_data),
              UVM_LOW)

  end


  //=========================================================
  // 8. TEST COMPLETED
  //=========================================================
  `uvm_info("WDT_SEQ",
            "TC_RANDOM_04 : RANDOM RESET_WIDTH CHECK COMPLETED",
            UVM_LOW)

  #300;


  


    //=========================================================
  // TC_RANDOM_03 : RANDOM TIMEOUT + WDT RESET RESTART CHECK
  //=========================================================

  repeat (10) begin

    timeout_data = $urandom_range(10, 100);

    // UNLOCK
    req = apb_master_tx::type_id::create("timeout_data_unlock");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;
    start_item(req);
    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    }) `uvm_fatal("APB","Randomization Failed")
    req.paddr  = 32'h0000_0014;
    req.pwdata = 32'h1ACCE551;
    finish_item(req);
    #50;

    // CLEAR STATUS
    req = apb_master_tx::type_id::create("timeout_data_clear_status");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;
    start_item(req);
    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    }) `uvm_fatal("APB","Randomization Failed")
    req.paddr  = 32'h0000_0010;
    req.pwdata = 32'h0000_000F;
    finish_item(req);
    #50;

    // WRITE RANDOM TIMEOUT
    req = apb_master_tx::type_id::create("timeout_data_write");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;
    start_item(req);
    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    }) `uvm_fatal("APB","Randomization Failed")
    req.paddr  = 32'h0000_0004;
    req.pwdata = timeout_data;
    finish_item(req);
    #50;

    // ENABLE WDT + RESET_EN
    // CTRL[0] ENABLE   = 1
    // CTRL[1] RESET_EN = 1
    // CTRL = 0x3
    req = apb_master_tx::type_id::create("timeout_data_enable_reset");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;
    start_item(req);
    if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
    }) `uvm_fatal("APB","Randomization Failed")
    req.paddr  = 32'h0000_0000;
    req.pwdata = 32'h0000_0003;
    finish_item(req);

    `uvm_info("TC_RANDOM_03",
              $sformatf("Started timeout iteration with TIMEOUT=%0d",
                        timeout_data),
              UVM_LOW)

    // WAIT FOR COUNTDOWN TO COMPLETE
    repeat (timeout_data + 20)
      @(posedge wdt_vintf.wdt_clk);

    // WAIT FOR WDT RESET OUTPUT
    wait (wdt_vintf.wdt_reset == 1'b1);
    wait (wdt_vintf.wdt_reset == 1'b0);

    `uvm_info("TC_RANDOM_03",
              "WDT reset pulse observed",
              UVM_LOW)

    // APPLY REAL WDT INPUT RESET FOR NEXT ITERATION
    wdt_vintf.wdt_rstn = 1'b0;
    repeat (5) @(posedge wdt_vintf.wdt_clk);

    wdt_vintf.wdt_rstn = 1'b1;
    repeat (5) @(posedge wdt_vintf.wdt_clk);

    `uvm_info("TC_RANDOM_03",
              "WDT input reset completed, next iteration can start fresh",
              UVM_LOW)

  end

  `uvm_info("WDT_SEQ",
            "TC_RANDOM_03 : RANDOM TIMEOUT + WDT RESET RESTART CHECK COMPLETED",
            UVM_LOW)

  #300;


  


  //=========================================================
  // TC_RANDOM_01 : RANDOM LAST_PC CHECK
  //
  // Goal:
  // Randomize CPU committed PC through WDT interface.
  //
  // Register:
  // WDT_LAST_PC = 0x00000020
  //
  // Expected:
  // cpu_commit_valid pulse captures cpu_commit_pc into last_pc.
  //=========================================================
  repeat (20) begin

    pc_data = $urandom_range(32'h8000_0000, 32'h8000_FFFF);

    #10;
    wdt_vintf.cpu_commit_pc    = pc_data;
    wdt_vintf.cpu_commit_valid = 1'b1;

    #10;
    wdt_vintf.cpu_commit_valid = 1'b0;

    #20;

    req = apb_master_tx::type_id::create("random_last_pc_read");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if(!req.randomize() with {
        req.pselx         == SLAVE_0;
        req.transfer_size == BIT_32;
        req.pwrite        == READ;
    })
      `uvm_fatal("APB","Randomization Failed")

    req.paddr = 32'h0000_0020;

    finish_item(req);

    #50;

    `uvm_info("TC_RANDOM_01",
              $sformatf("Random PC driven = 0x%08h", pc_data),
              UVM_LOW)

  end

  `uvm_info("WDT_SEQ",
            "TC_RANDOM_01 : RANDOM LAST_PC CHECK COMPLETED",
            UVM_LOW)


  //=========================================================
  // TC_RANDOM_02 : RANDOM DEBUG FREEZE CHECK
  //
  // Goal:
  // Randomize cpu_dbg_halt and dbg_freeze.
  //
  // Spec:
  // freeze_condition = dbg_freeze_en &
  //                    (cpu_dbg_halt | dbg_freeze)
  //
  // Requirement:
  // Enable CTRL[3] DBG_FREEZE_EN.
  //
  // CTRL:
  // bit0 ENABLE        = 1
  // bit3 DBG_FREEZE_EN = 1
  // CTRL = 0x00000009
  //=========================================================


  //=========================================================
  // 1. UNLOCK WDT
  //=========================================================
  req = apb_master_tx::type_id::create("rand_dbg_unlock");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0014;
  req.pwdata = 32'h1ACCE551;

  finish_item(req);

  #50;


  //=========================================================
  // 2. PROGRAM TIMEOUT = 50
  //=========================================================
  req = apb_master_tx::type_id::create("rand_dbg_timeout");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0004;
  req.pwdata = 32'h0000_0032;

  finish_item(req);

  #50;


  //=========================================================
  // 3. ENABLE WDT + DBG_FREEZE_EN
  //=========================================================
  req = apb_master_tx::type_id::create("rand_dbg_ctrl");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0000;
  req.pwdata = 32'h0000_0009;

  finish_item(req);

  #100;


  //=========================================================
  // 4. RANDOM DEBUG FREEZE DRIVE LOOP - WDT_CLK BASED
  //=========================================================
  repeat (10) begin

    rand_halt       = $urandom_range(0, 1);
    rand_dbg_freeze = $urandom_range(0, 1);
    freeze_wait     = $urandom_range(2, 8); // WDT clock cycles

    @(posedge wdt_vintf.wdt_clk);
    wdt_vintf.cpu_dbg_halt = rand_halt;
    wdt_vintf.dbg_freeze   = rand_dbg_freeze;

    `uvm_info("TC_RANDOM_02",
              $sformatf("Drive cpu_dbg_halt=%0b dbg_freeze=%0b wait_wdt_cycles=%0d",
                        rand_halt, rand_dbg_freeze, freeze_wait),
              UVM_LOW)

    repeat (freeze_wait) @(posedge wdt_vintf.wdt_clk);

    wdt_vintf.cpu_dbg_halt = 1'b0;
    wdt_vintf.dbg_freeze   = 1'b0;

    repeat (3) @(posedge wdt_vintf.wdt_clk);

  end

  
  `uvm_info("WDT_SEQ",
            "TC_RANDOM_02 : RANDOM DEBUG FREEZE CHECK COMPLETED",
            UVM_LOW)

  #300;

  


  

  //=========================================================
  // TC_RANDOM_01 : RANDOM LAST_PC CHECK
  //
  // Goal:
  // Randomize CPU committed PC through WDT interface.
  //
  // Register:
  // WDT_LAST_PC = 0x00000020
  //
  // Expected:
  // When cpu_commit_valid = 1,
  // WDT captures cpu_commit_pc into LAST_PC register.
  //
  // Random range:
  // 0x8000_0000 to 0x8000_FFFF
  //=========================================================


  //=========================================================
  // 1. GET WDT INTERFACE HANDLE
  //=========================================================
  if (!uvm_config_db#(virtual wdt_intf)::get(
        null,
        "*",
        "wdt_vintf",
        wdt_vintf
      )) begin
    `uvm_fatal("WDT_SEQ", "Failed to get wdt_vintf")
  end


  //=========================================================
  // 2. RANDOM PC DRIVE LOOP
  //=========================================================
  repeat (20) begin

    pc_data = $urandom_range(32'h8000_0000, 32'h8000_FFFF);

    //=======================================================
    // 2.1 DRIVE RANDOM CPU COMMIT PC
    //=======================================================
    #10;
    wdt_vintf.cpu_commit_pc    = pc_data;
    wdt_vintf.cpu_commit_valid = 1'b1;

    #10;
    wdt_vintf.cpu_commit_valid = 1'b0;

    #20;


    //=======================================================
    // 2.2 READ WDT_LAST_PC REGISTER
    //=======================================================
    req = apb_master_tx::type_id::create("random_last_pc_read");
    req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

    start_item(req);

    if(!req.randomize() with {
        req.pselx         == SLAVE_0;
        req.transfer_size == BIT_32;
        req.pwrite        == READ;
    })
      `uvm_fatal("APB","Randomization Failed")

    req.paddr = 32'h0000_0020;

    finish_item(req);

    #50;

    `uvm_info("TC_RANDOM_01",
              $sformatf("Random PC driven = 0x%08h, WDT_LAST_PC read issued",
                        pc_data),
              UVM_LOW)

  end


  //=========================================================
  // 3. TEST COMPLETED
  //=========================================================
  `uvm_info("WDT_SEQ",
            "TC_RANDOM_01 : RANDOM LAST_PC CHECK COMPLETED",
            UVM_LOW)

  #300;









  

    //=========================================================
  // TC_SCOPE_01_TO_04 : RESET_SCOPE ENCODING CHECK
  //
  // Goal:
  // Verify CTRL[7:6] RESET_SCOPE programming.
  //
  // Spec:
  // 00 = Core reset
  // 01 = Cluster reset
  // 10 = Subsystem reset
  // 11 = Full SoC reset
  //
  // CTRL bits:
  // bit0 ENABLE
  // bit1 RESET_EN
  // bits[7:6] RESET_SCOPE
  //
  // Expected CTRL values:
  // Scope 00 : CTRL = 0x00000003
  // Scope 01 : CTRL = 0x00000043
  // Scope 10 : CTRL = 0x00000083
  // Scope 11 : CTRL = 0x000000C3
  //=========================================================


  //=========================================================
  // 1. UNLOCK WDT
  //=========================================================
  req = apb_master_tx::type_id::create("unlock_wdt");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0014;
  req.pwdata = 32'h1ACCE551;

  finish_item(req);

  #50;


  //=========================================================
  // 2. RESET_SCOPE = 00 CORE RESET
  //
  // CTRL = 0x03
  //=========================================================
  req = apb_master_tx::type_id::create("scope_core_write");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0000;
  req.pwdata = 32'h0000_0003;

  finish_item(req);

  #50;

  req = apb_master_tx::type_id::create("scope_core_read");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0000;

  finish_item(req);

  #100;


  //=========================================================
  // 3. RESET_SCOPE = 01 CLUSTER RESET
  //
  // CTRL = 0x43
  //=========================================================
  req = apb_master_tx::type_id::create("scope_cluster_write");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0000;
  req.pwdata = 32'h0000_0043;

  finish_item(req);

  #50;

  req = apb_master_tx::type_id::create("scope_cluster_read");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0000;

  finish_item(req);

  #100;


  //=========================================================
  // 4. RESET_SCOPE = 10 SUBSYSTEM RESET
  //
  // CTRL = 0x83
  //=========================================================
  req = apb_master_tx::type_id::create("scope_subsystem_write");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0000;
  req.pwdata = 32'h0000_0083;

  finish_item(req);

  #50;

  req = apb_master_tx::type_id::create("scope_subsystem_read");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0000;

  finish_item(req);

  #100;


  //=========================================================
  // 5. RESET_SCOPE = 11 FULL SOC RESET
  //
  // CTRL = 0xC3
  //=========================================================
  req = apb_master_tx::type_id::create("scope_soc_write");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0000;
  req.pwdata = 32'h0000_00C3;

  finish_item(req);

  #50;

  req = apb_master_tx::type_id::create("scope_soc_read");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0000;

  finish_item(req);

  #100;


  `uvm_info("WDT_SEQ",
            "TC_SCOPE_01_TO_04 : RESET_SCOPE ENCODING CHECK COMPLETED",
            UVM_LOW)

  #300;

  

    //=========================================================
  // TC_RESET_WIDTH_02 : RESET WIDTH = 10 CHECK
  //
  // Goal:
  // Verify WDT_RESET_WIDTH controls wdt_reset pulse duration
  // for a different programmed value.
  //
  // Register:
  // WDT_RESET_WIDTH = 0x028
  //
  // Configuration:
  // RESET_WIDTH = 10
  // TIMEOUT     = 5
  // CTRL        = 0x3
  //
  // Expected:
  // wdt_reset asserted for 10 wdt_clk cycles
  // reset_counter counts 1 -> 10
  //=========================================================


  //=========================================================
  // 1. UNLOCK WDT
  //=========================================================
  req = apb_master_tx::type_id::create("unlock_wdt");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0014;
  req.pwdata = 32'h1ACCE551;

  finish_item(req);

  #50;


  //=========================================================
  // 2. CLEAR STATUS
  //=========================================================
  req = apb_master_tx::type_id::create("clear_status");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0010;
  req.pwdata = 32'h0000_000F;

  finish_item(req);

  #50;


  //=========================================================
  // 3. CLEAR BOOT_STATUS OLD PREV_RESET_WDT
  //=========================================================
  req = apb_master_tx::type_id::create("clear_boot_status");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0024;
  req.pwdata = 32'h0000_0001;

  finish_item(req);

  #50;


  //=========================================================
  // 4. PROGRAM RESET_WIDTH = 10
  //=========================================================
  req = apb_master_tx::type_id::create("reset_width_10");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0028;
  req.pwdata = 32'd10;

  finish_item(req);

  #50;


  //=========================================================
  // 5. READ RESET_WIDTH BACK
  //
  // Expected:
  // PRDATA = 10
  //=========================================================
  req = apb_master_tx::type_id::create("read_reset_width_10");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0028;

  finish_item(req);

  #50;


  //=========================================================
  // 6. PROGRAM TIMEOUT = 5
  //=========================================================
  req = apb_master_tx::type_id::create("timeout_5");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0004;
  req.pwdata = 32'd5;

  finish_item(req);

  #50;


  //=========================================================
  // 7. ENABLE WATCHDOG + RESET GENERATION
  //
  // CTRL[0] ENABLE   = 1
  // CTRL[1] RESET_EN = 1
  //
  // CTRL = 0x3
  //=========================================================
  req = apb_master_tx::type_id::create("enable_reset");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0000;
  req.pwdata = 32'h0000_0003;

  finish_item(req);


  //=========================================================
  // 8. WAIT FOR TIMEOUT + RESET PULSE
  //
  // Expected:
  // counter       : 5 -> 4 -> 3 -> 2 -> 1 -> 0
  // wdt_timeout   : 1
  // wdt_reset     : 1
  // reset_counter : 1 -> 10
  //=========================================================
  #3500;


  //=========================================================
  // 9. READ STATUS
  //
  // Expected:
  // STATUS = 0x00000009
  //=========================================================
  req = apb_master_tx::type_id::create("read_status_after_reset_width_10");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0010;

  finish_item(req);

  #100;


  //=========================================================
  // 10. READ RESET_WIDTH AGAIN
  //
  // Expected:
  // PRDATA = 10
  //=========================================================
  req = apb_master_tx::type_id::create("read_reset_width_final");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0028;

  finish_item(req);

  #100;


  `uvm_info("WDT_SEQ",
            "TC_RESET_WIDTH_02 : RESET WIDTH = 10 CHECK COMPLETED",
            UVM_LOW)

  #300;

  

    //=========================================================
  // TC_BOOT_STATUS_02 : PREV_RESET_WDT RW1C CHECK
  //
  // Goal:
  // Verify BOOT_STATUS[0] is set after watchdog reset
  // and clears when software writes 1 to bit0.
  //
  // Register:
  // WDT_BOOT_STATUS = 0x024
  //
  // Spec:
  // bit[0] = PREV_RESET_WDT     RW1C
  // bit[1] = RECOVERY_BOOT_REQ  RW
  //
  // Expected:
  // After WDT reset:
  //   PRDATA = 0x00000001
  //
  // After W1C clear:
  //   PRDATA = 0x00000000
  //=========================================================


  //=========================================================
  // 1. UNLOCK WDT
  //=========================================================
  req = apb_master_tx::type_id::create("unlock_wdt");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0014;
  req.pwdata = 32'h1ACCE551;

  finish_item(req);

  #50;


  //=========================================================
  // 2. CLEAR STATUS
  //=========================================================
  req = apb_master_tx::type_id::create("clear_status");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0010;
  req.pwdata = 32'h0000_000F;

  finish_item(req);

  #50;


  //=========================================================
  // 3. CLEAR BOOT_STATUS BIT0 BEFORE TEST
  //
  // PREV_RESET_WDT is RW1C.
  // Write 1 to bit0 to clear old value.
  // Keep bit1 = 0.
  //=========================================================
  req = apb_master_tx::type_id::create("clear_boot_status_before");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0024;
  req.pwdata = 32'h0000_0001;

  finish_item(req);

  #100;


  //=========================================================
  // 4. PROGRAM RESET_WIDTH = 5
  //=========================================================
  req = apb_master_tx::type_id::create("reset_width_5");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0028;
  req.pwdata = 32'd5;

  finish_item(req);

  #50;


  //=========================================================
  // 5. PROGRAM TIMEOUT = 5
  //=========================================================
  req = apb_master_tx::type_id::create("timeout_5");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0004;
  req.pwdata = 32'd5;

  finish_item(req);

  #50;


  //=========================================================
  // 6. ENABLE WATCHDOG + RESET GENERATION
  //
  // CTRL[0] ENABLE   = 1
  // CTRL[1] RESET_EN = 1
  //
  // CTRL = 0x3
  //=========================================================
  req = apb_master_tx::type_id::create("enable_reset");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0000;
  req.pwdata = 32'h0000_0003;

  finish_item(req);


  //=========================================================
  // 7. WAIT FOR TIMEOUT + RESET + BOOT_STATUS UPDATE
  //
  // Important:
  // Add enough delay because BOOT_STATUS may update after
  // reset cause/status logic.
  //=========================================================
  #2500;


  //=========================================================
  // 8. READ BOOT_STATUS AFTER WDT RESET
  //
  // Expected:
  // BOOT_STATUS[0] = PREV_RESET_WDT = 1
  // PRDATA = 0x00000001
  //=========================================================
  req = apb_master_tx::type_id::create("read_boot_status_after_wdt_reset");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0024;

  finish_item(req);

  #100;


  //=========================================================
  // 9. CLEAR PREV_RESET_WDT USING W1C
  //
  // Write 1 to bit0.
  // bit1 remains 0.
  //=========================================================
  req = apb_master_tx::type_id::create("clear_prev_reset_wdt_w1c");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0024;
  req.pwdata = 32'h0000_0001;

  finish_item(req);

  #100;


  //=========================================================
  // 10. READ BOOT_STATUS AFTER CLEAR
  //
  // Expected:
  // PRDATA = 0x00000000
  //=========================================================
  req = apb_master_tx::type_id::create("read_boot_status_after_clear");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0024;

  finish_item(req);

  #100;


  `uvm_info("WDT_SEQ",
            "TC_BOOT_STATUS_02 : PREV_RESET_WDT RW1C CHECK COMPLETED",
            UVM_LOW)

  #300;


  

    //=========================================================
  // TC_BOOT_STATUS_01 : WDT_BOOT_STATUS REGISTER CHECK
  //
  // Goal:
  // Verify WDT_BOOT_STATUS register behavior.
  //
  // Register:
  // WDT_BOOT_STATUS = 0x024
  //
  // Spec:
  // bit[0] = PREV_RESET_WDT     RW1C
  // bit[1] = RECOVERY_BOOT_REQ  RW
  //
  // Test:
  // 1. Write RECOVERY_BOOT_REQ = 1
  // 2. Read back BOOT_STATUS
  // 3. Expected PRDATA[1] = 1
  // 4. Write bit0 = 1 to clear PREV_RESET_WDT if set
  // 5. Read back again
  //=========================================================


  //=========================================================
  // 1. UNLOCK WDT
  //=========================================================
  req = apb_master_tx::type_id::create("unlock_wdt");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0014;
  req.pwdata = 32'h1ACCE551;

  finish_item(req);

  #50;


  //=========================================================
  // 2. WRITE RECOVERY_BOOT_REQ = 1
  //
  // BOOT_STATUS[1] = 1
  // Write data = 0x00000002
  //=========================================================
  req = apb_master_tx::type_id::create("write_recovery_boot_req");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0024;
  req.pwdata = 32'h0000_0002;

  finish_item(req);

  #100;


  //=========================================================
  // 3. READ BOOT_STATUS
  //
  // Expected:
  // PRDATA = 0x00000002
  //=========================================================
  req = apb_master_tx::type_id::create("read_boot_status_1");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0024;

  finish_item(req);

  #100;


  //=========================================================
  // 4. WRITE PREV_RESET_WDT W1C
  //
  // BOOT_STATUS[0] = RW1C
  // Writing 1 clears bit0 if it is set.
  //
  // Keep bit1 set by writing bit1 = 1 also.
  // Write data = 0x00000003
  //=========================================================
  req = apb_master_tx::type_id::create("clear_prev_reset_wdt");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0024;
  req.pwdata = 32'h0000_0003;

  finish_item(req);

  #100;


  //=========================================================
  // 5. READ BOOT_STATUS AGAIN
  //
  // Expected:
  // bit0 cleared
  // bit1 remains set
  //
  // PRDATA = 0x00000002
  //=========================================================
  req = apb_master_tx::type_id::create("read_boot_status_2");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0024;

  finish_item(req);

  #100;


  //=========================================================
  // 6. CLEAR RECOVERY_BOOT_REQ
  //
  // BOOT_STATUS[1] is RW
  // Write 0 clears bit1.
  //=========================================================
  req = apb_master_tx::type_id::create("clear_recovery_boot_req");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0024;
  req.pwdata = 32'h0000_0000;

  finish_item(req);

  #100;


  //=========================================================
  // 7. READ BOOT_STATUS FINAL
  //
  // Expected:
  // PRDATA = 0x00000000
  //=========================================================
  req = apb_master_tx::type_id::create("read_boot_status_3");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0024;

  finish_item(req);

  #100;


  `uvm_info("WDT_SEQ",
            "TC_BOOT_STATUS_01 : WDT_BOOT_STATUS REGISTER CHECK COMPLETED",
            UVM_LOW)

  #300;

  

    //=========================================================
  // TC_LAST_PC_01 : WDT_LAST_PC REGISTER CHECK
  //
  // Goal:
  // Verify WDT_LAST_PC captures last committed CPU PC.
  //
  // Register:
  // WDT_LAST_PC = 0x020
  //
  // Spec:
  // Captured using:
  // cpu_commit_pc
  // cpu_commit_valid
  //
  // Configuration:
  // cpu_commit_pc    = 32'h8000_1234
  // cpu_commit_valid = 1 pulse
  //
  // Then:
  // TIMEOUT       = 5
  // RESET_WIDTH   = 5
  // CTRL          = 0x3
  //
  // Expected:
  // WDT_LAST_PC PRDATA = 32'h8000_1234
  //=========================================================


  //=========================================================
  // 1. DRIVE CPU COMMIT PC
  //=========================================================
//  vif.cpu_commit_pc    <= 32'h8000_1234;
 // vif.cpu_commit_valid <= 1'b1;

 // #20;

 // vif.cpu_commit_valid <= 1'b0;

  #50;


  //=========================================================
  // 2. UNLOCK WDT
  //=========================================================
  req = apb_master_tx::type_id::create("unlock_wdt");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0014;
  req.pwdata = 32'h1ACCE551;

  finish_item(req);

  #50;


  //=========================================================
  // 3. CLEAR STATUS
  //=========================================================
  req = apb_master_tx::type_id::create("clear_status");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0010;
  req.pwdata = 32'h0000_000F;

  finish_item(req);

  #50;


  //=========================================================
  // 4. PROGRAM RESET_WIDTH = 5
  //=========================================================
  req = apb_master_tx::type_id::create("reset_width_5");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0028;
  req.pwdata = 32'd5;

  finish_item(req);

  #50;


  //=========================================================
  // 5. PROGRAM TIMEOUT = 5
  //=========================================================
  req = apb_master_tx::type_id::create("timeout_5");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0004;
  req.pwdata = 32'd5;

  finish_item(req);

  #50;


  //=========================================================
  // 6. ENABLE WATCHDOG + RESET GENERATION
  //
  // CTRL[0] ENABLE   = 1
  // CTRL[1] RESET_EN = 1
  //
  // CTRL = 0x3
  //=========================================================
  req = apb_master_tx::type_id::create("enable_reset");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0000;
  req.pwdata = 32'h0000_0003;

  finish_item(req);


  //=========================================================
  // 7. WAIT FOR TIMEOUT + RESET + LAST_PC UPDATE
  //=========================================================
  #200;


  //=========================================================
  // 8. READ WDT_LAST_PC
  //
  // Address:
  // WDT_LAST_PC = 0x020
  //
  // Expected:
  // PRDATA = 32'h8000_1234
  //=========================================================
  req = apb_master_tx::type_id::create("read_last_pc");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0020;

  finish_item(req);

  #100;


  //=========================================================
  // 9. READ STATUS
  //
  // Expected:
  // PRDATA = 0x00000009
  //=========================================================
  req = apb_master_tx::type_id::create("read_status");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0010;

  finish_item(req);

  #100;


  `uvm_info("WDT_SEQ",
            "TC_LAST_PC_01 : WDT_LAST_PC REGISTER CHECK COMPLETED",
            UVM_LOW)

  #300;

  

    //=========================================================
  // TC_RESET_CAUSE_01 : WDT_RESET_CAUSE REGISTER CHECK
  //
  // Goal:
  // Verify WDT_RESET_CAUSE[0] is set after watchdog reset.
  //
  // Register:
  // WDT_RESET_CAUSE = 0x01C
  //
  // Spec:
  // bit[0] = WDT_RESET_CAUSE
  //
  // Configuration:
  // TIMEOUT       = 5
  // RESET_WIDTH   = 5
  // ENABLE        = 1
  // RESET_EN      = 1
  //
  // Expected:
  // wdt_timeout asserted
  // wdt_reset asserted
  // STATUS = 0x9
  // RESET_CAUSE PRDATA[0] = 1
  //=========================================================


  //=========================================================
  // 1. UNLOCK WDT
  //=========================================================
  req = apb_master_tx::type_id::create("unlock_wdt");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0014;
  req.pwdata = 32'h1ACCE551;

  finish_item(req);

  #50;


  //=========================================================
  // 2. CLEAR STATUS
  //=========================================================
  req = apb_master_tx::type_id::create("clear_status");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0010;
  req.pwdata = 32'h0000_000F;

  finish_item(req);

  #50;


  //=========================================================
  // 3. PROGRAM RESET_WIDTH = 5
  //=========================================================
  req = apb_master_tx::type_id::create("reset_width_5");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0028;
  req.pwdata = 32'd5;

  finish_item(req);

  #50;


  //=========================================================
  // 4. PROGRAM TIMEOUT = 5
  //=========================================================
  req = apb_master_tx::type_id::create("timeout_5");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0004;
  req.pwdata = 32'd5;

  finish_item(req);

  #50;


  //=========================================================
  // 5. ENABLE WATCHDOG + RESET GENERATION
  //
  // CTRL[0] ENABLE   = 1
  // CTRL[1] RESET_EN = 1
  //
  // CTRL = 0x3
  //=========================================================
  req = apb_master_tx::type_id::create("enable_reset");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0000;
  req.pwdata = 32'h0000_0003;

  finish_item(req);


  //=========================================================
  // 6. WAIT FOR TIMEOUT AND RESET PULSE
  //
  // Expected:
  // counter 5 -> 4 -> 3 -> 2 -> 1 -> 0
  // wdt_timeout = 1
  // wdt_reset   = 1
  //=========================================================
  #20;


  //=========================================================
  // 7. READ WDT_RESET_CAUSE
  //
  // Address:
  // WDT_RESET_CAUSE = 0x01C
  //
  // Expected:
  // PRDATA[0] = 1
  // PRDATA    = 0x00000001
  //=========================================================
  req = apb_master_tx::type_id::create("read_reset_cause");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_001C;

  finish_item(req);

  #100;


  //=========================================================
  // 8. READ STATUS ALSO
  //
  // Expected:
  // STATUS[0] = TIMEOUT_FLAG
  // STATUS[3] = RESET_ISSUED
  // PRDATA    = 0x00000009
  //=========================================================
  req = apb_master_tx::type_id::create("read_status");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0010;

  finish_item(req);

  #100;


  `uvm_info("WDT_SEQ",
            "TC_RESET_CAUSE_01 : WDT_RESET_CAUSE REGISTER CHECK COMPLETED",
            UVM_LOW)

  #300;


  

    //=========================================================
  // TC_RESET_WIDTH_01 : RESET WIDTH REGISTER CHECK
  //
  // Goal:
  // Verify WDT_RESET_WIDTH controls wdt_reset pulse duration.
  //
  // Register:
  // WDT_RESET_WIDTH = 0x028
  //
  // Configuration:
  // TIMEOUT       = 5
  // RESET_WIDTH   = 5
  // ENABLE        = 1
  // RESET_EN      = 1
  //
  // Expected:
  // watchdog_counter reaches 0
  // wdt_timeout asserted
  // wdt_reset asserted
  // reset_counter counts reset width
  // wdt_reset duration = RESET_WIDTH clocks
  // STATUS = 0x9
  //=========================================================


  //=========================================================
  // 1. UNLOCK WDT
  //=========================================================
  req = apb_master_tx::type_id::create("unlock_wdt");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0014;
  req.pwdata = 32'h1ACCE551;

  finish_item(req);

  #50;


  //=========================================================
  // 2. CLEAR STATUS
  //=========================================================
  req = apb_master_tx::type_id::create("clear_status");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0010;
  req.pwdata = 32'h0000_000F;

  finish_item(req);

  #50;


  //=========================================================
  // 3. PROGRAM RESET_WIDTH = 5
  //
  // WDT_RESET_WIDTH = 0x028
  //=========================================================
  req = apb_master_tx::type_id::create("reset_width_5");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0028;
  req.pwdata = 32'd5;

  finish_item(req);

  #50;


  //=========================================================
  // 4. PROGRAM TIMEOUT = 5
  //=========================================================
  req = apb_master_tx::type_id::create("timeout_5");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0004;
  req.pwdata = 32'd5;

  finish_item(req);

  #50;


  //=========================================================
  // 5. ENABLE WATCHDOG + RESET GENERATION
  //
  // CTRL[0] ENABLE   = 1
  // CTRL[1] RESET_EN = 1
  //
  // CTRL = 0x3
  //=========================================================
  req = apb_master_tx::type_id::create("enable_reset");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0000;
  req.pwdata = 32'h0000_0003;

  finish_item(req);

  #10;


  //=========================================================
  // 6. READ COUNT BEFORE TIMEOUT
  //
  // Expected:
  // COUNT near 5/4/3 depending timing
  //=========================================================
  req = apb_master_tx::type_id::create("read_count_before_timeout");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0018;

  finish_item(req);

  #10;


  //=========================================================
  // 7. READ STATUS AFTER TIMEOUT/RESET
  //
  // Expected:
  // STATUS[0] TIMEOUT_FLAG  = 1
  // STATUS[3] RESET_ISSUED  = 1
  // PRDATA = 0x00000009
  //=========================================================
  req = apb_master_tx::type_id::create("read_status_after_reset");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0010;

  finish_item(req);

  #10;


  //=========================================================
  // 8. READ RESET_WIDTH BACK
  //
  // Expected:
  // PRDATA = 5
  //=========================================================
  req = apb_master_tx::type_id::create("read_reset_width");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0028;

  finish_item(req);

  #100;


  `uvm_info("WDT_SEQ",
            "TC_RESET_WIDTH_01 : RESET WIDTH REGISTER CHECK COMPLETED",
            UVM_LOW)

  #300;

  

    //=========================================================
  // TC_COUNT_04 : COUNT REGISTER IN WINDOW MODE
  //
  // Goal:
  // Verify COUNT register operation in Window Mode.
  //
  // Verify:
  // 1. Counter decrements normally
  // 2. COUNT register matches counter
  // 3. Legal refresh reloads counter
  // 4. COUNT reflects reloaded value
  //
  // Configuration:
  // TIMEOUT   = 20
  // WINDOW    = 10
  // WINDOW_EN = 1
  //=========================================================


  //=========================================================
  // 1. UNLOCK WDT
  //=========================================================
  req = apb_master_tx::type_id::create("unlock_wdt");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0014;
  req.pwdata = 32'h1ACCE551;

  finish_item(req);

  #50;


  //=========================================================
  // 2. CLEAR STATUS
  //=========================================================
  req = apb_master_tx::type_id::create("clear_status");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0010;
  req.pwdata = 32'h0000_000F;

  finish_item(req);

  #50;


  //=========================================================
  // 3. PROGRAM TIMEOUT = 20
  //=========================================================
  req = apb_master_tx::type_id::create("timeout_20");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0004;
  req.pwdata = 32'd20;

  finish_item(req);

  #50;


  //=========================================================
  // 4. PROGRAM WINDOW = 10
  //=========================================================
  req = apb_master_tx::type_id::create("window_10");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0008;
  req.pwdata = 32'd10;

  finish_item(req);

  #50;


  //=========================================================
  // 5. ENABLE WATCHDOG + WINDOW MODE
  //
  // ENABLE    = bit0
  // WINDOW_EN = bit2
  //
  // CTRL = 0x5
  //=========================================================
  req = apb_master_tx::type_id::create("enable_window");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0000;
  req.pwdata = 32'h0000_0005;

  finish_item(req);

  #10;


  //=========================================================
  // 6. READ COUNT ABOVE WINDOW
  //
  // Expected:
  // COUNT > 10
  //=========================================================
  req = apb_master_tx::type_id::create("count_above_window");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0018;

  finish_item(req);

  #30;


  //=========================================================
  // 7. READ COUNT NEAR WINDOW
  //
  // Expected:
  // COUNT around 10
  //=========================================================
  req = apb_master_tx::type_id::create("count_near_window");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0018;

  finish_item(req);

  #30;


  //=========================================================
  // 8. LEGAL REFRESH
  //
  // Refresh when COUNT <= WINDOW
  //=========================================================
  req = apb_master_tx::type_id::create("refresh_a5");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_000C;
  req.pwdata = 32'h000000A5;

  finish_item(req);

  #50;


  req = apb_master_tx::type_id::create("refresh_5a");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_000C;
  req.pwdata = 32'h0000005A;

  finish_item(req);

  #10;


  //=========================================================
  // 9. READ COUNT AFTER REFRESH
  //
  // Expected:
  // COUNT reloads to 20
  //=========================================================
  req = apb_master_tx::type_id::create("count_after_refresh");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0018;

  finish_item(req);

  #10;


  //=========================================================
  // 10. READ STATUS
  //
  // Expected:
  // WINDOW_VIOLATION = 0
  // REFRESH_ERROR    = 0
  //=========================================================
  req = apb_master_tx::type_id::create("read_status");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0010;

  finish_item(req);

  #100;


  `uvm_info("WDT_SEQ",
            "TC_COUNT_04 : COUNT REGISTER IN WINDOW MODE",
            UVM_LOW)

  #300;



  

    //=========================================================
  // TC_COUNT_03 : COUNT AFTER TIMEOUT
  //
  // Goal:
  // Verify COUNT register behavior after timeout.
  //
  // Expected:
  // Counter reaches 0
  // timeout_flag asserted
  // Read COUNT after timeout
  //=========================================================


  //=========================================================
  // 1. UNLOCK WDT
  //=========================================================
  req = apb_master_tx::type_id::create("unlock_wdt");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0014;
  req.pwdata = 32'h1ACCE551;

  finish_item(req);

  #50;


  //=========================================================
  // 2. CLEAR STATUS
  //=========================================================
  req = apb_master_tx::type_id::create("clear_status");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0010;
  req.pwdata = 32'h0000_000F;

  finish_item(req);

  #50;


  //=========================================================
  // 3. PROGRAM TIMEOUT = 5
  //=========================================================
  req = apb_master_tx::type_id::create("timeout_5");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0004;
  req.pwdata = 32'd5;

  finish_item(req);

  #50;


  //=========================================================
  // 4. ENABLE WATCHDOG
  //=========================================================
  req = apb_master_tx::type_id::create("enable_wdt");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0000;
  req.pwdata = 32'h0000_0001;

  finish_item(req);

  #50;


  //=========================================================
  // 5. READ COUNT BEFORE TIMEOUT
  //=========================================================
  req = apb_master_tx::type_id::create("count_before_timeout");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0018;

  finish_item(req);

  #30;


  //=========================================================
  // 6. WAIT FOR TIMEOUT
  //
  // Expected:
  // 5 -> 4 -> 3 -> 2 -> 1 -> 0
  // timeout_flag asserted
  //=========================================================
  

  //=========================================================
  // 7. READ COUNT AFTER TIMEOUT
  //=========================================================
  req = apb_master_tx::type_id::create("count_after_timeout");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0018;

  finish_item(req);

  #10;


  //=========================================================
  // 8. READ STATUS
  //
  // Expected:
  // STATUS[0] = TIMEOUT_FLAG
  //=========================================================
  req = apb_master_tx::type_id::create("read_status");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0010;

  finish_item(req);

  #10;


  //=========================================================
  // 9. READ COUNT AGAIN
  //
  // Check whether COUNT:
  //  - stays at 0
  //  - reloads
  //  - remains stable
  //
  // Determine actual RTL behavior
  //=========================================================
  req = apb_master_tx::type_id::create("count_after_timeout_2");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0018;

  finish_item(req);

  #100;


  `uvm_info("WDT_SEQ",
            "TC_COUNT_03 : COUNT AFTER TIMEOUT CHECK",
            UVM_LOW)

  #300;



  

    //=========================================================
  // TC_COUNT_02 : COUNT DURING DEBUG FREEZE
  //
  // Goal:
  // Verify watchdog counter stops decrementing
  // when debug freeze condition is active.
  //
  // Expected:
  // watchdog_counter stops
  // COUNT register remains constant
  //=========================================================


  //=========================================================
  // 1. UNLOCK WDT
  //=========================================================
  req = apb_master_tx::type_id::create("unlock_wdt");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0014;
  req.pwdata = 32'h1ACCE551;

  finish_item(req);

  #50;


  //=========================================================
  // 2. PROGRAM TIMEOUT = 20
  //=========================================================
  req = apb_master_tx::type_id::create("timeout_20");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0004;
  req.pwdata = 32'd20;

  finish_item(req);

  #50;


  //=========================================================
  // 3. ENABLE DEBUG FREEZE FEATURE
  //
  // CTRL[4] = DBG_FREEZE_EN
  // CTRL[0] = ENABLE
  //
  // CTRL = 0x11
  //=========================================================
  req = apb_master_tx::type_id::create("enable_dbg_freeze");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0000;
  req.pwdata = 32'h0000_0009;

  finish_item(req);

  #30;


  //=========================================================
  // 4. READ COUNT BEFORE FREEZE
  //=========================================================
  req = apb_master_tx::type_id::create("count_before_freeze");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0018;

  finish_item(req);

  #10;


  //=========================================================
  // 5. ENTER DEBUG HALT
  //
  // Drive from TB:
  //
  // cpu_dbg_halt = 1;
  //
  //=========================================================

 // vif.cpu_dbg_halt <= 1'b1;

  #50;


  //=========================================================
  // 6. READ COUNT DURING FREEZE
  //=========================================================
  req = apb_master_tx::type_id::create("count_freeze_1");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0018;

  finish_item(req);

  #30;


  //=========================================================
  // 7. READ COUNT AGAIN
  //
  // Expected:
  // Same value as previous read
  //=========================================================
  req = apb_master_tx::type_id::create("count_freeze_2");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0018;

  finish_item(req);

  #30;


  //=========================================================
  // 8. EXIT DEBUG HALT
  //=========================================================
 // vif.cpu_dbg_halt <= 1'b0;

  #50;


  //=========================================================
  // 9. READ COUNT AFTER RESUME
  //
  // Expected:
  // Counter starts decrementing again
  //=========================================================
  req = apb_master_tx::type_id::create("count_after_resume");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0018;

  finish_item(req);

  #100;


  `uvm_info("WDT_SEQ",
            "TC_COUNT_02 : COUNT DURING DEBUG FREEZE CHECK",
            UVM_LOW)

  #300;

  

    //=========================================================
  // TC_COUNT_01 : WDT_COUNT REGISTER CHECK
  //
  // Goal:
  // Verify WDT_COUNT register reflects watchdog counter.
  //
  // Expected:
  // 1. COUNT decreases after ENABLE
  // 2. COUNT reloads after valid refresh
  // 3. COUNT starts decrementing again after refresh
  //
  // Register:
  // WDT_COUNT = 0x018
  //=========================================================


  //=========================================================
  // 1. UNLOCK WDT
  //=========================================================
  req = apb_master_tx::type_id::create("unlock_wdt");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0014;
  req.pwdata = 32'h1ACCE551;

  finish_item(req);

  #50;


  //=========================================================
  // 2. CLEAR STATUS
  //=========================================================
  req = apb_master_tx::type_id::create("clear_status");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0010;
  req.pwdata = 32'h0000_000F;

  finish_item(req);

  #50;


  //=========================================================
  // 3. PROGRAM TIMEOUT = 20
  //=========================================================
  req = apb_master_tx::type_id::create("timeout_20");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0004;
  req.pwdata = 32'd20;

  finish_item(req);

  #50;


  //=========================================================
  // 4. ENABLE WATCHDOG
  //
  // CTRL[0] ENABLE = 1
  //=========================================================
  req = apb_master_tx::type_id::create("enable_wdt");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0000;
  req.pwdata = 32'h0000_0001;

  finish_item(req);

  #100;


  //=========================================================
  // 5. READ COUNT FIRST TIME
  //
  // Expected:
  // PRDATA should be near 20
  //=========================================================
  req = apb_master_tx::type_id::create("rd_count_1");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0018;

  finish_item(req);

  #200;


  //=========================================================
  // 6. READ COUNT SECOND TIME
  //
  // Expected:
  // PRDATA should be less than first read
  //=========================================================
  req = apb_master_tx::type_id::create("rd_count_2");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0018;

  finish_item(req);

  #20;


 
  //=========================================================
  // 8. VALID REFRESH KEY 1
  //
  // REFRESH = 0xA5
  //=========================================================
  req = apb_master_tx::type_id::create("refresh_key_a5");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_000C;
  req.pwdata = 32'h0000_00A5;

  finish_item(req);

  #10;


  //=========================================================
  // 9. VALID REFRESH KEY 2
  //
  // REFRESH = 0x5A
  // Expected:
  // refresh_valid = 1
  // watchdog_counter reloads
  //=========================================================
  req = apb_master_tx::type_id::create("refresh_key_5a");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_000C;
  req.pwdata = 32'h0000_005A;

  finish_item(req);

  #10;


  //=========================================================
  // 10. READ COUNT AFTER REFRESH
  //
  // Expected:
  // PRDATA should reload near 20
  // Possible value: 20 or 19 depending on timing
  //=========================================================
  req = apb_master_tx::type_id::create("rd_count_after_refresh");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0018;

  finish_item(req);

  #20;


  //=========================================================
  // 11. READ COUNT AGAIN AFTER REFRESH
  //
  // Expected:
  // PRDATA should decrement again
  //=========================================================
  req = apb_master_tx::type_id::create("rd_count_after_run");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0018;

  finish_item(req);

  #100;


  `uvm_info("WDT_SEQ",
            "TC_COUNT_01 : WDT_COUNT REGISTER CHECK COMPLETED",
            UVM_LOW)

  #300;

  

    //=========================================================
  // TC_STATUS_05 : RESET_ISSUED STATUS BIT CHECK
  //
  // Goal:
  // Verify STATUS[3] is set when watchdog generates reset.
  //
  // Expected:
  // wdt_reset asserted
  // STATUS[3] = 1
  // PRDATA = 0x00000008
  //=========================================================


  //=========================================================
  // 1. UNLOCK WDT
  //=========================================================
  req = apb_master_tx::type_id::create("unlock_wdt");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0014;
  req.pwdata = 32'h1ACCE551;

  finish_item(req);

  #50;


  //=========================================================
  // 2. CLEAR STATUS
  //=========================================================
  req = apb_master_tx::type_id::create("clear_status");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0010;
  req.pwdata = 32'h0000_000F;

  finish_item(req);

  #50;


  //=========================================================
  // 3. TIMEOUT = 10
  //=========================================================
  req = apb_master_tx::type_id::create("timeout_10");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0004;
  req.pwdata = 32'd10;

  finish_item(req);

  #50;


  //=========================================================
  // 4. ENABLE WATCHDOG
  //
  // ENABLE=1
  // RESET_EN=1
  //=========================================================
  req = apb_master_tx::type_id::create("enable_wdt");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0000;
  req.pwdata = 32'h0000_0003;

  finish_item(req);


  //=========================================================
  // 5. WAIT FOR TIMEOUT
  //
  // No refresh
  //=========================================================
  #200;


  //=========================================================
  // 6. READ STATUS
  //
  // Expected:
  // STATUS[3] = RESET_ISSUED
  // PRDATA = 0x00000008
  //=========================================================
  req = apb_master_tx::type_id::create("rd_status");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0010;

  finish_item(req);

  #100;


  `uvm_info("WDT_SEQ",
            "TC_STATUS_05 : RESET_ISSUED STATUS CHECK",
            UVM_LOW)

  #300;

  

    //=========================================================
  // TC_STATUS_04 : WINDOW VIOLATION STATUS CHECK - FIXED
  //
  // Goal:
  // Verify STATUS[1] is set for early refresh.
  //
  // Configuration:
  // TIMEOUT = 100
  // WINDOW  = 10
  // CTRL    = 0x5  // ENABLE + WINDOW_EN
  //
  // Early refresh condition:
  // CURRENT_COUNT > WINDOW_VALUE
  //
  // Expected:
  // window_violation = 1
  // STATUS[1] = 1
  // PRDATA[1] = 1
  //=========================================================


  //=========================================================
  // 1. UNLOCK WDT
  //=========================================================
  req = apb_master_tx::type_id::create("unlock_wdt");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);
  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0014;
  req.pwdata = 32'h1ACCE551;
  finish_item(req);

  #50;


  //=========================================================
  // 2. CLEAR OLD STATUS FLAGS
  //=========================================================
  req = apb_master_tx::type_id::create("clear_status");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);
  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0010;
  req.pwdata = 32'h0000_000F;
  finish_item(req);

  #50;


  //=========================================================
  // 3. WRITE TIMEOUT = 100
  //
  // Larger timeout avoids counter reaching legal window
  // before APB refresh sequence completes.
  //=========================================================
  req = apb_master_tx::type_id::create("wr_timeout_100");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);
  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0004;
  req.pwdata = 32'd100;
  finish_item(req);

  #50;


  //=========================================================
  // 4. WRITE WINDOW = 10
  //
  // Early refresh is any refresh while count > 10.
  //=========================================================
  req = apb_master_tx::type_id::create("wr_window_10");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);
  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0008;
  req.pwdata = 32'd10;
  finish_item(req);

  #50;


  //=========================================================
  // 5. ENABLE WATCHDOG + WINDOW MODE
  //
  // CTRL[0] = ENABLE
  // CTRL[2] = WINDOW_EN
  // CTRL = 0x5
  //=========================================================
  req = apb_master_tx::type_id::create("wr_ctrl_enable_window");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);
  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0000;
  req.pwdata = 32'h0000_0005;
  finish_item(req);

  // Keep very small delay after enable.
  // Counter will still be around 100/99/98, much greater than 10.
  #20;


  //=========================================================
  // 6. EARLY REFRESH KEY 1 = 0xA5
  //=========================================================
  req = apb_master_tx::type_id::create("early_refresh_a5");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);
  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_000C;
  req.pwdata = 32'h0000_00A5;
  finish_item(req);

  #20;


  //=========================================================
  // 7. EARLY REFRESH KEY 2 = 0x5A
  //
  // Expected:
  // window_violation = 1 because counter > window_value.
  //=========================================================
  req = apb_master_tx::type_id::create("early_refresh_5a");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);
  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_000C;
  req.pwdata = 32'h0000_005A;
  finish_item(req);

  #100;


  //=========================================================
  // 8. READ STATUS
  //
  // Expected:
  // PRDATA[1] = 1
  // Clean expected PRDATA = 0x00000002
  //=========================================================
  req = apb_master_tx::type_id::create("rd_status_window_violation");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);
  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0010;
  finish_item(req);

  `uvm_info("WDT_SEQ",
            "TC_STATUS_04 fixed completed. Expected PRDATA[1] = 1",
            UVM_LOW)

  #300;


  
    //=========================================================
  // TC_STATUS_03 : REFRESH ERROR STATUS CHECK
  //
  // Goal:
  // Verify invalid refresh sequence updates
  // WDT_STATUS[2].
  //
  // STATUS[2] = REFRESH_ERROR
  //
  // Expected:
  // PRDATA[2] = 1
  //=========================================================


  //=========================================================
  // 1. UNLOCK WDT
  //=========================================================
  req = apb_master_tx::type_id::create("unlock_wdt");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0014;
  req.pwdata = 32'h1ACCE551;

  finish_item(req);

  #50;


  //=========================================================
  // 2. PROGRAM TIMEOUT = 10
  //=========================================================
  req = apb_master_tx::type_id::create("wr_timeout_10");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0004;
  req.pwdata = 32'h0000_000A;

  finish_item(req);

  #50;


  //=========================================================
  // 3. ENABLE WATCHDOG
  //=========================================================
  req = apb_master_tx::type_id::create("wr_ctrl_enable");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0000;
  req.pwdata = 32'h0000_0001;

  finish_item(req);

  #50;


  //=========================================================
  // 4. INVALID REFRESH
  //
  // Write only first key
  //
  // Expected:
  // refresh_error = 1
  //=========================================================
  req = apb_master_tx::type_id::create("invalid_refresh");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_000C;   // WDT_REFRESH
  req.pwdata = 32'h0000_00A5;   // only first key

  finish_item(req);

  #20;

//=========================================================
  // . WRONG REFRESH KEY STEP 2
  // Expected:
  // refresh_error = 1
  //=========================================================
  req = apb_master_tx::type_id::create("refresh_wrong_key_55");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_000C;   // WDT_REFRESH
  req.pwdata = 32'h0000_0055;   // Wrong second key

  finish_item(req);

  #20;
  


  //=========================================================
  // 5. READ STATUS REGISTER
  //
  // Expected:
  // STATUS[2] = 1
  // PRDATA = 0x00000004
  //=========================================================
  req = apb_master_tx::type_id::create("rd_status_refresh_error");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0010;    // WDT_STATUS

  finish_item(req);


  `uvm_info("WDT_SEQ",
            "TC_STATUS_03 : REFRESH ERROR STATUS CHECK",
            UVM_LOW)

  #20;


    //=========================================================
  // TC_STATUS_01 : TIMEOUT STATUS FLAG CHECK
  //
  // Goal:
  // Verify timeout event updates WDT_STATUS[0].
  //
  // Register:
  // WDT_STATUS = 0x010
  //
  // Status bit:
  // STATUS[0] = TIMEOUT_FLAG
  //
  // Sequence:
  // 1. Unlock WDT
  // 2. Program TIMEOUT = 10
  // 3. Enable WDT
  // 4. Do not refresh
  // 5. Wait for timeout
  // 6. Read STATUS register
  //
  // Expected:
  // timeout_flag = 1
  // WDT_STATUS[0] = 1
  //=========================================================


  //=========================================================
  // 1. UNLOCK WDT
  // WDT_LOCK = 0x1ACCE551
  //=========================================================
  req = apb_master_tx::type_id::create("unlock_wdt");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0014;
  req.pwdata = 32'h1ACCE551;

  finish_item(req);

  #50;


  //=========================================================
  // 2. WRITE TIMEOUT = 10
  //=========================================================
  req = apb_master_tx::type_id::create("wr_timeout_10");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0004;
  req.pwdata = 32'h0000_000A;

  finish_item(req);

  #50;


  //=========================================================
  // 3. ENABLE WATCHDOG
  // CTRL[0] = ENABLE
  // CTRL = 0x1
  //=========================================================
  req = apb_master_tx::type_id::create("wr_ctrl_enable");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0000;
  req.pwdata = 32'h0000_0001;

  finish_item(req);


  //=========================================================
  // 4. WAIT WITHOUT REFRESH
  //
  // Expected:
  // watchdog_counter reaches 0
  // timeout_flag asserts
  //=========================================================
  #300;


  //=========================================================
  // 5. READ WDT_STATUS
  //
  // Expected:
  // PRDATA[0] = 1
  //=========================================================
  req = apb_master_tx::type_id::create("rd_status_timeout_flag");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0010;

  finish_item(req);


  `uvm_info("WDT_SEQ",
            "TC_STATUS_01 : TIMEOUT STATUS FLAG CHECK COMPLETED. Expected WDT_STATUS[0] = 1",
            UVM_LOW)

  #50;

    //=========================================================
  // TC_STATUS_02 : TIMEOUT STATUS W1C CLEAR CHECK
  //
  // Goal:
  // Verify WDT_STATUS[0] clears when writing 1.
  //
  // Register:
  // WDT_STATUS = 0x010
  //
  // Bit:
  // STATUS[0] = TIMEOUT_FLAG
  //
  // Expected:
  // Before clear : STATUS[0] = 1
  // After clear  : STATUS[0] = 0
  //=========================================================


  //=========================================================
  // 1. UNLOCK WDT
  //=========================================================
  req = apb_master_tx::type_id::create("unlock_wdt");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0014;
  req.pwdata = 32'h1ACCE551;

  finish_item(req);

  #50;


  //=========================================================
  // 2. WRITE TIMEOUT = 10
  //=========================================================
  req = apb_master_tx::type_id::create("wr_timeout_10");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0004;
  req.pwdata = 32'h0000_000A;

  finish_item(req);

  #50;


  //=========================================================
  // 3. ENABLE WATCHDOG
  //=========================================================
  req = apb_master_tx::type_id::create("wr_ctrl_enable");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0000;
  req.pwdata = 32'h0000_0001;

  finish_item(req);


  //=========================================================
  // 4. WAIT FOR TIMEOUT
  //=========================================================
  #500;


  //=========================================================
  // 5. READ STATUS BEFORE CLEAR
  //
  // Expected:
  // PRDATA[0] = 1
  //=========================================================
  req = apb_master_tx::type_id::create("rd_status_before_clear");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0010;

  finish_item(req);

  #50;


  //=========================================================
  // 6. WRITE 1 TO CLEAR TIMEOUT_FLAG
  //
  // W1C:
  // Writing 1 to bit[0] clears timeout_flag.
  //=========================================================
  req = apb_master_tx::type_id::create("wr_status_w1c_timeout_clear");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0010;
  req.pwdata = 32'h0000_0001;

  finish_item(req);

  #50;


  //=========================================================
  // 7. READ STATUS AFTER CLEAR
  //
  // Expected:
  // PRDATA[0] = 0
  // PRDATA    = 0x00000000
  //=========================================================
  req = apb_master_tx::type_id::create("rd_status_after_clear");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0010;

  finish_item(req);


  `uvm_info("WDT_SEQ",
            "TC_STATUS_02 : TIMEOUT STATUS W1C CLEAR CHECK COMPLETED",
            UVM_LOW)

  #200;
  

    //=========================================================
  // TC_DBG_FREEZE_01 : DEBUG FREEZE OPERATION
  //
  // Goal:
  // When debug freeze is active, watchdog_counter should hold.
  //
  // Expected:
  // Before freeze  : counter decrements
  // During freeze  : counter holds
  // After unfreeze : counter resumes decrementing
  //=========================================================


 

  //=========================================================
  // 1. UNLOCK WDT
  // WDT_LOCK = 0x1ACCE551
  //=========================================================
  req = apb_master_tx::type_id::create("unlock_wdt");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0014;
  req.pwdata = 32'h1ACCE551;

  finish_item(req);

  #50;


  //=========================================================
  // 2. WRITE TIMEOUT = 10
  //=========================================================
  req = apb_master_tx::type_id::create("wr_timeout_10");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0004;
  req.pwdata = 32'h0000_000A;

  finish_item(req);

  #50;


  //=========================================================
  // 3. ENABLE WATCHDOG
  // WDT_CTRL[0] = 1
  //=========================================================
  req = apb_master_tx::type_id::create("wr_ctrl_enable");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0000;
  req.pwdata = 32'h0000_0009;

  finish_item(req);

  // Allow counter to start decrementing
  #200;


    //=========================================================
  // TC_LOCK_03 : RESET_WIDTH REGISTER PROTECTION AFTER LOCK
  //
  // Goal:
  // After lock, WDT_RESET_WIDTH write should be ignored.
  //
  // Protected register:
  // WDT_RESET_WIDTH = 0x010
  //
  // Expected:
  // reset_cycles remains 5 even after writing RESET_WIDTH = 20
  //=========================================================


  //=========================================================
  // 1. UNLOCK WDT
  // WDT_LOCK = 0x1ACCE551
  //=========================================================
  req = apb_master_tx::type_id::create("unlock_wdt");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0014;
  req.pwdata = 32'h1ACCE551;

  finish_item(req);

  #50;


  //=========================================================
  // 2. WRITE RESET_WIDTH = 5
  //
  // Expected:
  // reset_cycles should become 5
  //=========================================================
  req = apb_master_tx::type_id::create("wr_reset_width_5");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0010;
  req.pwdata = 32'h0000_0005;

  finish_item(req);

  #50;


  //=========================================================
  // 3. LOCK WDT
  // WDT_LOCK = 0x00000000
  //=========================================================
  req = apb_master_tx::type_id::create("lock_wdt");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0014;
  req.pwdata = 32'h0000_0000;

  finish_item(req);

  #50;


  //=========================================================
  // 4. TRY TO MODIFY RESET_WIDTH AFTER LOCK
  // WRITE RESET_WIDTH = 20
  //
  // Expected:
  // This write should be ignored.
  // reset_cycles should remain 5.
  //=========================================================
  req = apb_master_tx::type_id::create("overwrite_reset_width_20");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0010;
  req.pwdata = 32'h0000_0014;

  finish_item(req);


  `uvm_info("WDT_SEQ",
            "TC_LOCK_03 : RESET_WIDTH REGISTER PROTECTION AFTER LOCK",
            UVM_LOW)

  #300;

    //=========================================================
  // TC_LOCK_02 : CTRL REGISTER PROTECTION AFTER LOCK
  //
  // Goal:
  // After lock, WDT_CTRL write should be ignored.
  //
  // Protected register:
  // WDT_CTRL = 0x000
  //
  // Expected:
  // enable remains 1 even after writing CTRL = 0
  //=========================================================


  //=========================================================
  // 1. UNLOCK WDT
  // WDT_LOCK = 0x1ACCE551
  //=========================================================
  req = apb_master_tx::type_id::create("unlock_wdt");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0014;
  req.pwdata = 32'h1ACCE551;

  finish_item(req);

  #50;


  //=========================================================
  // 2. WRITE TIMEOUT = 10
  //=========================================================
  req = apb_master_tx::type_id::create("wr_timeout_10");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0004;
  req.pwdata = 32'h0000_000A;

  finish_item(req);

  #50;


  //=========================================================
  // 3. WRITE CTRL = ENABLE
  // CTRL[0] = 1
  //=========================================================
  req = apb_master_tx::type_id::create("wr_ctrl_enable");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0000;
  req.pwdata = 32'h0000_0001;

  finish_item(req);

  #50;


  //=========================================================
  // 4. LOCK WDT
  // WDT_LOCK = 0x00000000
  //=========================================================
  req = apb_master_tx::type_id::create("lock_wdt");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0014;
  req.pwdata = 32'h0000_0000;

  finish_item(req);

  #50;


  //=========================================================
  // 5. TRY TO DISABLE WATCHDOG AFTER LOCK
  // WRITE CTRL = 0
  //
  // Expected:
  // This write should be ignored.
  // enable should remain 1.
  //=========================================================
  req = apb_master_tx::type_id::create("overwrite_ctrl_disable");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0000;
  req.pwdata = 32'h0000_0000;

  finish_item(req);


  `uvm_info("WDT_SEQ",
            "TC_LOCK_02 : CTRL REGISTER PROTECTION AFTER LOCK",
            UVM_LOW)

  #300;
    //=========================================================
  // TC_LOCK_01 : LOCK BLOCKS WRITES - CLEAN SEQUENCE
  //=========================================================

  // 1. UNLOCK FIRST
  req = apb_master_tx::type_id::create("unlock_wdt");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;
  start_item(req);
  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")
  req.paddr  = 32'h0000_0014;
  req.pwdata = 32'h1ACCE551;
  finish_item(req);

  #50;

  // 2. PROGRAM TIMEOUT = 10
  req = apb_master_tx::type_id::create("wr_timeout_10");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;
  start_item(req);
  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")
  req.paddr  = 32'h0000_0004;
  req.pwdata = 32'h0000_000A;
  finish_item(req);

  #50;

  // 3. PROGRAM WINDOW = 5
  req = apb_master_tx::type_id::create("wr_window_5");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;
  start_item(req);
  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")
  req.paddr  = 32'h0000_0008;
  req.pwdata = 32'h0000_0005;
  finish_item(req);

  #50;

  // 4. PROGRAM CTRL = ENABLE
  req = apb_master_tx::type_id::create("wr_ctrl_enable");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;
  start_item(req);
  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")
  req.paddr  = 32'h0000_0000;
  req.pwdata = 32'h0000_0001;
  finish_item(req);

  #50;

  // 5. LOCK WDT
  req = apb_master_tx::type_id::create("lock_wdt");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;
  start_item(req);
  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")
  req.paddr  = 32'h0000_0014;
  req.pwdata = 32'h0000_0000;
  finish_item(req);

  #50;

  // 6. TRY TO OVERWRITE TIMEOUT = 20
  req = apb_master_tx::type_id::create("overwrite_timeout_20");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;
  start_item(req);
  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")
  req.paddr  = 32'h0000_0004;
  req.pwdata = 32'h0000_0014;
  finish_item(req);

  #50;

  // 7. TRY TO OVERWRITE WINDOW = 8
  req = apb_master_tx::type_id::create("overwrite_window_8");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;
  start_item(req);
  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")
  req.paddr  = 32'h0000_0008;
  req.pwdata = 32'h0000_0008;
  finish_item(req);

  #50;

  // 8. TRY TO OVERWRITE CTRL = 0
  req = apb_master_tx::type_id::create("overwrite_ctrl_0");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;
  start_item(req);
  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")
  req.paddr  = 32'h0000_0000;
  req.pwdata = 32'h0000_0000;
  finish_item(req);

  `uvm_info("WDT_SEQ",
            "TC_LOCK_01 : LOCK BLOCKS PROTECTED WRITES",
            UVM_LOW)

  #300;
  */
  /*

    //=========================================================
  // TC_WINDOW_04 : WINDOW DISABLED CHECK
  //
  // Purpose:
  // WINDOW register is programmed, but WINDOW_EN = 0.
  // So refresh should be allowed even when counter > window_value.
  //
  // TIMEOUT = 10
  // WINDOW  = 5
  // CTRL    = 0x1
  //
  // CTRL[0] = ENABLE    = 1
  // CTRL[2] = WINDOW_EN = 0
  //
  // Expected:
  // refresh_valid    = 1
  // refresh_error    = 0
  // window_violation = 0
  // counter reloads to 10
  //=========================================================


  //=========================================================
  // WRITE TIMEOUT = 10
  // Address 0x004
  //=========================================================
  req = apb_master_tx::type_id::create("wr_timeout");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0004;
  req.pwdata = 32'h0000_000A;

  finish_item(req);


  //=========================================================
  // WRITE WINDOW = 5
  // Address 0x008
  //
  // Note:
  // Window value is programmed, but window mode is disabled.
  //=========================================================
  req = apb_master_tx::type_id::create("wr_window");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0008;
  req.pwdata = 32'h0000_0005;

  finish_item(req);


  //=========================================================
  // WRITE CTRL = 0x1
  //
  // ENABLE    = 1
  // WINDOW_EN = 0
  //=========================================================
  req = apb_master_tx::type_id::create("wr_ctrl_enable_only");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0000;
  req.pwdata = 32'h0000_0001;

  finish_item(req);


  //=========================================================
  // EARLY REFRESH TIMING
  //
  // Refresh while counter is still > window_value.
  // Example:
  // counter = 8 or 7
  // window  = 5
  //
  // Since WINDOW_EN = 0, this should NOT create violation.
  //=========================================================
  #20;


  //=========================================================
  // WRITE REFRESH KEY1 = 0xA5
  // Address 0x00C
  //=========================================================
  req = apb_master_tx::type_id::create("win_dis_a5");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_000C;
  req.pwdata = 32'h0000_00A5;

  finish_item(req);


  //=========================================================
  // WRITE REFRESH KEY2 = 0x5A
  // Address 0x00C
  //=========================================================
  req = apb_master_tx::type_id::create("win_dis_5a");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_000C;
  req.pwdata = 32'h0000_005A;

  finish_item(req);


  `uvm_info("WDT_SEQ",
            "TC_WINDOW_04 : WINDOW DISABLED CHECK",
            UVM_LOW)


  //=========================================================
  // WAIT TO OBSERVE RELOAD / NO WINDOW VIOLATION
  //=========================================================
  #200;

    //=========================================================
  // TC_WINDOW_03 : BOUNDARY CONDITION
  //
  // Refresh exactly at:
  // watchdog_counter = 5
  // window_value     = 5
  //=========================================================

  //=========================================================
  // WRITE TIMEOUT = 10
  //=========================================================
  req = apb_master_tx::type_id::create("wr_timeout");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0004;
  req.pwdata = 32'h0000_000A;

  finish_item(req);

  //=========================================================
  // WRITE WINDOW = 5
  //=========================================================
  req = apb_master_tx::type_id::create("wr_window");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0008;
  req.pwdata = 32'h0000_0005;

  finish_item(req);

  //=========================================================
  // ENABLE + WINDOW MODE
  //=========================================================
  req = apb_master_tx::type_id::create("wr_ctrl");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0000;
  req.pwdata = 32'h0000_0005;

  finish_item(req);

  //=========================================================
  // WAIT UNTIL COUNTER REACHES 5
  //
  // Tune this delay using waveform
  //=========================================================
  #10

  //=========================================================
  // REFRESH KEY1
  //=========================================================
  req = apb_master_tx::type_id::create("boundary_a5");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_000C;
  req.pwdata = 32'h0000_00A5;

  finish_item(req);

  //=========================================================
  // REFRESH KEY2
  //=========================================================
  req = apb_master_tx::type_id::create("boundary_5a");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_000C;
  req.pwdata = 32'h0000_005A;

  finish_item(req);

  `uvm_info("WDT_SEQ",
            "TC_WINDOW_03 : BOUNDARY CONDITION",
            UVM_LOW)

  #200;

     //=========================================================
  // TC_WINDOW_02 : EARLY REFRESH VIOLATION 
  //=========================================================

  // WRITE TIMEOUT = 10
  req = apb_master_tx::type_id::create("wr_timeout");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;
  start_item(req);
  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")
  req.paddr  = 32'h0000_0004;
  req.pwdata = 32'h0000_000A;
  finish_item(req);

  // WRITE WINDOW = 5
  req = apb_master_tx::type_id::create("wr_window");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;
  start_item(req);
  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")
  req.paddr  = 32'h0000_0008;
  req.pwdata = 32'h0000_0005;
  finish_item(req);

  // WRITE CTRL = ENABLE + WINDOW_EN = 0x5
  req = apb_master_tx::type_id::create("wr_ctrl");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;
  start_item(req);
  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")
  req.paddr  = 32'h0000_0000;
  req.pwdata = 32'h0000_0005;
  finish_item(req);

  // IMPORTANT:
  // No delay here. Refresh immediately before counter reaches 5.

  // WRITE REFRESH KEY1 = A5
  req = apb_master_tx::type_id::create("early_refresh_a5");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;
  start_item(req);
  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")
  req.paddr  = 32'h0000_000C;
  req.pwdata = 32'h0000_00A5;
  finish_item(req);

  // WRITE REFRESH KEY2 = 5A
  req = apb_master_tx::type_id::create("early_refresh_5a");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;
  start_item(req);
  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")
  req.paddr  = 32'h0000_000C;
  req.pwdata = 32'h0000_005A;
  finish_item(req);

  `uvm_info("WDT_SEQ",
            "TC_WINDOW_02 : EARLY REFRESH VIOLATION",
            UVM_LOW)

  #200;

    //=========================================================
  // TC_WINDOW_01 : VALID WINDOW REFRESH
  //
  // TIMEOUT = 10
  // WINDOW  = 5
  // ENABLE  = 1
  // WINDOW_EN = 1
  //
  // Refresh when counter <= 5
  //=========================================================

  //=========================================================
  // WRITE TIMEOUT = 10
  //=========================================================
  req = apb_master_tx::type_id::create("wr_timeout");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0004;
  req.pwdata = 32'h0000_000A;

  finish_item(req);

  //=========================================================
  // WRITE WINDOW = 5
  //=========================================================
  req = apb_master_tx::type_id::create("wr_window");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0008;
  req.pwdata = 32'h0000_0005;

  finish_item(req);

  //=========================================================
  // ENABLE WDT + WINDOW MODE
  // CTRL = ENABLE(bit0) + WINDOW_EN(bit2)
  //      = 0x5
  //=========================================================
  req = apb_master_tx::type_id::create("wr_ctrl");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0000;
  req.pwdata = 32'h0000_0005;

  finish_item(req);

  //=========================================================
  // WAIT UNTIL COUNTER ENTERS VALID WINDOW
  //
  // Counter:
  // 10 9 8 7 6 5
  //
  // Refresh at count <= 5
  //=========================================================
  #50;

  //=========================================================
  // REFRESH KEY 1
  //=========================================================
  req = apb_master_tx::type_id::create("refresh_key1");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_000C;
  req.pwdata = 32'h0000_00A5;

  finish_item(req);

  //=========================================================
  // REFRESH KEY 2
  //=========================================================
  req = apb_master_tx::type_id::create("refresh_key2");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_000C;
  req.pwdata = 32'h0000_005A;

  finish_item(req);

  `uvm_info("WDT_SEQ",
            "TC_WINDOW_01 : VALID WINDOW REFRESH",
            UVM_LOW)

  #200;

  //=================================================
  // WRITE TIMEOUT = 10
  //=================================================
  req = apb_master_tx::type_id::create("wr_timeout");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0004;
  req.pwdata = 32'd10;

  finish_item(req);

  `uvm_info("WDT_SEQ",
            "WRITE TIMEOUT = 10",
            UVM_LOW)

  //=================================================
  // WRITE CTRL = 1
  //=================================================
  req = apb_master_tx::type_id::create("wr_ctrl");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_0000;
  req.pwdata = 32'h0000_0001;

  finish_item(req);

  `uvm_info("WDT_SEQ",
            "WRITE CTRL = 1",
            UVM_LOW)

    //=========================================================
  // TC_REFRESH_04 : INVALID REFRESH - RANDOM KEY
  //=========================================================

  #100;

  req = apb_master_tx::type_id::create("refresh_random_key");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_000C;
  req.pwdata = 32'h1234_5678;

  finish_item(req);

  `uvm_info("WDT_SEQ",
            "TC_REFRESH_04: WRITE RANDOM INVALID KEY",
            UVM_LOW)

  #100;


    //=========================================================
  // TC_REFRESH_03 : INVALID REFRESH - 5A ONLY
  //=========================================================

  #100;

  req = apb_master_tx::type_id::create("refresh_key2_only");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_000C;
  req.pwdata = 32'h0000_005A;

  finish_item(req);

  `uvm_info("WDT_SEQ",
            "TC_REFRESH_03: WRITE 5A ONLY",
            UVM_LOW)

  #100;


    //=========================================================
  // INVALID REFRESH : A5 -> A5
  //=========================================================

  #100;

  req = apb_master_tx::type_id::create("refresh_key1");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_000C;
  req.pwdata = 32'h0000_00A5;

  finish_item(req);

  //---------------------------------------------------------

  req = apb_master_tx::type_id::create("refresh_key1_again");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_000C;
  req.pwdata = 32'h0000_00A5;

  finish_item(req);

  #100;


    //=========================================================
  // WAIT FEW CYCLES BEFORE REFRESH
  //=========================================================
  #100;

  //=========================================================
  // REFRESH STEP 1 : WRITE REFRESH KEY1 = 0xA5
  //=========================================================
  req = apb_master_tx::type_id::create("wr_refresh_key1");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_000C;
  req.pwdata = 32'h0000_00A5;

  finish_item(req);

  `uvm_info("WDT_SEQ",
            "WRITE REFRESH KEY1 = 0xA5",
            UVM_LOW)


  //=========================================================
  // REFRESH STEP 2 : WRITE REFRESH KEY2 = 0x5A
  //=========================================================
  req = apb_master_tx::type_id::create("wr_refresh_key2");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == WRITE;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr  = 32'h0000_000C;
  req.pwdata = 32'h0000_005A;

  finish_item(req);

  `uvm_info("WDT_SEQ",
            "WRITE REFRESH KEY2 = 0x5A",
            UVM_LOW)


  //=========================================================
  // WAIT AFTER REFRESH TO OBSERVE COUNTER RELOAD
  //=========================================================
  #100;

  //=================================================
  // READ TIMEOUT REGISTER
  //=================================================
  req = apb_master_tx::type_id::create("rd_timeout");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0004;

  finish_item(req);

  `uvm_info("WDT_SEQ",
            "READ TIMEOUT REGISTER",
            UVM_LOW)

  //=================================================
  // READ CTRL REGISTER
  //=================================================
  req = apb_master_tx::type_id::create("rd_ctrl");
  req.apb_master_agent_cfg_h = p_sequencer.apb_master_agent_cfg_h;

  start_item(req);

  if(!req.randomize() with {
      req.pselx         == SLAVE_0;
      req.transfer_size == BIT_32;
      req.pwrite        == READ;
  })
    `uvm_fatal("APB","Randomization Failed")

  req.paddr = 32'h0000_0000;

  finish_item(req);

  `uvm_info("WDT_SEQ",
            "READ CTRL REGISTER",
            UVM_LOW) */

endtask

`endif

