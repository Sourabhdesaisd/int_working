class int_base_test extends uvm_test;

  `uvm_component_utils(int_base_test)

  int_env env;

  function new(string name = "int_base_test", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    env = int_env::type_id::create("env", this);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);

    uvm_top.print_topology();
  endfunction

  task run_phase(uvm_phase phase);

   // irq0_basic_seq seq;
  //  irq0_irq5_priority_seq seq;

  //  irq5_irq6_priority_seq seq;
//
 //  disabled_irq_seq seq;

  // three_way_priority_seq seq;

 //  eoi_flow_seq seq;

  // equal_priority_tie_break_seq seq;

 //  active_lvl_threshold_seq  seq;

 //  reset_during_active_irq_seq seq;

//   simul_new_irq_during_eoi_seq seq;

  // random_multi_irq_seq  seq;

//   simultaneous_new_irq_during_eoi_seq seq;

// enable_disable_masking_seq seq;

// back_to_back_interrupts_seq seq;

// wrong_eoi_fail_seq seq;

// random_all_48_irq_seq seq;

// same_priority_random_seq seq;

// random_enable_mask_seq seq;

// random_equal_priority_seq seq;

// random_ack_latency_seq seq;

// random_eoi_progression_seq seq;

// random_tie_break_eoi_seq seq;

// dynamic_priority_override_seq seq;

// random_interrupt_storm_seq seq;
 
// rand_storm_seq seq;
//random_active_level_priority_seq seq;

zic_full_regression_seq seq;

//zic_seq_base seq;


 
   
 //zic_multi_irq_seq seq;

    phase.raise_objection(this);

   // seq = irq0_basic_seq::type_id::create("seq");

  //  seq = irq0_irq5_priority_seq::type_id::create("seq");

 //  seq = irq5_irq6_priority_seq::type_id::create("seq");

    //seq = disabled_irq_seq::type_id::create("seq");

   // seq = three_way_priority_seq::type_id::create("seq");
    
   // seq = eoi_flow_seq::type_id::create("seq");

   // seq = equal_priority_tie_break_seq::type_id::create("seq");
    
//    seq = active_lvl_threshold_seq::type_id::create("seq");

   // seq = reset_during_active_irq_seq::type_id::create("seq");

 //   seq = simul_new_irq_during_eoi_seq::type_id::create("seq");

  //  seq = random_multi_irq_seq::type_id::create("seq");

   // seq = simultaneous_new_irq_during_eoi_seq::type_id::create("seq");

  //  seq = enable_disable_masking_seq::type_id::create("seq");

   // seq = back_to_back_interrupts_seq::type_id::create("seq");

  //  seq = wrong_eoi_fail_seq::type_id::create("seq");

  //  seq = random_all_48_irq_seq::type_id::create("seq");

  // seq = same_priority_random_seq::type_id::create("seq");

 //  seq = random_enable_mask_seq::type_id::create("seq");


  // seq = random_equal_priority_seq::type_id::create("seq");

 //  seq = random_ack_latency_seq::type_id::create("seq");

 //  seq = random_eoi_progression_seq::type_id::create("seq");

  // seq = random_tie_break_eoi_seq::type_id::create("seq");
   
   
   
 //  seq = dynamic_priority_override_seq::type_id::create("seq");
   
 //  seq = random_interrupt_storm_seq::type_id::create("seq");
   
  // seq = rand_storm_seq::type_id::create("seq");
//  seq = random_active_level_priority_seq::type_id::create("seq");


  seq = zic_full_regression_seq::type_id::create("seq");


  // seq = zic_seq_base::type_id::create("seq");
   
  

   

   
  


    
    
    
   
    
 
    
 
    seq.start(env.agent.sqr);

    #200;

    phase.drop_objection(this);

  endtask

endclass
