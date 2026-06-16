// =============================================================================
// Proje: Hayati Chip - SoC UVM Testbench
// Dosya: axi_lite_sequence.sv
// İşlev: Test senaryolarının (örneğin TFLite tetikleme) arka arkaya üretilmesi
// =============================================================================

`include "uvm_macros.svh"
import uvm_pkg::*;

class axi_lite_sequence extends uvm_sequence#(axi_lite_transaction);
    `uvm_object_utils(axi_lite_sequence)

    function new(string name = "axi_lite_sequence");
        super.new(name);
    endfunction

    // Ana test senaryosu görevi
    virtual task body();
        axi_lite_transaction req;
        
        // 1. Senaryo: TFLite Hızlandırıcıyı Başlat (0x1000C000 adresine 1 yaz)
        req = axi_lite_transaction::type_id::create("req");
        start_item(req);
        if(!req.randomize() with {
            addr == 32'h1000C000;
            data == 32'h00000001;
            is_write == 1'b1;
        }) `uvm_error("SEQ", "Randomization failed!")
        finish_item(req);
        
        // Buraya ileride I2C, QSPI test senaryolarını alt alta ekleyeceğiz
    endtask
endclass