class int_monitor extends uvm_monitor;

  `uvm_component_utils(int_monitor)

  localparam int NUM_IRQ = 16;
  localparam bit [15:0] IRQ_CTL_BASE = 16'h1003;

  virtual intf vif;
  uvm_analysis_port #(int_seq_item) mon_ap;

  bit [31:0]  irq_ctl_mirror [NUM_IRQ];
  bit [15:0] global_en_mirror;

  bit       ack_pending;
  bit [7:0] pend_exp_ack_id;
  bit [7:0] pend_exp_lvl_pr;

  function new(string name = "int_monitor", uvm_component parent);
    super.new(name, parent);
    mon_ap = new("mon_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db #(virtual intf)::get(this, "", "vif", vif)) begin
      `uvm_fatal("MON", "virtual interface not found")
    end

    reset_model();
  endfunction

  function void reset_model();

    foreach (irq_ctl_mirror[i]) begin
      irq_ctl_mirror[i] = 32'h0000_0000;
    end

    global_en_mirror = 16'h0000;

    ack_pending     = 1'b0;
    pend_exp_ack_id = 8'h00;
    pend_exp_lvl_pr = 8'h00;

  endfunction

  function automatic int get_irq_id_from_ctl_addr(bit [15:0] addr);
    int id;

    if (addr < IRQ_CTL_BASE) begin
      return -1;
    end

    if (((addr - IRQ_CTL_BASE) % 4) != 0) begin
      return -1;
    end

    id = (addr - IRQ_CTL_BASE) / 4;

    if ((id < 0) || (id >= NUM_IRQ)) begin
      return -1;
    end

    return id;
  endfunction

  function automatic bit higher_priority(
    bit [7:0] cur_ctl,
    int       cur_id,
    bit [7:0] best_ctl,
    int       best_id
  );

    if (cur_ctl[7:5] > best_ctl[7:5]) begin
      return 1'b1;
    end

    if ((cur_ctl[7:5] == best_ctl[7:5]) &&
        (cur_ctl[4:2] >  best_ctl[4:2])) begin
      return 1'b1;
    end

    if ((cur_ctl[7:5] == best_ctl[7:5]) &&
        (cur_ctl[4:2] == best_ctl[4:2]) &&
        (cur_id > best_id)) begin
      return 1'b1;
    end

    return 1'b0;
  endfunction

  task run_phase(uvm_phase phase);
    int_seq_item tr;

    forever begin
      @(posedge vif.soc_clk);
      #1step;

      tr = int_seq_item::type_id::create("tr", this);

      sample_dut(tr);

      if (vif.soc_rst == 1'b0) begin
        reset_model();

        tr.exp_valid          = 1'b0;
        tr.exp_irq_req        = 1'b0;
        tr.exp_ack_id         = 8'h00;
        tr.exp_highest_lvl_pr = 8'h00;

        tr.exp_mmr_read_valid = 1'b0;
        tr.exp_mmr_read_data  = 32'h0000_0000;
      end
      else begin
        update_mirror(tr);
        predict_expected(tr);
        predict_mmr_read(tr);
      end

      mon_ap.write(tr);
    end
  endtask

  task sample_dut(int_seq_item tr);

    tr.soc_rst = vif.soc_rst;

    tr.interrupt_request_o      = vif.interrupt_request_o;
    tr.soc_ack_int_id_o         = vif.soc_ack_int_id_o;
    tr.highest_pending_lvl_pr_o = vif.highest_pending_lvl_pr_o;
    tr.soc_mmr_read_data_o      = vif.soc_mmr_read_data_o;

    tr.ext_int = vif.ext_int[15:0];

    tr.soc_mmr_write_en_i   = vif.soc_mmr_write_en_i;
    tr.soc_mmr_write_addr_i = vif.soc_mmr_write_addr_i;
    tr.soc_mmr_write_data_i = vif.soc_mmr_write_data_i;

    tr.soc_mmr_read_en_i    = vif.soc_mmr_read_en_i;
    tr.soc_mmr_read_addr_i  = vif.soc_mmr_read_addr_i;

    tr.soc_ack_read_valid_en = vif.soc_ack_read_valid_en;

    tr.soc_eoi_valid_i = vif.soc_eoi_valid_i;
    tr.soc_eoi_id_i    = vif.soc_eoi_id_i;

    tr.active_lvl_pr_i = vif.active_lvl_pr_i;

    tr.global_int_enable_bit_i   = vif.global_int_enable_bit_i[15:0];
    tr.global_int_enable_valid_i = vif.global_int_enable_valid_i;

    tr.debug_mode_valid_i = vif.debug_mode_valid_i;
    tr.debug_mode_reset_i = vif.debug_mode_reset_i;
    tr.debug_ndm_reset_i  = vif.debug_ndm_reset_i;

    `uvm_info("RAW_DUT",
$sformatf(
"ext=%0h irq_req=%0b highest_lvl=%0h ack=%0h",
tr.ext_int,
tr.interrupt_request_o,
tr.highest_pending_lvl_pr_o,
tr.soc_ack_int_id_o),
UVM_LOW)

 
  endtask

  task update_mirror(int_seq_item tr);
    int irq_id;

    if (tr.soc_mmr_write_en_i) begin

      irq_id = get_irq_id_from_ctl_addr(tr.soc_mmr_write_addr_i);

      if (irq_id != -1) begin
        irq_ctl_mirror[irq_id] = tr.soc_mmr_write_data_i;

        `uvm_info("MON_MIRROR",
                    $sformatf("IRQ%0d CTL mirror updated addr=0x%0h data=0x%08h",
                    irq_id,
                    tr.soc_mmr_write_addr_i,
                    irq_ctl_mirror[irq_id]),
          UVM_MEDIUM)
      end
    end

    if (tr.global_int_enable_valid_i) begin
      global_en_mirror = tr.global_int_enable_bit_i[15:0];
      

      `uvm_info("GLOBAL_UPDATE",$sformatf("Mirror Updated -> %04h",global_en_mirror),UVM_LOW)
    end
      
  endtask

  task predict_expected(int_seq_item tr);

    int       best_id;
    bit       best_found;
    bit [7:0] best_ctl;

    best_id    = 0;
    best_found = 1'b0;
    best_ctl   = 8'h00;

    tr.exp_valid          = 1'b0;
    tr.exp_irq_req        = 1'b0;
    tr.exp_ack_id         = 8'h00;
    tr.exp_highest_lvl_pr = 8'h00;

    for (int i = 0; i < NUM_IRQ; i++) begin

      if (tr.ext_int[i] && global_en_mirror[i]) begin

        if (!best_found) begin
          best_found = 1'b1;
          best_id    = i;
          best_ctl   = irq_ctl_mirror[i][7:0];
        end
        else if (higher_priority(irq_ctl_mirror[i][7:0], i, best_ctl, best_id)) begin
          best_id  = i;
          best_ctl = irq_ctl_mirror[i][7:0];
        end

      end
    end

    //------------------------------------------------------------
// Debug prediction
//------------------------------------------------------------
`uvm_info("MON_DEBUG",
$sformatf(
"best_found=%0b best_id=%0d best_ctl=%02h active_lvl=%02h active_level_only=%0d best_level=%0d ext=%04h en=%04h",
best_found,
best_id,
best_ctl,
tr.active_lvl_pr_i,
tr.active_lvl_pr_i[7:5],
best_ctl[7:5],
tr.ext_int,
global_en_mirror),
UVM_LOW)


/*`uvm_info("MON_SCAN",$sformatf("-------------------------------------------"),UVM_LOW)
for (int j=0;j<NUM_IRQ;j++) begin
  `uvm_info("MON_SCAN",  $sformatf(  "IRQ=%0d EXT=%0b EN=%0b CTL=%02h",  j,  tr.ext_int[j],  global_en_mirror[j],  irq_ctl_mirror[j][7:0]),
  UVM_LOW)

end*/

    // RTL compares only LEVEL bits [7:5]
if (best_found &&
    (best_ctl[7:5] > tr.active_lvl_pr_i[7:5])) begin

    tr.exp_irq_req        = 1'b1;
    tr.exp_ack_id         = 8'h10 + best_id[7:0];
    tr.exp_highest_lvl_pr = best_ctl;

end

    tr.exp_valid = 1'b0;

    if (tr.soc_ack_read_valid_en &&
        tr.exp_irq_req &&
        tr.soc_ack_int_id_o != 8'h00) begin

      tr.exp_valid = 1'b1;

    end
    else if (tr.soc_ack_read_valid_en &&
             tr.exp_irq_req &&
             tr.soc_ack_int_id_o == 8'h00) begin

      ack_pending     = 1'b1;
      pend_exp_ack_id = tr.exp_ack_id;
      pend_exp_lvl_pr = tr.exp_highest_lvl_pr;

    end
    else if (ack_pending &&
             tr.soc_ack_int_id_o != 8'h00) begin

      tr.exp_valid          = 1'b1;
      tr.exp_ack_id         = pend_exp_ack_id;
      tr.exp_highest_lvl_pr = pend_exp_lvl_pr;

      ack_pending = 1'b0;

    end

    `uvm_info("MON_PREDICT",
      $sformatf("ext=0x%0h en=0x%0h best_id=%0d best_ctl=0x%0h active_lvl=0x%0h | exp_irq=%0b exp_valid=%0b exp_ack=0x%0h exp_lvl=0x%0h | act_irq=%0b act_ack=0x%0h act_lvl=0x%0h",
                tr.ext_int,
                global_en_mirror,
                best_id,
                best_ctl,
                tr.active_lvl_pr_i,
                tr.exp_irq_req,
                tr.exp_valid,
                tr.exp_ack_id,
                tr.exp_highest_lvl_pr,
                tr.interrupt_request_o,
                tr.soc_ack_int_id_o,
                tr.highest_pending_lvl_pr_o),
      UVM_MEDIUM)


  //    `uvm_info("GLOBAL_EN",$sformatf("valid=%0b input=%04h mirror=%04h",tr.global_int_enable_valid_i,tr.global_int_enable_bit_i,global_en_mirror),UVM_LOW)


    endtask

  task predict_mmr_read(int_seq_item tr);
    int irq_id;

    tr.exp_mmr_read_valid = 1'b0;
    tr.exp_mmr_read_data  = 32'h0000_0000;

    if (tr.soc_mmr_read_en_i) begin

      irq_id = get_irq_id_from_ctl_addr(tr.soc_mmr_read_addr_i);

      if (irq_id != -1) begin
        tr.exp_mmr_read_valid = 1'b1;
        tr.exp_mmr_read_data = irq_ctl_mirror[irq_id];
      end

    end

  endtask

endclass

/*class int_monitor extends uvm_monitor;

  `uvm_component_utils(int_monitor)

  // ============================================================
  // 16 interrupt configuration
  // ============================================================
  localparam int NUM_IRQ = 16;
  localparam bit [15:0] IRQ_CTL_BASE = 16'h1003;

  virtual intf vif;
  uvm_analysis_port #(int_seq_item) mon_ap;

  // Golden/reference model mirrors
  bit [7:0]  irq_ctl_mirror [NUM_IRQ];
  bit [15:0] global_en_mirror;

  // ACK delay handling
  bit       ack_pending;
  bit [7:0] pend_exp_ack_id;
  bit [7:0] pend_exp_lvl_pr;

  function new(string name = "int_monitor", uvm_component parent);
    super.new(name, parent);
    mon_ap = new("mon_ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db #(virtual intf)::get(this, "", "vif", vif)) begin
      `uvm_fatal("MON", "virtual interface not found")
    end

    reset_model();
  endfunction


  // ============================================================
  // Reset reference model
  // ============================================================
  function void reset_model();

    foreach (irq_ctl_mirror[i]) begin
      irq_ctl_mirror[i] = 8'h00;
    end

    global_en_mirror = 16'h0000;

    ack_pending     = 1'b0;
    pend_exp_ack_id = 8'h00;
    pend_exp_lvl_pr = 8'h00;

  endfunction


  // ============================================================
  // Convert IRQ control register address to IRQ ID
  //
  // irq0  address = 16'h1003
  // irq1  address = 16'h1007
  // irq2  address = 16'h100B
  // ...
  // irq15 address = 16'h103F
  // ============================================================
  function automatic int get_irq_id_from_ctl_addr(bit [15:0] addr);
    int id;

    if (addr < IRQ_CTL_BASE) begin
      return -1;
    end

    if (((addr - IRQ_CTL_BASE) % 4) != 0) begin
      return -1;
    end

    id = (addr - IRQ_CTL_BASE) / 4;

    if ((id < 0) || (id >= NUM_IRQ)) begin
      return -1;
    end

    return id;
  endfunction


  // ============================================================
  // Priority comparison
  //
  // Assumption based on your existing model:
  // level    = irq_ctl[7:5]
  // priority = irq_ctl[4:2]
  //
  // Higher level wins.
  // If level same, higher priority wins.
  // If both same, higher interrupt ID wins.
  // ============================================================
  function automatic bit higher_priority(
    bit [7:0] cur_ctl,
    int       cur_id,
    bit [7:0] best_ctl,
    int       best_id
  );

    if (cur_ctl[7:5] > best_ctl[7:5]) begin
      return 1'b1;
    end

    if ((cur_ctl[7:5] == best_ctl[7:5]) &&
        (cur_ctl[4:2] >  best_ctl[4:2])) begin
      return 1'b1;
    end

    if ((cur_ctl[7:5] == best_ctl[7:5]) &&
        (cur_ctl[4:2] == best_ctl[4:2]) &&
        (cur_id > best_id)) begin
      return 1'b1;
    end

    return 1'b0;
  endfunction


  // ============================================================
  // Monitor run phase
  // ============================================================
  task run_phase(uvm_phase phase);
    int_seq_item tr;

    forever begin
      @(posedge vif.soc_clk);
      #1step;

      tr = int_seq_item::type_id::create("tr", this);

      sample_dut(tr);

      if (vif.soc_rst == 1'b0) begin
        reset_model();

        tr.exp_valid          = 1'b0;
        tr.exp_irq_req        = 1'b0;
        tr.exp_ack_id         = 8'h00;
        tr.exp_highest_lvl_pr = 8'h00;
      end
      else begin
        update_mirror(tr);
        predict_expected(tr);
      end

      mon_ap.write(tr);
    end
  endtask


  // ============================================================
  // Sample DUT interface signals
  // ============================================================
  task sample_dut(int_seq_item tr);

    tr.soc_rst = vif.soc_rst;

    // DUT outputs
    tr.interrupt_request_o      = vif.interrupt_request_o;
    tr.soc_ack_int_id_o         = vif.soc_ack_int_id_o;
    tr.highest_pending_lvl_pr_o = vif.highest_pending_lvl_pr_o;
    tr.soc_mmr_read_data_o      = vif.soc_mmr_read_data_o;

    // DUT inputs
    tr.ext_int = vif.ext_int[15:0];

    tr.soc_mmr_write_en_i   = vif.soc_mmr_write_en_i;
    tr.soc_mmr_write_addr_i = vif.soc_mmr_write_addr_i;
    tr.soc_mmr_write_data_i = vif.soc_mmr_write_data_i;

    tr.soc_mmr_read_en_i    = vif.soc_mmr_read_en_i;
    tr.soc_mmr_read_addr_i  = vif.soc_mmr_read_addr_i;

    tr.soc_ack_read_valid_en = vif.soc_ack_read_valid_en;

    tr.soc_eoi_valid_i = vif.soc_eoi_valid_i;
    tr.soc_eoi_id_i    = vif.soc_eoi_id_i;

    tr.active_lvl_pr_i = vif.active_lvl_pr_i;

    tr.global_int_enable_bit_i   = vif.global_int_enable_bit_i[15:0];
    tr.global_int_enable_valid_i = vif.global_int_enable_valid_i;

    tr.debug_mode_valid_i = vif.debug_mode_valid_i;
    tr.debug_mode_reset_i = vif.debug_mode_reset_i;
    tr.debug_ndm_reset_i  = vif.debug_ndm_reset_i;

  endtask


  // ============================================================
  // Update golden model mirror from programmed MMR writes
  // ============================================================
  task update_mirror(int_seq_item tr);
    int irq_id;

    if (tr.soc_mmr_write_en_i) begin

      irq_id = get_irq_id_from_ctl_addr(tr.soc_mmr_write_addr_i);

      if (irq_id != -1) begin
        irq_ctl_mirror[irq_id] = tr.soc_mmr_write_data_i[7:0];

        `uvm_info("MON_MIRROR",
          $sformatf("IRQ%0d CTL mirror updated addr=0x%0h data=0x%0h",
                    irq_id,
                    tr.soc_mmr_write_addr_i,
                    irq_ctl_mirror[irq_id]),
          UVM_MEDIUM)
      end
    end

    if (tr.global_int_enable_valid_i) begin
      global_en_mirror = tr.global_int_enable_bit_i[15:0];

      `uvm_info("MON_MIRROR",
        $sformatf("Global enable mirror updated = 0x%0h", global_en_mirror),
        UVM_MEDIUM)
    end

  endtask


  // ============================================================
  // Predict expected interrupt request, ACK ID, and level-priority
  // ============================================================
  task predict_expected(int_seq_item tr);

    int       best_id;
    bit       best_found;
    bit [7:0] best_ctl;

    best_id    = 0;
    best_found = 1'b0;
    best_ctl   = 8'h00;

    tr.exp_valid          = 1'b0;
    tr.exp_irq_req        = 1'b0;
    tr.exp_ack_id         = 8'h00;
    tr.exp_highest_lvl_pr = 8'h00;

    // ------------------------------------------------------------
    // Find highest valid pending interrupt among 16 IRQs
    // active condition:
    //   external interrupt asserted AND global enable bit set
    // ------------------------------------------------------------
    for (int i = 0; i < NUM_IRQ; i++) begin

      if (tr.ext_int[i] && global_en_mirror[i]) begin

        if (!best_found) begin
          best_found = 1'b1;
          best_id    = i;
          best_ctl   = irq_ctl_mirror[i];
        end
        else if (higher_priority(irq_ctl_mirror[i], i, best_ctl, best_id)) begin
          best_id  = i;
          best_ctl = irq_ctl_mirror[i];
        end

      end
    end

    // ------------------------------------------------------------
    // Interrupt request expected only when selected interrupt
    // level-priority is greater than active_lvl_pr_i
    // ------------------------------------------------------------
    if (best_found && (best_ctl > tr.active_lvl_pr_i)) begin

        `uvm_info("IRQ_REASON",
$sformatf(
"IRQ asserted because best_level=%0d active_level=%0d",
best_ctl[7:5],
tr.active_lvl_pr_i[7:5]),
UVM_LOW)


      tr.exp_irq_req        = 1'b1;
      tr.exp_ack_id         = 8'h10 + best_id[7:0];
      tr.exp_highest_lvl_pr = best_ctl;

    end

    // ------------------------------------------------------------
    // ACK compare timing
    //
    // Case 1:
    // ACK read and ACK output valid in same cycle.
    //
    // Case 2:
    // ACK read seen, but DUT ACK output is not ready.
    // Store expected ID and wait.
    //
    // Case 3:
    // Pending ACK compare becomes valid later.
    // ------------------------------------------------------------
    tr.exp_valid = 1'b0;

    if (tr.soc_ack_read_valid_en &&
        tr.exp_irq_req &&
        tr.soc_ack_int_id_o != 8'h00) begin

      tr.exp_valid = 1'b1;

    end
    else if (tr.soc_ack_read_valid_en &&
             tr.exp_irq_req &&
             tr.soc_ack_int_id_o == 8'h00) begin

      ack_pending     = 1'b1;
      pend_exp_ack_id = tr.exp_ack_id;
      pend_exp_lvl_pr = tr.exp_highest_lvl_pr;

    end
    else if (ack_pending &&
             tr.soc_ack_int_id_o != 8'h00) begin

      tr.exp_valid          = 1'b1;
      tr.exp_ack_id         = pend_exp_ack_id;
      tr.exp_highest_lvl_pr = pend_exp_lvl_pr;

      ack_pending = 1'b0;

    end

    `uvm_info("MON_PREDICT",
      $sformatf("ext=0x%0h en=0x%0h best_id=%0d best_ctl=0x%0h active_lvl=0x%0h | exp_irq=%0b exp_valid=%0b exp_ack=0x%0h exp_lvl=0x%0h | act_irq=%0b act_ack=0x%0h act_lvl=0x%0h",
                tr.ext_int,
                global_en_mirror,
                best_id,
                best_ctl,
                tr.active_lvl_pr_i,
                tr.exp_irq_req,
                tr.exp_valid,
                tr.exp_ack_id,
                tr.exp_highest_lvl_pr,
                tr.interrupt_request_o,
                tr.soc_ack_int_id_o,
                tr.highest_pending_lvl_pr_o),
      UVM_MEDIUM)

  endtask

endclass  */
