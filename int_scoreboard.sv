class int_scoreboard extends uvm_scoreboard;

//------------------------------------------------------------
// Expected IRQ Queue
//------------------------------------------------------------
int_seq_item exp_irq_q[$];

  `uvm_component_utils(int_scoreboard)

  uvm_analysis_imp #(int_seq_item, int_scoreboard) sb_imp;

  //============================================================
  // IRQ Compare Counters
  //============================================================
  int irq_compare_count;
  int irq_pass_count;
  int irq_fail_count;

  //============================================================
  // ACK Compare Counters
  //============================================================
  int ack_compare_count;
  int ack_pass_count;
  int ack_fail_count;

  //============================================================
  // Ignored Transactions
  //============================================================
  int ignored_count;

  //============================================================
  // MMR Compare Counters
  //============================================================
  int mmr_compare_count;
  int mmr_pass_count;
  int mmr_fail_count;

  function new(string name = "int_scoreboard",
               uvm_component parent);
    super.new(name,parent);

    sb_imp = new("sb_imp",this);

  endfunction


  function void build_phase(uvm_phase phase);

    super.build_phase(phase);

    //--------------------------------------------------------
    // IRQ
    //--------------------------------------------------------
    irq_compare_count = 0;
    irq_pass_count    = 0;
    irq_fail_count    = 0;

    //--------------------------------------------------------
    // ACK
    //--------------------------------------------------------
    ack_compare_count = 0;
    ack_pass_count    = 0;
    ack_fail_count    = 0;

    //--------------------------------------------------------
    // MMR
    //--------------------------------------------------------
    mmr_compare_count = 0;
    mmr_pass_count    = 0;
    mmr_fail_count    = 0;

    //--------------------------------------------------------
    // Ignored
    //--------------------------------------------------------
    ignored_count = 0;


  endfunction


  function void write(int_seq_item tr);

  //============================================================
  // MMR READ CHECK
  //============================================================

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
        "\nFAIL MMR READ\
        \nexp_data = 0x%08h\
        \nact_data = 0x%08h\
        \naddr     = 0x%0h",
        tr.exp_mmr_read_data,
        tr.soc_mmr_read_data_o,
        tr.soc_mmr_read_addr_i))

    end

  end


  //============================================================
  // IRQ REQUEST CHECK
  //============================================================

  if (!tr.exp_irq_req) begin
    ignored_count++;
    return;
  end

  irq_compare_count++;

  if (tr.interrupt_request_o === tr.exp_irq_req) begin

    irq_pass_count++;

    `uvm_info("IRQ_COMPARE",
      $sformatf(
      "PASS IRQ compare=%0d exp_irq=%0b act_irq=%0b",
      irq_compare_count,
      tr.exp_irq_req,
      tr.interrupt_request_o),
      UVM_LOW)

  end
  else begin

    irq_fail_count++;

    `uvm_error("IRQ_COMPARE",
      $sformatf(
      "\n========================================\
      \nIRQ REQUEST FAIL\
      \n========================================\
      \nExpected IRQ      : %0b\
      \nActual IRQ        : %0b\
      \nExpected ACK ID   : 0x%0h\
      \nExpected LEVEL    : 0x%0h\
      \nActual LEVEL      : 0x%0h\
      \nEXT_INT           : 0x%0h\
      \nGLOBAL_ENABLE     : 0x%0h\
      \nACTIVE_LEVEL      : 0x%0h\
      \n========================================",
      tr.exp_irq_req,
      tr.interrupt_request_o,
      tr.exp_ack_id,
      tr.exp_highest_lvl_pr,
      tr.highest_pending_lvl_pr_o,
      tr.ext_int,
      tr.global_int_enable_bit_i,
      tr.active_lvl_pr_i))

    return;

  end


  //============================================================
  // WAIT UNTIL ACK IS EXPECTED
  //============================================================
`uvm_info("SCB_DEBUG",
$sformatf(
"exp_irq=%0b act_irq=%0b exp_lvl=0x%02h act_lvl=0x%02h exp_ack=0x%02h act_ack=0x%02h exp_valid=%0b",
tr.exp_irq_req,
tr.interrupt_request_o,
tr.exp_highest_lvl_pr,
tr.highest_pending_lvl_pr_o,
tr.exp_ack_id,
tr.soc_ack_int_id_o,
tr.exp_valid),
UVM_LOW)



  if (!tr.exp_valid) begin
    ignored_count++;
    return;
  end


  //============================================================
  // ACK COMPARE
  //============================================================

  ack_compare_count++;

  if ((tr.soc_ack_int_id_o === tr.exp_ack_id) &&
      (tr.highest_pending_lvl_pr_o === tr.exp_highest_lvl_pr)) begin

    ack_pass_count++;

    `uvm_info("ACK_COMPARE",
      $sformatf(
      "PASS ACK compare=%0d exp_ack=0x%0h act_ack=0x%0h exp_lvl=0x%0h act_lvl=0x%0h",
      ack_compare_count,
      tr.exp_ack_id,
      tr.soc_ack_int_id_o,
      tr.exp_highest_lvl_pr,
      tr.highest_pending_lvl_pr_o),
      UVM_LOW)

  end
  else begin

    ack_fail_count++;

    `uvm_error("ACK_COMPARE",
      $sformatf(
      "\n========================================\
      \nACK FAIL\
      \n========================================\
      \nExpected ACK ID   : 0x%0h\
      \nActual ACK ID     : 0x%0h\
      \nExpected LEVEL    : 0x%0h\
      \nActual LEVEL      : 0x%0h\
      \nACK_VALID         : %0b\
      \nIRQ_REQUEST       : %0b\
      \nEXT_INT           : 0x%0h\
      \nGLOBAL_ENABLE     : 0x%0h\
      \nACTIVE_LEVEL      : 0x%0h\
      \n========================================",
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

  `uvm_info("ZIC_SCB_REPORT",
$sformatf(

"\n============================================================\
\n                INTERRUPT CONTROLLER SCOREBOARD REPORT\
\n============================================================\
\n\
\nIRQ REQUEST CHECK\
\n------------------------------------------------------------\
\nIRQ COMPARES      : %0d\
\nIRQ PASS          : %0d\
\nIRQ FAIL          : %0d\
\n\
\nACK CHECK\
\n------------------------------------------------------------\
\nACK COMPARES      : %0d\
\nACK PASS          : %0d\
\nACK FAIL          : %0d\
\n\
\nMMR READ CHECK\
\n------------------------------------------------------------\
\nMMR COMPARES      : %0d\
\nMMR PASS          : %0d\
\nMMR FAIL          : %0d\
\n\
\nGENERAL\
\n------------------------------------------------------------\
\nIGNORED           : %0d\
\n\
\n============================================================",

irq_compare_count,
irq_pass_count,
irq_fail_count,

ack_compare_count,
ack_pass_count,
ack_fail_count,

mmr_compare_count,
mmr_pass_count,
mmr_fail_count,

ignored_count

),
UVM_LOW)

endfunction

endclass
