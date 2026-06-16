module cv32e40p_clock_gate (
    input  logic clk_i,        // Ana saat girişi
    input  logic en_i,         // Enable sinyali
    input  logic scan_cg_en_i, // Test enable
    output logic clk_o         // İşlemciye giden saat
);

    // FPGA üzerinde çalışırken karmaşık clock gating yerine 
    // saati doğrudan ileterek işlemcinin her zaman uyanık kalmasını sağlıyoruz.
    assign clk_o = clk_i; 
    
endmodule