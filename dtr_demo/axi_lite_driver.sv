// =============================================================================
// Proje: Hayati Chip - SoC UVM Testbench
// Dosya: axi_lite_driver.sv
// İşlev: Sanal paketleri fiziksel AXI-Lite pin sinyallerine dönüştürür
// =============================================================================

`include "uvm_macros.svh"
import uvm_pkg::*;

class axi_lite_driver extends uvm_driver#(axi_lite_transaction);
    `uvm_component_utils(axi_lite_driver)

    // Fiziksel arayüze (interface) bağlantı
    virtual axi_lite_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Testbench'ten arayüzü çek
        if (!uvm_config_db#(virtual axi_lite_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("DRV", "Sanal Arayuz (vif) bulunamadi!")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            axi_lite_transaction req;
            
            // Senaryodan sıradaki paketi bekle
            seq_item_port.get_next_item(req);
            
            if (req.is_write) begin
                write_axi(req.addr, req.data, req.wstrb);
            end else begin
                read_axi(req.addr);
            end
            
            // Paket işlendi, sıradakini iste
            seq_item_port.item_done();
        end
    endtask

    // AXI Yazma Protokolü
    task write_axi(input logic [31:0] addr, input logic [31:0] data, input logic [3:0] strb);
        // AW Kanalı
        vif.awaddr  <= addr;
        vif.awvalid <= 1'b1;
        // W Kanalı
        vif.wdata   <= data;
        vif.wstrb   <= strb;
        vif.wvalid  <= 1'b1;
        
        // Ready gelene kadar bekle
        @(posedge vif.clk);
        while (!(vif.awready && vif.wready)) @(posedge vif.clk);
        
        vif.awvalid <= 1'b0;
        vif.wvalid  <= 1'b0;
        
        // B Kanalı (Onay) bekle
        vif.bready <= 1'b1;
        while (!vif.bvalid) @(posedge vif.clk);
        vif.bready <= 1'b0;
    endtask

    // AXI Okuma Protokolü
    task read_axi(input logic [31:0] addr);
        // AR Kanalı
        vif.araddr  <= addr;
        vif.arvalid <= 1'b1;
        
        @(posedge vif.clk);
        while (!vif.arready) @(posedge vif.clk);
        vif.arvalid <= 1'b0;
        
        // R Kanalı (Veri Dönüşü) bekle
        vif.rready <= 1'b1;
        while (!vif.rvalid) @(posedge vif.clk);
        vif.rready <= 1'b0;
    endtask

endclass