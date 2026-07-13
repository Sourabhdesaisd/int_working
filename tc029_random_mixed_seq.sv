//==============================================================
// TC029 : Random Mixed Functional Regression Sequence
//==============================================================

class tc029_random_mixed_seq extends uvm_sequence #(int_seq_item);

  `uvm_object_utils(tc029_random_mixed_seq)

  //------------------------------------------------------------
  // Parameters
  //------------------------------------------------------------

  localparam int NUM_IRQ = 16;

  int_seq_item tr;

  //------------------------------------------------------------
  // Random Variables
  //------------------------------------------------------------

  // Operation Selection
  typedef enum int
  {
    MMR_WRITE,
    MMR_READ,
    GLOBAL_ENABLE,
    EXT_INTERRUPT,
    ACK,
    EOI,
    ACTIVE_LEVEL,
    DEBUG_MODE,
    DEBUG_RESET,
    NDM_RESET,
    IDLE
  } operation_e;

  rand operation_e operation;

  // IRQ Information
  rand bit [3:0] irq_id;

  // Interrupt
  rand bit [15:0] ext_irq;

  // IRQ Configuration Register
  rand bit [7:0] ctl_data;

  // Global Enable
  rand bit [15:0] enable_mask;

  // Active Level
  rand bit [7:0] active_level;

  // EOI
  rand bit [7:0] eoi_id;

  // Debug
  rand bit debug_mode;
  rand bit debug_reset;
  rand bit ndm_reset;

  //------------------------------------------------------------
  // Variables used during sequence
  //------------------------------------------------------------

  bit [15:0] programmed_irq;
  bit [15:0] pending_irq;
  bit [15:0] enabled_irq;

  bit ack_done;
  //------------------------------------------------------------
  // Constraints
  //------------------------------------------------------------

  // Valid IRQ Number

  constraint irq_c
  {
    irq_id inside {[0:15]};
  }

  // Valid CTL Data

  constraint ctl_c
  {
    ctl_data inside {[8'h01:8'hFF]};
  }

  // External Interrupt cannot be zero

  constraint ext_irq_c
  {
    ext_irq != 16'h0000;
  }

  // Enable mask cannot be zero

  constraint enable_c
  {
    enable_mask != 16'h0000;
  }

  // Active Level

  constraint active_level_c
  {
    active_level inside {[8'h00:8'hFF]};
  }

  // EOI ID

  constraint eoi_c
  {
    eoi_id == (8'h10 + irq_id);
  }

  // Debug Reset and NDM Reset cannot occur together

  constraint debug_c
  {
    !(debug_reset && ndm_reset);
  }

  constraint multi_irq_c {
  if (operation == EXT_INTERRUPT)
    $countones(ext_irq) inside {[2:6]};
  }
  
  constraint enable_match_c {
  (enable_mask & ext_irq) != 16'h0000;
    }



  constraint operation_c
  {

    operation dist
    {

      MMR_WRITE      := 15,

      MMR_READ       := 10,

      GLOBAL_ENABLE  := 10,

      EXT_INTERRUPT  := 25,

      ACK            := 10,

      EOI            := 10,

      ACTIVE_LEVEL   := 5,

      DEBUG_MODE     := 5,

      DEBUG_RESET    := 2,

      NDM_RESET      := 2,

      IDLE           := 6

    };

  }
  //------------------------------------------------------------
  // Constructor
  //------------------------------------------------------------

  function new(string name="tc029_random_mixed_seq");

    super.new(name);

  endfunction

    //------------------------------------------------------------
  // Helper Function
  //------------------------------------------------------------

  function automatic bit [15:0] ctl_addr(int irq);

    return (16'h1003 + (irq * 4));

  endfunction

  //------------------------------------------------------------
// Body
//------------------------------------------------------------

task body();

  //----------------------------------------------------------
  // Phase-1 : Reset
  //----------------------------------------------------------

  `uvm_info(get_type_name(),
            "========== Phase-1 : Reset ==========",
            UVM_LOW)

  //==========================================================
  // Reset Assert
  //==========================================================

  tr = int_seq_item::type_id::create("reset_assert");

  start_item(tr);

  tr.soc_rst = 1'b0;

  // External Interrupt
  tr.ext_int = 16'h0000;

  // MMR Write
  tr.soc_mmr_write_en_i   = 1'b0;
  tr.soc_mmr_write_addr_i = 16'h0000;
  tr.soc_mmr_write_data_i = 32'h0000_0000;

  // MMR Read
  tr.soc_mmr_read_en_i   = 1'b0;
  tr.soc_mmr_read_addr_i = 16'h0000;

  // Global Enable
  tr.global_int_enable_valid_i = 1'b0;
  tr.global_int_enable_bit_i   = 16'h0000;

  // ACK
  tr.soc_ack_read_valid_en = 1'b0;

  // EOI
  tr.soc_eoi_valid_i = 1'b0;
  tr.soc_eoi_id_i    = 8'h00;

  // Active Level
  tr.active_lvl_pr_i = 8'h00;

  // Debug
  tr.debug_mode_valid_i = 1'b0;
  tr.debug_mode_reset_i = 1'b0;
  tr.debug_ndm_reset_i  = 1'b0;

  finish_item(tr);


  //==========================================================
  // Hold Reset
  //==========================================================

  repeat(5)
  begin

    tr = int_seq_item::type_id::create("reset_idle");

    start_item(tr);

    tr.soc_rst = 1'b0;

    tr.ext_int = 16'h0000;

    tr.soc_mmr_write_en_i   = 1'b0;
    tr.soc_mmr_write_addr_i = 16'h0000;
    tr.soc_mmr_write_data_i = 32'h0000_0000;

    tr.soc_mmr_read_en_i   = 1'b0;
    tr.soc_mmr_read_addr_i = 16'h0000;

    tr.global_int_enable_valid_i = 1'b0;
    tr.global_int_enable_bit_i   = 16'h0000;

    tr.soc_ack_read_valid_en = 1'b0;

    tr.soc_eoi_valid_i = 1'b0;
    tr.soc_eoi_id_i    = 8'h00;

    tr.active_lvl_pr_i = 8'h00;

    tr.debug_mode_valid_i = 1'b0;
    tr.debug_mode_reset_i = 1'b0;
    tr.debug_ndm_reset_i  = 1'b0;

    finish_item(tr);

  end


  //==========================================================
  // Release Reset
  //==========================================================

  tr = int_seq_item::type_id::create("reset_release");

  start_item(tr);

  tr.soc_rst = 1'b1;

  tr.ext_int = 16'h0000;

  tr.soc_mmr_write_en_i   = 1'b0;
  tr.soc_mmr_write_addr_i = 16'h0000;
  tr.soc_mmr_write_data_i = 32'h0000_0000;

  tr.soc_mmr_read_en_i   = 1'b0;
  tr.soc_mmr_read_addr_i = 16'h0000;

  tr.global_int_enable_valid_i = 1'b0;
  tr.global_int_enable_bit_i   = 16'h0000;

  tr.soc_ack_read_valid_en = 1'b0;

  tr.soc_eoi_valid_i = 1'b0;
  tr.soc_eoi_id_i    = 8'h00;

  tr.active_lvl_pr_i = 8'h00;

  tr.debug_mode_valid_i = 1'b0;
  tr.debug_mode_reset_i = 1'b0;
  tr.debug_ndm_reset_i  = 1'b0;

  finish_item(tr);


  //==========================================================
  // Initial Settle
  //==========================================================

  repeat(5)
  begin

    tr = int_seq_item::type_id::create("initial_idle");

    start_item(tr);

    tr.soc_rst = 1'b1;

    tr.ext_int = 16'h0000;

    tr.soc_mmr_write_en_i   = 1'b0;
    tr.soc_mmr_write_addr_i = 16'h0000;
    tr.soc_mmr_write_data_i = 32'h0000_0000;

    tr.soc_mmr_read_en_i   = 1'b0;
    tr.soc_mmr_read_addr_i = 16'h0000;

    tr.global_int_enable_valid_i = 1'b0;
    tr.global_int_enable_bit_i   = 16'h0000;

    tr.soc_ack_read_valid_en = 1'b0;

    tr.soc_eoi_valid_i = 1'b0;
    tr.soc_eoi_id_i    = 8'h00;

    tr.active_lvl_pr_i = 8'h00;

    tr.debug_mode_valid_i = 1'b0;
    tr.debug_mode_reset_i = 1'b0;
    tr.debug_ndm_reset_i  = 1'b0;

    finish_item(tr);

  end

    //----------------------------------------------------------
  // Phase-2 : Configure IRQ0 - IRQ15
  //----------------------------------------------------------

  `uvm_info(get_type_name(),
            "========== Phase-2 : Configure All IRQs ==========",
            UVM_LOW)

  for(int i=0; i<NUM_IRQ; i++)
  begin

    // Randomize CTL value
    assert(std::randomize(ctl_data))
    else
      `uvm_error(get_type_name(),"CTL Randomization Failed")

    tr = int_seq_item::type_id::create($sformatf("cfg_irq_%0d",i));

    start_item(tr);

    //----------------------------
    // Reset
    //----------------------------
    tr.soc_rst = 1'b1;

    //----------------------------
    // External Interrupt
    //----------------------------
    tr.ext_int = 16'h0000;

    //----------------------------
    // MMR Write
    //----------------------------
    tr.soc_mmr_write_en_i   = 1'b1;
    tr.soc_mmr_write_addr_i = ctl_addr(i);
    tr.soc_mmr_write_data_i = {24'h0,ctl_data};

    //----------------------------
    // MMR Read
    //----------------------------
    tr.soc_mmr_read_en_i   = 1'b0;
    tr.soc_mmr_read_addr_i = 16'h0000;

    //----------------------------
    // Global Enable
    //----------------------------
    tr.global_int_enable_valid_i = 1'b0;
    tr.global_int_enable_bit_i   = 16'h0000;

    //----------------------------
    // ACK
    //----------------------------
    tr.soc_ack_read_valid_en = 1'b0;

    //----------------------------
    // EOI
    //----------------------------
    tr.soc_eoi_valid_i = 1'b0;
    tr.soc_eoi_id_i    = 8'h00;

    //----------------------------
    // Active Level
    //----------------------------
    tr.active_lvl_pr_i = 8'h00;

    //----------------------------
    // Debug
    //----------------------------
    tr.debug_mode_valid_i = 1'b0;
    tr.debug_mode_reset_i = 1'b0;
    tr.debug_ndm_reset_i  = 1'b0;

    finish_item(tr);

    // Store programmed information
    programmed_irq[i] = 1'b1;

  end

    //----------------------------------------------------------
  // Phase-3 : Read Back All IRQ Configuration
  //----------------------------------------------------------

  `uvm_info(get_type_name(),
            "========== Phase-3 : Read Back All IRQs ==========",
            UVM_LOW)

  for(int i=0; i<NUM_IRQ; i++)
  begin

    tr = int_seq_item::type_id::create($sformatf("read_irq_%0d",i));

    start_item(tr);

    //----------------------------
    // Reset
    //----------------------------
    tr.soc_rst = 1'b1;

    //----------------------------
    // External Interrupt
    //----------------------------
    tr.ext_int = 16'h0000;

    //----------------------------
    // MMR Write
    //----------------------------
    tr.soc_mmr_write_en_i   = 1'b0;
    tr.soc_mmr_write_addr_i = 16'h0000;
    tr.soc_mmr_write_data_i = 32'h00000000;

    //----------------------------
    // MMR Read
    //----------------------------
    tr.soc_mmr_read_en_i   = 1'b1;
    tr.soc_mmr_read_addr_i = ctl_addr(i);

    //----------------------------
    // Global Enable
    //----------------------------
    tr.global_int_enable_valid_i = 1'b0;
    tr.global_int_enable_bit_i   = 16'h0000;

    //----------------------------
    // ACK
    //----------------------------
    tr.soc_ack_read_valid_en = 1'b0;

    //----------------------------
    // EOI
    //----------------------------
    tr.soc_eoi_valid_i = 1'b0;
    tr.soc_eoi_id_i    = 8'h00;

    //----------------------------
    // Active Level
    //----------------------------
    tr.active_lvl_pr_i = 8'h00;

    //----------------------------
    // Debug
    //----------------------------
    tr.debug_mode_valid_i = 1'b0;
    tr.debug_mode_reset_i = 1'b0;
    tr.debug_ndm_reset_i  = 1'b0;

    finish_item(tr);

  end

    //----------------------------------------------------------
  // Phase-4 : Global Interrupt Enable
  //----------------------------------------------------------

  `uvm_info(get_type_name(),
            "========== Phase-4 : Global Enable ==========",
            UVM_LOW)

  repeat(20)
  begin

    // Random Enable Mask
    assert(randomize(enable_mask))
    else
      `uvm_error(get_type_name(),"Enable Mask Randomization Failed")

    tr = int_seq_item::type_id::create("global_enable");

    start_item(tr);

    //----------------------------
    // Reset
    //----------------------------
    tr.soc_rst = 1'b1;

    //----------------------------
    // External Interrupt
    //----------------------------
    tr.ext_int = 16'h0000;

    //----------------------------
    // MMR Write
    //----------------------------
    tr.soc_mmr_write_en_i   = 1'b0;
    tr.soc_mmr_write_addr_i = 16'h0000;
    tr.soc_mmr_write_data_i = 32'h00000000;

    //----------------------------
    // MMR Read
    //----------------------------
    tr.soc_mmr_read_en_i   = 1'b0;
    tr.soc_mmr_read_addr_i = 16'h0000;

    //----------------------------
    // Global Enable
    //----------------------------
    tr.global_int_enable_valid_i = 1'b1;
    tr.global_int_enable_bit_i   = enable_mask;

    //----------------------------
    // ACK
    //----------------------------
    tr.soc_ack_read_valid_en = 1'b0;

    //----------------------------
    // EOI
    //----------------------------
    tr.soc_eoi_valid_i = 1'b0;
    tr.soc_eoi_id_i    = 8'h00;

    //----------------------------
    // Active Level
    //----------------------------
    tr.active_lvl_pr_i = 8'h00;

    //----------------------------
    // Debug
    //----------------------------
    tr.debug_mode_valid_i = 1'b0;
    tr.debug_mode_reset_i = 1'b0;
    tr.debug_ndm_reset_i  = 1'b0;

    finish_item(tr);

    // Save current enable mask
    enabled_irq = enable_mask;

  end

    //----------------------------------------------------------
  // Phase-5 : Single IRQ Verification
  //----------------------------------------------------------

  `uvm_info(get_type_name(),
            "========== Phase-5 : Single IRQ Verification ==========",
            UVM_LOW)

  for(int i=0; i<NUM_IRQ; i++)
  begin

    //------------------------------------------------------
    // Enable Current IRQ
    //------------------------------------------------------

    enable_mask = 16'h0000;
    enable_mask[i] = 1'b1;

    //------------------------------------------------------
    // Generate Current IRQ
    //------------------------------------------------------

    ext_irq = 16'h0000;
    ext_irq[i] = 1'b1;

    tr = int_seq_item::type_id::create($sformatf("irq_%0d_assert",i));

    start_item(tr);

    //----------------------------
    // Reset
    //----------------------------
    tr.soc_rst = 1'b1;

    //----------------------------
    // External Interrupt
    //----------------------------
    tr.ext_int = ext_irq;

    //----------------------------
    // MMR Write
    //----------------------------
    tr.soc_mmr_write_en_i   = 1'b0;
    tr.soc_mmr_write_addr_i = 16'h0000;
    tr.soc_mmr_write_data_i = 32'h00000000;

    //----------------------------
    // MMR Read
    //----------------------------
    tr.soc_mmr_read_en_i   = 1'b0;
    tr.soc_mmr_read_addr_i = 16'h0000;

    //----------------------------
    // Global Enable
    //----------------------------
    tr.global_int_enable_valid_i = 1'b1;
    tr.global_int_enable_bit_i   = enable_mask;

    //----------------------------
    // ACK
    //----------------------------
    tr.soc_ack_read_valid_en = 1'b0;

    //----------------------------
    // EOI
    //----------------------------
    tr.soc_eoi_valid_i = 1'b0;
    tr.soc_eoi_id_i    = 8'h00;

    //----------------------------
    // Active Level
    //----------------------------
    tr.active_lvl_pr_i = 8'h00;

    //----------------------------
    // Debug
    //----------------------------
    tr.debug_mode_valid_i = 1'b0;
    tr.debug_mode_reset_i = 1'b0;
    tr.debug_ndm_reset_i  = 1'b0;

    finish_item(tr);

    //------------------------------------------------------
    // Wait for IRQ Detection
    //------------------------------------------------------

    repeat(5)
    begin

      tr = int_seq_item::type_id::create("wait_irq");

      start_item(tr);

      tr.soc_rst = 1'b1;

      tr.ext_int = ext_irq;

      tr.soc_mmr_write_en_i = 1'b0;
      tr.soc_mmr_read_en_i  = 1'b0;

      tr.global_int_enable_valid_i = 1'b0;

      tr.soc_ack_read_valid_en = 1'b0;

      tr.soc_eoi_valid_i = 1'b0;

      tr.active_lvl_pr_i = 8'h00;

      tr.debug_mode_valid_i = 1'b0;
      tr.debug_mode_reset_i = 1'b0;
      tr.debug_ndm_reset_i  = 1'b0;

      finish_item(tr);

    end

  end

      //------------------------------------------------------
    // ACK Current IRQ
    //------------------------------------------------------

    tr = int_seq_item::type_id::create($sformatf("ack_irq_%0d",irq_id));

    start_item(tr);

    tr.soc_rst = 1'b1;

    tr.ext_int = ext_irq;

    // MMR
    tr.soc_mmr_write_en_i   = 1'b0;
    tr.soc_mmr_write_addr_i = 16'h0000;
    tr.soc_mmr_write_data_i = 32'h00000000;

    tr.soc_mmr_read_en_i    = 1'b0;
    tr.soc_mmr_read_addr_i  = 16'h0000;

    // Global Enable
    tr.global_int_enable_valid_i = 1'b0;
    tr.global_int_enable_bit_i   = enable_mask;

    // ACK
    tr.soc_ack_read_valid_en = 1'b1;

    // EOI
    tr.soc_eoi_valid_i = 1'b0;
    tr.soc_eoi_id_i    = 8'h00;

    // Active Level
    tr.active_lvl_pr_i = 8'h00;

    // Debug
    tr.debug_mode_valid_i = 1'b0;
    tr.debug_mode_reset_i = 1'b0;
    tr.debug_ndm_reset_i  = 1'b0;

    finish_item(tr);

    //------------------------------------------------------
    // Wait after ACK
    //------------------------------------------------------

    repeat(3)
    begin

      tr = int_seq_item::type_id::create("wait_after_ack");

      start_item(tr);

      tr.soc_rst = 1'b1;

      tr.ext_int = ext_irq;

      tr.soc_mmr_write_en_i = 1'b0;
      tr.soc_mmr_read_en_i  = 1'b0;

      tr.global_int_enable_valid_i = 1'b0;

      tr.soc_ack_read_valid_en = 1'b0;

      tr.soc_eoi_valid_i = 1'b0;

      tr.active_lvl_pr_i = 8'h00;

      tr.debug_mode_valid_i = 1'b0;
      tr.debug_mode_reset_i = 1'b0;
      tr.debug_ndm_reset_i  = 1'b0;

      finish_item(tr);

    end

    //------------------------------------------------------
    // Clear External Interrupt
    //------------------------------------------------------

    ext_irq = 16'h0000;

    //------------------------------------------------------
    // Send EOI
    //------------------------------------------------------

    tr = int_seq_item::type_id::create($sformatf("eoi_irq_%0d",irq_id));

    start_item(tr);

    tr.soc_rst = 1'b1;

    tr.ext_int = ext_irq;

    tr.soc_mmr_write_en_i   = 1'b0;
    tr.soc_mmr_write_addr_i = 16'h0000;
    tr.soc_mmr_write_data_i = 32'h00000000;

    tr.soc_mmr_read_en_i    = 1'b0;
    tr.soc_mmr_read_addr_i  = 16'h0000;

    tr.global_int_enable_valid_i = 1'b0;
    tr.global_int_enable_bit_i   = enable_mask;

    tr.soc_ack_read_valid_en = 1'b0;

    tr.soc_eoi_valid_i = 1'b1;
    tr.soc_eoi_id_i    = 8'h10 + irq_id;

    tr.active_lvl_pr_i = 8'h00;

    tr.debug_mode_valid_i = 1'b0;
    tr.debug_mode_reset_i = 1'b0;
    tr.debug_ndm_reset_i  = 1'b0;

    finish_item(tr);

    //------------------------------------------------------
    // Wait after EOI
    //------------------------------------------------------

    repeat(3)
    begin

      tr = int_seq_item::type_id::create("wait_after_eoi");

      start_item(tr);

      tr.soc_rst = 1'b1;

      tr.ext_int = 16'h0000;

      tr.soc_mmr_write_en_i = 1'b0;
      tr.soc_mmr_read_en_i  = 1'b0;

      tr.global_int_enable_valid_i = 1'b0;

      tr.soc_ack_read_valid_en = 1'b0;

      tr.soc_eoi_valid_i = 1'b0;
      tr.soc_eoi_id_i    = 8'h00;

      tr.active_lvl_pr_i = 8'h00;

      tr.debug_mode_valid_i = 1'b0;
      tr.debug_mode_reset_i = 1'b0;
      tr.debug_ndm_reset_i  = 1'b0;

      finish_item(tr);

    end

     // End of for loop

    //----------------------------------------------------------
  // Phase-6 : Multiple IRQ Verification
  //----------------------------------------------------------

  `uvm_info(get_type_name(),
            "========== Phase-6 : Multiple IRQ Verification ==========",
            UVM_LOW)

  repeat(50)
  begin

    //------------------------------------------------------
    // Randomize Multiple IRQs
    //------------------------------------------------------

    assert(randomize(ext_irq) with {

      ext_irq != 16'h0000;

      // At least two interrupts active
      $countones(ext_irq) inside {[2:6]};

    });

    //------------------------------------------------------
    // Random Enable Mask
    //------------------------------------------------------

    assert(randomize(enable_mask) with {

      enable_mask != 16'h0000;

      // At least one interrupt enabled
      (enable_mask & ext_irq) != 16'h0000;

    });

    //------------------------------------------------------
    // Assert Multiple Interrupts
    //------------------------------------------------------

    tr = int_seq_item::type_id::create("multiple_irq");

    start_item(tr);

    // Reset
    tr.soc_rst = 1'b1;

    // External Interrupt
    tr.ext_int = ext_irq;

    // MMR Write
    tr.soc_mmr_write_en_i   = 1'b0;
    tr.soc_mmr_write_addr_i = 16'h0000;
    tr.soc_mmr_write_data_i = 32'h00000000;

    // MMR Read
    tr.soc_mmr_read_en_i   = 1'b0;
    tr.soc_mmr_read_addr_i = 16'h0000;

    // Global Enable
    tr.global_int_enable_valid_i = 1'b1;
    tr.global_int_enable_bit_i   = enable_mask;

    // ACK
    tr.soc_ack_read_valid_en = 1'b0;

    // EOI
    tr.soc_eoi_valid_i = 1'b0;
    tr.soc_eoi_id_i    = 8'h00;

    // Active Level
    tr.active_lvl_pr_i = 8'h00;

    // Debug
    tr.debug_mode_valid_i = 1'b0;
    tr.debug_mode_reset_i = 1'b0;
    tr.debug_ndm_reset_i  = 1'b0;

    finish_item(tr);

    //------------------------------------------------------
    // Wait for Priority Resolution
    //------------------------------------------------------

    repeat(5)
    begin

      tr = int_seq_item::type_id::create("wait_priority");

      start_item(tr);

      tr.soc_rst = 1'b1;
      tr.ext_int = ext_irq;

      tr.soc_mmr_write_en_i = 1'b0;
      tr.soc_mmr_read_en_i  = 1'b0;

      tr.global_int_enable_valid_i = 1'b0;
      tr.global_int_enable_bit_i   = enable_mask;

      tr.soc_ack_read_valid_en = 1'b0;

      tr.soc_eoi_valid_i = 1'b0;
      tr.soc_eoi_id_i    = 8'h00;

      tr.active_lvl_pr_i = 8'h00;

      tr.debug_mode_valid_i = 1'b0;
      tr.debug_mode_reset_i = 1'b0;
      tr.debug_ndm_reset_i  = 1'b0;

      finish_item(tr);

    end

    //------------------------------------------------------
    // ACK Highest Priority Interrupt
    //------------------------------------------------------

    tr = int_seq_item::type_id::create("ack_multiple_irq");

    start_item(tr);

    tr.soc_rst = 1'b1;

    tr.ext_int = ext_irq;

    tr.soc_mmr_write_en_i = 1'b0;
    tr.soc_mmr_read_en_i  = 1'b0;

    tr.global_int_enable_valid_i = 1'b0;
    tr.global_int_enable_bit_i   = enable_mask;

    tr.soc_ack_read_valid_en = 1'b1;

    tr.soc_eoi_valid_i = 1'b0;
    tr.soc_eoi_id_i    = 8'h00;

    tr.active_lvl_pr_i = 8'h00;

    tr.debug_mode_valid_i = 1'b0;
    tr.debug_mode_reset_i = 1'b0;
    tr.debug_ndm_reset_i  = 1'b0;

    finish_item(tr);

    //------------------------------------------------------
    // EOI will be sent after scoreboard/monitor
    // identifies the acknowledged interrupt.
    //------------------------------------------------------

  end

  //----------------------------------------------------------
  // Phase-7 : Interrupt Storm Verification
  //----------------------------------------------------------

  `uvm_info(get_type_name(),
            "========== Phase-7 : Interrupt Storm ==========",
            UVM_LOW)

  repeat(100)
  begin

    //------------------------------------------
    // Randomize Storm
    //------------------------------------------

    assert(randomize());

    tr = int_seq_item::type_id::create("interrupt_storm");

    start_item(tr);

    //----------------------------
    // Reset
    //----------------------------
    tr.soc_rst = 1'b1;

    //----------------------------
    // Random External Interrupts
    //----------------------------
    tr.ext_int = ext_irq;

    //----------------------------
    // No MMR Write
    //----------------------------
    tr.soc_mmr_write_en_i   = 1'b0;
    tr.soc_mmr_write_addr_i = 16'h0000;
    tr.soc_mmr_write_data_i = 32'h00000000;

    //----------------------------
    // No MMR Read
    //----------------------------
    tr.soc_mmr_read_en_i   = 1'b0;
    tr.soc_mmr_read_addr_i = 16'h0000;

    //----------------------------
    // Global Enable
    //----------------------------
    tr.global_int_enable_valid_i = 1'b1;
    tr.global_int_enable_bit_i   = enable_mask;

    //----------------------------
    // No ACK
    //----------------------------
    tr.soc_ack_read_valid_en = 1'b0;

    //----------------------------
    // No EOI
    //----------------------------
    tr.soc_eoi_valid_i = 1'b0;
    tr.soc_eoi_id_i    = 8'h00;

    //----------------------------
    // Random Active Level
    //----------------------------
    tr.active_lvl_pr_i = active_level;

    //----------------------------
    // Debug
    //----------------------------
    tr.debug_mode_valid_i = 1'b0;
    tr.debug_mode_reset_i = 1'b0;
    tr.debug_ndm_reset_i  = 1'b0;

    finish_item(tr);

    //------------------------------------------
    // Wait
    //------------------------------------------

    repeat($urandom_range(2,6))
    begin

      tr = int_seq_item::type_id::create("storm_wait");

      start_item(tr);

      tr.soc_rst = 1'b1;

      tr.ext_int = ext_irq;

      tr.soc_mmr_write_en_i = 1'b0;
      tr.soc_mmr_read_en_i  = 1'b0;

      tr.global_int_enable_valid_i = 1'b0;
      tr.global_int_enable_bit_i   = enable_mask;

      tr.soc_ack_read_valid_en = 1'b0;

      tr.soc_eoi_valid_i = 1'b0;
      tr.soc_eoi_id_i    = 8'h00;

      tr.active_lvl_pr_i = active_level;

      tr.debug_mode_valid_i = 1'b0;
      tr.debug_mode_reset_i = 1'b0;
      tr.debug_ndm_reset_i  = 1'b0;

      finish_item(tr);

    end

  end

    //----------------------------------------------------------
  // Phase-8 : Random ACK Verification
  //----------------------------------------------------------

  `uvm_info(get_type_name(),
            "========== Phase-8 : ACK Verification ==========",
            UVM_LOW)

  repeat(100)
  begin

    //------------------------------------------
    // Random Wait before ACK
    //------------------------------------------

    repeat($urandom_range(1,5))
    begin

      tr = int_seq_item::type_id::create("ack_wait");

      start_item(tr);

      tr.soc_rst = 1'b1;

      tr.ext_int = ext_irq;

      tr.soc_mmr_write_en_i   = 1'b0;
      tr.soc_mmr_write_addr_i = 16'h0000;
      tr.soc_mmr_write_data_i = 32'h00000000;

      tr.soc_mmr_read_en_i    = 1'b0;
      tr.soc_mmr_read_addr_i  = 16'h0000;

      tr.global_int_enable_valid_i = 1'b0;
      tr.global_int_enable_bit_i   = enable_mask;

      tr.soc_ack_read_valid_en = 1'b0;

      tr.soc_eoi_valid_i = 1'b0;
      tr.soc_eoi_id_i    = 8'h00;

      tr.active_lvl_pr_i = active_level;

      tr.debug_mode_valid_i = 1'b0;
      tr.debug_mode_reset_i = 1'b0;
      tr.debug_ndm_reset_i  = 1'b0;

      finish_item(tr);

    end

    //------------------------------------------
    // Send ACK
    //------------------------------------------

    tr = int_seq_item::type_id::create("ack");

    start_item(tr);

    tr.soc_rst = 1'b1;

    tr.ext_int = ext_irq;

    tr.soc_mmr_write_en_i   = 1'b0;
    tr.soc_mmr_write_addr_i = 16'h0000;
    tr.soc_mmr_write_data_i = 32'h00000000;

    tr.soc_mmr_read_en_i    = 1'b0;
    tr.soc_mmr_read_addr_i  = 16'h0000;

    tr.global_int_enable_valid_i = 1'b0;
    tr.global_int_enable_bit_i   = enable_mask;

    //-----------------------------
    // ACK
    //-----------------------------
    tr.soc_ack_read_valid_en = 1'b1;

    //-----------------------------
    // No EOI Yet
    //-----------------------------
    tr.soc_eoi_valid_i = 1'b0;
    tr.soc_eoi_id_i    = 8'h00;

    tr.active_lvl_pr_i = active_level;

    tr.debug_mode_valid_i = 1'b0;
    tr.debug_mode_reset_i = 1'b0;
    tr.debug_ndm_reset_i  = 1'b0;

    finish_item(tr);

  end

    //----------------------------------------------------------
  // Phase-9 : Random EOI Verification
  //----------------------------------------------------------

  `uvm_info(get_type_name(),
            "========== Phase-9 : EOI Verification ==========",
            UVM_LOW)

  repeat(100)
  begin

    //------------------------------------------------------
    // Random Delay Before EOI
    //------------------------------------------------------

    repeat($urandom_range(1,5))
    begin

      tr = int_seq_item::type_id::create("eoi_wait");

      start_item(tr);

      tr.soc_rst = 1'b1;

      tr.ext_int = ext_irq;

      // No MMR Access
      tr.soc_mmr_write_en_i   = 1'b0;
      tr.soc_mmr_write_addr_i = 16'h0000;
      tr.soc_mmr_write_data_i = 32'h00000000;

      tr.soc_mmr_read_en_i    = 1'b0;
      tr.soc_mmr_read_addr_i  = 16'h0000;

      // No Enable Update
      tr.global_int_enable_valid_i = 1'b0;
      tr.global_int_enable_bit_i   = enable_mask;

      // No ACK
      tr.soc_ack_read_valid_en = 1'b0;

      // No EOI
      tr.soc_eoi_valid_i = 1'b0;
      tr.soc_eoi_id_i    = 8'h00;

      tr.active_lvl_pr_i = active_level;

      tr.debug_mode_valid_i = 1'b0;
      tr.debug_mode_reset_i = 1'b0;
      tr.debug_ndm_reset_i  = 1'b0;

      finish_item(tr);

    end

    //------------------------------------------------------
    // Send EOI
    //------------------------------------------------------

    tr = int_seq_item::type_id::create("send_eoi");

    start_item(tr);

    tr.soc_rst = 1'b1;

    // External Interrupt Cleared
    tr.ext_int = 16'h0000;

    // No MMR
    tr.soc_mmr_write_en_i   = 1'b0;
    tr.soc_mmr_write_addr_i = 16'h0000;
    tr.soc_mmr_write_data_i = 32'h00000000;

    tr.soc_mmr_read_en_i    = 1'b0;
    tr.soc_mmr_read_addr_i  = 16'h0000;

    // No Enable Update
    tr.global_int_enable_valid_i = 1'b0;
    tr.global_int_enable_bit_i   = enable_mask;

    // ACK Low
    tr.soc_ack_read_valid_en = 1'b0;

    // Send EOI
    tr.soc_eoi_valid_i = 1'b1;
    tr.soc_eoi_id_i    = eoi_id;

    tr.active_lvl_pr_i = active_level;

    tr.debug_mode_valid_i = 1'b0;
    tr.debug_mode_reset_i = 1'b0;
    tr.debug_ndm_reset_i  = 1'b0;

    finish_item(tr);

    //------------------------------------------------------
    // Wait after EOI
    //------------------------------------------------------

    repeat(3)
    begin

      tr = int_seq_item::type_id::create("wait_after_eoi");

      start_item(tr);

      tr.soc_rst = 1'b1;

      tr.ext_int = 16'h0000;

      tr.soc_mmr_write_en_i = 1'b0;
      tr.soc_mmr_read_en_i  = 1'b0;

      tr.global_int_enable_valid_i = 1'b0;
      tr.global_int_enable_bit_i   = enable_mask;

      tr.soc_ack_read_valid_en = 1'b0;

      tr.soc_eoi_valid_i = 1'b0;
      tr.soc_eoi_id_i    = 8'h00;

      tr.active_lvl_pr_i = active_level;

      tr.debug_mode_valid_i = 1'b0;
      tr.debug_mode_reset_i = 1'b0;
      tr.debug_ndm_reset_i  = 1'b0;

      finish_item(tr);

    end

  end


    //----------------------------------------------------------
  // Phase-10 : Active Level Verification
  //----------------------------------------------------------

  `uvm_info(get_type_name(),
            "========== Phase-10 : Active Level ==========",
            UVM_LOW)

  repeat(100)
  begin

    //------------------------------------------
    // Random Active Level
    //------------------------------------------

    assert(randomize(active_level));

    //------------------------------------------
    // Random Interrupt
    //------------------------------------------

    assert(randomize(ext_irq));

    //------------------------------------------
    // Random Enable Mask
    //------------------------------------------

    assert(randomize(enable_mask));

    tr = int_seq_item::type_id::create("active_level");

    start_item(tr);

    //----------------------------
    // Reset
    //----------------------------
    tr.soc_rst = 1'b1;

    //----------------------------
    // External Interrupt
    //----------------------------
    tr.ext_int = ext_irq;

    //----------------------------
    // No MMR Access
    //----------------------------
    tr.soc_mmr_write_en_i   = 1'b0;
    tr.soc_mmr_write_addr_i = 16'h0000;
    tr.soc_mmr_write_data_i = 32'h00000000;

    tr.soc_mmr_read_en_i    = 1'b0;
    tr.soc_mmr_read_addr_i  = 16'h0000;

    //----------------------------
    // Global Enable
    //----------------------------
    tr.global_int_enable_valid_i = 1'b1;
    tr.global_int_enable_bit_i   = enable_mask;

    //----------------------------
    // ACK
    //----------------------------
    tr.soc_ack_read_valid_en = 1'b0;

    //----------------------------
    // EOI
    //----------------------------
    tr.soc_eoi_valid_i = 1'b0;
    tr.soc_eoi_id_i    = 8'h00;

    //----------------------------
    // Active Level
    //----------------------------
    tr.active_lvl_pr_i = active_level;

    //----------------------------
    // Debug
    //----------------------------
    tr.debug_mode_valid_i = 1'b0;
    tr.debug_mode_reset_i = 1'b0;
    tr.debug_ndm_reset_i  = 1'b0;

    finish_item(tr);

    //------------------------------------------
    // Wait
    //------------------------------------------

    repeat($urandom_range(2,5))
    begin

      tr = int_seq_item::type_id::create("active_wait");

      start_item(tr);

      tr.soc_rst = 1'b1;

      tr.ext_int = ext_irq;

      tr.soc_mmr_write_en_i = 1'b0;
      tr.soc_mmr_read_en_i  = 1'b0;

      tr.global_int_enable_valid_i = 1'b0;
      tr.global_int_enable_bit_i   = enable_mask;

      tr.soc_ack_read_valid_en = 1'b0;

      tr.soc_eoi_valid_i = 1'b0;

      tr.active_lvl_pr_i = active_level;

      tr.debug_mode_valid_i = 1'b0;
      tr.debug_mode_reset_i = 1'b0;
      tr.debug_ndm_reset_i  = 1'b0;

      finish_item(tr);

    end

  end

    //----------------------------------------------------------
  // Phase-11 : Debug Mode Verification
  //----------------------------------------------------------

  `uvm_info(get_type_name(),
            "========== Phase-11 : Debug Verification ==========",
            UVM_LOW)

  repeat(50)
  begin

    //----------------------------------------
    // Randomize
    //----------------------------------------

    assert(randomize(debug_mode));
    assert(randomize(debug_reset));
    assert(randomize(ndm_reset));

    tr = int_seq_item::type_id::create("debug_mode");

    start_item(tr);

    //----------------------------
    // Reset
    //----------------------------
    tr.soc_rst = 1'b1;

    //----------------------------
    // External Interrupt
    //----------------------------
    tr.ext_int = ext_irq;

    //----------------------------
    // No MMR Access
    //----------------------------
    tr.soc_mmr_write_en_i   = 1'b0;
    tr.soc_mmr_write_addr_i = 16'h0000;
    tr.soc_mmr_write_data_i = 32'h00000000;

    tr.soc_mmr_read_en_i   = 1'b0;
    tr.soc_mmr_read_addr_i = 16'h0000;

    //----------------------------
    // Global Enable
    //----------------------------
    tr.global_int_enable_valid_i = 1'b0;
    tr.global_int_enable_bit_i   = enable_mask;

    //----------------------------
    // ACK
    //----------------------------
    tr.soc_ack_read_valid_en = 1'b0;

    //----------------------------
    // EOI
    //----------------------------
    tr.soc_eoi_valid_i = 1'b0;
    tr.soc_eoi_id_i    = 8'h00;

    //----------------------------
    // Active Level
    //----------------------------
    tr.active_lvl_pr_i = active_level;

    //----------------------------
    // Debug
    //----------------------------
    tr.debug_mode_valid_i = debug_mode;
    tr.debug_mode_reset_i = debug_reset;
    tr.debug_ndm_reset_i  = ndm_reset;

    finish_item(tr);

    //----------------------------------------
    // Wait
    //----------------------------------------

    repeat($urandom_range(2,5))
    begin

      tr = int_seq_item::type_id::create("debug_wait");

      start_item(tr);

      tr.soc_rst = 1'b1;

      tr.ext_int = ext_irq;

      tr.soc_mmr_write_en_i = 1'b0;
      tr.soc_mmr_read_en_i  = 1'b0;

      tr.global_int_enable_valid_i = 1'b0;

      tr.soc_ack_read_valid_en = 1'b0;

      tr.soc_eoi_valid_i = 1'b0;
      tr.soc_eoi_id_i    = 8'h00;

      tr.active_lvl_pr_i = active_level;

      tr.debug_mode_valid_i = 1'b0;
      tr.debug_mode_reset_i = 1'b0;
      tr.debug_ndm_reset_i  = 1'b0;

      finish_item(tr);

    end

  end

  //----------------------------------------------------------
  // Phase-12 : Mixed Random Functional Regression
  //----------------------------------------------------------

  `uvm_info(get_type_name(),
            "========== Phase-12 : Mixed Random Regression ==========",
            UVM_LOW)

  repeat(500)
  begin

    assert(randomize());

    case(operation)
      

      MMR_WRITE:
begin

  assert(randomize(irq_id, ctl_data));

  tr = int_seq_item::type_id::create("mmr_write");

  start_item(tr);

  tr.soc_rst = 1'b1;

  // External Interrupt
  tr.ext_int = 16'h0000;

  // MMR Write
  tr.soc_mmr_write_en_i   = 1'b1;
  tr.soc_mmr_write_addr_i = ctl_addr(irq_id);
  tr.soc_mmr_write_data_i = {24'h0, ctl_data};

  // MMR Read
  tr.soc_mmr_read_en_i    = 1'b0;
  tr.soc_mmr_read_addr_i  = 16'h0000;

  // Global Enable
  tr.global_int_enable_valid_i = 1'b0;
  tr.global_int_enable_bit_i   = 16'h0000;

  // ACK
  tr.soc_ack_read_valid_en = 1'b0;

  // EOI
  tr.soc_eoi_valid_i = 1'b0;
  tr.soc_eoi_id_i    = 8'h00;

  // Active Level
  tr.active_lvl_pr_i = active_level;

  // Debug
  tr.debug_mode_valid_i = 1'b0;
  tr.debug_mode_reset_i = 1'b0;
  tr.debug_ndm_reset_i  = 1'b0;

  finish_item(tr);

  programmed_irq[irq_id] = 1'b1;

end


MMR_READ:
begin

  assert(randomize(irq_id));

  if(programmed_irq[irq_id])
  begin

    tr = int_seq_item::type_id::create("mmr_read");

    start_item(tr);

    tr.soc_rst = 1'b1;

    tr.ext_int = 16'h0000;

    tr.soc_mmr_write_en_i   = 1'b0;
    tr.soc_mmr_write_addr_i = 16'h0000;
    tr.soc_mmr_write_data_i = 32'h00000000;

    tr.soc_mmr_read_en_i   = 1'b1;
    tr.soc_mmr_read_addr_i = ctl_addr(irq_id);

    tr.global_int_enable_valid_i = 1'b0;
    tr.global_int_enable_bit_i   = 16'h0000;

    tr.soc_ack_read_valid_en = 1'b0;

    tr.soc_eoi_valid_i = 1'b0;
    tr.soc_eoi_id_i    = 8'h00;

    tr.active_lvl_pr_i = active_level;

    tr.debug_mode_valid_i = 1'b0;
    tr.debug_mode_reset_i = 1'b0;
    tr.debug_ndm_reset_i  = 1'b0;

    finish_item(tr);

  end

end

GLOBAL_ENABLE:
begin

  assert(randomize(enable_mask));

  tr = int_seq_item::type_id::create("global_enable");

  start_item(tr);

  tr.soc_rst = 1'b1;

  tr.ext_int = 16'h0000;

  tr.soc_mmr_write_en_i = 1'b0;
  tr.soc_mmr_read_en_i  = 1'b0;

  tr.global_int_enable_valid_i = 1'b1;
  tr.global_int_enable_bit_i   = enable_mask;

  tr.soc_ack_read_valid_en = 1'b0;

  tr.soc_eoi_valid_i = 1'b0;
  tr.soc_eoi_id_i    = 8'h00;

  tr.active_lvl_pr_i = active_level;

  tr.debug_mode_valid_i = 1'b0;
  tr.debug_mode_reset_i = 1'b0;
  tr.debug_ndm_reset_i  = 1'b0;

  finish_item(tr);

  enabled_irq = enable_mask;

end


EXT_INTERRUPT:
begin

  assert(randomize(ext_irq));

  tr = int_seq_item::type_id::create("ext_interrupt");

  start_item(tr);

  tr.soc_rst = 1'b1;

  tr.ext_int = ext_irq;

  tr.soc_mmr_write_en_i = 1'b0;
  tr.soc_mmr_read_en_i  = 1'b0;

  tr.global_int_enable_valid_i = 1'b0;
  tr.global_int_enable_bit_i   = enabled_irq;

  tr.soc_ack_read_valid_en = 1'b0;

  tr.soc_eoi_valid_i = 1'b0;
  tr.soc_eoi_id_i    = 8'h00;

  tr.active_lvl_pr_i = active_level;

  tr.debug_mode_valid_i = 1'b0;
  tr.debug_mode_reset_i = 1'b0;
  tr.debug_ndm_reset_i  = 1'b0;

  finish_item(tr);

  pending_irq = ext_irq;

end


      //------------------------------------------------------
      // ACK
      //------------------------------------------------------

      ACK:
      begin

        if(pending_irq != 16'h0000)
        begin

          tr = int_seq_item::type_id::create("ack");

          start_item(tr);

          //----------------------------
          // Reset
          //----------------------------
          tr.soc_rst = 1'b1;

          //----------------------------
          // Keep Pending Interrupt
          //----------------------------
          tr.ext_int = pending_irq;

          //----------------------------
          // No MMR Access
          //----------------------------
          tr.soc_mmr_write_en_i   = 1'b0;
          tr.soc_mmr_write_addr_i = 16'h0000;
          tr.soc_mmr_write_data_i = 32'h00000000;

          tr.soc_mmr_read_en_i    = 1'b0;
          tr.soc_mmr_read_addr_i  = 16'h0000;

          //----------------------------
          // Keep Global Enable
          //----------------------------
          tr.global_int_enable_valid_i = 1'b0;
          tr.global_int_enable_bit_i   = enabled_irq;

          //----------------------------
          // ACK
          //----------------------------
          tr.soc_ack_read_valid_en = 1'b1;

          //----------------------------
          // No EOI
          //----------------------------
          tr.soc_eoi_valid_i = 1'b0;
          tr.soc_eoi_id_i    = 8'h00;

          //----------------------------
          // Active Level
          //----------------------------
          tr.active_lvl_pr_i = active_level;

          //----------------------------
          // Debug
          //----------------------------
          tr.debug_mode_valid_i = 1'b0;
          tr.debug_mode_reset_i = 1'b0;
          tr.debug_ndm_reset_i  = 1'b0;

          finish_item(tr);

          ack_done = 1'b1;

        end

      end


            //------------------------------------------------------
      // EOI
      //------------------------------------------------------

      EOI:
      begin

        if(ack_done)
        begin

          tr = int_seq_item::type_id::create("eoi");

          start_item(tr);

          //----------------------------
          // Reset
          //----------------------------
          tr.soc_rst = 1'b1;

          //----------------------------
          // Clear External Interrupt
          //----------------------------
          tr.ext_int = 16'h0000;

          //----------------------------
          // No MMR Access
          //----------------------------
          tr.soc_mmr_write_en_i   = 1'b0;
          tr.soc_mmr_write_addr_i = 16'h0000;
          tr.soc_mmr_write_data_i = 32'h00000000;

          tr.soc_mmr_read_en_i    = 1'b0;
          tr.soc_mmr_read_addr_i  = 16'h0000;

          //----------------------------
          // Keep Global Enable
          //----------------------------
          tr.global_int_enable_valid_i = 1'b0;
          tr.global_int_enable_bit_i   = enabled_irq;

          //----------------------------
          // No ACK
          //----------------------------
          tr.soc_ack_read_valid_en = 1'b0;

          //----------------------------
          // EOI
          //----------------------------
          tr.soc_eoi_valid_i = 1'b1;
          tr.soc_eoi_id_i    = eoi_id;

          //----------------------------
          // Active Level
          //----------------------------
          tr.active_lvl_pr_i = active_level;

          //----------------------------
          // Debug
          //----------------------------
          tr.debug_mode_valid_i = 1'b0;
          tr.debug_mode_reset_i = 1'b0;
          tr.debug_ndm_reset_i  = 1'b0;

          finish_item(tr);

          //----------------------------------
          // Clear Sequence Status
          //----------------------------------

          pending_irq = 16'h0000;
          ack_done    = 1'b0;

        end

      end

            //------------------------------------------------------
      // ACTIVE LEVEL
      //------------------------------------------------------

      ACTIVE_LEVEL:
      begin

        assert(randomize(active_level));

        tr = int_seq_item::type_id::create("active_level");

        start_item(tr);

        tr.soc_rst = 1'b1;

        tr.ext_int = pending_irq;

        //----------------------------
        // No MMR Access
        //----------------------------
        tr.soc_mmr_write_en_i   = 1'b0;
        tr.soc_mmr_write_addr_i = 16'h0000;
        tr.soc_mmr_write_data_i = 32'h0000_0000;

        tr.soc_mmr_read_en_i    = 1'b0;
        tr.soc_mmr_read_addr_i  = 16'h0000;

        //----------------------------
        // Global Enable
        //----------------------------
        tr.global_int_enable_valid_i = 1'b0;
        tr.global_int_enable_bit_i   = enabled_irq;

        //----------------------------
        // ACK / EOI
        //----------------------------
        tr.soc_ack_read_valid_en = 1'b0;

        tr.soc_eoi_valid_i = 1'b0;
        tr.soc_eoi_id_i    = 8'h00;

        //----------------------------
        // Active Level
        //----------------------------
        tr.active_lvl_pr_i = active_level;

        //----------------------------
        // Debug
        //----------------------------
        tr.debug_mode_valid_i = 1'b0;
        tr.debug_mode_reset_i = 1'b0;
        tr.debug_ndm_reset_i  = 1'b0;

        finish_item(tr);

      end


            //------------------------------------------------------
      // DEBUG MODE
      //------------------------------------------------------

      DEBUG_MODE:
      begin

        tr = int_seq_item::type_id::create("debug_mode");

        start_item(tr);

        tr.soc_rst = 1'b1;

        tr.ext_int = pending_irq;

        tr.soc_mmr_write_en_i = 1'b0;
        tr.soc_mmr_read_en_i  = 1'b0;

        tr.global_int_enable_valid_i = 1'b0;
        tr.global_int_enable_bit_i   = enabled_irq;

        tr.soc_ack_read_valid_en = 1'b0;

        tr.soc_eoi_valid_i = 1'b0;
        tr.soc_eoi_id_i    = 8'h00;

        tr.active_lvl_pr_i = active_level;

        tr.debug_mode_valid_i = 1'b1;
        tr.debug_mode_reset_i = 1'b0;
        tr.debug_ndm_reset_i  = 1'b0;

        finish_item(tr);

      end

            //------------------------------------------------------
      // DEBUG RESET
      //------------------------------------------------------

      DEBUG_RESET:
      begin

        tr = int_seq_item::type_id::create("debug_reset");

        start_item(tr);

        tr.soc_rst = 1'b1;

        tr.ext_int = 16'h0000;

        tr.soc_mmr_write_en_i = 1'b0;
        tr.soc_mmr_read_en_i  = 1'b0;

        tr.global_int_enable_valid_i = 1'b0;
        tr.global_int_enable_bit_i   = enabled_irq;

        tr.soc_ack_read_valid_en = 1'b0;

        tr.soc_eoi_valid_i = 1'b0;
        tr.soc_eoi_id_i    = 8'h00;

        tr.active_lvl_pr_i = active_level;

        tr.debug_mode_valid_i = 1'b0;
        tr.debug_mode_reset_i = 1'b1;
        tr.debug_ndm_reset_i  = 1'b0;

        finish_item(tr);

      end

            //------------------------------------------------------
      // NDM RESET
      //------------------------------------------------------

      NDM_RESET:
      begin

        tr = int_seq_item::type_id::create("ndm_reset");

        start_item(tr);

        tr.soc_rst = 1'b1;

        tr.ext_int = 16'h0000;

        tr.soc_mmr_write_en_i = 1'b0;
        tr.soc_mmr_read_en_i  = 1'b0;

        tr.global_int_enable_valid_i = 1'b0;
        tr.global_int_enable_bit_i   = enabled_irq;

        tr.soc_ack_read_valid_en = 1'b0;

        tr.soc_eoi_valid_i = 1'b0;
        tr.soc_eoi_id_i    = 8'h00;

        tr.active_lvl_pr_i = active_level;

        tr.debug_mode_valid_i = 1'b0;
        tr.debug_mode_reset_i = 1'b0;
        tr.debug_ndm_reset_i  = 1'b1;

        finish_item(tr);

      end

            //------------------------------------------------------
      // IDLE
      //------------------------------------------------------

      IDLE:
      begin

        repeat($urandom_range(2,10))
        begin

          tr = int_seq_item::type_id::create("idle");

          start_item(tr);

          tr.soc_rst = 1'b1;

          tr.ext_int = pending_irq;

          tr.soc_mmr_write_en_i = 1'b0;
          tr.soc_mmr_read_en_i  = 1'b0;

          tr.global_int_enable_valid_i = 1'b0;
          tr.global_int_enable_bit_i   = enabled_irq;

          tr.soc_ack_read_valid_en = 1'b0;

          tr.soc_eoi_valid_i = 1'b0;
          tr.soc_eoi_id_i    = 8'h00;

          tr.active_lvl_pr_i = active_level;

          tr.debug_mode_valid_i = 1'b0;
          tr.debug_mode_reset_i = 1'b0;
          tr.debug_ndm_reset_i  = 1'b0;

          finish_item(tr);

        end

      end

       endcase

  end // repeat

  `uvm_info(get_type_name(),
            "========== TC029 RANDOM MIXED FUNCTIONAL TEST COMPLETED ==========",
            UVM_LOW)

endtask 

endclass 




