`include "uvm_macros.svh"
import uvm_pkg::*;

class axi_lite_monitor extends uvm_monitor;
    `uvm_component_utils(axi_lite_monitor)

    virtual axi_lite_if vif;
    uvm_analysis_port #(axi_lite_transaction) item_collected_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_lite_if)::get(this, "", "vif", vif))
            `uvm_fatal("MON", "Arayuz bulunamadi!")
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            axi_lite_transaction trans;
            @(posedge vif.clk);
            
            // Yazma işlemini yakala
            if (vif.awvalid && vif.awready) begin
                trans = axi_lite_transaction::type_id::create("trans");
                trans.addr = vif.awaddr;
                trans.data = vif.wdata;
                trans.is_write = 1'b1;
                item_collected_port.write(trans);
                `uvm_info("MON", $sformatf("Yazma yakalandi: Addr=%h Data=%h", trans.addr, trans.data), UVM_LOW)
            end
        end
    endtask
endclass