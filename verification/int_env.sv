class int_env extends uvm_env;

  `uvm_component_utils(int_env)

  int_agent     agent;
  int_scoreboard scb;
  int_coverage  cov;

  function new(string name = "int_env", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    agent = int_agent::type_id::create("agent", this);
    scb   = int_scoreboard::type_id::create("scb", this);
    cov   = int_coverage::type_id::create("cov", this);

  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    agent.mon.mon_ap.connect(scb.sb_imp);
    agent.mon.mon_ap.connect(cov.analysis_export);

  endfunction

endclass

