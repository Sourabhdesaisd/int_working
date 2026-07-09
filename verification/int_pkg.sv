`timescale 1ns/1ps



package int_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "int_seq_item.sv"

  `include "int_seq1.sv"
  `include "int_sequencer.sv"

  `include "int_driver.sv"
  `include "int_monitor.sv"

  // Subscribers
  `include "int_scoreboard.sv"
  `include "int_coverage.sv"

  // Higher-level TB
  `include "int_agent.sv"
  `include "int_env.sv"

  // Tests
  `include "int_test.sv"

endpackage
