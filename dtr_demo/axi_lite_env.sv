`include "uvm_macros.svh"
import uvm_pkg::*;

class axi_lite_env extends uvm_env;
    `uvm_component_utils(axi_lite_env)

    axi_lite_agent agent;
    // İleride buraya Scoreboard eklenecek: axi_lite_scoreboard sb;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = axi_lite_agent::type_id::create("agent", this);
    endfunction
endclass