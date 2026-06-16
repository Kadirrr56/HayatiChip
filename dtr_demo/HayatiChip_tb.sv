`timescale 1ns / 1ps

module HayatiChip_tb();

    logic clk; logic rst_n; logic [31:0] led_out;
    logic uart_rx; logic uart_tx; logic uart2_rx; logic uart2_tx;
    tri1 i2c_scl; tri1 i2c_sda;
    logic qspi_clk; logic qspi_cs_n; tri1 [3:0] qspi_io; 

    // =======================================================
    // 1. YAPAY ZEKA TEST VERİSİ (MOCK DATA) TANIMLAMALARI
    // =======================================================
    reg [7:0] mock_audio_data [0:1959];

    initial begin 
        // DİKKAT: Buradaki yolu kendi bilgisayarındaki mutlak yol ile değiştir!
        $readmemh("yes_audio.hex", u_instr_ram.mem); // u_instr_ram kısmını kendi modül adına göre kontrol et
    end

    // =======================================================
    // 2. TEMEL SİNYALLER (CLOCK & RESET)
    // =======================================================
    initial begin 
        clk = 0; 
        forever #5 clk = ~clk; // 100 MHz
    end

    initial begin 
        rst_n = 0; 
        #100; 
        rst_n = 1; 
        $display("[%0t] Reset kaldirildi.", $time); 
    end

    assign uart_rx = 1'b1; 

    // =======================================================
    // 3. UART2 ÜZERİNDEN VERİ GÖNDERME GÖREVİ (TASK)
    // =======================================================
    task send_uart_byte(input [7:0] data_byte);
        integer i;
        begin
            uart2_rx = 1'b0; // START Biti (Hattı Low'a çek)
            #8680;           // 115200 Baud Rate için bekleme
            
            for (i = 0; i < 8; i = i + 1) begin
                uart2_rx = data_byte[i]; // Veri bitleri
                #8680;
            end
            
            uart2_rx = 1'b1; // STOP Biti (Hattı High'a çek)
            #8680;
        end
    endtask

    // =======================================================
    // 4. HIZLI YAPAY ZEKA SENARYOSU (TEST VEKTÖRÜ AKIŞI)
    // =======================================================
    initial begin
        uart2_rx = 1'b1; // Başlangıçta UART2 hattı boşta (Idle = High)
        
        // HIZLI TEST: Sadece 1 mikrosaniye (1000 ns) bekle ve ateşle!
        #1000; 

        $display("[%0t] UART2 HIZLI TEST BASLIYOR...", $time);
        
        // HIZLI TEST: 1960 bayt yerine SADECE İLK 5 BAYTI yolla
        for (int j = 0; j < 5; j = j + 1) begin
            send_uart_byte(mock_audio_data[j]);
        end
        
        $display("[%0t] UART2 HIZLI TEST TAMAMLANDI!", $time);
    end

    // =======================================================
    // 5. ANA DONANIM (DUT) BAĞLANTILARI
    // =======================================================
    HayatiChip_Top dut (
        .clk(clk), .rst_n(rst_n), .led_out(led_out), 
        .uart_rx(uart_rx), .uart_tx_o(uart_tx), 
        .uart2_rx(uart2_rx), .uart2_tx_o(uart2_tx), 
        .i2c_scl(i2c_scl), .i2c_sda(i2c_sda), 
        .qspi_clk(qspi_clk), .qspi_cs_n(qspi_cs_n), .qspi_io(qspi_io)
    );

endmodule