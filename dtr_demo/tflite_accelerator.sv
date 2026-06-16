// =============================================================================
// Proje: Hayati Chip - SoC
// Modül: tflite_accelerator (TFLite Micro Speech Donanım Hızlandırıcısı)
// İşlev: YZ Belleğinden veriyi okur, CNN katmanlarını simüle eder, IRQ üretir.
// =============================================================================

module tflite_accelerator (
    input  logic        s_axi_aclk,
    input  logic        s_axi_aresetn,

    // --- AXI-LITE ARAYÜZÜ (İşlemciden Komut Almak İçin) ---
    input  logic [31:0] s_axi_awaddr,
    input  logic        s_axi_awvalid,
    output logic        s_axi_awready,
    input  logic [31:0] s_axi_wdata,
    input  logic [3:0]  s_axi_wstrb,
    input  logic        s_axi_wvalid,
    output logic        s_axi_wready,
    output logic [1:0]  s_axi_bresp,
    output logic        s_axi_bvalid,
    input  logic        s_axi_bready,
    input  logic [31:0] s_axi_araddr,
    input  logic        s_axi_arvalid,
    output logic        s_axi_arready,
    output logic [31:0] s_axi_rdata,
    output logic [1:0]  s_axi_rresp,
    output logic        s_axi_rvalid,
    input  logic        s_axi_rready,

    // --- YZ BELLEĞİ PORT B ARAYÜZÜ (Doğrudan ve Hızlı Erişim) ---
    output logic        mem_clk,
    output logic        mem_en,
    output logic        mem_we,
    output logic [12:0] mem_addr,
    output logic [31:0] mem_wdata,
    input  logic [31:0] mem_rdata,

    // --- İŞLEMCİYE GİDECEK KESME SİNYALİ ---
    output logic        irq_done_o
);

    assign mem_clk = s_axi_aclk; // Bellek ile aynı saatte çalışıyoruz

    // --- KAYDEDİCİLER (CSR - Control/Status Registers) ---
    // 0x00: CTRL   (Bit 0: Start, Bit 1: Clear IRQ)
    // 0x04: STATUS (Bit 0: Busy, Bit 1: Done)
    // 0x08: RESULT (Sınıflandırma Sonucu -> 0: Evet, 1: Hayır, 2: Bilinmeyen, 3: Sessizlik)
    logic [31:0] ctrl_reg;
    logic [31:0] status_reg;
    logic [31:0] result_reg;

    logic aw_en, w_en, ar_en;
    assign s_axi_awready = aw_en;
    assign s_axi_wready  = w_en;
    assign s_axi_arready = ar_en;
    assign s_axi_bresp   = 2'b00;
    assign s_axi_rresp   = 2'b00;

    logic busy, done;
    assign status_reg = {30'b0, done, busy};
    assign irq_done_o = done; // Done biti 1 olduğunda işlemciye interrupt gider

    // =========================================================
    // AXI-LITE YAZMA / OKUMA (İşlemci Arayüzü)
    // =========================================================
    always_ff @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            aw_en <= 1'b1; w_en <= 1'b1; s_axi_bvalid <= 1'b0; 
            ar_en <= 1'b1; s_axi_rvalid <= 1'b0;
            ctrl_reg <= 0; s_axi_rdata <= 0;
        end else begin
            // YAZMA İŞLEMİ
            if (s_axi_awvalid && s_axi_awready && s_axi_wvalid && s_axi_wready) begin
                aw_en <= 1'b0; w_en <= 1'b0; s_axi_bvalid <= 1'b1;
                case (s_axi_awaddr[7:0])
                    8'h00: ctrl_reg <= s_axi_wdata;
                endcase
            end else if (s_axi_bready && s_axi_bvalid) begin
                aw_en <= 1'b1; w_en <= 1'b1; s_axi_bvalid <= 1'b0;
            end

            // İşlemci "Clear IRQ" (Bit 1) yollarsa veya FSM işi bitirirse Start'ı temizle
            if (ctrl_reg[1]) begin
                ctrl_reg[1] <= 1'b0; // Temizleme emrini al ve kendini sıfırla
            end
            if (done) begin
                ctrl_reg[0] <= 1'b0; // FSM bitirdiğinde Start bitini düşür
            end

            // OKUMA İŞLEMİ
            if (s_axi_arvalid && s_axi_arready) begin
                ar_en <= 1'b0; s_axi_rvalid <= 1'b1;
                case (s_axi_araddr[7:0])
                    8'h00: s_axi_rdata <= ctrl_reg;
                    8'h04: s_axi_rdata <= status_reg;
                    8'h08: s_axi_rdata <= result_reg;
                    default: s_axi_rdata <= 32'h0;
                endcase
            end else if (s_axi_rready && s_axi_rvalid) begin
                ar_en <= 1'b1; s_axi_rvalid <= 1'b0;
            end
        end
    end

    // =========================================================
    // YZ HIZLANDIRICI DURUM MAKİNESİ (CNN Katman Simülasyonu)
    // =========================================================
    typedef enum logic [2:0] {
        IDLE, FETCH_DATA, CONV2D, FULLY_CONNECTED, SOFTMAX, FINISH
    } state_t;
    state_t state;

    logic [15:0] delay_counter; // Matematiksel işlemlerin süresini simüle etmek için

    always_ff @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            state <= IDLE;
            busy <= 0; done <= 0; result_reg <= 0;
            mem_en <= 0; mem_we <= 0; mem_addr <= 0; mem_wdata <= 0;
            delay_counter <= 0;
        end else begin
            
            // İşlemci IRQ temizleme (Clear IRQ) yollarsa Done bitini düşür
            if (ctrl_reg[1]) begin
                done <= 1'b0;
            end

            case (state)
                IDLE: begin
                    busy <= 0;
                    mem_en <= 0;
                    if (ctrl_reg[0] && !done) begin // İşlemciden Start emri geldi
                        busy <= 1;
                        state <= FETCH_DATA;
                    end
                end
                
                FETCH_DATA: begin
                    // B Portundan veri okuma isteği gönder (Örnek Adres 0x00)
                    mem_en <= 1'b1;
                    mem_we <= 1'b0;
                    mem_addr <= 13'h0000;
                    delay_counter <= 16'd50; // 50 clock cycle okuma simülasyonu
                    state <= CONV2D;
                end
                
                CONV2D: begin
                    mem_en <= 1'b0; // Okuma isteğini kapat
                    if (delay_counter == 0) begin
                        delay_counter <= 16'd150; // DepthwiseConv2D + ReLU simülasyonu
                        state <= FULLY_CONNECTED;
                    end else begin
                        delay_counter <= delay_counter - 1;
                    end
                end
                
                FULLY_CONNECTED: begin
                    if (delay_counter == 0) begin
                        delay_counter <= 16'd50; // FC simülasyonu
                        state <= SOFTMAX;
                    end else begin
                        delay_counter <= delay_counter - 1;
                    end
                end
                
                SOFTMAX: begin
                    if (delay_counter == 0) begin
                        // Simüle edilen sonuç: 0 (Evet sınıfı bulundu)
                        // Gerçek tasarımda burada donanımsal çarpım sonucu çıkar
                        result_reg <= 32'd0; 
                        state <= FINISH;
                    end else begin
                        delay_counter <= delay_counter - 1;
                    end
                end
                
                FINISH: begin
                    done <= 1'b1;   // Kesme (Interrupt) üret!
                    busy <= 1'b0;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule