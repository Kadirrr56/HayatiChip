// =============================================================================
// Modül: axi_timer
// İşlev: AXI-Lite Uyumlu 32-bit Zamanlayıcı (Timer) ve Frekans Bölücü
// =============================================================================

module axi_timer (
    input  logic        s_axi_aclk,
    input  logic        s_axi_aresetn,

    // --- AXI-LITE ARAYÜZÜ ---
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

    // --- DONANIM ÇIKIŞI ---
    output logic        irq_o  // İşlemciye gidecek Kesme (Interrupt) Sinyali
);

    // --- TİMER KAYDEDİCİLERİ (REGISTERS) ---
    // CTRL: [0] Enable, [1] Interrupt Enable, [2] Auto-Reload, [3] Interrupt Bayrağı, [15:8] Prescaler
    logic [31:0] ctrl_reg; 
    logic [31:0] cmp_reg;  // Hedef Sayı
    logic [31:0] val_reg;  // Güncel Sayaç Değeri

    logic [7:0]  prescaler_cnt; // Frekans bölücü sayacı

    // AXI-Lite Haberleşme Sinyalleri
    logic aw_en, w_en, ar_en;
    assign s_axi_awready = aw_en;
    assign s_axi_wready  = w_en;
    assign s_axi_arready = ar_en;
    assign s_axi_bresp   = 2'b00; // OK
    assign s_axi_rresp   = 2'b00; // OK

    // =========================================================
    // YAZMA (WRITE) MANTIĞI - İşlemciden Timer'a veri gelirse
    // =========================================================
    always_ff @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            aw_en <= 1'b1; w_en <= 1'b1; s_axi_bvalid <= 1'b0;
            ctrl_reg <= 32'h0;
            cmp_reg  <= 32'hFFFFFFFF;
        end else begin
            if (s_axi_awvalid && s_axi_awready && s_axi_wvalid && s_axi_wready) begin
                aw_en <= 1'b0; w_en <= 1'b0; s_axi_bvalid <= 1'b1;
                
                // Adrese göre Register'a yaz
                case (s_axi_awaddr[7:0])
                    8'h00: begin
                        ctrl_reg[2:0] <= s_axi_wdata[2:0];
                        ctrl_reg[15:8] <= s_axi_wdata[15:8];
                        if (s_axi_wdata[3]) ctrl_reg[3] <= 1'b0; // "1" yazılırsa Interrupt Bayrağını TEMİZLE
                    end
                    8'h04: cmp_reg <= s_axi_wdata;
                    // Not: val_reg yazma işlemi sayacı sıfırlamak içindir, aşağıda sayma mantığında işlenecek.
                endcase
            end else if (s_axi_bready && s_axi_bvalid) begin
                aw_en <= 1'b1; w_en <= 1'b1; s_axi_bvalid <= 1'b0;
            end
            
            // Timer sayma esnasında Interrupt üretirse bayrağı kaldır
            if (val_reg == cmp_reg && ctrl_reg[0] && ctrl_reg[1]) begin
                ctrl_reg[3] <= 1'b1; // Interrupt tetiklendi
            end
        end
    end

    // =========================================================
    // OKUMA (READ) MANTIĞI - İşlemci Timer'dan veri isterse
    // =========================================================
    always_ff @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            ar_en <= 1'b1; s_axi_rvalid <= 1'b0; s_axi_rdata <= 32'h0;
        end else begin
            if (s_axi_arvalid && s_axi_arready) begin
                ar_en <= 1'b0; s_axi_rvalid <= 1'b1;
                case (s_axi_araddr[7:0])
                    8'h00: s_axi_rdata <= ctrl_reg;
                    8'h04: s_axi_rdata <= cmp_reg;
                    8'h08: s_axi_rdata <= val_reg;
                    default: s_axi_rdata <= 32'h0;
                endcase
            end else if (s_axi_rready && s_axi_rvalid) begin
                ar_en <= 1'b1; s_axi_rvalid <= 1'b0;
            end
        end
    end

    // =========================================================
    // SAYMA (COUNT) MANTIĞI - Asıl Timer Kalbi
    // =========================================================
    always_ff @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            val_reg <= 32'h0;
            prescaler_cnt <= 8'h0;
        end else begin
            // Eğer İşlemci VAL register'ına veri yazdıysa, sayacı zorla o değere çek
            if (s_axi_awvalid && s_axi_awready && s_axi_wvalid && s_axi_wready && s_axi_awaddr[7:0] == 8'h08) begin
                val_reg <= s_axi_wdata;
            end 
            // İşlemci yazmıyorsa ve Timer Enable (Aktif) ise saymaya devam et
            else if (ctrl_reg[0]) begin
                if (prescaler_cnt >= ctrl_reg[15:8]) begin
                    prescaler_cnt <= 8'h0; // Prescaler sıfırla
                    
                    if (val_reg == cmp_reg) begin
                        if (ctrl_reg[2]) val_reg <= 32'h0; // Auto-reload açıksa sıfırla
                        else val_reg <= val_reg + 1;       // Kapalıysa saymaya devam et
                    end else begin
                        val_reg <= val_reg + 1; // Normal sayma
                    end
                end else begin
                    prescaler_cnt <= prescaler_cnt + 1; // Sadece prescaler'ı artır (hızı yavaşlatıyor)
                end
            end
        end
    end

    // Kesme Sinyali (Interrupt) Çıkışı
    assign irq_o = ctrl_reg[3];

endmodule