`timescale 1ns/1ps

module teknotest_wrapper (
    input  logic clk_i,
    input  logic resetn_i,
    input  logic uart_rx_i,
    output logic uart_tx_o
);

    // HayatiChip Top Modül Bağlantısı
    HayatiChip_Top my_soc (
        .clk       (clk_i),
        .rst_n     (resetn_i),
        
        // Jürinin test ortamı UART1'e bağlanıyor
        .uart1_rx  (uart_rx_i),
        .uart1_tx  (uart_tx_o),
        
        // Kullanılmayan UART2 pini (UART idle High olduğu için 1'e çekiyoruz)
        .uart2_rx  (1'b1),
        .uart2_tx  ()
        
        // Not: Eğer HayatiChip_Top modülünüzde GPIO, I2C veya SPI pinleri dışarı 
        // çıkıyorsa, onların input olanlarını 0'a, output olanlarını boşta () bırakın.
    );

endmodule