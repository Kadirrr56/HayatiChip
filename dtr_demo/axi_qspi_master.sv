// =============================================================================
// Proje: Hayati Chip - SoC
// Modül: axi_qspi_master
// İşlev: AXI-Lite Uyumlu QSPI (Quad-SPI) Master Haberleşme Birimi
// =============================================================================

module axi_qspi_master (
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

    // --- QSPI FİZİKSEL SİNYALLER (Tri-State Uyumlu) ---
    output logic        qspi_clk,
    output logic        qspi_cs_n,  // Chip Select (Aktif Düşük)
    
    // 4 Adet Çift Yönlü Veri Hattı (IO0, IO1, IO2, IO3)
    input  logic [3:0]  qspi_io_i,
    output logic [3:0]  qspi_io_o,
    output logic [3:0]  qspi_io_t   // 0: Sür (Çıkış), 1: Bırak (Giriş)
);

    // --- KAYDEDİCİLER (REGISTERS) ---
    logic [31:0] ctrl_reg;  // [0]: Başlat, [1]: Quad Modu (1=4-bit, 0=1-bit), [2]: CS_N Kontrol
    logic [31:0] tx_reg;    // Gönderilecek 8-bit Veri
    logic [31:0] rx_reg;    // Okunan 8-bit Veri
    logic [31:0] stat_reg;  // [0]: Meşgul (Busy)

    logic aw_en, w_en, ar_en;
    assign s_axi_awready = aw_en;
    assign s_axi_wready  = w_en;
    assign s_axi_arready = ar_en;
    assign s_axi_bresp   = 2'b00;
    assign s_axi_rresp   = 2'b00;

    logic busy;
    logic qspi_done;
    logic [7:0] rx_data_internal;
    
    assign stat_reg = {31'b0, busy};

    // =========================================================
    // AXI-LITE YAZMA / OKUMA (İşlemci Arayüzü)
    // =========================================================
    always_ff @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            aw_en <= 1'b1; w_en <= 1'b1; s_axi_bvalid <= 1'b0; ar_en <= 1'b1; s_axi_rvalid <= 1'b0;
            ctrl_reg <= 32'h0000_0004; // Varsayılan: CS_N Yüksek (Boşta)
            tx_reg <= 0; rx_reg <= 0; s_axi_rdata <= 0;
        end else begin
            // YAZMA İŞLEMİ
            if (s_axi_awvalid && s_axi_awready && s_axi_wvalid && s_axi_wready) begin
                aw_en <= 1'b0; w_en <= 1'b0; s_axi_bvalid <= 1'b1;
                case (s_axi_awaddr[7:0])
                    8'h00: ctrl_reg <= s_axi_wdata;
                    8'h04: tx_reg   <= s_axi_wdata;
                endcase
            end else if (s_axi_bready && s_axi_bvalid) begin
                aw_en <= 1'b1; w_en <= 1'b1; s_axi_bvalid <= 1'b0;
            end

            // OKUMA İŞLEMİ
            if (s_axi_arvalid && s_axi_arready) begin
                ar_en <= 1'b0; s_axi_rvalid <= 1'b1;
                case (s_axi_araddr[7:0])
                    8'h00: s_axi_rdata <= ctrl_reg;
                    8'h04: s_axi_rdata <= tx_reg;
                    8'h08: s_axi_rdata <= rx_reg;
                    8'h0C: s_axi_rdata <= stat_reg;
                    default: s_axi_rdata <= 32'h0;
                endcase
            end else if (s_axi_rready && s_axi_rvalid) begin
                ar_en <= 1'b1; s_axi_rvalid <= 1'b0;
            end
            
            // FSM işi bitirdiğinde CTRL Start bitini düşür ve okunan veriyi RX yazmacına al
            if (qspi_done) begin
                ctrl_reg[0] <= 1'b0;
                rx_reg <= {24'b0, rx_data_internal};
            end
        end
    end

    // Chip Select doğrudan CTRL register üzerinden manuel yönetilir (Daha esnek)
    assign qspi_cs_n = ctrl_reg[2];

    // =========================================================
    // QSPI MASTER DURUM MAKİNESİ (FSM)
    // =========================================================
    typedef enum logic [2:0] {
        IDLE, SHIFT_OUT, CLK_HIGH, CLK_LOW, DONE
    } state_t;
    state_t state;

    logic [7:0] shift_tx;
    logic [2:0] bit_cnt;
    logic quad_mode;

    always_ff @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            state <= IDLE;
            busy <= 0; qspi_done <= 0; qspi_clk <= 0;
            qspi_io_o <= 0; qspi_io_t <= 4'b1111; // Varsayılan giriş modu
            bit_cnt <= 0; shift_tx <= 0; rx_data_internal <= 0;
            quad_mode <= 0;
        end else begin
            qspi_done <= 0;
            case (state)
                IDLE: begin
                    qspi_clk <= 0;
                    if (ctrl_reg[0]) begin // Başla komutu geldi
                        busy <= 1;
                        shift_tx <= tx_reg[7:0];
                        quad_mode <= ctrl_reg[1];
                        
                        if (ctrl_reg[1]) begin
                            // QUAD MOD: 4 bit aynı anda, toplam 2 vuruş
                            bit_cnt <= 1; 
                        end else begin
                            // STANDART SPI: 1 bit, toplam 8 vuruş
                            bit_cnt <= 7;
                        end
                        state <= SHIFT_OUT;
                    end else begin
                        busy <= 0;
                    end
                end
                
                SHIFT_OUT: begin
                    if (quad_mode) begin
                        // 4 pini de çıkış yap ve verinin üst 4 bitini hatta sür
                        qspi_io_t <= 4'b0000;
                        qspi_io_o <= shift_tx[7:4];
                        shift_tx <= {shift_tx[3:0], 4'b0000};
                    end else begin
                        // Standart SPI: Sadece IO0 (MOSI) çıkış, IO1 (MISO) giriş
                        qspi_io_t <= 4'b1110; 
                        qspi_io_o[0] <= shift_tx[7];
                        shift_tx <= {shift_tx[6:0], 1'b0};
                    end
                    state <= CLK_HIGH;
                end
                
                CLK_HIGH: begin
                    qspi_clk <= 1; // Saati yükselt
                    state <= CLK_LOW;
                end
                
                CLK_LOW: begin
                    qspi_clk <= 0; // Saati düşür ve gelen veriyi oku
                    
                    if (quad_mode) begin
                        rx_data_internal <= {rx_data_internal[3:0], qspi_io_i};
                    end else begin
                        rx_data_internal <= {rx_data_internal[6:0], qspi_io_i[1]}; // MISO'dan oku
                    end
                    
                    if (bit_cnt == 0) state <= DONE;
                    else begin
                        bit_cnt <= bit_cnt - 1;
                        state <= SHIFT_OUT;
                    end
                end
                
                DONE: begin
                    qspi_done <= 1;
                    qspi_io_t <= 4'b1111; // Hatları güvenli (dinleme) moduna al
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule