class int_coverage extends uvm_subscriber #(int_seq_item);

  `uvm_component_utils(int_coverage)

  // ============================================================
  // 16 interrupt configuration
  // ============================================================
  localparam int NUM_IRQ = 16;

  int_seq_item tr;

  bit        cov_reset;
  bit        cov_irq_req;
  bit        cov_ack_valid;
  bit        cov_ack_output_valid;
  bit        cov_eoi_valid;

  bit [7:0]  cov_ack_id;
  bit [7:0]  cov_exp_ack_id;

  bit [15:0] cov_ext_int;
  bit [15:0] cov_int_en;

  bit [7:0]  cov_highest_lvl_pr;
  bit [7:0]  cov_active_lvl_pr;

  int        cov_active_irq_count;
  int        cov_ack_irq_num;
  int        cov_exp_ack_irq_num;

  bit        cov_wr_en;
  bit        cov_rd_en;
  bit [15:0] cov_wr_addr;
  bit [15:0] cov_rd_addr;
  bit [31:0] cov_wr_data;
  bit [7:0]  cov_eoi_id;
  bit        cov_global_en_valid;

  // ============================================================
  // Coverage group
  // ============================================================
  covergroup zic_cg;

    option.per_instance = 1;

    cp_reset : coverpoint cov_reset {
      bins reset_active   = {0};
      bins reset_inactive = {1};
    }

    cp_irq_req : coverpoint cov_irq_req {
      bins irq_low  = {0};
      bins irq_high = {1};
    }

    cp_ack_valid : coverpoint cov_ack_valid {
      bins no_ack_compare = {0};
      bins ack_compare    = {1};
    }

    cp_ack_output_valid : coverpoint cov_ack_output_valid {
      bins ack_output_zero    = {0};
      bins ack_output_nonzero = {1};
    }

    // For 16 interrupts only: IRQ 0 to IRQ 15
    cp_ack_irq_num : coverpoint cov_ack_irq_num iff (cov_ack_output_valid) {
      bins irq_0_7[] = {[0:7]};
      bins irq_8_15[] = {[8:15]};
    }

    cp_exp_ack_irq_num : coverpoint cov_exp_ack_irq_num iff (cov_ack_valid) {
      bins exp_irq_0_7[]  = {[0:7]};
      bins exp_irq_8_15[] = {[8:15]};
    }

    // ACK ID encoding: interrupt ID = 8'h10 + irq_num
    // For 16 interrupts valid ACK IDs are 8'h10 to 8'h1F
    cp_ack_id_raw : coverpoint cov_ack_id iff (cov_ack_output_valid) {
      bins ack_10_17[] = {[8'h10:8'h17]};
      bins ack_18_1f[] = {[8'h18:8'h1F]};
    }

    cp_exp_ack_id_raw : coverpoint cov_exp_ack_id iff (cov_ack_valid) {
      bins exp_ack_10_17[] = {[8'h10:8'h17]};
      bins exp_ack_18_1f[] = {[8'h18:8'h1F]};
    }

    cp_active_irq_count : coverpoint cov_active_irq_count {
      bins no_irq     = {0};
      bins single_irq = {1};
      bins two_irq    = {2};
      bins few_irq[]    = {[3:5]};
      bins many_irq[]   = {[6:15]};
      bins all_irq    = {16};
    }

    cp_highest_lvl_pr : coverpoint cov_highest_lvl_pr {
      bins low_range[]  = {[8'h00:8'h3F]};
      bins mid_range[]  = {[8'h40:8'h9F]};
      bins high_range[] = {[8'hA0:8'hFF]};
    }

    cp_active_lvl_pr : coverpoint cov_active_lvl_pr {
      bins zero_level = {8'h00};
      bins low_level[]  = {[8'h01:8'h3F]};
      bins mid_level[]  = {[8'h40:8'h9F]};
      bins high_level[] = {[8'hA0:8'hFF]};
    }

    cp_eoi_valid : coverpoint cov_eoi_valid {
      bins no_eoi   = {0};
      bins eoi_seen = {1};
    }

    cp_wr_en : coverpoint cov_wr_en {
      bins wr_low  = {0};
      bins wr_high = {1};
    }

    cp_rd_en : coverpoint cov_rd_en {
      bins rd_low  = {0};
      bins rd_high = {1};
    }

    // 16 IRQ control registers:
    // irq0  = 16'h1003
    // irq15 = 16'h103F
    cp_wr_addr : coverpoint cov_wr_addr iff (cov_wr_en) {
      bins irq_ctl_0  = {16'h1003};
      bins irq_ctl_1  = {16'h1007};
      bins irq_ctl_2  = {16'h100B};
      bins irq_ctl_3  = {16'h100F};
      bins irq_ctl_4  = {16'h1013};
      bins irq_ctl_5  = {16'h1017};
      bins irq_ctl_6  = {16'h101B};
      bins irq_ctl_7  = {16'h101F};
      bins irq_ctl_8  = {16'h1023};
      bins irq_ctl_9  = {16'h1027};
      bins irq_ctl_10 = {16'h102B};
      bins irq_ctl_11 = {16'h102F};
      bins irq_ctl_12 = {16'h1033};
      bins irq_ctl_13 = {16'h1037};
      bins irq_ctl_14 = {16'h103B};
      bins irq_ctl_15 = {16'h103F};
    }
    
    cp_rd_addr : coverpoint cov_rd_addr iff (cov_rd_en) {
      bins rd_irq_ctl_0  = {16'h1003};
      bins rd_irq_ctl_1  = {16'h1007};
      bins rd_irq_ctl_2  = {16'h100B};
      bins rd_irq_ctl_3  = {16'h100F};
      bins rd_irq_ctl_4  = {16'h1013};
      bins rd_irq_ctl_5  = {16'h1017};
      bins rd_irq_ctl_6  = {16'h101B};
      bins rd_irq_ctl_7  = {16'h101F};
      bins rd_irq_ctl_8  = {16'h1023};
      bins rd_irq_ctl_9  = {16'h1027};
      bins rd_irq_ctl_10 = {16'h102B};
      bins rd_irq_ctl_11 = {16'h102F};
      bins rd_irq_ctl_12 = {16'h1033};
      bins rd_irq_ctl_13 = {16'h1037};
      bins rd_irq_ctl_14 = {16'h103B};
      bins rd_irq_ctl_15 = {16'h103F};
    }

    cp_wr_data : coverpoint cov_wr_data[7:0] iff (cov_wr_en) {
      bins low_val[]  = {[8'h00:8'h3F]};
      bins mid_val[]  = {[8'h40:8'h9F]};
      bins high_val[] = {[8'hA0:8'hFF]};
    }

    cp_ext_int_present : coverpoint (cov_ext_int != 16'h0000) {
      bins no_ext_int = {0};
      bins ext_int_on = {1};
    }

    cp_global_enable_present : coverpoint (cov_int_en != 16'h0000) {
    //  bins no_global_enable = {0};
      bins global_enable_on = {1};
    }

    cp_global_en_valid : coverpoint cov_global_en_valid {
      bins invalid = {0};
      bins valid   = {1};
    }

    cp_eoi_id : coverpoint cov_eoi_id iff (cov_eoi_valid) {
      bins eoi_10_17[] = {[8'h10:8'h17]};
      bins eoi_18_1f[] = {[8'h18:8'h1F]};
    }

    cross_wr_addr_data  : cross cp_wr_addr, cp_wr_data;
    cross_ext_enable    : cross cp_ext_int_present, cp_global_enable_present;
    cross_irq_count_req : cross cp_active_irq_count, cp_irq_req;
    cross_irq_ack       : cross cp_irq_req, cp_ack_valid;
    cross_ack_pr        : cross cp_exp_ack_irq_num, cp_highest_lvl_pr;
    cross_threshold_irq : cross cp_active_lvl_pr, cp_irq_req;

  endgroup

  // ============================================================
  // Constructor
  // ============================================================
  function new(string name = "int_coverage", uvm_component parent = null);
    super.new(name, parent);
    zic_cg = new();
  endfunction

  // ============================================================
  // Write function from analysis port
  // ============================================================
  function void write(int_seq_item t);

    tr = t;

    cov_reset             = tr.soc_rst;
    cov_irq_req           = tr.interrupt_request_o;
    cov_ack_valid         = tr.exp_valid;
    cov_ack_output_valid  = (tr.soc_ack_int_id_o != 8'h00);

    cov_ack_id            = tr.soc_ack_int_id_o;
    cov_exp_ack_id        = tr.exp_ack_id;

    cov_ext_int           = tr.ext_int[15:0];
    cov_int_en            = tr.global_int_enable_bit_i[15:0];

    cov_highest_lvl_pr    = tr.highest_pending_lvl_pr_o;
    cov_active_lvl_pr     = tr.active_lvl_pr_i;

    cov_eoi_valid         = tr.soc_eoi_valid_i;

    cov_active_irq_count  = count_active_interrupts(cov_ext_int, cov_int_en);
    cov_ack_irq_num       = ack_to_irq_num(cov_ack_id);
    cov_exp_ack_irq_num   = ack_to_irq_num(cov_exp_ack_id);

    cov_wr_en             = tr.soc_mmr_write_en_i;
    cov_rd_en             = tr.soc_mmr_read_en_i;
    cov_wr_addr           = tr.soc_mmr_write_addr_i;
    cov_rd_addr           = tr.soc_mmr_read_addr_i;
    cov_wr_data           = tr.soc_mmr_write_data_i;
    cov_eoi_id            = tr.soc_eoi_id_i;
    cov_global_en_valid   = tr.global_int_enable_valid_i;

    `uvm_info("COV_SAMPLE",
      $sformatf("rst=%0b irq_req=%0b ack_valid=%0b ack_o=%0h exp_ack=%0h wr_en=%0b rd_en=%0b ext=%0h en=%0h",
      cov_reset,
      cov_irq_req,
      cov_ack_valid,
      cov_ack_id,
      cov_exp_ack_id,
      cov_wr_en,
      cov_rd_en,
      cov_ext_int,
      cov_int_en),
      UVM_LOW)

    zic_cg.sample();

  endfunction

  // ============================================================
  // Count active interrupts
  // active interrupt = external interrupt asserted AND enabled
  // ============================================================
  function int count_active_interrupts(bit [15:0] ext_int,
                                       bit [15:0] int_en);
    int count;

    count = 0;

    for (int i = 0; i < NUM_IRQ; i++) begin
      if (ext_int[i] && int_en[i]) begin
        count++;
      end
    end

    return count;
  endfunction

  // ============================================================
  // Convert ACK ID to IRQ number
  // valid ACK range for 16 IRQ:
  // 8'h10 -> irq0
  // 8'h11 -> irq1
  // ...
  // 8'h1F -> irq15
  // ============================================================
  function int ack_to_irq_num(bit [7:0] ack_id);

    if ((ack_id >= 8'h10) && (ack_id <= 8'h1F)) begin
      return int'(ack_id - 8'h10);
    end
    else begin
      return -1;
    end

  endfunction

endclass
