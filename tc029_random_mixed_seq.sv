

class tc029_random_mixed_seq extends uvm_sequence #(int_seq_item);

  `uvm_object_utils(tc029_random_mixed_seq)

  //------------------------------------------------------------
  // Transaction Handle
  //------------------------------------------------------------
  int_seq_item tr;

  int last_irq_id;  //read purpose


  //------------------------------------------------------------
  // Random Fields
  //------------------------------------------------------------
  rand int unsigned irq_id;

  rand bit [7:0] irq_ctl;

  rand bit [15:0] global_mask;

  rand bit [15:0] ext_mask;

  rand bit [7:0] active_level;

  rand bit [7:0] eoi_id;

  //------------------------------------------------------------
  // Constraints
  //------------------------------------------------------------

  constraint c_irq_id
  {
      irq_id inside {[0:15]};
  }

  constraint c_irq_ctl
  {
      irq_ctl[1:0] == 2'b00;
  }

  constraint c_active_level
  {
      active_level[1:0] == 2'b00;
  }

  //------------------------------------------------------------
  // Local Reference Model
  //------------------------------------------------------------

  bit [31:0] irq_cfg[16];

  bit [15:0] global_enable;

  bit [15:0] ext_pending;

  bit [7:0] current_active_level;

  bit [7:0] last_ack_id;

  bit irq_active;

  //------------------------------------------------------------
  // Statistics
  //------------------------------------------------------------

  int cfg_count;

  int enable_count;

  int irq_count;

  int ack_count;

  int eoi_count;

  int idle_count;

  int mmr_read_count;

  int debug_count;

  //------------------------------------------------------------
  // Constructor
  //------------------------------------------------------------

  function new(string name="tc029_random_mixed_seq");

      super.new(name);

  endfunction


    //------------------------------------------------------------
  // Body
  //------------------------------------------------------------
  virtual task body();

    string summary;
  

    super.body();

    //----------------------------------------------------------
    // Initialize local reference model
    //----------------------------------------------------------
    foreach (irq_cfg[i])
      irq_cfg[i] = 32'h0000_0000;

    global_enable       = 16'h0000;
    ext_pending         = 16'h0000;
    current_active_level= 8'h00;
    last_ack_id         = 8'h00;
    irq_active          = 1'b0;

    cfg_count    = 0;
    enable_count = 0;
    irq_count    = 0;
    ack_count    = 0;
    eoi_count    = 0;
    idle_count   = 0;
    mmr_read_count = 0;
    debug_count = 0;


    //----------------------------------------------------------
    // Reset Transaction
    //----------------------------------------------------------
    tr = int_seq_item::type_id::create("reset");

    start_item(tr);

    tr.soc_rst = 1'b0;

    tr.ext_int = 16'h0000;

    tr.soc_mmr_write_en_i   = 1'b0;
    tr.soc_mmr_write_addr_i = 16'h0000;
    tr.soc_mmr_write_data_i = 32'h00000000;

    tr.soc_mmr_read_en_i    = 1'b0;
    tr.soc_mmr_read_addr_i  = 16'h0000;

    tr.global_int_enable_valid_i = 1'b0;
    tr.global_int_enable_bit_i   = 16'h0000;

    tr.soc_ack_read_valid_en = 1'b0;

    tr.soc_eoi_valid_i = 1'b0;
    tr.soc_eoi_id_i    = 8'h00;

    tr.active_lvl_pr_i = 8'h00;

    tr.debug_mode_valid_i = 1'b0;

    finish_item(tr);

    //----------------------------------------------------------
    // Release Reset
    //----------------------------------------------------------
    tr = int_seq_item::type_id::create("release_reset");

    start_item(tr);

    tr.soc_rst = 1'b1;

    tr.ext_int = 16'h0000;

    tr.soc_mmr_write_en_i   = 1'b0;
    tr.soc_mmr_write_addr_i = 16'h0000;
    tr.soc_mmr_write_data_i = 32'h00000000;

    tr.soc_mmr_read_en_i    = 1'b0;
    tr.soc_mmr_read_addr_i  = 16'h0000;

    tr.global_int_enable_valid_i = 1'b0;
    tr.global_int_enable_bit_i   = 16'h0000;

    tr.soc_ack_read_valid_en = 1'b0;

    tr.soc_eoi_valid_i = 1'b0;
    tr.soc_eoi_id_i    = 8'h00;

    tr.active_lvl_pr_i = 8'h00;

    tr.debug_mode_valid_i = 1'b0;

    finish_item(tr);

repeat (1)
  begin

    random_irq_cfg();

    random_mmr_read();

    random_global_enable();

    random_interrupt_assert();

    random_eoi();

    random_ack();

    random_active_level();

    idle_cycle();

    random_debug_mode();

  end

  `uvm_info("TC029","TC029 COMPLETED",UVM_LOW)




summary = $sformatf(
"\n================ Random Summary ================\
\nIRQ CFG        : %0d\
\nGLOBAL EN      : %0d\
\nIRQ ASSERT     : %0d\
\nACK            : %0d\
\nEOI            : %0d\
\nIDLE           : %0d\
\nMMR READ       : %0d\
\nDEBUG MODE     : %0d\
\n==============================================",
cfg_count,
enable_count,
irq_count,
ack_count,
eoi_count,
idle_count,
mmr_read_count,
debug_count
);
        
    `uvm_info("TC029", summary, UVM_LOW)

  endtask

  //------------------------------------------------------------
// Drive Default Transaction
//------------------------------------------------------------
task drive_default();

  tr = int_seq_item::type_id::create("tr");

  start_item(tr);

  tr.soc_rst = 1'b1;

  //--------------------------------------------------------
  // Current External Interrupt State
  //--------------------------------------------------------
  tr.ext_int = ext_pending;

  //--------------------------------------------------------
  // Default MMR
  //--------------------------------------------------------
  tr.soc_mmr_write_en_i   = 1'b0;
  tr.soc_mmr_write_addr_i = 16'h0000;
  tr.soc_mmr_write_data_i = 32'h00000000;

  tr.soc_mmr_read_en_i    = 1'b0;
  tr.soc_mmr_read_addr_i  = 16'h0000;

  //--------------------------------------------------------
  // Global Enable
  //--------------------------------------------------------
  tr.global_int_enable_valid_i = 1'b0;
  tr.global_int_enable_bit_i   = global_enable;

  //--------------------------------------------------------
  // ACK
  //--------------------------------------------------------
  tr.soc_ack_read_valid_en = 1'b0;

  //--------------------------------------------------------
  // EOI
  //--------------------------------------------------------
  tr.soc_eoi_valid_i = 1'b0;
  tr.soc_eoi_id_i    = 8'h00;

  //--------------------------------------------------------
  // Active Level
  //--------------------------------------------------------
  tr.active_lvl_pr_i = current_active_level;

  //--------------------------------------------------------
  // Debug
  //--------------------------------------------------------
  tr.debug_mode_valid_i = 1'b0;


endtask

//------------------------------------------------------------
// Random IRQ Configuration
//------------------------------------------------------------
task random_irq_cfg();

  drive_default();

  irq_id = $urandom_range(0,15);

  last_irq_id = irq_id;

  irq_ctl[7:5] = $urandom_range(0,7);

  irq_ctl[4:2] = $urandom_range(0,7);

  irq_ctl[1:0] = 2'b00;

  irq_cfg[irq_id] = {24'h0,irq_ctl};

  tr.soc_mmr_write_en_i   = 1'b1;

  tr.soc_mmr_write_addr_i = 16'h1003 + (irq_id*4);

  tr.soc_mmr_write_data_i = irq_cfg[irq_id];

  cfg_count++;

  `uvm_info("TC029_CFG",
  $sformatf(
  "IRQ%0d programmed DATA=0x%08h",
  irq_id,
  irq_cfg[irq_id]),
  UVM_MEDIUM)

  finish_item(tr);

endtask

//------------------------------------------------------------
// Random Global Enable
//------------------------------------------------------------
task random_global_enable();

  drive_default();

  global_enable = $urandom;

  tr.global_int_enable_valid_i = 1'b1;
  tr.global_int_enable_bit_i   = global_enable;

  enable_count++;

  `uvm_info("TC029_GLOBAL",
  $sformatf("GLOBAL_ENABLE = %04h",
            global_enable),
  UVM_MEDIUM)

  finish_item(tr);

endtask

//------------------------------------------------------------
// Random External Interrupts
//------------------------------------------------------------
task random_interrupt_assert();

  drive_default();

  //----------------------------------------------------------
  // Random pending interrupt bitmap
  //----------------------------------------------------------

  ext_pending = $urandom;

  tr.ext_int = ext_pending;

  irq_count++;

    irq_active = 1'b1;     

  `uvm_info("TC029_IRQ",
  $sformatf("EXT_INT = %04h",
            ext_pending),
  UVM_MEDIUM)

  finish_item(tr);

endtask

task random_ack();

  if(!irq_active)
    return;

  drive_default();

  tr.soc_ack_read_valid_en = 1'b1;

  ack_count++;

  finish_item(tr);

endtask


task random_eoi();

  if(!irq_active)
    return;

  drive_default();

  tr.soc_eoi_valid_i = 1'b1;
  tr.soc_eoi_id_i    = last_ack_id;

  irq_active = 0;

  current_active_level = 8'h00;

  eoi_count++;

  finish_item(tr);

endtask

//------------------------------------------------------------
// Random Active Level
//------------------------------------------------------------
task random_active_level();

  drive_default();

  active_level[7:5] = $urandom_range(0,7);
  active_level[4:2] = $urandom_range(0,7);
  active_level[1:0] = 2'b00;

  current_active_level = active_level;

  tr.active_lvl_pr_i = current_active_level;

  `uvm_info("TC029_ACTIVE",
    $sformatf("ACTIVE_LEVEL = 0x%02h",
              current_active_level),
    UVM_MEDIUM)

  finish_item(tr);

endtask

//------------------------------------------------------------
// Idle Cycle
//------------------------------------------------------------
task idle_cycle();

  drive_default();

  idle_count++;

  finish_item(tr);

endtask


//------------------------------------------------------------
// Random MMR Read
//------------------------------------------------------------
task random_mmr_read();

    drive_default();

    irq_id = last_irq_id;

    tr.soc_mmr_read_en_i   = 1'b1;

    tr.soc_mmr_read_addr_i = 16'h1003 + (irq_id*4);

    mmr_read_count++;

    `uvm_info("TC029_MMR_READ",
      $sformatf("MMR READ IRQ%0d ADDR=0x%04h",
                irq_id,
                tr.soc_mmr_read_addr_i),
      UVM_MEDIUM)

    finish_item(tr);

endtask

//------------------------------------------------------------
// Random Debug Mode
//------------------------------------------------------------
task random_debug_mode();

  drive_default();

  //----------------------------------------------------------
  // Randomly choose one debug operation
  //----------------------------------------------------------
  case($urandom_range(0,3))

    //--------------------------------------------------------
    // Normal Mode
    //--------------------------------------------------------
    0:
    begin
      tr.debug_mode_valid_i = 1'b0;
      tr.debug_mode_reset_i = 1'b0;
      tr.debug_ndm_reset_i  = 1'b0;
    end

    //--------------------------------------------------------
    // Enter Debug Mode
    //--------------------------------------------------------
    1:
    begin
      tr.debug_mode_valid_i = 1'b1;
      tr.debug_mode_reset_i = 1'b0;
      tr.debug_ndm_reset_i  = 1'b0;
    end

    //--------------------------------------------------------
    // Debug Reset
    //--------------------------------------------------------
    2:
    begin
      tr.debug_mode_valid_i = 1'b1;
      tr.debug_mode_reset_i = 1'b1;
      tr.debug_ndm_reset_i  = 1'b0;
    end

    //--------------------------------------------------------
    // NDM Reset
    //--------------------------------------------------------
    3:
    begin
      tr.debug_mode_valid_i = 1'b1;
      tr.debug_mode_reset_i = 1'b0;
      tr.debug_ndm_reset_i  = 1'b1;
    end

  endcase

  debug_count++;

  finish_item(tr);

endtask


endclass
