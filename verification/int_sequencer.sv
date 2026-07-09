class int_sequencer extends uvm_sequencer #(int_seq_item);

  `uvm_component_utils(int_sequencer)

  function new(string name = "int_sequencer", uvm_component parent);
    super.new(name, parent);
  endfunction

endclass
