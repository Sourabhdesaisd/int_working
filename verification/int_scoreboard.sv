/*class int_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(int_scoreboard)

  function new(string name = "int_scoreboard", uvm_component parent);
    super.new(name, parent);
  endfunction


endclass*/

class int_scoreboard extends uvm_scoreboard;

  `uvm_component_utils(int_scoreboard)

  uvm_analysis_imp #(int_seq_item, int_scoreboard) sb_imp;

  int pass_count;
  int fail_count;
  int ignored_count;
  int compare_count;

  int mmr_pass_count;
  int mmr_fail_count;
  int mmr_compare_count;

  function new(string name = "int_scoreboard", uvm_component parent);
    super.new(name, parent);
    sb_imp = new("sb_imp", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    pass_count    = 0;
    fail_count    = 0;
    ignored_count = 0;
    compare_count = 0;

    mmr_pass_count    = 0;
    mmr_fail_count    = 0;
    mmr_compare_count = 0;
  endfunction



  function void write(int_seq_item tr);

  // ============================================================
// MMR READ CHECK
// ============================================================

    if (tr.exp_mmr_read_valid) begin
    
      mmr_compare_count++;
    
      if (tr.soc_mmr_read_data_o === tr.exp_mmr_read_data) begin
    
        mmr_pass_count++;
    
        `uvm_info("ZIC_MMR_SCB",
          $sformatf("PASS MMR READ exp=0x%08h act=0x%08h",
                    tr.exp_mmr_read_data,
                    tr.soc_mmr_read_data_o),
          UVM_LOW)
    
      end
      else begin
    
        mmr_fail_count++;
    
        `uvm_error("ZIC_MMR_SCB",
          $sformatf(
          "\nFAIL MMR READ\nexp_data = 0x%08h\nact_data = 0x%08h\naddr     = 0x%0h\n",
          tr.exp_mmr_read_data,
          tr.soc_mmr_read_data_o,
          tr.soc_mmr_read_addr_i))
    
      end
    
    end

    // ------------------------------------------------------------
    // Do not compare idle / non-ACK prediction cycles
    // ------------------------------------------------------------
    if (!tr.exp_valid) begin
      ignored_count++;
      return;
    end
    
    if (tr.interrupt_request_o !== 1'b1) begin
      ignored_count++;
      return;
    end

    compare_count++;

    // ------------------------------------------------------------
    // ACK ID compare
    // ------------------------------------------------------------
    if ((tr.soc_ack_int_id_o === tr.exp_ack_id) &&
        (tr.highest_pending_lvl_pr_o === tr.exp_highest_lvl_pr)) begin

      pass_count++;

      `uvm_info("soc_SCB",
        $sformatf("PASS ACK_ID compare=%0d exp_ack=0x%0h act_ack=0x%0h exp_lvl=0x%0h act_lvl=0x%0h",
                  compare_count,
                  tr.exp_ack_id,
                  tr.soc_ack_int_id_o,
                  tr.exp_highest_lvl_pr,
                  tr.highest_pending_lvl_pr_o),
        UVM_LOW)

    end
    else begin

      fail_count++;

      `uvm_error("soc_SCB",
        $sformatf("\nFAIL ACK_ID\ncompare_count       = %0d\nexp_ack_id         = 0x%0h\nact_ack_id         = 0x%0h\nexp_highest_lvl_pr = 0x%0h\nact_highest_lvl_pr = 0x%0h\nack_read_valid     = %0b\ninterrupt_request  = %0b\next_int            = 0x%0h\nglobal_enable      = 0x%0h\nactive_lvl_pr      = 0x%0h\n",
                  compare_count,
                  tr.exp_ack_id,
                  tr.soc_ack_int_id_o,
                  tr.exp_highest_lvl_pr,
                  tr.highest_pending_lvl_pr_o,
                  tr.soc_ack_read_valid_en,
                  tr.interrupt_request_o,
                  tr.ext_int,
                  tr.global_int_enable_bit_i,
                  tr.active_lvl_pr_i))

    end

  endfunction

  function void extract_phase(uvm_phase phase);
    super.extract_phase(phase);

    `uvm_info("soc_SCB_REPORT",
      $sformatf("\n========================================\nsoc SCOREBOARD FINAL REPORT\n========================================\nTOTAL COMPARES : %0d\nPASS_COUNT     : %0d\nFAIL_COUNT     : %0d\n========================================",
                compare_count,
                pass_count,
                fail_count),
      UVM_LOW)

    /////

    `uvm_info("ZIC_SCB_REPORT",
$sformatf(
"\n====================================================\
\nZIC SCOREBOARD FINAL REPORT\
\n====================================================\
\nACK COMPARES      : %0d\
\nACK PASS          : %0d\
\nACK FAIL          : %0d\
\n----------------------------------------------------\
\nMMR COMPARES      : %0d\
\nMMR PASS          : %0d\
\nMMR FAIL          : %0d\
\n====================================================",
compare_count,
pass_count,
fail_count,
mmr_compare_count,
mmr_pass_count,
mmr_fail_count),
UVM_LOW)

  endfunction





  

endclass
