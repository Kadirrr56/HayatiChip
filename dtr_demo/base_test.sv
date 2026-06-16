`include "uvm_macros.svh"
import uvm_pkg::*;

class base_test extends uvm_test;
    `uvm_component_utils(base_test)

    axi_lite_env env;

    function new(string name = "base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = axi_lite_env::type_id::create("env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        axi_lite_sequence seq;
        seq = axi_lite_sequence::type_id::create("seq");
        
        phase.raise_objection(this); // Simülasyonu başlat
        seq.start(env.agent.sequencer); // Senaryoyu (AI Tetikleme) oynat
        
        // 2 ms = 2,000,000 ns (Derleme hatası vermemesi için sayısal yazıldı)
        #2000000; 
        
        phase.drop_objection(this); // Simülasyonu bitir
    endtask
endclass