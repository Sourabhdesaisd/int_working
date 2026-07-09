class int_driver extends uvm_driver #(int_seq_item);

  `uvm_component_utils(int_driver)

  virtual intf vif;

  function new(string name = "int_driver", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual intf)::get(this, "", "vif", vif)) begin
      `uvm_fatal("DRV", "Virtual interface not found")
    end
  endfunction


  // ============================================================
  // Drive idle values
  // soc_rst is active-low:
  // 0 = reset active
  // 1 = normal operation
  // ============================================================
  task drive_idle();

    vif.soc_rst <= 1'b1;

    vif.ext_int <= 16'h0000;

    vif.soc_mmr_write_en_i   <= 1'b0;
    vif.soc_mmr_write_addr_i <= 16'h0000;
    vif.soc_mmr_write_data_i <= 32'h0000_0000;

    vif.soc_mmr_read_en_i    <= 1'b0;
    vif.soc_mmr_read_addr_i  <= 16'h0000;

    vif.soc_ack_read_valid_en <= 1'b0;

    vif.soc_eoi_valid_i <= 1'b0;
    vif.soc_eoi_id_i    <= 8'h00;

    vif.active_lvl_pr_i <= 8'h00;

    vif.global_int_enable_bit_i   <= 16'h0000;
    vif.global_int_enable_valid_i <= 1'b0;

    vif.debug_mode_valid_i <= 1'b0;
    vif.debug_mode_reset_i <= 1'b0;
    vif.debug_ndm_reset_i  <= 1'b0;

  endtask


  // ============================================================
  // Reset transaction
  // ============================================================
  task drive_reset();

    `uvm_info("DRV", "RESET transaction received", UVM_LOW)

    drive_idle();

    @(posedge vif.soc_clk);

    vif.soc_rst <= 1'b0;

    repeat (5) @(posedge vif.soc_clk);

    vif.soc_rst <= 1'b1;

    repeat (3) @(posedge vif.soc_clk);

    `uvm_info("DRV", "RESET done", UVM_LOW)

  endtask


  // ============================================================
  // Normal transaction
  // ============================================================
  task drive_normal(int_seq_item tr);

    vif.soc_rst <= 1'b1;

    vif.ext_int <= tr.ext_int[15:0];

    vif.soc_mmr_write_en_i   <= tr.soc_mmr_write_en_i;
    vif.soc_mmr_write_addr_i <= tr.soc_mmr_write_addr_i;
    vif.soc_mmr_write_data_i <= tr.soc_mmr_write_data_i;

    vif.soc_mmr_read_en_i    <= tr.soc_mmr_read_en_i;
    vif.soc_mmr_read_addr_i  <= tr.soc_mmr_read_addr_i;

    vif.soc_ack_read_valid_en <= tr.soc_ack_read_valid_en;

    vif.soc_eoi_valid_i <= tr.soc_eoi_valid_i;
    vif.soc_eoi_id_i    <= tr.soc_eoi_id_i;

    vif.active_lvl_pr_i <= tr.active_lvl_pr_i;

    vif.global_int_enable_bit_i   <= tr.global_int_enable_bit_i[15:0];
    vif.global_int_enable_valid_i <= tr.global_int_enable_valid_i;

    vif.debug_mode_valid_i <= tr.debug_mode_valid_i;
    vif.debug_mode_reset_i <= tr.debug_mode_reset_i;
    vif.debug_ndm_reset_i  <= tr.debug_ndm_reset_i;

    @(posedge vif.soc_clk);

    // one-cycle pulse controls
    vif.soc_mmr_write_en_i        <= 1'b0;
    vif.soc_mmr_read_en_i         <= 1'b0;
    vif.global_int_enable_valid_i <= 1'b0;
    vif.soc_ack_read_valid_en     <= 1'b0;
    vif.soc_eoi_valid_i           <= 1'b0;

  endtask


  // ============================================================
  // Run phase
  // ============================================================
  task run_phase(uvm_phase phase);

    `uvm_info("DRV", "Driver run_phase started", UVM_LOW)

    drive_idle();

    forever begin

      seq_item_port.get_next_item(req);

      if (req.soc_rst == 1'b0) begin
        drive_reset();
      end
      else begin
        `uvm_info("DRV", "Normal transaction received", UVM_LOW)
        drive_normal(req);
      end

      seq_item_port.item_done();

    end

  endtask

endclass
