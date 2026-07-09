// ============================================================
// COMMON BASE FOR reset_basic_seq / mmr_basic_seq
// single_irq_seq / multi_irq_seq
// 16 INTERRUPT VERSION
// ============================================================
class zic_comman_base_seq extends uvm_sequence #(int_seq_item);

  `uvm_object_utils(zic_comman_base_seq)

  localparam int NUM_IRQ = 16;
  localparam bit [15:0] VALID_IRQ_MASK = 16'hFFFF;

  function new(string name = "zic_comman_base_seq");
    super.new(name);
  endfunction

  function automatic bit [15:0] ctl_addr(int id);
    return 16'h1003 + (id * 4);
  endfunction

  task send_tr(
    string name,
    bit soc_rst,
    bit [15:0] ext_int,
    bit wr_en,
    bit [15:0] wr_addr,
    bit [31:0] wr_data,
    bit rd_en,
    bit [15:0] rd_addr,
    bit eoi_valid,
    bit [7:0] eoi_id,
    bit [15:0] enable_bits,
    bit enable_valid,
    bit [7:0] active_lvl,
    bit ack_valid
  );

    int_seq_item tr;

    tr = int_seq_item::type_id::create(name);
    start_item(tr);

    tr.soc_rst = soc_rst;
    tr.ext_int = ext_int;

    tr.soc_mmr_write_en_i   = wr_en;
    tr.soc_mmr_write_addr_i = wr_addr;
    tr.soc_mmr_write_data_i = wr_data;

    tr.soc_mmr_read_en_i   = rd_en;
    tr.soc_mmr_read_addr_i = rd_addr;

    tr.soc_ack_read_valid_en = ack_valid;

    tr.soc_eoi_valid_i = eoi_valid;
    tr.soc_eoi_id_i    = eoi_id;

    tr.global_int_enable_bit_i   = enable_bits;
    tr.global_int_enable_valid_i = enable_valid;

    tr.active_lvl_pr_i = active_lvl;

    tr.debug_mode_valid_i = 1'b0;
    tr.debug_mode_reset_i = 1'b0;
    tr.debug_ndm_reset_i  = 1'b0;

    finish_item(tr);

  endtask

  task idle(
    int n,
    bit [15:0] ext = 16'h0000,
    bit [15:0] en  = VALID_IRQ_MASK
  );

    repeat (n) begin
      send_tr("idle",
              1'b1, ext,
              1'b0, 16'h0000, 32'h0000_0000,
              1'b0, 16'h0000,
              1'b0, 8'h00,
              en, 1'b0,
              8'h00,
              1'b0);
    end

  endtask

  task write_ctl(int irq, bit [7:0] ctl);

    send_tr($sformatf("write_ctl_irq%0d", irq),
            1'b1, 16'h0000,
            1'b1, ctl_addr(irq), {24'h0, ctl},
            1'b0, 16'h0000,
            1'b0, 8'h00,
            VALID_IRQ_MASK, 1'b0,
            8'h00,
            1'b0);

  endtask

endclass


// ============================================================
// RANDOM INTERRUPT STORM SEQUENCE
// 16 INTERRUPT VERSION
// ============================================================
class random_interrupt_storm_seq extends uvm_sequence #(int_seq_item);

  `uvm_object_utils(random_interrupt_storm_seq)

  localparam int NUM_IRQ = 16;
  localparam bit [15:0] VALID_IRQ_MASK = 16'hFFFF;

  rand bit [7:0] irq_ctl [NUM_IRQ];

  rand int unsigned irq_count;
  rand int unsigned irq_group;
  rand int unsigned prio_group;

  int unsigned storm_cycles = 1000;

  constraint ctl_c {
    foreach (irq_ctl[i]) {
      irq_ctl[i] inside {[8'h01:8'hFF]};
    }
  }

  constraint cov_bias_c {

    irq_count dist {
      1      := 35,
      2      := 35,
      [3:5]  := 20,
      [6:10] := 10,
      [11:16]:= 10
    };

    irq_group dist {
      0 := 35,   // irq 0 to 3
      1 := 35,   // irq 4 to 7
      2 := 25,   // irq 8 to 11
      3 := 25    // irq 12 to 15
    };

    prio_group dist {
      0 := 35,
      1 := 35,
      2 := 30
    };
  }

  function new(string name = "random_interrupt_storm_seq");
    super.new(name);
  endfunction

  function automatic bit [15:0] ctl_addr(int id);
    return 16'h1003 + (id * 4);
  endfunction

  function automatic int rand_irq_from_group(int group_id);

    case (group_id)
      0: return $urandom_range(0, 3);
      1: return $urandom_range(4, 7);
      2: return $urandom_range(8, 11);
      3: return $urandom_range(12, 15);
      default: return $urandom_range(0, 15);
    endcase

  endfunction

  function automatic bit [7:0] rand_ctl_from_group(int group_id);

    case (group_id)
      0: return $urandom_range(8'h01, 8'h3F);
      1: return $urandom_range(8'h40, 8'h9F);
      2: return $urandom_range(8'hA0, 8'hFF);
      default: return $urandom_range(8'h01, 8'hFF);
    endcase

  endfunction

  function automatic bit higher_priority(
    bit [7:0] cur_ctl,
    int       cur_id,
    bit [7:0] best_ctl,
    int       best_id
  );

    if (cur_ctl[7:5] > best_ctl[7:5])
      return 1'b1;

    if ((cur_ctl[7:5] == best_ctl[7:5]) &&
        (cur_ctl[4:2] >  best_ctl[4:2]))
      return 1'b1;

    if ((cur_ctl[7:5] == best_ctl[7:5]) &&
        (cur_ctl[4:2] == best_ctl[4:2]) &&
        (cur_id > best_id))
      return 1'b1;

    return 1'b0;

  endfunction

  function automatic int find_best_id(bit [15:0] mask);

    int best_id;
    bit best_found;
    bit [7:0] best_ctl;

    best_id    = 0;
    best_found = 1'b0;
    best_ctl   = 8'h00;

    for (int i = 0; i < NUM_IRQ; i++) begin

      if (mask[i]) begin

        if (!best_found) begin
          best_found = 1'b1;
          best_id    = i;
          best_ctl   = irq_ctl[i];
        end
        else if (higher_priority(irq_ctl[i], i, best_ctl, best_id)) begin
          best_id  = i;
          best_ctl = irq_ctl[i];
        end

      end

    end

    if (!best_found)
      return -1;

    return best_id;

  endfunction

  task body();

    bit [15:0] ext_mask;
    bit [15:0] en_mask;
    bit [15:0] eligible_mask;

    int best_id;
    int wait_cycles;
    bit [7:0] active_lvl_rand;

    if (!this.randomize()) begin
      `uvm_fatal("RAND_STORM_SEQ", "Initial randomization failed")
    end

    `uvm_info("RAND_STORM_SEQ",
      $sformatf("Starting 16-interrupt random storm, cycles=%0d", storm_cycles),
      UVM_LOW)

    // Reset active-low: 0 = reset active
    send_tr("reset",
            1'b0, 16'h0000,
            1'b0, 16'h0000, 32'h0000_0000,
            1'b0, 16'h0000,
            1'b0, 8'h00,
            16'h0000, 1'b0,
            8'h00,
            1'b0,
            1'b0, 1'b0, 1'b0);

    repeat (3) begin
      send_tr("post_reset_idle",
              1'b1, 16'h0000,
              1'b0, 16'h0000, 32'h0000_0000,
              1'b0, 16'h0000,
              1'b0, 8'h00,
              16'h0000, 1'b0,
              8'h00,
              1'b0,
              1'b0, 1'b0, 1'b0);
    end

    // Initial CTL programming for IRQ0 to IRQ15
    for (int i = 0; i < NUM_IRQ; i++) begin

      send_tr($sformatf("mmr_write_irq%0d_ctl", i),
              1'b1, 16'h0000,
              1'b1, ctl_addr(i), {24'h0, irq_ctl[i]},
              1'b0, 16'h0000,
              1'b0, 8'h00,
              16'h0000, 1'b0,
              8'h00,
              1'b0,
              1'b0, 1'b0, 1'b0);

    end

    repeat (5) begin
      send_tr("initial_ctl_settle",
              1'b1, 16'h0000,
              1'b0, 16'h0000, 32'h0000_0000,
              1'b0, 16'h0000,
              1'b0, 8'h00,
              16'h0000, 1'b0,
              8'h00,
              1'b0,
              1'b0, 1'b0, 1'b0);
    end

    repeat (storm_cycles) begin

      if (!this.randomize()) begin
        `uvm_fatal("RAND_STORM_SEQ", "Loop randomization failed")
      end

      ext_mask = 16'h0000;
      en_mask  = 16'h0000;

      // Re-program CTL values
      for (int i = 0; i < NUM_IRQ; i++) begin

        irq_ctl[i] = rand_ctl_from_group(prio_group);

        send_tr($sformatf("cov_mmr_write_irq%0d_ctl", i),
                1'b1, 16'h0000,
                1'b1, ctl_addr(i), {24'h0, irq_ctl[i]},
                1'b0, 16'h0000,
                1'b0, 8'h00,
                16'h0000, 1'b0,
                8'h00,
                1'b0,
                1'b0, 1'b0, 1'b0);

      end

      repeat (8) begin
        send_tr("settle_after_ctl_programming",
                1'b1, 16'h0000,
                1'b0, 16'h0000, 32'h0000_0000,
                1'b0, 16'h0000,
                1'b0, 8'h00,
                16'h0000, 1'b0,
                8'h00,
                1'b0,
                1'b0, 1'b0, 1'b0);
      end

      // Generate active/enabled IRQs
      repeat (irq_count) begin
        int irq;
        irq = rand_irq_from_group(irq_group);
        ext_mask[irq] = 1'b1;
        en_mask[irq]  = 1'b1;
      end

      if ((ext_mask & en_mask) == 16'h0000) begin
        int irq;
        irq = rand_irq_from_group(irq_group);
        ext_mask[irq] = 1'b1;
        en_mask[irq]  = 1'b1;
      end

      eligible_mask   = ext_mask & en_mask;
      best_id         = find_best_id(eligible_mask);
      wait_cycles     = $urandom_range(6, 10);
      active_lvl_rand = 8'h00;

      `uvm_info("RAND_STORM_SEQ",
        $sformatf("ext=0x%0h en=0x%0h best_id=%0d exp_ack=0x%0h ctl=0x%0h lvl=0x%0h pri=0x%0h",
                  ext_mask,
                  en_mask,
                  best_id,
                  8'h10 + best_id[7:0],
                  irq_ctl[best_id],
                  irq_ctl[best_id][7:5],
                  irq_ctl[best_id][4:2]),
        UVM_LOW)

      // Drive interrupt + enable
      send_tr("drive_ext_irq_and_global_enable",
              1'b1, ext_mask,
              1'b0, 16'h0000, 32'h0000_0000,
              1'b0, 16'h0000,
              1'b0, 8'h00,
              en_mask, 1'b1,
              active_lvl_rand,
              1'b0,
              1'b0, 1'b0, 1'b0);

      // Wait for priority resolve
      repeat (wait_cycles) begin
        send_tr("wait_priority_resolve",
                1'b1, ext_mask,
                1'b0, 16'h0000, 32'h0000_0000,
                1'b0, 16'h0000,
                1'b0, 8'h00,
                en_mask, 1'b0,
                active_lvl_rand,
                1'b0,
                1'b0, 1'b0, 1'b0);
      end

      // Optional MMR read
      if ($urandom_range(0, 3) == 0) begin
        int rd_irq;
        rd_irq = $urandom_range(0, 15);

        send_tr("mmr_read_random_ctl",
                1'b1, ext_mask,
                1'b0, 16'h0000, 32'h0000_0000,
                1'b1, ctl_addr(rd_irq),
                1'b0, 8'h00,
                en_mask, 1'b0,
                active_lvl_rand,
                1'b0,
                1'b0, 1'b0, 1'b0);

        repeat (3) begin
          send_tr("settle_after_mmr_read",
                  1'b1, ext_mask,
                  1'b0, 16'h0000, 32'h0000_0000,
                  1'b0, 16'h0000,
                  1'b0, 8'h00,
                  en_mask, 1'b0,
                  active_lvl_rand,
                  1'b0,
                  1'b0, 1'b0, 1'b0);
        end
      end

      // ACK current IRQ
      send_tr("ack_current_irq",
              1'b1, ext_mask,
              1'b0, 16'h0000, 32'h0000_0000,
              1'b0, 16'h0000,
              1'b0, 8'h00,
              en_mask, 1'b0,
              active_lvl_rand,
              1'b1,
              1'b0, 1'b0, 1'b0);

      repeat (3) begin
        send_tr("idle_after_ack",
                1'b1, ext_mask,
                1'b0, 16'h0000, 32'h0000_0000,
                1'b0, 16'h0000,
                1'b0, 8'h00,
                en_mask, 1'b0,
                active_lvl_rand,
                1'b0,
                1'b0, 1'b0, 1'b0);
      end

      // Clear external IRQ before EOI
      send_tr("clear_ext_before_eoi",
              1'b1, 16'h0000,
              1'b0, 16'h0000, 32'h0000_0000,
              1'b0, 16'h0000,
              1'b0, 8'h00,
              en_mask, 1'b0,
              active_lvl_rand,
              1'b0,
              1'b0, 1'b0, 1'b0);

      // EOI served interrupt
      if (best_id >= 0) begin
        send_tr("eoi_served_irq",
                1'b1, 16'h0000,
                1'b0, 16'h0000, 32'h0000_0000,
                1'b0, 16'h0000,
                1'b1, 8'h10 + best_id[7:0],
                en_mask, 1'b0,
                active_lvl_rand,
                1'b0,
                1'b0, 1'b0, 1'b0);
      end

      repeat (3) begin
        send_tr("clear_irq_idle",
                1'b1, 16'h0000,
                1'b0, 16'h0000, 32'h0000_0000,
                1'b0, 16'h0000,
                1'b0, 8'h00,
                en_mask, 1'b0,
                8'h00,
                1'b0,
                1'b0, 1'b0, 1'b0);
      end

    end

  endtask


  task send_tr(
    string name,
    bit soc_rst,
    bit [15:0] ext_int,
    bit wr_en,
    bit [15:0] wr_addr,
    bit [31:0] wr_data,
    bit rd_en,
    bit [15:0] rd_addr,
    bit eoi_valid,
    bit [7:0] eoi_id,
    bit [15:0] enable_bits,
    bit enable_valid,
    bit [7:0] active_lvl,
    bit ack_valid,
    bit debug_valid,
    bit debug_reset,
    bit debug_ndm_reset
  );

    int_seq_item tr;

    tr = int_seq_item::type_id::create(name);
    start_item(tr);

    tr.soc_rst = soc_rst;
    tr.ext_int = ext_int;

    tr.soc_mmr_write_en_i   = wr_en;
    tr.soc_mmr_write_addr_i = wr_addr;
    tr.soc_mmr_write_data_i = wr_data;

    tr.soc_mmr_read_en_i    = rd_en;
    tr.soc_mmr_read_addr_i  = rd_addr;

    tr.soc_ack_read_valid_en = ack_valid;

    tr.soc_eoi_valid_i = eoi_valid;
    tr.soc_eoi_id_i    = eoi_id;

    tr.active_lvl_pr_i = active_lvl;

    tr.global_int_enable_bit_i   = enable_bits;
    tr.global_int_enable_valid_i = enable_valid;

    tr.debug_mode_valid_i = debug_valid;
    tr.debug_mode_reset_i = debug_reset;
    tr.debug_ndm_reset_i  = debug_ndm_reset;

    finish_item(tr);

  endtask

endclass

// ============================================================
// RANDOM STORM SEQUENCE - 16 INTERRUPT VERSION
// ============================================================
class rand_storm_seq extends uvm_sequence #(int_seq_item);

  `uvm_object_utils(rand_storm_seq)

  localparam int NUM_IRQ = 16;
  localparam bit [15:0] VALID_IRQ_MASK = 16'hFFFF;

  int_seq_item tr;

  bit [7:0] irq_ctl [NUM_IRQ];

  int unsigned storm_cycles = 1000;

  function new(string name = "rand_storm_seq");
    super.new(name);
  endfunction

  function automatic bit [15:0] ctl_addr(int id);
    return 16'h1003 + (id * 4);
  endfunction

  function automatic int find_best_id(bit [15:0] mask);

    int best_id;
    bit found;

    bit [2:0] best_lvl;
    bit [2:0] best_pri;
    bit [2:0] cur_lvl;
    bit [2:0] cur_pri;

    best_id  = -1;
    found    = 1'b0;
    best_lvl = 3'h0;
    best_pri = 3'h0;

    for (int i = 0; i < NUM_IRQ; i++) begin

      if (mask[i]) begin

        cur_lvl = irq_ctl[i][7:5];
        cur_pri = irq_ctl[i][4:2];

        if (!found) begin
          found    = 1'b1;
          best_id  = i;
          best_lvl = cur_lvl;
          best_pri = cur_pri;
        end
        else if (cur_lvl > best_lvl) begin
          best_id  = i;
          best_lvl = cur_lvl;
          best_pri = cur_pri;
        end
        else if ((cur_lvl == best_lvl) && (cur_pri > best_pri)) begin
          best_id  = i;
          best_lvl = cur_lvl;
          best_pri = cur_pri;
        end
        else if ((cur_lvl == best_lvl) &&
                 (cur_pri == best_pri) &&
                 (i > best_id)) begin
          best_id  = i;
          best_lvl = cur_lvl;
          best_pri = cur_pri;
        end

      end
    end

    return best_id;

  endfunction


  task send_tr(
    string name,
    bit soc_rst,
    bit [15:0] ext_mask,
    bit wr_en,
    bit [15:0] wr_addr,
    bit [31:0] wr_data,
    bit ack_valid,
    bit eoi_valid,
    bit [7:0] eoi_id,
    bit [15:0] en_mask,
    bit en_valid
  );

    tr = int_seq_item::type_id::create(name);
    start_item(tr);

    tr.soc_rst = soc_rst;
    tr.ext_int = ext_mask;

    tr.soc_mmr_write_en_i   = wr_en;
    tr.soc_mmr_write_addr_i = wr_addr;
    tr.soc_mmr_write_data_i = wr_data;

    tr.soc_mmr_read_en_i    = 1'b0;
    tr.soc_mmr_read_addr_i  = 16'h0000;

    tr.soc_ack_read_valid_en = ack_valid;

    tr.soc_eoi_valid_i = eoi_valid;
    tr.soc_eoi_id_i    = eoi_id;

    tr.active_lvl_pr_i = 8'h00;

    tr.global_int_enable_bit_i   = en_mask;
    tr.global_int_enable_valid_i = en_valid;

    tr.debug_mode_valid_i = 1'b0;
    tr.debug_mode_reset_i = 1'b0;
    tr.debug_ndm_reset_i  = 1'b0;

    finish_item(tr);

  endtask


  task body();

    int i;
    int n;
    int irq;
    int best_id;

    bit [15:0] rand_ext;
    bit [15:0] active_mask;

    // Reset active-low
    send_tr("reset",
            1'b0,
            16'h0000,
            1'b0, 16'h0000, 32'h0000_0000,
            1'b0,
            1'b0, 8'h00,
            16'h0000,
            1'b0);

    repeat (3) begin
      send_tr("post_reset_idle",
              1'b1,
              16'h0000,
              1'b0, 16'h0000, 32'h0000_0000,
              1'b0,
              1'b0, 8'h00,
              16'h0000,
              1'b0);
    end

    // Configure IRQ0 to IRQ15
    for (i = 0; i < NUM_IRQ; i++) begin

      irq_ctl[i] = $urandom_range(8'h20, 8'hFF);

      send_tr($sformatf("cfg_irq_%0d", i),
              1'b1,
              16'h0000,
              1'b1,
              ctl_addr(i),
              {24'h0, irq_ctl[i]},
              1'b0,
              1'b0, 8'h00,
              16'h0000,
              1'b0);
    end

    // Enable IRQ0 to IRQ15
    send_tr("enable_irq_0_to_15",
            1'b1,
            16'h0000,
            1'b0, 16'h0000, 32'h0000_0000,
            1'b0,
            1'b0, 8'h00,
            VALID_IRQ_MASK,
            1'b1);

    repeat (5) begin
      send_tr("settle_after_enable",
              1'b1,
              16'h0000,
              1'b0, 16'h0000, 32'h0000_0000,
              1'b0,
              1'b0, 8'h00,
              VALID_IRQ_MASK,
              1'b0);
    end

    // Random interrupt storm
    repeat (storm_cycles) begin

      rand_ext = 16'h0000;

      n = $urandom_range(1, 5);

      for (i = 0; i < n; i++) begin
        irq = $urandom_range(0, 15);
        rand_ext[irq] = 1'b1;
      end

      active_mask = rand_ext & VALID_IRQ_MASK;
      best_id     = find_best_id(active_mask);

      `uvm_info("RAND_STORM_SEQ",
        $sformatf("rand_ext=0x%0h best_id=%0d exp_ack=0x%0h ctl=0x%0h level=0x%0h pri=0x%0h",
                  rand_ext,
                  best_id,
                  8'h10 + best_id[7:0],
                  irq_ctl[best_id],
                  irq_ctl[best_id][7:5],
                  irq_ctl[best_id][4:2]),
        UVM_LOW)

      send_tr("rand_irq_assert",
              1'b1,
              rand_ext,
              1'b0, 16'h0000, 32'h0000_0000,
              1'b0,
              1'b0, 8'h00,
              VALID_IRQ_MASK,
              1'b0);

      repeat (4) begin
        send_tr("wait_priority_resolve",
                1'b1,
                rand_ext,
                1'b0, 16'h0000, 32'h0000_0000,
                1'b0,
                1'b0, 8'h00,
                VALID_IRQ_MASK,
                1'b0);
      end

      send_tr("rand_irq_ack",
              1'b1,
              rand_ext,
              1'b0, 16'h0000, 32'h0000_0000,
              1'b1,
              1'b0, 8'h00,
              VALID_IRQ_MASK,
              1'b0);

      send_tr("idle_after_ack",
              1'b1,
              rand_ext,
              1'b0, 16'h0000, 32'h0000_0000,
              1'b0,
              1'b0, 8'h00,
              VALID_IRQ_MASK,
              1'b0);

      send_tr("clear_ext_before_eoi",
              1'b1,
              16'h0000,
              1'b0, 16'h0000, 32'h0000_0000,
              1'b0,
              1'b0, 8'h00,
              VALID_IRQ_MASK,
              1'b0);

      if (best_id >= 0) begin
        send_tr("eoi_served_irq",
                1'b1,
                16'h0000,
                1'b0, 16'h0000, 32'h0000_0000,
                1'b0,
                1'b1, 8'h10 + best_id[7:0],
                VALID_IRQ_MASK,
                1'b0);
      end

      repeat (3) begin
        send_tr("clear_irq_idle",
                1'b1,
                16'h0000,
                1'b0, 16'h0000, 32'h0000_0000,
                1'b0,
                1'b0, 8'h00,
                VALID_IRQ_MASK,
                1'b0);
      end

    end

  endtask

endclass


// ============================================================
// DYNAMIC PRIORITY OVERRIDE SEQUENCE - 16 INTERRUPT VERSION
// ============================================================
class dynamic_priority_override_seq extends uvm_sequence #(int_seq_item);

  `uvm_object_utils(dynamic_priority_override_seq)

  rand int low_irq;
  rand int high_irq;

  constraint irq_c {
    low_irq  inside {[0:7]};
    high_irq inside {[8:15]};
    low_irq != high_irq;
  }

  function new(string name = "dynamic_priority_override_seq");
    super.new(name);
  endfunction

  function automatic bit [15:0] ctl_addr(int id);
    return 16'h1003 + (id * 4);
  endfunction

  task body();

    bit [15:0] enable_mask;
    bit [15:0] low_mask;
    bit [15:0] both_mask;

    if (!this.randomize()) begin
      `uvm_fatal("DYN_PRIO_SEQ", "Randomization failed")
    end

    enable_mask = 16'h0000;
    low_mask    = 16'h0000;
    both_mask   = 16'h0000;

    enable_mask[low_irq]  = 1'b1;
    enable_mask[high_irq] = 1'b1;

    low_mask[low_irq] = 1'b1;

    both_mask[low_irq]  = 1'b1;
    both_mask[high_irq] = 1'b1;

    `uvm_info("DYN_PRIO_SEQ",
      $sformatf("LOW_IRQ=%0d LOW_ACK=0x%0h PRIO=0x20 | HIGH_IRQ=%0d HIGH_ACK=0x%0h PRIO=0xE0",
                low_irq,  8'h10 + low_irq[7:0],
                high_irq, 8'h10 + high_irq[7:0]),
      UVM_LOW)

    send_tr("reset", 1'b0, 16'h0000,
            1'b0, 16'h0000, 32'h0000_0000,
            1'b0, 8'h00,
            16'h0000, 1'b0,
            8'h00, 1'b0);

    repeat (3) begin
      send_tr("post_reset_idle", 1'b1, 16'h0000,
              1'b0, 16'h0000, 32'h0000_0000,
              1'b0, 8'h00,
              16'h0000, 1'b0,
              8'h00, 1'b0);
    end

    write_ctl($sformatf("write_low_irq%0d_ctl", low_irq),
              ctl_addr(low_irq),
              8'h20);

    write_ctl($sformatf("write_high_irq%0d_ctl", high_irq),
              ctl_addr(high_irq),
              8'hE0);

    send_tr("assert_low_irq_only", 1'b1, low_mask,
            1'b0, 16'h0000, 32'h0000_0000,
            1'b0, 8'h00,
            enable_mask, 1'b1,
            8'h00, 1'b0);

    repeat (5) begin
      send_tr("wait_low_irq_resolve", 1'b1, low_mask,
              1'b0, 16'h0000, 32'h0000_0000,
              1'b0, 8'h00,
              enable_mask, 1'b0,
              8'h00, 1'b0);
    end

    send_tr("ack_low_irq", 1'b1, low_mask,
            1'b0, 16'h0000, 32'h0000_0000,
            1'b0, 8'h00,
            enable_mask, 1'b0,
            8'h00, 1'b1);

    repeat (2) begin
      send_tr("idle_after_low_ack", 1'b1, low_mask,
              1'b0, 16'h0000, 32'h0000_0000,
              1'b0, 8'h00,
              enable_mask, 1'b0,
              8'h00, 1'b0);
    end

    send_tr("high_irq_arrives", 1'b1, both_mask,
            1'b0, 16'h0000, 32'h0000_0000,
            1'b0, 8'h00,
            enable_mask, 1'b0,
            8'h00, 1'b0);

    repeat (5) begin
      send_tr("wait_high_override", 1'b1, both_mask,
              1'b0, 16'h0000, 32'h0000_0000,
              1'b0, 8'h00,
              enable_mask, 1'b0,
              8'h00, 1'b0);
    end

    send_tr("ack_high_irq_override", 1'b1, both_mask,
            1'b0, 16'h0000, 32'h0000_0000,
            1'b0, 8'h00,
            enable_mask, 1'b0,
            8'h00, 1'b1);

    repeat (3) begin
      send_tr("idle_after_high_ack", 1'b1, both_mask,
              1'b0, 16'h0000, 32'h0000_0000,
              1'b0, 8'h00,
              enable_mask, 1'b0,
              8'h00, 1'b0);
    end

  endtask


  task write_ctl(string name, bit [15:0] addr, bit [7:0] data);

    send_tr(name, 1'b1, 16'h0000,
            1'b1, addr, {24'h0, data},
            1'b0, 8'h00,
            16'h0000, 1'b0,
            8'h00, 1'b0);

  endtask


  task send_tr(
    string name,
    bit soc_rst,
    bit [15:0] ext_int,
    bit wr_en,
    bit [15:0] wr_addr,
    bit [31:0] wr_data,
    bit eoi_valid,
    bit [7:0] eoi_id,
    bit [15:0] enable_bits,
    bit enable_valid,
    bit [7:0] active_lvl,
    bit ack_valid
  );

    int_seq_item tr;

    tr = int_seq_item::type_id::create(name);
    start_item(tr);

    tr.soc_rst = soc_rst;
    tr.ext_int = ext_int;

    tr.soc_mmr_write_en_i   = wr_en;
    tr.soc_mmr_write_addr_i = wr_addr;
    tr.soc_mmr_write_data_i = wr_data;

    tr.soc_mmr_read_en_i   = 1'b0;
    tr.soc_mmr_read_addr_i = 16'h0000;

    tr.soc_ack_read_valid_en = ack_valid;

    tr.soc_eoi_valid_i = eoi_valid;
    tr.soc_eoi_id_i    = eoi_id;

    tr.active_lvl_pr_i = active_lvl;

    tr.global_int_enable_bit_i   = enable_bits;
    tr.global_int_enable_valid_i = enable_valid;

    tr.debug_mode_valid_i = 1'b0;
    tr.debug_mode_reset_i = 1'b0;
    tr.debug_ndm_reset_i  = 1'b0;

    finish_item(tr);

  endtask

endclass

// ============================================================
// RANDOM TIE BREAK + EOI SEQUENCE - 16 IRQ
// ============================================================
class random_tie_break_eoi_seq extends uvm_sequence #(int_seq_item);

  `uvm_object_utils(random_tie_break_eoi_seq)

  rand bit [15:0] active_mask;
  rand bit [15:0] enable_mask;
  rand bit [7:0]  shared_prio;

  constraint valid_c {
    active_mask != 16'h0;
    enable_mask != 16'h0;
    (active_mask & enable_mask) != 16'h0;
    $countones(active_mask & enable_mask) >= 3;
    shared_prio inside {[8'h01:8'hFF]};
  }

  function new(string name = "random_tie_break_eoi_seq");
    super.new(name);
  endfunction

  function automatic bit [15:0] ctl_addr(int id);
    return 16'h1003 + (id * 4);
  endfunction

  function automatic int find_highest_id(bit [15:0] mask);
    int best_id = -1;

    for (int i = 0; i < 16; i++) begin
      if (mask[i] && (i > best_id))
        best_id = i;
    end

    return best_id;
  endfunction

  task body();

    bit [15:0] work_mask;
    int winner;

    if (!this.randomize())
      `uvm_fatal("RAND_TIE_EOI_SEQ", "Randomization failed")

    work_mask = active_mask & enable_mask;

    send_tr("reset", 1'b0, 16'h0,
            0, 16'h0, 32'h0,
            0, 8'h00,
            16'h0, 0,
            8'h00, 0);

    repeat (3) begin
      send_tr("post_reset_idle", 1'b1, 16'h0,
              0, 16'h0, 32'h0,
              0, 8'h00,
              16'h0, 0,
              8'h00, 0);
    end

    for (int i = 0; i < 16; i++) begin
      write_ctl($sformatf("write_irq%0d_ctl", i),
                ctl_addr(i),
                shared_prio);
    end

    send_tr("assert_tie_break_irqs", 1'b1, active_mask,
            0, 16'h0, 32'h0,
            0, 8'h00,
            enable_mask, 1,
            8'h00, 0);

    repeat (5) begin
      send_tr("wait_initial_resolve", 1'b1, active_mask,
              0, 16'h0, 32'h0,
              0, 8'h00,
              enable_mask, 0,
              8'h00, 0);
    end

    repeat (3) begin

      winner = find_highest_id(work_mask);

      send_tr("ack_highest_id_winner", 1'b1, work_mask,
              0, 16'h0, 32'h0,
              0, 8'h00,
              enable_mask, 0,
              8'h00, 1);

      repeat (2) begin
        send_tr("idle_after_ack", 1'b1, work_mask,
                0, 16'h0, 32'h0,
                0, 8'h00,
                enable_mask, 0,
                8'h00, 0);
      end

      work_mask[winner] = 1'b0;

      send_tr("eoi_highest_id_winner", 1'b1, work_mask,
              0, 16'h0, 32'h0,
              1, 8'h10 + winner[7:0],
              enable_mask, 0,
              8'h00, 0);

      repeat (4) begin
        send_tr("wait_next_tie_resolve", 1'b1, work_mask,
                0, 16'h0, 32'h0,
                0, 8'h00,
                enable_mask, 0,
                8'h00, 0);
      end

    end

  endtask

  task write_ctl(string name, bit [15:0] addr, bit [7:0] data);
    send_tr(name, 1'b1, 16'h0,
            1, addr, {24'h0, data},
            0, 8'h00,
            16'h0, 0,
            8'h00, 0);
  endtask

  task send_tr(
    string name,
    bit soc_rst,
    bit [15:0] ext_int,
    bit wr_en,
    bit [15:0] wr_addr,
    bit [31:0] wr_data,
    bit eoi_valid,
    bit [7:0] eoi_id,
    bit [15:0] enable_bits,
    bit enable_valid,
    bit [7:0] active_lvl,
    bit ack_valid
  );

    int_seq_item tr;

    tr = int_seq_item::type_id::create(name);
    start_item(tr);

    tr.soc_rst = soc_rst;
    tr.ext_int = ext_int;

    tr.soc_mmr_write_en_i   = wr_en;
    tr.soc_mmr_write_addr_i = wr_addr;
    tr.soc_mmr_write_data_i = wr_data;

    tr.soc_mmr_read_en_i   = 0;
    tr.soc_mmr_read_addr_i = 0;

    tr.soc_ack_read_valid_en = ack_valid;

    tr.soc_eoi_valid_i = eoi_valid;
    tr.soc_eoi_id_i    = eoi_id;

    tr.active_lvl_pr_i = active_lvl;

    tr.global_int_enable_bit_i   = enable_bits;
    tr.global_int_enable_valid_i = enable_valid;

    tr.debug_mode_valid_i = 0;
    tr.debug_mode_reset_i = 0;
    tr.debug_ndm_reset_i  = 0;

    finish_item(tr);

  endtask

endclass


// ============================================================
// RANDOM EOI PROGRESSION SEQUENCE - 16 IRQ
// ============================================================
class random_eoi_progression_seq extends uvm_sequence #(int_seq_item);

  `uvm_object_utils(random_eoi_progression_seq)

  rand bit [7:0]  irq_ctl [16];
  rand bit [15:0] active_mask;
  rand bit [15:0] enable_mask;

  constraint valid_c {
    active_mask != 16'h0;
    enable_mask != 16'h0;
    (active_mask & enable_mask) != 16'h0;
    $countones(active_mask & enable_mask) >= 3;

    foreach (irq_ctl[i]) {
      irq_ctl[i] inside {[8'h01:8'hFF]};
    }
  }

  function new(string name = "random_eoi_progression_seq");
    super.new(name);
  endfunction

  function automatic bit [15:0] ctl_addr(int id);
    return 16'h1003 + (id * 4);
  endfunction

  function automatic int find_best_id(bit [15:0] mask);
    int best_id;
    bit [7:0] best_prio;

    best_id   = -1;
    best_prio = 8'h00;

    for (int i = 0; i < 16; i++) begin
      if (mask[i]) begin
        if ((best_id == -1) ||
            (irq_ctl[i] > best_prio) ||
            ((irq_ctl[i] == best_prio) && (i > best_id))) begin
          best_id   = i;
          best_prio = irq_ctl[i];
        end
      end
    end

    return best_id;
  endfunction

  task body();

    bit [15:0] work_mask;
    int winner;

    if (!this.randomize())
      `uvm_fatal("RAND_EOI_PROG_SEQ", "Randomization failed")

    work_mask = active_mask & enable_mask;

    send_tr("reset", 1'b0, 16'h0,
            0, 16'h0, 32'h0,
            0, 8'h00,
            16'h0, 0,
            8'h00, 0);

    repeat (3) begin
      send_tr("post_reset_idle", 1'b1, 16'h0,
              0, 16'h0, 32'h0,
              0, 8'h00,
              16'h0, 0,
              8'h00, 0);
    end

    for (int i = 0; i < 16; i++) begin
      write_ctl($sformatf("write_irq%0d_ctl", i),
                ctl_addr(i),
                irq_ctl[i]);
    end

    send_tr("assert_initial_irqs", 1'b1, active_mask,
            0, 16'h0, 32'h0,
            0, 8'h00,
            enable_mask, 1,
            8'h00, 0);

    repeat (5) begin
      send_tr("wait_initial_resolve", 1'b1, active_mask,
              0, 16'h0, 32'h0,
              0, 8'h00,
              enable_mask, 0,
              8'h00, 0);
    end

    repeat (3) begin

      winner = find_best_id(work_mask);

      send_tr("ack_current_winner", 1'b1, work_mask,
              0, 16'h0, 32'h0,
              0, 8'h00,
              enable_mask, 0,
              8'h00, 1);

      repeat (2) begin
        send_tr("idle_after_ack", 1'b1, work_mask,
                0, 16'h0, 32'h0,
                0, 8'h00,
                enable_mask, 0,
                8'h00, 0);
      end

      work_mask[winner] = 1'b0;

      send_tr("eoi_current_winner", 1'b1, work_mask,
              0, 16'h0, 32'h0,
              1, 8'h10 + winner[7:0],
              enable_mask, 0,
              8'h00, 0);

      repeat (4) begin
        send_tr("wait_next_resolve", 1'b1, work_mask,
                0, 16'h0, 32'h0,
                0, 8'h00,
                enable_mask, 0,
                8'h00, 0);
      end

    end

  endtask

  task write_ctl(string name, bit [15:0] addr, bit [7:0] data);
    send_tr(name, 1'b1, 16'h0,
            1, addr, {24'h0, data},
            0, 8'h00,
            16'h0, 0,
            8'h00, 0);
  endtask

  task send_tr(
    string name,
    bit soc_rst,
    bit [15:0] ext_int,
    bit wr_en,
    bit [15:0] wr_addr,
    bit [31:0] wr_data,
    bit eoi_valid,
    bit [7:0] eoi_id,
    bit [15:0] enable_bits,
    bit enable_valid,
    bit [7:0] active_lvl,
    bit ack_valid
  );

    int_seq_item tr;

    tr = int_seq_item::type_id::create(name);
    start_item(tr);

    tr.soc_rst = soc_rst;
    tr.ext_int = ext_int;

    tr.soc_mmr_write_en_i   = wr_en;
    tr.soc_mmr_write_addr_i = wr_addr;
    tr.soc_mmr_write_data_i = wr_data;

    tr.soc_mmr_read_en_i   = 0;
    tr.soc_mmr_read_addr_i = 0;

    tr.soc_ack_read_valid_en = ack_valid;

    tr.soc_eoi_valid_i = eoi_valid;
    tr.soc_eoi_id_i    = eoi_id;

    tr.active_lvl_pr_i = active_lvl;

    tr.global_int_enable_bit_i   = enable_bits;
    tr.global_int_enable_valid_i = enable_valid;

    tr.debug_mode_valid_i = 0;
    tr.debug_mode_reset_i = 0;
    tr.debug_ndm_reset_i  = 0;

    finish_item(tr);

  endtask

endclass


// ============================================================
// RANDOM ACK LATENCY SEQUENCE - 16 IRQ
// ============================================================
class random_ack_latency_seq extends uvm_sequence #(int_seq_item);

  `uvm_object_utils(random_ack_latency_seq)

  rand bit [7:0]  irq_ctl [16];
  rand bit [15:0] active_mask;
  rand bit [15:0] enable_mask;
  rand int unsigned ack_delay;

  constraint valid_c {
    active_mask != 16'h0;
    enable_mask != 16'h0;
    (active_mask & enable_mask) != 16'h0;

    ack_delay inside {[1:25]};

    foreach (irq_ctl[i]) {
      irq_ctl[i] inside {[8'h01:8'hFF]};
    }
  }

  function new(string name = "random_ack_latency_seq");
    super.new(name);
  endfunction

  function automatic bit [15:0] ctl_addr(int id);
    return 16'h1003 + (id * 4);
  endfunction

  task body();

    int best_id;
    bit [7:0] best_prio;

    if (!this.randomize())
      `uvm_fatal("RAND_ACK_LAT_SEQ", "Randomization failed")

    best_id   = -1;
    best_prio = 8'h00;

    for (int i = 0; i < 16; i++) begin
      if (active_mask[i] && enable_mask[i]) begin
        if ((best_id == -1) ||
            (irq_ctl[i] > best_prio) ||
            ((irq_ctl[i] == best_prio) && (i > best_id))) begin
          best_id   = i;
          best_prio = irq_ctl[i];
        end
      end
    end

    send_tr("reset", 1'b0, 16'h0,
            0, 16'h0, 32'h0,
            0, 8'h00,
            16'h0, 0,
            8'h00, 0);

    repeat (3) begin
      send_tr("post_reset_idle", 1'b1, 16'h0,
              0, 16'h0, 32'h0,
              0, 8'h00,
              16'h0, 0,
              8'h00, 0);
    end

    for (int i = 0; i < 16; i++) begin
      write_ctl($sformatf("write_irq%0d_ctl", i),
                ctl_addr(i),
                irq_ctl[i]);
    end

    send_tr("assert_irqs", 1'b1, active_mask,
            0, 16'h0, 32'h0,
            0, 8'h00,
            enable_mask, 1,
            8'h00, 0);

    repeat (ack_delay) begin
      send_tr("wait_before_ack_random_delay", 1'b1, active_mask,
              0, 16'h0, 32'h0,
              0, 8'h00,
              enable_mask, 0,
              8'h00, 0);
    end

    repeat (2) begin
      send_tr("ack_after_random_delay", 1'b1, active_mask,
              0, 16'h0, 32'h0,
              0, 8'h00,
              enable_mask, 0,
              8'h00, 1);
    end

    repeat (2) begin
      send_tr("idle_after_ack_sample", 1'b1, active_mask,
              0, 16'h0, 32'h0,
              0, 8'h00,
              enable_mask, 0,
              8'h00, 0);
    end

    send_tr("clear_irqs_after_ack", 1'b1, 16'h0,
            0, 16'h0, 32'h0,
            0, 8'h00,
            enable_mask, 0,
            8'h00, 0);

    repeat (3) begin
      send_tr("final_idle", 1'b1, 16'h0,
              0, 16'h0, 32'h0,
              0, 8'h00,
              enable_mask, 0,
              8'h00, 0);
    end

  endtask

  task write_ctl(string name, bit [15:0] addr, bit [7:0] data);
    send_tr(name, 1'b1, 16'h0,
            1, addr, {24'h0, data},
            0, 8'h00,
            16'h0, 0,
            8'h00, 0);
  endtask

  task send_tr(
    string name,
    bit soc_rst,
    bit [15:0] ext_int,
    bit wr_en,
    bit [15:0] wr_addr,
    bit [31:0] wr_data,
    bit eoi_valid,
    bit [7:0] eoi_id,
    bit [15:0] enable_bits,
    bit enable_valid,
    bit [7:0] active_lvl,
    bit ack_valid
  );

    int_seq_item tr;

    tr = int_seq_item::type_id::create(name);
    start_item(tr);

    tr.soc_rst = soc_rst;
    tr.ext_int = ext_int;

    tr.soc_mmr_write_en_i   = wr_en;
    tr.soc_mmr_write_addr_i = wr_addr;
    tr.soc_mmr_write_data_i = wr_data;

    tr.soc_mmr_read_en_i   = 0;
    tr.soc_mmr_read_addr_i = 0;

    tr.soc_ack_read_valid_en = ack_valid;

    tr.soc_eoi_valid_i = eoi_valid;
    tr.soc_eoi_id_i    = eoi_id;

    tr.active_lvl_pr_i = active_lvl;

    tr.global_int_enable_bit_i   = enable_bits;
    tr.global_int_enable_valid_i = enable_valid;

    tr.debug_mode_valid_i = 0;
    tr.debug_mode_reset_i = 0;
    tr.debug_ndm_reset_i  = 0;

    finish_item(tr);

  endtask

endclass

// ============================================================
// RANDOM EQUAL PRIORITY SEQUENCE - 16 IRQ
// ============================================================
class random_equal_priority_seq extends uvm_sequence #(int_seq_item);

  `uvm_object_utils(random_equal_priority_seq)

  rand bit [15:0] active_mask;
  rand bit [15:0] enable_mask;
  rand bit [7:0]  shared_prio;

  bit [7:0] irq_ctl [16];

  constraint valid_c {
    active_mask != 16'h0;
    enable_mask != 16'h0;
    (active_mask & enable_mask) != 16'h0;
    shared_prio inside {[8'h01:8'hFF]};
  }

  function new(string name = "random_equal_priority_seq");
    super.new(name);
  endfunction

  function automatic bit [15:0] ctl_addr(int id);
    return 16'h1003 + (id * 4);
  endfunction

  task body();

    int winner_id;

    if (!this.randomize())
      `uvm_fatal("RAND_EQUAL_PRIO_SEQ", "Randomization failed")

    foreach (irq_ctl[i]) begin
      irq_ctl[i] = shared_prio;
    end

    winner_id = -1;

    for (int i = 0; i < 16; i++) begin
      if (active_mask[i] && enable_mask[i]) begin
        if (i > winner_id)
          winner_id = i;
      end
    end

    send_tr("reset", 1'b0, 16'h0,
            0, 16'h0, 32'h0,
            0, 8'h00,
            16'h0, 0,
            8'h00, 0);

    repeat (3) begin
      send_tr("post_reset_idle", 1'b1, 16'h0,
              0, 16'h0, 32'h0,
              0, 8'h00,
              16'h0, 0,
              8'h00, 0);
    end

    for (int i = 0; i < 16; i++) begin
      write_ctl($sformatf("write_irq%0d_ctl", i),
                ctl_addr(i),
                irq_ctl[i]);
    end

    send_tr("assert_equal_priority_irqs", 1'b1, active_mask,
            0, 16'h0, 32'h0,
            0, 8'h00,
            enable_mask, 1,
            8'h00, 0);

    repeat (5) begin
      send_tr("wait_resolve", 1'b1, active_mask,
              0, 16'h0, 32'h0,
              0, 8'h00,
              enable_mask, 0,
              8'h00, 0);
    end

    send_tr("ack_winner", 1'b1, active_mask,
            0, 16'h0, 32'h0,
            0, 8'h00,
            enable_mask, 0,
            8'h00, 1);

  endtask

  task write_ctl(string name, bit [15:0] addr, bit [7:0] data);
    send_tr(name, 1'b1, 16'h0,
            1, addr, {24'h0, data},
            0, 8'h00,
            16'h0, 0,
            8'h00, 0);
  endtask

  task send_tr(
    string name,
    bit soc_rst,
    bit [15:0] ext_int,
    bit wr_en,
    bit [15:0] wr_addr,
    bit [31:0] wr_data,
    bit eoi_valid,
    bit [7:0] eoi_id,
    bit [15:0] enable_bits,
    bit enable_valid,
    bit [7:0] active_lvl,
    bit ack_valid
  );

    int_seq_item tr;

    tr = int_seq_item::type_id::create(name);
    start_item(tr);

    tr.soc_rst = soc_rst;
    tr.ext_int = ext_int;

    tr.soc_mmr_write_en_i   = wr_en;
    tr.soc_mmr_write_addr_i = wr_addr;
    tr.soc_mmr_write_data_i = wr_data;

    tr.soc_mmr_read_en_i   = 0;
    tr.soc_mmr_read_addr_i = 0;

    tr.soc_ack_read_valid_en = ack_valid;

    tr.soc_eoi_valid_i = eoi_valid;
    tr.soc_eoi_id_i    = eoi_id;

    tr.active_lvl_pr_i = active_lvl;

    tr.global_int_enable_bit_i   = enable_bits;
    tr.global_int_enable_valid_i = enable_valid;

    tr.debug_mode_valid_i = 0;
    tr.debug_mode_reset_i = 0;
    tr.debug_ndm_reset_i  = 0;

    finish_item(tr);

  endtask

endclass

/////////////////////

class random_active_level_priority_seq extends uvm_sequence #(int_seq_item);

  `uvm_object_utils(random_active_level_priority_seq)

  rand int unsigned irq_count;
  rand bit [7:0] active_lvl;

  constraint c_valid {
    irq_count inside {[1:10]};
  }

  function new(string name = "random_active_level_priority_seq");
    super.new(name);
  endfunction

  function automatic bit [15:0] ctl_addr(int irq);
    return 16'h1003 + (irq * 4);
  endfunction

  task body();

    int irq;
    bit [15:0] ext_mask;
    bit [15:0] en_mask;
    bit [7:0] ctl_val;

    if (!this.randomize())
      `uvm_fatal("RAND_ACT_LVL", "Randomization failed")

    send_tr("reset",
            1'b0,
            16'h0000,
            1'b0, 16'h0000, 32'h0000_0000,
            1'b0, 8'h00,
            16'h0000, 1'b0,
            8'h00,
            1'b0);

    active_lvl = $urandom_range(8'h00, 8'hFF);

    ext_mask = 16'h0000;
    en_mask  = 16'h0000;

    repeat (irq_count) begin

      irq     = $urandom_range(0, 15);
      ctl_val = $urandom_range(8'h01, 8'hFF);

      write_ctl($sformatf("irq_%0d_ctl", irq),
                ctl_addr(irq),
                ctl_val);

      ext_mask[irq] = 1'b1;
      en_mask[irq]  = 1'b1;

    end

    send_tr("assert_random_irqs",
            1'b1,
            ext_mask,
            1'b0, 16'h0000, 32'h0000_0000,
            1'b0, 8'h00,
            en_mask, 1'b1,
            active_lvl,
            1'b0);

    repeat ($urandom_range(2, 8)) begin
      send_tr("wait_irq",
              1'b1,
              ext_mask,
              1'b0, 16'h0000, 32'h0000_0000,
              1'b0, 8'h00,
              en_mask, 1'b0,
              active_lvl,
              1'b0);
    end

    send_tr("ack_read",
            1'b1,
            ext_mask,
            1'b0, 16'h0000, 32'h0000_0000,
            1'b0, 8'h00,
            en_mask, 1'b0,
            active_lvl,
            1'b1);

    repeat ($urandom_range(1, 5)) begin
      send_tr("idle",
              1'b1,
              16'h0000,
              1'b0, 16'h0000, 32'h0000_0000,
              1'b0, 8'h00,
              en_mask, 1'b0,
              active_lvl,
              1'b0);
    end

  endtask


  task write_ctl(
    string name,
    bit [15:0] addr,
    bit [7:0] data
  );

    send_tr(name,
            1'b1,
            16'h0000,
            1'b1,
            addr,
            {24'h0, data},
            1'b0,
            8'h00,
            16'h0000,
            1'b0,
            8'h00,
            1'b0);

  endtask


  task send_tr(
    string name,
    bit soc_rst,
    bit [15:0] ext_int,
    bit wr_en,
    bit [15:0] wr_addr,
    bit [31:0] wr_data,
    bit eoi_valid,
    bit [7:0] eoi_id,
    bit [15:0] enable_mask,
    bit enable_valid,
    bit [7:0] active_lvl_pr,
    bit ack_valid
  );

    int_seq_item tr;

    tr = int_seq_item::type_id::create(name);

    start_item(tr);

    tr.soc_rst = soc_rst;

    tr.ext_int = ext_int;

    tr.soc_mmr_write_en_i   = wr_en;
    tr.soc_mmr_write_addr_i = wr_addr;
    tr.soc_mmr_write_data_i = wr_data;

    tr.soc_mmr_read_en_i   = 1'b0;
    tr.soc_mmr_read_addr_i = 16'h0000;

    tr.soc_ack_read_valid_en = ack_valid;

    tr.soc_eoi_valid_i = eoi_valid;
    tr.soc_eoi_id_i    = eoi_id;

    tr.active_lvl_pr_i = active_lvl_pr;

    tr.global_int_enable_bit_i   = enable_mask;
    tr.global_int_enable_valid_i = enable_valid;

    tr.debug_mode_valid_i = 1'b0;
    tr.debug_mode_reset_i = 1'b0;
    tr.debug_ndm_reset_i  = 1'b0;

    finish_item(tr);

  endtask

endclass
// ============================================================
// RANDOM ENABLE MASK SEQUENCE - 16 IRQ
// ============================================================
class random_enable_mask_seq extends uvm_sequence #(int_seq_item);

  `uvm_object_utils(random_enable_mask_seq)

  rand bit [7:0]  irq_ctl [16];
  rand bit [15:0] ext_mask;
  rand bit [15:0] en_mask;

  constraint valid_c {
    ext_mask != 16'h0;
    en_mask  != 16'h0;
    (ext_mask & en_mask) != 16'h0;

    foreach (irq_ctl[i]) {
      irq_ctl[i] inside {[8'h01:8'hFF]};
    }
  }

  function new(string name = "random_enable_mask_seq");
    super.new(name);
  endfunction

  function automatic bit [15:0] ctl_addr(int id);
    return 16'h1003 + (id * 4);
  endfunction

  task body();

    int best_id;
    bit [7:0] best_prio;

    if (!this.randomize())
      `uvm_fatal("RAND_EN_MASK_SEQ", "Randomization failed")

    best_id   = -1;
    best_prio = 8'h00;

    for (int i = 0; i < 16; i++) begin
      if (ext_mask[i] && en_mask[i]) begin
        if ((best_id == -1) ||
            (irq_ctl[i] > best_prio) ||
            ((irq_ctl[i] == best_prio) && (i > best_id))) begin
          best_id   = i;
          best_prio = irq_ctl[i];
        end
      end
    end

    send_tr("reset", 1'b0, 16'h0,
            0, 16'h0, 32'h0,
            0, 8'h00,
            16'h0, 0,
            8'h00, 0);

    repeat (3) begin
      send_tr("post_reset_idle", 1'b1, 16'h0,
              0, 16'h0, 32'h0,
              0, 8'h00,
              16'h0, 0,
              8'h00, 0);
    end

    for (int i = 0; i < 16; i++) begin
      write_ctl($sformatf("write_irq%0d_ctl", i),
                ctl_addr(i),
                irq_ctl[i]);
    end

    send_tr("assert_random_enable_mask", 1'b1, ext_mask,
            0, 16'h0, 32'h0,
            0, 8'h00,
            en_mask, 1,
            8'h00, 0);

    repeat (5) begin
      send_tr("wait_resolve", 1'b1, ext_mask,
              0, 16'h0, 32'h0,
              0, 8'h00,
              en_mask, 0,
              8'h00, 0);
    end

    send_tr("ack_enabled_winner", 1'b1, ext_mask,
            0, 16'h0, 32'h0,
            0, 8'h00,
            en_mask, 0,
            8'h00, 1);

  endtask

  task write_ctl(string name, bit [15:0] addr, bit [7:0] data);
    send_tr(name, 1'b1, 16'h0,
            1, addr, {24'h0, data},
            0, 8'h00,
            16'h0, 0,
            8'h00, 0);
  endtask

  task send_tr(
    string name,
    bit soc_rst,
    bit [15:0] ext_int,
    bit wr_en,
    bit [15:0] wr_addr,
    bit [31:0] wr_data,
    bit eoi_valid,
    bit [7:0] eoi_id,
    bit [15:0] enable_mask,
    bit enable_valid,
    bit [7:0] active_lvl,
    bit ack_valid
  );

    int_seq_item tr;

    tr = int_seq_item::type_id::create(name);
    start_item(tr);

    tr.soc_rst = soc_rst;
    tr.ext_int = ext_int;

    tr.soc_mmr_write_en_i   = wr_en;
    tr.soc_mmr_write_addr_i = wr_addr;
    tr.soc_mmr_write_data_i = wr_data;

    tr.soc_mmr_read_en_i   = 0;
    tr.soc_mmr_read_addr_i = 0;

    tr.soc_ack_read_valid_en = ack_valid;

    tr.soc_eoi_valid_i = eoi_valid;
    tr.soc_eoi_id_i    = eoi_id;

    tr.active_lvl_pr_i = active_lvl;

    tr.global_int_enable_bit_i   = enable_mask;
    tr.global_int_enable_valid_i = enable_valid;

    tr.debug_mode_valid_i = 0;
    tr.debug_mode_reset_i = 0;
    tr.debug_ndm_reset_i  = 0;

    finish_item(tr);

  endtask

endclass


// ============================================================
// SAME PRIORITY RANDOM SEQUENCE - 16 IRQ
// ============================================================
class same_priority_random_seq extends uvm_sequence #(int_seq_item);

  `uvm_object_utils(same_priority_random_seq)

  rand int irq_id[5];
  rand bit [7:0] common_prio;

  constraint irq_c {
    foreach (irq_id[i]) {
      irq_id[i] inside {[0:15]};
    }

    foreach (irq_id[i]) {
      foreach (irq_id[j]) {
        if (i != j) irq_id[i] != irq_id[j];
      }
    }

    common_prio inside {[8'h01:8'hFF]};
  }

  function new(string name = "same_priority_random_seq");
    super.new(name);
  endfunction

  function automatic bit [15:0] ctl_addr(int id);
    return 16'h1003 + (id * 4);
  endfunction

  task body();

    bit [15:0] irq_mask;
    int expected_id;

    if (!this.randomize())
      `uvm_fatal("SAME_PRIO_SEQ", "Randomization failed")

    irq_mask    = 16'h0;
    expected_id = irq_id[0];

    foreach (irq_id[i]) begin
      irq_mask[irq_id[i]] = 1'b1;

      if (irq_id[i] > expected_id)
        expected_id = irq_id[i];
    end

    send_tr("reset", 1'b0, 16'h0,
            0, 16'h0, 32'h0,
            0, 8'h00,
            16'h0, 0,
            8'h00, 0);

    repeat (3) begin
      send_tr("post_reset_idle", 1'b1, 16'h0,
              0, 16'h0, 32'h0,
              0, 8'h00,
              16'h0, 0,
              8'h00, 0);
    end

    foreach (irq_id[i]) begin
      write_ctl($sformatf("write_irq%0d_ctl", irq_id[i]),
                ctl_addr(irq_id[i]),
                common_prio);
    end

    send_tr("assert_same_priority_irqs", 1'b1, irq_mask,
            0, 16'h0, 32'h0,
            0, 8'h00,
            irq_mask, 1,
            8'h00, 0);

    repeat (5) begin
      send_tr("wait_resolve", 1'b1, irq_mask,
              0, 16'h0, 32'h0,
              0, 8'h00,
              irq_mask, 0,
              8'h00, 0);
    end

    send_tr("ack_highest_id", 1'b1, irq_mask,
            0, 16'h0, 32'h0,
            0, 8'h00,
            irq_mask, 0,
            8'h00, 1);

    repeat (3) begin
      send_tr("idle_after_ack", 1'b1, irq_mask,
              0, 16'h0, 32'h0,
              0, 8'h00,
              irq_mask, 0,
              8'h00, 0);
    end

  endtask

  task write_ctl(string name, bit [15:0] addr, bit [7:0] data);
    send_tr(name, 1'b1, 16'h0,
            1, addr, {24'h0, data},
            0, 8'h00,
            16'h0, 0,
            8'h00, 0);
  endtask

  task send_tr(
    string name,
    bit soc_rst,
    bit [15:0] ext_int,
    bit wr_en,
    bit [15:0] wr_addr,
    bit [31:0] wr_data,
    bit eoi_valid,
    bit [7:0] eoi_id,
    bit [15:0] enable_mask,
    bit enable_valid,
    bit [7:0] active_lvl,
    bit ack_valid
  );

    int_seq_item tr;

    tr = int_seq_item::type_id::create(name);
    start_item(tr);

    tr.soc_rst = soc_rst;
    tr.ext_int = ext_int;

    tr.soc_mmr_write_en_i   = wr_en;
    tr.soc_mmr_write_addr_i = wr_addr;
    tr.soc_mmr_write_data_i = wr_data;

    tr.soc_mmr_read_en_i   = 0;
    tr.soc_mmr_read_addr_i = 0;

    tr.soc_ack_read_valid_en = ack_valid;

    tr.soc_eoi_valid_i = eoi_valid;
    tr.soc_eoi_id_i    = eoi_id;

    tr.active_lvl_pr_i = active_lvl;

    tr.global_int_enable_bit_i   = enable_mask;
    tr.global_int_enable_valid_i = enable_valid;

    tr.debug_mode_valid_i = 0;
    tr.debug_mode_reset_i = 0;
    tr.debug_ndm_reset_i  = 0;

    finish_item(tr);

  endtask

endclass


// ============================================================
// RANDOM ALL 16 IRQ SEQUENCE
// ============================================================
class random_all_16_irq_seq extends uvm_sequence #(int_seq_item);

  `uvm_object_utils(random_all_16_irq_seq)

  rand bit [7:0]  irq_ctl [16];
  rand bit [15:0] irq_mask;

  constraint valid_c {
    irq_mask != 16'h0;

    foreach (irq_ctl[i]) {
      irq_ctl[i] inside {[8'h01:8'hFF]};
    }
  }

  function new(string name = "random_all_16_irq_seq");
    super.new(name);
  endfunction

  function automatic bit [15:0] ctl_addr(int irq_id);
    return 16'h1003 + (irq_id * 4);
  endfunction

  function automatic int find_best_id(bit [15:0] mask);

    int best_id;
    bit [7:0] best_prio;

    best_id   = -1;
    best_prio = 8'h00;

    for (int i = 0; i < 16; i++) begin
      if (mask[i]) begin
        if ((best_id == -1) ||
            (irq_ctl[i] > best_prio) ||
            ((irq_ctl[i] == best_prio) && (i > best_id))) begin
          best_id   = i;
          best_prio = irq_ctl[i];
        end
      end
    end

    return best_id;

  endfunction

  task body();

    int best_id;

    if (!this.randomize())
      `uvm_fatal("RAND16_SEQ", "randomization failed")

    best_id = find_best_id(irq_mask);

    send_tr("reset", 1'b0, 16'h0,
            0, 16'h0, 32'h0,
            0, 8'h00,
            16'h0, 0,
            8'h00, 0);

    repeat (3) begin
      send_tr("post_reset_idle", 1'b1, 16'h0,
              0, 16'h0, 32'h0,
              0, 8'h00,
              16'h0, 0,
              8'h00, 0);
    end

    for (int i = 0; i < 16; i++) begin
      write_ctl($sformatf("write_irq%0d_ctl", i),
                ctl_addr(i),
                irq_ctl[i]);
    end

    send_tr("enable_all_assert_random_mask", 1'b1, irq_mask,
            0, 16'h0, 32'h0,
            0, 8'h00,
            16'hFFFF, 1,
            8'h00, 0);

    repeat (5) begin
      send_tr("wait_priority_resolve", 1'b1, irq_mask,
              0, 16'h0, 32'h0,
              0, 8'h00,
              16'hFFFF, 0,
              8'h00, 0);
    end

    send_tr("ack_random_winner", 1'b1, irq_mask,
            0, 16'h0, 32'h0,
            0, 8'h00,
            16'hFFFF, 0,
            8'h00, 1);

    repeat (2) begin
      send_tr("idle_after_first_ack", 1'b1, irq_mask,
              0, 16'h0, 32'h0,
              0, 8'h00,
              16'hFFFF, 0,
              8'h00, 0);
    end

    irq_mask[best_id] = 1'b0;

    send_tr("eoi_first_winner", 1'b1, irq_mask,
            0, 16'h0, 32'h0,
            1, 8'h10 + best_id[7:0],
            16'hFFFF, 0,
            8'h00, 0);

    repeat (3) begin
      send_tr("wait_next_pending", 1'b1, irq_mask,
              0, 16'h0, 32'h0,
              0, 8'h00,
              16'hFFFF, 0,
              8'h00, 0);
    end

    if (irq_mask != 16'h0) begin
      send_tr("ack_next_winner", 1'b1, irq_mask,
              0, 16'h0, 32'h0,
              0, 8'h00,
              16'hFFFF, 0,
              8'h00, 1);
    end

    repeat (3) begin
      send_tr("idle_after_ack", 1'b1, irq_mask,
              0, 16'h0, 32'h0,
              0, 8'h00,
              16'hFFFF, 0,
              8'h00, 0);
    end

  endtask

  task write_ctl(string name, bit [15:0] addr, bit [7:0] data);
    send_tr(name, 1'b1, 16'h0,
            1, addr, {24'h0, data},
            0, 8'h00,
            16'h0, 0,
            8'h00, 0);
  endtask

  task send_tr(
    string name,
    bit soc_rst,
    bit [15:0] ext_int,
    bit wr_en,
    bit [15:0] wr_addr,
    bit [31:0] wr_data,
    bit eoi_valid,
    bit [7:0] eoi_id,
    bit [15:0] enable_mask,
    bit enable_valid,
    bit [7:0] active_lvl,
    bit ack_valid
  );

    int_seq_item tr;

    tr = int_seq_item::type_id::create(name);
    start_item(tr);

    tr.soc_rst = soc_rst;
    tr.ext_int = ext_int;

    tr.soc_mmr_write_en_i   = wr_en;
    tr.soc_mmr_write_addr_i = wr_addr;
    tr.soc_mmr_write_data_i = wr_data;

    tr.soc_mmr_read_en_i   = 0;
    tr.soc_mmr_read_addr_i = 0;

    tr.soc_ack_read_valid_en = ack_valid;

    tr.soc_eoi_valid_i = eoi_valid;
    tr.soc_eoi_id_i    = eoi_id;

    tr.active_lvl_pr_i = active_lvl;

    tr.global_int_enable_bit_i   = enable_mask;
    tr.global_int_enable_valid_i = enable_valid;

    tr.debug_mode_valid_i = 0;
    tr.debug_mode_reset_i = 0;
    tr.debug_ndm_reset_i  = 0;

    finish_item(tr);

  endtask

endclass

// ============================================================
// ENABLE / DISABLE MASKING SEQUENCE - 16 IRQ
// ============================================================
class enable_disable_masking_seq extends uvm_sequence #(int_seq_item);

  `uvm_object_utils(enable_disable_masking_seq)

  function new(string name = "enable_disable_masking_seq");
    super.new(name);
  endfunction

  task body();

    // RESET: active-low
    send_tr("reset", 1'b0, 16'h0000,
            0, 16'h0000, 32'h0000_0000,
            0, 8'h00,
            16'h0000, 0,
            8'h00, 0);

    repeat (3)
      send_tr("post_reset_idle", 1'b1, 16'h0000,
              0, 16'h0000, 32'h0000_0000,
              0, 8'h00,
              16'h0000, 0,
              8'h00, 0);

    // IRQ5 control address = 16'h1003 + 5*4 = 16'h1017
    write_ctl("irq5_ctl", 16'h1017, 8'hE0);

    // IRQ5 active, but disabled
    send_tr("irq5_active_disabled", 1'b1, 16'h0020,
            0, 16'h0000, 32'h0000_0000,
            0, 8'h00,
            16'h0000, 1,
            8'h00, 0);

    repeat (5)
      send_tr("wait_disabled", 1'b1, 16'h0020,
              0, 16'h0000, 32'h0000_0000,
              0, 8'h00,
              16'h0000, 0,
              8'h00, 0);

    // Enable IRQ5 while still active
    send_tr("enable_irq5", 1'b1, 16'h0020,
            0, 16'h0000, 32'h0000_0000,
            0, 8'h00,
            16'h0020, 1,
            8'h00, 0);

    repeat (3)
      send_tr("wait_enabled_irq5", 1'b1, 16'h0020,
              0, 16'h0000, 32'h0000_0000,
              0, 8'h00,
              16'h0020, 0,
              8'h00, 0);

    // ACK IRQ5 expected = 8'h15
    send_tr("ack_irq5", 1'b1, 16'h0020,
            0, 16'h0000, 32'h0000_0000,
            0, 8'h00,
            16'h0020, 0,
            8'h00, 1);

    repeat (2)
      send_tr("idle_after_ack", 1'b1, 16'h0020,
              0, 16'h0000, 32'h0000_0000,
              0, 8'h00,
              16'h0020, 0,
              8'h00, 0);

    // Disable IRQ5 again while still active
    send_tr("disable_irq5_again", 1'b1, 16'h0020,
            0, 16'h0000, 32'h0000_0000,
            0, 8'h00,
            16'h0000, 1,
            8'h00, 0);

    repeat (5)
      send_tr("wait_after_disable_again", 1'b1, 16'h0020,
              0, 16'h0000, 32'h0000_0000,
              0, 8'h00,
              16'h0000, 0,
              8'h00, 0);

  endtask

  task write_ctl(string name, bit [15:0] addr, bit [7:0] data);
    send_tr(name, 1'b1, 16'h0000,
            1, addr, {24'h0, data},
            0, 8'h00,
            16'h0000, 0,
            8'h00, 0);
  endtask

  task send_tr(
    string name,
    bit soc_rst,
    bit [15:0] ext_int,
    bit wr_en,
    bit [15:0] wr_addr,
    bit [31:0] wr_data,
    bit eoi_valid,
    bit [7:0] eoi_id,
    bit [15:0] enable_mask,
    bit enable_valid,
    bit [7:0] active_lvl,
    bit ack_valid
  );

    int_seq_item tr;

    tr = int_seq_item::type_id::create(name);
    start_item(tr);

    tr.soc_rst = soc_rst;
    tr.ext_int = ext_int;

    tr.soc_mmr_write_en_i   = wr_en;
    tr.soc_mmr_write_addr_i = wr_addr;
    tr.soc_mmr_write_data_i = wr_data;

    tr.soc_mmr_read_en_i   = 1'b0;
    tr.soc_mmr_read_addr_i = 16'h0000;

    tr.soc_ack_read_valid_en = ack_valid;

    tr.soc_eoi_valid_i = eoi_valid;
    tr.soc_eoi_id_i    = eoi_id;

    tr.active_lvl_pr_i = active_lvl;

    tr.global_int_enable_bit_i   = enable_mask;
    tr.global_int_enable_valid_i = enable_valid;

    tr.debug_mode_valid_i = 1'b0;
    tr.debug_mode_reset_i = 1'b0;
    tr.debug_ndm_reset_i  = 1'b0;

    finish_item(tr);

  endtask

endclass


// ============================================================
// SIMULTANEOUS NEW IRQ DURING EOI SEQUENCE - 16 IRQ
// ============================================================
class simultaneous_new_irq_during_eoi_seq extends uvm_sequence #(int_seq_item);

  `uvm_object_utils(simultaneous_new_irq_during_eoi_seq)

  function new(string name = "simultaneous_new_irq_during_eoi_seq");
    super.new(name);
  endfunction

  task body();

    send_tr("reset", 1'b0, 16'h0000,
            0, 16'h0000, 32'h0000_0000,
            0, 8'h00,
            16'h0000, 0,
            8'h00, 0);

    repeat (3)
      send_tr("post_reset_idle", 1'b1, 16'h0000,
              0, 16'h0000, 32'h0000_0000,
              0, 8'h00,
              16'h0000, 0,
              8'h00, 0);

    // IRQ5 = 0x20, IRQ6 = 0xE0
    write_ctl("irq5_ctl", 16'h1017, 8'h20);
    write_ctl("irq6_ctl", 16'h101B, 8'hE0);

    // Assert IRQ5 only, enable IRQ5 and IRQ6
    send_tr("assert_irq5", 1'b1, 16'h0020,
            0, 16'h0000, 32'h0000_0000,
            0, 8'h00,
            16'h0060, 1,
            8'h00, 0);

    repeat (3)
      send_tr("wait_irq5", 1'b1, 16'h0020,
              0, 16'h0000, 32'h0000_0000,
              0, 8'h00,
              16'h0060, 0,
              8'h00, 0);

    // ACK IRQ5 expected = 8'h15
    send_tr("ack_irq5", 1'b1, 16'h0020,
            0, 16'h0000, 32'h0000_0000,
            0, 8'h00,
            16'h0060, 0,
            8'h00, 1);

    repeat (2)
      send_tr("wait_after_ack5", 1'b1, 16'h0020,
              0, 16'h0000, 32'h0000_0000,
              0, 8'h00,
              16'h0060, 0,
              8'h00, 0);

    // Same cycle: EOI IRQ5 and new IRQ6 arrives
    send_tr("eoi_irq5_new_irq6", 1'b1, 16'h0040,
            0, 16'h0000, 32'h0000_0000,
            1, 8'h15,
            16'h0060, 0,
            8'h00, 0);

    repeat (3)
      send_tr("wait_irq6", 1'b1, 16'h0040,
              0, 16'h0000, 32'h0000_0000,
              0, 8'h00,
              16'h0060, 0,
              8'h00, 0);

    // ACK IRQ6 expected = 8'h16
    send_tr("ack_irq6", 1'b1, 16'h0040,
            0, 16'h0000, 32'h0000_0000,
            0, 8'h00,
            16'h0060, 0,
            8'h00, 1);

    repeat (3)
      send_tr("idle", 1'b1, 16'h0000,
              0, 16'h0000, 32'h0000_0000,
              0, 8'h00,
              16'h0060, 0,
              8'h00, 0);

  endtask

  task write_ctl(string name, bit [15:0] addr, bit [7:0] data);
    send_tr(name, 1'b1, 16'h0000,
            1, addr, {24'h0, data},
            0, 8'h00,
            16'h0000, 0,
            8'h00, 0);
  endtask

  task send_tr(
    string name,
    bit soc_rst,
    bit [15:0] ext_int,
    bit wr_en,
    bit [15:0] wr_addr,
    bit [31:0] wr_data,
    bit eoi_valid,
    bit [7:0] eoi_id,
    bit [15:0] enable_mask,
    bit enable_valid,
    bit [7:0] active_lvl,
    bit ack_valid
  );

    int_seq_item tr;

    tr = int_seq_item::type_id::create(name);
    start_item(tr);

    tr.soc_rst = soc_rst;
    tr.ext_int = ext_int;

    tr.soc_mmr_write_en_i   = wr_en;
    tr.soc_mmr_write_addr_i = wr_addr;
    tr.soc_mmr_write_data_i = wr_data;

    tr.soc_mmr_read_en_i   = 1'b0;
    tr.soc_mmr_read_addr_i = 16'h0000;

    tr.soc_ack_read_valid_en = ack_valid;

    tr.soc_eoi_valid_i = eoi_valid;
    tr.soc_eoi_id_i    = eoi_id;

    tr.active_lvl_pr_i = active_lvl;

    tr.global_int_enable_bit_i   = enable_mask;
    tr.global_int_enable_valid_i = enable_valid;

    tr.debug_mode_valid_i = 1'b0;
    tr.debug_mode_reset_i = 1'b0;
    tr.debug_ndm_reset_i  = 1'b0;

    finish_item(tr);

  endtask

endclass


// ============================================================
// RANDOM MULTI IRQ SEQUENCE - 16 IRQ
// ============================================================
class random_multi_irq_seq extends uvm_sequence #(int_seq_item);

  `uvm_object_utils(random_multi_irq_seq)

  rand int irq_a;
  rand int irq_b;
  rand int irq_c;

  rand bit [7:0] prio_a;
  rand bit [7:0] prio_b;
  rand bit [7:0] prio_c;

  constraint valid_irq_c {
    irq_a inside {[0:15]};
    irq_b inside {[0:15]};
    irq_c inside {[0:15]};

    irq_a != irq_b;
    irq_b != irq_c;
    irq_a != irq_c;

    prio_a inside {[8'h01:8'hFF]};
    prio_b inside {[8'h01:8'hFF]};
    prio_c inside {[8'h01:8'hFF]};
  }

  function new(string name = "random_multi_irq_seq");
    super.new(name);
  endfunction

  function automatic bit [15:0] ctl_addr(int irq_id);
    return 16'h1003 + (irq_id * 4);
  endfunction

  task body();

    bit [15:0] irq_mask;

    if (!this.randomize())
      `uvm_fatal("RAND_SEQ", "randomization failed")

    irq_mask = 16'h0000;
    irq_mask[irq_a] = 1'b1;
    irq_mask[irq_b] = 1'b1;
    irq_mask[irq_c] = 1'b1;

    send_tr("reset", 1'b0, 16'h0000,
            0, 16'h0000, 32'h0000_0000,
            0, 8'h00,
            16'h0000, 0,
            8'h00, 0);

    repeat (3)
      send_tr("post_reset_idle", 1'b1, 16'h0000,
              0, 16'h0000, 32'h0000_0000,
              0, 8'h00,
              16'h0000, 0,
              8'h00, 0);

    write_ctl("write_irq_a", ctl_addr(irq_a), prio_a);
    write_ctl("write_irq_b", ctl_addr(irq_b), prio_b);
    write_ctl("write_irq_c", ctl_addr(irq_c), prio_c);

    send_tr("assert_random_irqs", 1'b1, irq_mask,
            0, 16'h0000, 32'h0000_0000,
            0, 8'h00,
            irq_mask, 1,
            8'h00, 0);

    repeat (3)
      send_tr("wait_random_irqs", 1'b1, irq_mask,
              0, 16'h0000, 32'h0000_0000,
              0, 8'h00,
              irq_mask, 0,
              8'h00, 0);

    send_tr("ack_random_winner", 1'b1, irq_mask,
            0, 16'h0000, 32'h0000_0000,
            0, 8'h00,
            irq_mask, 0,
            8'h00, 1);

    repeat (2)
      send_tr("idle_after_ack", 1'b1, irq_mask,
              0, 16'h0000, 32'h0000_0000,
              0, 8'h00,
              irq_mask, 0,
              8'h00, 0);

  endtask

  task write_ctl(string name, bit [15:0] addr, bit [7:0] data);
    send_tr(name, 1'b1, 16'h0000,
            1, addr, {24'h0, data},
            0, 8'h00,
            16'h0000, 0,
            8'h00, 0);
  endtask

  task send_tr(
    string name,
    bit soc_rst,
    bit [15:0] ext_int,
    bit wr_en,
    bit [15:0] wr_addr,
    bit [31:0] wr_data,
    bit eoi_valid,
    bit [7:0] eoi_id,
    bit [15:0] enable_mask,
    bit enable_valid,
    bit [7:0] active_lvl,
    bit ack_valid
  );

    int_seq_item tr;

    tr = int_seq_item::type_id::create(name);
    start_item(tr);

    tr.soc_rst = soc_rst;
    tr.ext_int = ext_int;

    tr.soc_mmr_write_en_i   = wr_en;
    tr.soc_mmr_write_addr_i = wr_addr;
    tr.soc_mmr_write_data_i = wr_data;

    tr.soc_mmr_read_en_i   = 1'b0;
    tr.soc_mmr_read_addr_i = 16'h0000;

    tr.soc_ack_read_valid_en = ack_valid;

    tr.soc_eoi_valid_i = eoi_valid;
    tr.soc_eoi_id_i    = eoi_id;

    tr.active_lvl_pr_i = active_lvl;

    tr.global_int_enable_bit_i   = enable_mask;
    tr.global_int_enable_valid_i = enable_valid;

    tr.debug_mode_valid_i = 1'b0;
    tr.debug_mode_reset_i = 1'b0;
    tr.debug_ndm_reset_i  = 1'b0;

    finish_item(tr);

  endtask

endclass

// ============================================================
// EOI FLOW SEQUENCE - 16 IRQ
// ============================================================
class eoi_flow_seq extends uvm_sequence #(int_seq_item);

  `uvm_object_utils(eoi_flow_seq)

  function new(string name = "eoi_flow_seq");
    super.new(name);
  endfunction

  task body();

    send_tr("reset", 1'b0, 16'h0000,
            0, 16'h0000, 32'h0,
            0, 8'h00,
            16'h0000, 0,
            8'h00, 0);

    repeat (3)
      send_tr("post_reset_idle", 1'b1, 16'h0000,
              0, 16'h0000, 32'h0,
              0, 8'h00,
              16'h0000, 0,
              8'h00, 0);

    write_ctl("prog_irq5_ctl", 16'h1017, 8'h20);
    write_ctl("prog_irq6_ctl", 16'h101B, 8'hE0);

    send_tr("assert_irq5_irq6", 1'b1, 16'h0060,
            0, 16'h0000, 32'h0,
            0, 8'h00,
            16'h0060, 1,
            8'h00, 0);

    repeat (3)
      send_tr("wait_first_irq", 1'b1, 16'h0060,
              0, 16'h0000, 32'h0,
              0, 8'h00,
              16'h0060, 0,
              8'h00, 0);

    send_tr("ack_irq6", 1'b1, 16'h0060,
            0, 16'h0000, 32'h0,
            0, 8'h00,
            16'h0060, 0,
            8'h00, 1);

    repeat (2)
      send_tr("idle_after_ack6", 1'b1, 16'h0060,
              0, 16'h0000, 32'h0,
              0, 8'h00,
              16'h0060, 0,
              8'h00, 0);

    send_tr("eoi_irq6", 1'b1, 16'h0020,
            0, 16'h0000, 32'h0,
            1, 8'h16,
            16'h0060, 0,
            8'h00, 0);

    repeat (3)
      send_tr("wait_next_irq5", 1'b1, 16'h0020,
              0, 16'h0000, 32'h0,
              0, 8'h00,
              16'h0060, 0,
              8'h00, 0);

    send_tr("ack_irq5_after_eoi", 1'b1, 16'h0020,
            0, 16'h0000, 32'h0,
            0, 8'h00,
            16'h0060, 0,
            8'h00, 1);

  endtask

  task write_ctl(string name, bit [15:0] addr, bit [7:0] data);
    send_tr(name, 1'b1, 16'h0000,
            1, addr, {24'h0, data},
            0, 8'h00,
            16'h0000, 0,
            8'h00, 0);
  endtask

  task send_tr(
    string name,
    bit soc_rst,
    bit [15:0] ext_int,
    bit wr_en,
    bit [15:0] wr_addr,
    bit [31:0] wr_data,
    bit eoi_valid,
    bit [7:0] eoi_id,
    bit [15:0] enable_mask,
    bit enable_valid,
    bit [7:0] active_lvl,
    bit ack_valid
  );

    int_seq_item tr;

    tr = int_seq_item::type_id::create(name);
    start_item(tr);

    tr.soc_rst = soc_rst;
    tr.ext_int = ext_int;

    tr.soc_mmr_write_en_i   = wr_en;
    tr.soc_mmr_write_addr_i = wr_addr;
    tr.soc_mmr_write_data_i = wr_data;

    tr.soc_mmr_read_en_i   = 1'b0;
    tr.soc_mmr_read_addr_i = 16'h0000;

    tr.soc_ack_read_valid_en = ack_valid;

    tr.soc_eoi_valid_i = eoi_valid;
    tr.soc_eoi_id_i    = eoi_id;

    tr.active_lvl_pr_i = active_lvl;

    tr.global_int_enable_bit_i   = enable_mask;
    tr.global_int_enable_valid_i = enable_valid;

    tr.debug_mode_valid_i = 1'b0;
    tr.debug_mode_reset_i = 1'b0;
    tr.debug_ndm_reset_i  = 1'b0;

    finish_item(tr);

  endtask

endclass


// ============================================================
// RESET BASIC SEQUENCE
// ============================================================
class reset_basic_seq extends zic_comman_base_seq;

  `uvm_object_utils(reset_basic_seq)

  rand int unsigned rst_cycles;
  rand int unsigned post_idle_cycles;

  constraint c {
    rst_cycles       inside {[1:10]};
    post_idle_cycles inside {[1:10]};
  }

  function new(string name = "reset_basic_seq");
    super.new(name);
  endfunction

  task body();

    if (!this.randomize())
      `uvm_fatal("RESET_SEQ", "Randomization failed")

    repeat (rst_cycles) begin
      send_tr("random_reset",
              1'b0, 16'h0000,
              0, 16'h0000, 32'h0,
              0, 16'h0000,
              0, 8'h00,
              16'h0000, 0,
              8'h00,
              0);
    end

    idle(post_idle_cycles);

  endtask

endclass


// ============================================================
// MMR BASIC SEQUENCE
// ============================================================
class mmr_basic_seq extends zic_comman_base_seq;

  `uvm_object_utils(mmr_basic_seq)

  rand int unsigned num_ops;

  constraint c {
    num_ops inside {[20:50]};
  }

  function new(string name = "mmr_basic_seq");
    super.new(name);
  endfunction

  task body();

    int irq;
    bit [7:0] ctl_data;
    bit [15:0] rd_addr;

    if (!this.randomize())
      `uvm_fatal("MMR_SEQ", "Randomization failed")

    // ============================================================
    //  HIT ALL IRQ ADDRESSES ONCE
    // For 16 interrupt design: IRQ0 to IRQ15
    // ============================================================
    for (int i = 0; i < 16; i++) begin

      ctl_data = $urandom_range(8'h01, 8'hFF);

      // Write every IRQ CTL address once
      write_ctl(i, ctl_data);

      // Read every IRQ CTL address once
      send_tr($sformatf("read_irq%0d_ctl", i),
              0, 48'h0,
              0, 16'h0, 32'h0,
              1, ctl_addr(i),
              0, 8'h00,
              VALID_IRQ_MASK, 0,
              8'h00,
              0);

      idle(1);

    end

    // ============================================================
    //  HIT DATA VALUE 0x00
    // ============================================================
    write_ctl(0, 8'h00);

    send_tr("read_zero_data_irq0",
            0, 48'h0,
            0, 16'h0, 32'h0,
            1, ctl_addr(0),
            0, 8'h00,
            VALID_IRQ_MASK, 0,
            8'h00,
            0);

    idle(1);

    // ============================================================
    // HIT ALL 8-bit DATA VALUES 0x00 to 0xFF
    // ============================================================
    for (int d = 0; d < 256; d++) begin

      irq = d % 16;

      write_ctl(irq, bit'(d[7:0]));

      idle(1);

    end

    // ============================================================
    //  RANDOM MMR STRESS
    // ============================================================
    repeat (num_ops) begin

      irq      = $urandom_range(0, 15);
      ctl_data = $urandom_range(8'h00, 8'hFF);
      rd_addr  = ctl_addr(irq);

      write_ctl(irq, ctl_data);

      send_tr("random_mmr_read",
              0, 16'h0,
              0, 16'h0, 32'h0,
              1, rd_addr,
              0, 8'h00,
              VALID_IRQ_MASK, 0,
              8'h00,
              0);

      idle($urandom_range(1, 3));

    end

  endtask

endclass


// ============================================================
// SINGLE IRQ SEQUENCE
// ============================================================
class single_irq_seq extends zic_comman_base_seq;

  `uvm_object_utils(single_irq_seq)

  rand int irq;
  rand bit [7:0] irq_ctl;
  rand int unsigned ack_delay;
  rand int unsigned eoi_delay;

  constraint c {
    irq       inside {[0:15]};
    irq_ctl   inside {[8'h01:8'hFF]};
    ack_delay inside {[2:10]};
    eoi_delay inside {[1:5]};
  }

  function new(string name = "single_irq_seq");
    super.new(name);
  endfunction

  task body();

    bit [15:0] ext;
    bit [15:0] en;

    if (!this.randomize())
      `uvm_fatal("SINGLE_IRQ_SEQ", "Randomization failed")

    ext = 16'h0000;
    en  = VALID_IRQ_MASK;
    ext[irq] = 1'b1;

    write_ctl(irq, irq_ctl);

    send_tr("single_irq_assert",
            1'b1, ext,
            0, 16'h0000, 32'h0,
            0, 16'h0000,
            0, 8'h00,
            en, 1,
            8'h00,
            0);

    idle(ack_delay, ext, en);

    send_tr("single_irq_ack",
            1'b1, ext,
            0, 16'h0000, 32'h0,
            0, 16'h0000,
            0, 8'h00,
            en, 0,
            8'h00,
            1);

    idle(eoi_delay, ext, en);

    send_tr("single_irq_clear",
            1'b1, 16'h0000,
            0, 16'h0000, 32'h0,
            0, 16'h0000,
            0, 8'h00,
            en, 0,
            8'h00,
            0);

    send_tr("single_irq_eoi",
            1'b1, 16'h0000,
            0, 16'h0000, 32'h0,
            0, 16'h0000,
            1, 8'h10 + irq[7:0],
            en, 0,
            8'h00,
            0);

    idle(3);

  endtask

endclass


// ============================================================
// MULTI IRQ SEQUENCE
// ============================================================
class multi_irq_seq extends zic_comman_base_seq;

  `uvm_object_utils(multi_irq_seq)

  rand bit [7:0] irq_ctl [16];
  rand int unsigned irq_count;
  rand int unsigned ack_delay;

  constraint c {
    irq_count inside {[2:10]};
    ack_delay inside {[3:10]};

    foreach (irq_ctl[i]) {
      irq_ctl[i] inside {[8'h01:8'hFF]};
    }
  }

  function new(string name = "multi_irq_seq");
    super.new(name);
  endfunction

  function automatic bit higher_priority(
    bit [7:0] cur_ctl,
    int cur_id,
    bit [7:0] best_ctl,
    int best_id
  );

    if (cur_ctl[7:5] > best_ctl[7:5])
      return 1'b1;

    if ((cur_ctl[7:5] == best_ctl[7:5]) &&
        (cur_ctl[4:2] > best_ctl[4:2]))
      return 1'b1;

    if ((cur_ctl[7:5] == best_ctl[7:5]) &&
        (cur_ctl[4:2] == best_ctl[4:2]) &&
        (cur_id > best_id))
      return 1'b1;

    return 1'b0;

  endfunction

  function automatic int find_best_id(bit [15:0] mask);

    int best_id;
    bit found;
    bit [7:0] best_ctl;

    best_id  = 0;
    found    = 0;
    best_ctl = 8'h00;

    for (int i = 0; i < 16; i++) begin
      if (mask[i]) begin
        if (!found) begin
          found    = 1;
          best_id  = i;
          best_ctl = irq_ctl[i];
        end
        else if (higher_priority(irq_ctl[i], i, best_ctl, best_id)) begin
          best_id  = i;
          best_ctl = irq_ctl[i];
        end
      end
    end

    return best_id;

  endfunction

  task body();

    bit [15:0] ext;
    bit [15:0] en;
    int irq;
    int best_id;

    if (!this.randomize())
      `uvm_fatal("MULTI_IRQ_SEQ", "Randomization failed")

    ext = 16'h0000;
    en  = VALID_IRQ_MASK;

    for (int i = 0; i < 16; i++) begin
      write_ctl(i, irq_ctl[i]);
    end

    repeat (irq_count) begin
      irq = $urandom_range(0, 15);
      ext[irq] = 1'b1;
    end

    best_id = find_best_id(ext);

    send_tr("multi_irq_assert",
            1'b1, ext,
            0, 16'h0000, 32'h0,
            0, 16'h0000,
            0, 8'h00,
            en, 1,
            8'h00,
            0);

    idle(ack_delay, ext, en);

    send_tr("multi_irq_ack",
            1'b1, ext,
            0, 16'h0000, 32'h0,
            0, 16'h0000,
            0, 8'h00,
            en, 0,
            8'h00,
            1);

    idle(2, ext, en);

    send_tr("multi_irq_clear",
            1'b1, 16'h0000,
            0, 16'h0000, 32'h0,
            0, 16'h0000,
            0, 8'h00,
            en, 0,
            8'h00,
            0);

    send_tr("multi_irq_eoi",
            1'b1, 16'h0000,
            0, 16'h0000, 32'h0,
            0, 16'h0000,
            1, 8'h10 + best_id[7:0],
            en, 0,
            8'h00,
            0);

    idle(3);

  endtask

endclass


// ============================================================
// PRIORITY RANGE STRESS SEQUENCE - 16 IRQ
// ============================================================
class priority_range_stress_seq extends uvm_sequence #(int_seq_item);

  `uvm_object_utils(priority_range_stress_seq)

  function new(string name = "priority_range_stress_seq");
    super.new(name);
  endfunction

  task body();

    bit [15:0] ext;
    bit [7:0] ctl_val;

    for (int grp = 0; grp < 4; grp++) begin

      ext = 16'h0000;

      for (int irq = (grp * 4);
           irq < ((grp * 4) + 4) && irq < 16;
           irq++) begin

        case (grp)
          0: ctl_val = 8'h10;
          1: ctl_val = 8'h40;
          2: ctl_val = 8'hA0;
          3: ctl_val = 8'hFF;
          default: ctl_val = 8'h10;
        endcase

        send_tr("cfg_priority_range",
                1'b1, 16'h0000,
                1, 16'h1003 + (irq * 4), {24'h0, ctl_val},
                0, 8'h00,
                16'h0000, 0,
                8'h00, 0);

        ext[irq] = 1'b1;

      end

      send_tr("drive_priority_range",
              1'b1, ext,
              0, 16'h0000, 32'h0,
              0, 8'h00,
              16'hFFFF, 1,
              8'h00, 0);

      repeat (3)
        send_tr("wait_priority_range",
                1'b1, ext,
                0, 16'h0000, 32'h0,
                0, 8'h00,
                16'hFFFF, 0,
                8'h00, 0);

    end

  endtask

  task send_tr(
    string name,
    bit soc_rst,
    bit [15:0] ext_int,
    bit wr_en,
    bit [15:0] wr_addr,
    bit [31:0] wr_data,
    bit eoi_valid,
    bit [7:0] eoi_id,
    bit [15:0] enable_mask,
    bit enable_valid,
    bit [7:0] active_lvl,
    bit ack_valid
  );

    int_seq_item tr;

    tr = int_seq_item::type_id::create(name);
    start_item(tr);

    tr.soc_rst = soc_rst;
    tr.ext_int = ext_int;

    tr.soc_mmr_write_en_i   = wr_en;
    tr.soc_mmr_write_addr_i = wr_addr;
    tr.soc_mmr_write_data_i = wr_data;

    tr.soc_mmr_read_en_i   = 1'b0;
    tr.soc_mmr_read_addr_i = 16'h0000;

    tr.soc_ack_read_valid_en = ack_valid;

    tr.soc_eoi_valid_i = eoi_valid;
    tr.soc_eoi_id_i    = eoi_id;

    tr.active_lvl_pr_i = active_lvl;

    tr.global_int_enable_bit_i   = enable_mask;
    tr.global_int_enable_valid_i = enable_valid;

    tr.debug_mode_valid_i = 1'b0;
    tr.debug_mode_reset_i = 1'b0;
    tr.debug_ndm_reset_i  = 1'b0;

    finish_item(tr);

  endtask

endclass

// ============================================================
// EOI WITHOUT ACK SEQUENCE - 16 IRQ / soc_*
// ============================================================
class illegal_eoi_seq extends zic_comman_base_seq;

  `uvm_object_utils(illegal_eoi_seq)

  function new(string name = "illegal_eoi_seq");
    super.new(name);
  endfunction

  task body();

    // Reset active-low
    send_tr("reset",
            1'b0, 16'h0000,
            0, 16'h0000, 32'h0,
            0, 16'h0000,
            0, 8'h00,
            16'h0000, 0,
            8'h00,
            0);

    idle(3);

    // Program IRQ5
    write_ctl(5, 8'hE0);

    // Assert IRQ5 and enable IRQ5
    send_tr("assert_irq5_no_ack",
            1'b1, 16'h0020,
            0, 16'h0000, 32'h0,
            0, 16'h0000,
            0, 8'h00,
            16'h0020, 1,
            8'h00,
            0);

    idle(4, 16'h0020, 16'h0020);

    // EOI without ACK
    send_tr("eoi_without_ack_irq5",
            1'b1, 16'h0020,
            0, 16'h0000, 32'h0,
            0, 16'h0000,
            1, 8'h15,
            16'h0020, 0,
            8'h00,
            0);

    idle(5, 16'h0020, 16'h0020);

    // ACK should still be possible if DUT did not wrongly clear IRQ5
    send_tr("ack_irq5_after_illegal_eoi",
            1'b1, 16'h0020,
            0, 16'h0000, 32'h0,
            0, 16'h0000,
            0, 8'h00,
            16'h0020, 0,
            8'h00,
            1);

    idle(3, 16'h0020, 16'h0020);

  endtask

endclass


// ============================================================
// SAME IRQ REASSERT SEQUENCE - 16 IRQ / soc_*
// IRQ5 assert -> ACK -> clear -> EOI -> assert again -> ACK -> EOI
// ============================================================
class irq_reassert_seq extends zic_comman_base_seq;

  `uvm_object_utils(irq_reassert_seq)

  function new(string name = "irq_reassert_seq");
    super.new(name);
  endfunction

  task body();

    bit [15:0] ext;
    bit [15:0] en;

    ext = 16'h0020; // IRQ5
    en  = 16'h0020;

    // Reset active-low
    send_tr("reset",
            1'b0, 16'h0000,
            0, 16'h0000, 32'h0,
            0, 16'h0000,
            0, 8'h00,
            16'h0000, 0,
            8'h00,
            0);

    idle(3);

    // Program IRQ5 high priority
    write_ctl(5, 8'hE0);

    // ========================================================
    // First IRQ5 service
    // ========================================================
    send_tr("irq5_assert_first",
            1'b1, ext,
            0, 16'h0000, 32'h0,
            0, 16'h0000,
            0, 8'h00,
            en, 1,
            8'h00,
            0);

    idle(5, ext, en);

    send_tr("irq5_ack_first",
            1'b1, ext,
            0, 16'h0000, 32'h0,
            0, 16'h0000,
            0, 8'h00,
            en, 0,
            8'h00,
            1);

    idle(2, ext, en);

    // Clear external interrupt before EOI
    send_tr("irq5_clear_first",
            1'b1, 16'h0000,
            0, 16'h0000, 32'h0,
            0, 16'h0000,
            0, 8'h00,
            en, 0,
            8'h00,
            0);

    idle(2, 16'h0000, en);

    send_tr("irq5_eoi_first",
            1'b1, 16'h0000,
            0, 16'h0000, 32'h0,
            0, 16'h0000,
            1, 8'h15,
            en, 0,
            8'h00,
            0);

    idle(4, 16'h0000, en);

    // ========================================================
    // Reassert same IRQ5 again
    // ========================================================
    send_tr("irq5_reassert_second",
            1'b1, ext,
            0, 16'h0000, 32'h0,
            0, 16'h0000,
            0, 8'h00,
            en, 1,
            8'h00,
            0);

    idle(5, ext, en);

    send_tr("irq5_ack_second",
            1'b1, ext,
            0, 16'h0000, 32'h0,
            0, 16'h0000,
            0, 8'h00,
            en, 0,
            8'h00,
            1);

    idle(2, ext, en);

    send_tr("irq5_clear_second",
            1'b1, 16'h0000,
            0, 16'h0000, 32'h0,
            0, 16'h0000,
            0, 8'h00,
            en, 0,
            8'h00,
            0);

    idle(2, 16'h0000, en);

    send_tr("irq5_eoi_second",
            1'b1, 16'h0000,
            0, 16'h0000, 32'h0,
            0, 16'h0000,
            1, 8'h15,
            en, 0,
            8'h00,
            0);

    idle(5);

  endtask

endclass

// ============================================================
// ALL INTERRUPTS HIGH AT SAME TIME SEQUENCE - 16 IRQ / soc_*
// Purpose:
//   - Assert IRQ0 to IRQ15 together
//   - Enable IRQ0 to IRQ15 together
//   - Program different priorities
//   - Expected winner should be highest priority IRQ
// ============================================================
class all_interrupts_high_seq extends zic_comman_base_seq;

  `uvm_object_utils(all_interrupts_high_seq)

  function new(string name = "all_interrupts_high_seq");
    super.new(name);
  endfunction

  task body();

    bit [15:0] ext;
    bit [15:0] en;

    ext = 16'hFFFF;
    en  = 16'hFFFF;

    // ------------------------------------------------------------
    // RESET
    // ------------------------------------------------------------
    send_tr("reset",
            1'b0, 16'h0000,
            1'b0, 16'h0000, 32'h0000_0000,
            1'b0, 16'h0000,
            1'b0, 8'h00,
            16'h0000, 1'b0,
            8'h00,
            1'b0);

    idle(3);

    // ------------------------------------------------------------
    // Program IRQ0 to IRQ15 with increasing level-priority values
    // IRQ15 gets highest value, so expected ACK = 8'h1F
    // ------------------------------------------------------------
    for (int i = 0; i < 16; i++) begin
      write_ctl(i, 8'h10 + (i * 8));
    end

    // ------------------------------------------------------------
    // Assert all interrupts and enable all interrupts
    // ------------------------------------------------------------
    send_tr("assert_all_interrupts_high",
            1'b1, ext,
            1'b0, 16'h0000, 32'h0000_0000,
            1'b0, 16'h0000,
            1'b0, 8'h00,
            en, 1'b1,
            8'h00,
            1'b0);

    // Wait for priority resolver
    idle(5, ext, en);

    // ------------------------------------------------------------
    // ACK highest interrupt
    // Expected winner: IRQ15
    // Expected ACK ID: 8'h1F
    // ------------------------------------------------------------
    send_tr("ack_all_interrupts_winner",
            1'b1, ext,
            1'b0, 16'h0000, 32'h0000_0000,
            1'b0, 16'h0000,
            1'b0, 8'h00,
            en, 1'b0,
            8'h00,
            1'b1);

    idle(3, ext, en);

    // ------------------------------------------------------------
    // Clear all external interrupts
    // ------------------------------------------------------------
    send_tr("clear_all_interrupts",
            1'b1, 16'h0000,
            1'b0, 16'h0000, 32'h0000_0000,
            1'b0, 16'h0000,
            1'b0, 8'h00,
            en, 1'b0,
            8'h00,
            1'b0);

    // EOI IRQ15
    send_tr("eoi_irq15",
            1'b1, 16'h0000,
            1'b0, 16'h0000, 32'h0000_0000,
            1'b0, 16'h0000,
            1'b1, 8'h1F,
            en, 1'b0,
            8'h00,
            1'b0);

    idle(5);

  endtask

endclass


// ============================================================
// FULL REGRESSION SEQUENCE - 16 IRQ
// ============================================================
class zic_full_regression_seq extends uvm_sequence #(int_seq_item);

  `uvm_object_utils(zic_full_regression_seq)

  reset_basic_seq                   reset_seq;
  mmr_basic_seq                     mmr_seq;
  single_irq_seq                    single_seq;
  multi_irq_seq                     multi_seq;
  random_enable_mask_seq            enable_seq;
  random_equal_priority_seq         equal_seq;
  same_priority_random_seq          same_pri_seq;
  dynamic_priority_override_seq     dyn_pri_seq;
  random_eoi_progression_seq        eoi_seq;
  random_all_16_irq_seq             all_irq_seq;
  random_interrupt_storm_seq        storm_seq;
  rand_storm_seq                    rand_storm;
  priority_range_stress_seq         pri_seq;
 random_active_level_priority_seq  active_lvl_seq;
  illegal_eoi_seq                   illegal_eoi_s;
  irq_reassert_seq                  reassert_seq;
 all_interrupts_high_seq           all_high_seq;

  function new(string name = "zic_full_regression_seq");
    super.new(name);
  endfunction

  task body();

    `uvm_info("ZIC_REG_SEQ", "FULL ZIC 16-IRQ RANDOM REGRESSION STARTED", UVM_LOW)

    repeat (10) begin
      reset_seq = reset_basic_seq::type_id::create("reset_seq");
      reset_seq.start(m_sequencer);
    end 

    repeat (20) begin
      mmr_seq = mmr_basic_seq::type_id::create("mmr_seq");
      mmr_seq.start(m_sequencer);
    end

    repeat (30) begin
      single_seq = single_irq_seq::type_id::create("single_seq");
      single_seq.start(m_sequencer);
    end

    repeat (30) begin
      multi_seq = multi_irq_seq::type_id::create("multi_seq");
      multi_seq.start(m_sequencer);
    end

    repeat (30) begin
      enable_seq = random_enable_mask_seq::type_id::create("enable_seq");
      enable_seq.start(m_sequencer);
    end

    repeat (30) begin
      equal_seq = random_equal_priority_seq::type_id::create("equal_seq");
      equal_seq.start(m_sequencer);
    end

    repeat (30) begin
      same_pri_seq = same_priority_random_seq::type_id::create("same_pri_seq");
      same_pri_seq.start(m_sequencer);
    end

    repeat (30) begin
      dyn_pri_seq = dynamic_priority_override_seq::type_id::create("dyn_pri_seq");
      dyn_pri_seq.start(m_sequencer);
    end

    repeat (30) begin
      eoi_seq = random_eoi_progression_seq::type_id::create("eoi_seq");
      eoi_seq.start(m_sequencer);
    end

    repeat (10) begin
      all_irq_seq = random_all_16_irq_seq::type_id::create("all_irq_seq");
      all_irq_seq.start(m_sequencer);
    end

    repeat (20) begin
      pri_seq = priority_range_stress_seq::type_id::create("pri_seq");
      pri_seq.start(m_sequencer);
    end
    
    repeat(50) begin
    active_lvl_seq = random_active_level_priority_seq::type_id::create("active_lvl_seq");

    active_lvl_seq.start(m_sequencer);
    end

    repeat (20) begin
      illegal_eoi_s = illegal_eoi_seq::type_id::create("illegal_eoi_s");
      illegal_eoi_s.start(m_sequencer);
    end
    
    repeat (20) begin
      reassert_seq = irq_reassert_seq::type_id::create("reassert_seq");
      reassert_seq.start(m_sequencer);
    end

    repeat (20) begin
      all_high_seq = all_interrupts_high_seq::type_id::create("all_high_seq");
      all_high_seq.start(m_sequencer);
    end
    
    storm_seq = random_interrupt_storm_seq::type_id::create("storm_seq");
    storm_seq.storm_cycles = 500;
    storm_seq.start(m_sequencer);

    rand_storm = rand_storm_seq::type_id::create("rand_storm");
    rand_storm.storm_cycles = 1000;
    rand_storm.start(m_sequencer); 

    `uvm_info("ZIC_REG_SEQ", "FULL ZIC 16-IRQ RANDOM REGRESSION COMPLETED", UVM_LOW)

  endtask

endclass
