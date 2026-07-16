`ifndef WDT_APB_WRITE_TEST_INCLUDED_
`define WDT_APB_WRITE_TEST_INCLUDED_

import uvm_pkg::*;
`include "uvm_macros.svh"

import apb_global_pkg::*;
import apb_master_pkg::*;
import apb_master_seq_pkg::*;

class wdt_apb_write_test extends uvm_test;

  `uvm_component_utils(wdt_apb_write_test)

  apb_master_agent_config  apb_master_agent_cfg_h;
  apb_master_agent         master_agent_h;
  apb_master_32b_write_seq write_seq_h;

  function new(string name = "wdt_apb_write_test",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    apb_master_agent_cfg_h =
      apb_master_agent_config::type_id::create("apb_master_agent_cfg_h");

    apb_master_agent_cfg_h.is_active = UVM_ACTIVE;

    uvm_config_db#(apb_master_agent_config)::set(
      this,
      "master_agent_h",
      "apb_master_agent_config",
      apb_master_agent_cfg_h
    );

    master_agent_h =
      apb_master_agent::type_id::create("master_agent_h", this);
  endfunction

  task run_phase(uvm_phase phase);

  phase.raise_objection(this);

  `uvm_info("WDT_TEST", "RUN PHASE STARTED", UVM_LOW)

  #100ns;

  write_seq_h = apb_master_32b_write_seq::type_id::create("write_seq_h");

  `uvm_info("WDT_TEST", "STARTING APB MASTER WRITE SEQUENCE", UVM_LOW)

  write_seq_h.start(master_agent_h.apb_master_seqr_h);

  `uvm_info("WDT_TEST", "APB MASTER WRITE SEQUENCE COMPLETED", UVM_LOW)

  #1000ns;

  phase.drop_objection(this);

endtask
endclass

`endif
