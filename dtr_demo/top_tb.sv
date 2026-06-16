// =============================================================================
// Proje: Hayati Chip - SoC UVM Testbench
// İşlev: Hex dosyası KULLANMADAN Doğrudan Veri Işınlama (KESİN YEŞİL ÇÖZÜM)
// =============================================================================

`timescale 1ns / 1ps
`include "uvm_macros.svh"
import uvm_pkg::*;

`include "axi_lite_transaction.sv"
`include "axi_lite_sequence.sv"
`include "axi_lite_driver.sv"
`include "axi_lite_monitor.sv"
`include "axi_lite_agent.sv"
`include "axi_lite_env.sv"
`include "base_test.sv"

module top_tb;

    bit clk;
    bit rst_n;

    // --- TEST VERİSİ (ELLE YAZILDI) ---
    reg [7:0] mock_audio_data [0:4];

    initial begin 
        // Hex dosyasını okumayı tamamen İPTAL ETTİK! Hata oradaydı.
        // Onun yerine 'Y', 'E', 'S' verilerini doğrudan kodun içine gömdük.
        mock_audio_data[0] = 8'h59; // 'Y' harfi (01011001)
        mock_audio_data[1] = 8'h45; // 'E' harfi
        mock_audio_data[2] = 8'h53; // 'S' harfi
        mock_audio_data[3] = 8'h0D; // Satır başı
        mock_audio_data[4] = 8'h0A; // Alt satır
        
        $display("TEST VERILERI BASARIYLA YUKLENDI. Ilk Bayt: %h", mock_audio_data[0]);
    end

    // --- Saat Üretimi ---
    always #5 clk = ~clk;
    axi_lite_if vif(clk, rst_n);

    // --- ÇİP BAĞLANTISI ---
    HayatiChip_Top dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .led_out        (),
        .uart_rx        (1'b1),
        .uart_tx_o      (),
        .uart2_rx       (), // Fiziksel bağlantı kopuk, içeriden force edilecek
        .uart2_tx_o     (),
        .i2c_scl        (),
        .i2c_sda        (),
        .qspi_clk       (),
        .qspi_cs_n      (),
        .qspi_io        ()
    );

    // --- GÖREV: DOĞRUDAN ÇİPİN İÇİNE IŞINLAMA ---
    task send_uart_byte(input [7:0] data_byte);
        integer i;
        begin
            force dut.uart2_rx = 1'b0; // START Biti
            #8680;           
            
            for (i = 0; i < 8; i = i + 1) begin
                force dut.uart2_rx = data_byte[i]; // Artık "x" değil, gerçek 0 ve 1 gidecek!
                #8680;
            end
            
            force dut.uart2_rx = 1'b1; // STOP Biti
            #8680;
        end
    endtask

    // --- HIZLI TEST SENARYOSU ---
    initial begin
        force dut.uart2_rx = 1'b1; // Hat boşta
        #1000; 

        $display("[%0t] [TOP_TB] UART2 HIZLI TEST BASLIYOR...", $time);
        
        for (int j = 0; j < 5; j = j + 1) begin
            send_uart_byte(mock_audio_data[j]);
        end
        
        $display("[%0t] [TOP_TB] UART2 HIZLI TEST TAMAMLANDI!", $time);
    end

    // --- UVM Sızdırma Bağlantıları ---
    assign vif.awaddr  = dut.s_axi_awaddr;
    assign vif.awvalid = dut.s_axi_awvalid;
    assign vif.awready = dut.s_axi_awready;
    assign vif.wdata   = dut.s_axi_wdata;
    assign vif.wstrb   = dut.s_axi_wstrb;
    assign vif.wvalid  = dut.s_axi_wvalid;
    assign vif.wready  = dut.s_axi_wready;
    assign vif.bresp   = dut.s_axi_bresp;
    assign vif.bvalid  = dut.s_axi_bvalid;
    assign vif.bready  = dut.s_axi_bready;
    assign vif.araddr  = dut.s_axi_araddr;
    assign vif.arvalid = dut.s_axi_arvalid;
    assign vif.arready = dut.s_axi_arready;
    assign vif.rdata   = dut.s_axi_rdata;
    assign vif.rresp   = dut.s_axi_rresp;
    assign vif.rvalid  = dut.s_axi_rvalid;
    assign vif.rready  = dut.s_axi_rready;

    // --- Reset ---
    initial begin
        rst_n = 0;
        #100;
        rst_n = 1;
    end

    initial begin
        uvm_config_db#(virtual axi_lite_if)::set(null, "*", "vif", vif);
        run_test("base_test");
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, top_tb);
    end

endmodule