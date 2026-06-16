// =============================================================================
// Proje: Hayati Chip - SoC UVM Testbench
// Dosya: axi_lite_transaction.sv
// İşlev: AXI-Lite veriyolunda taşınacak okuma/yazma paketinin tanımlanması
// =============================================================================

`include "uvm_macros.svh"
import uvm_pkg::*;

class axi_lite_transaction extends uvm_sequence_item;
    
    // Rastgele atanabilecek (rand) değişkenler
    rand bit [31:0] addr;
    rand bit [31:0] data;
    rand bit        is_write; // 1: Yazma, 0: Okuma
    rand bit [3:0]  wstrb;

    // UVM Fabrikasına kayıt
    `uvm_object_utils_begin(axi_lite_transaction)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(data, UVM_ALL_ON)
        `uvm_field_int(is_write, UVM_ALL_ON)
        `uvm_field_int(wstrb, UVM_ALL_ON)
    `uvm_object_utils_end

    // Sınırlar (Constraints) - Adreslerin doğru hizalandığından emin olmak için
    constraint addr_align_c { addr % 4 == 0; }
    constraint wstrb_c { wstrb == 4'b1111; } // Varsayılan olarak 32-bit (4 byte) tam yazma

    // Kurucu fonksiyon (Constructor)
    function new(string name = "axi_lite_transaction");
        super.new(name);
    endfunction

endclass