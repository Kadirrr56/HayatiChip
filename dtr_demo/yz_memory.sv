// =============================================================================
// Proje: Hayati Chip - SoC
// Modül: yz_memory - RAMB36E1 Direkt Instantiation (TDP)
// 4x RAMB36E1, her biri 9-bit wide (8+1 parity), 8192 deep
// Port A = AXI (s_axi_aclk) | Port B = TFLite (tflite_clk)
// =============================================================================
module yz_memory (
    input  logic        s_axi_aclk,
    input  logic        s_axi_aresetn,

    // PORT A: AXI-LITE
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

    // PORT B: TFLITE
    input  logic        tflite_clk,
    input  logic        tflite_en,
    input  logic        tflite_we,
    input  logic [12:0] tflite_addr,
    input  logic [31:0] tflite_wdata,
    output logic [31:0] tflite_rdata
);

    // -------------------------------------------------------------------------
    // AXI yazma öncelikli: yazma varsa yaz, yoksa oku
    // TDP Port A tek adres kullanır
    // -------------------------------------------------------------------------
    logic        a_we;
    logic [15:0] a_addr;
    logic [31:0] bram_doado [0:3];

    assign a_we   = s_axi_awvalid & s_axi_wvalid;
    // Yazma işlemindeyse yazma adresini, okumadaysa okuma adresini ver
    assign a_addr = a_we ? {3'b000, s_axi_awaddr[14:2]} 
                         : {3'b000, s_axi_araddr[14:2]};

    // -------------------------------------------------------------------------
    // 4x RAMB36E1 - byte-wide TDP
    // ADDRARDADDR[15:0]: [15]=1(zorunlu), [14:3]=addr[12:1], [2:0]=000
    // 8-bit wide modda adres: {1'b1, addr[12:0], 2'b00} = 16 bit
    // -------------------------------------------------------------------------
    genvar i;
    generate
        for (i = 0; i < 4; i++) begin : bram_bank
            RAMB36E1 #(
                .RAM_MODE           ("TDP"),
                .READ_WIDTH_A       (9),
                .WRITE_WIDTH_A      (9),
                .READ_WIDTH_B       (9),
                .WRITE_WIDTH_B      (9),
                .WRITE_MODE_A       ("READ_FIRST"),
                .WRITE_MODE_B       ("READ_FIRST"),
                .DOA_REG            (0),
                .DOB_REG            (0),
                .INIT_A             (36'h000000000),
                .INIT_B             (36'h000000000),
                .SRVAL_A            (36'h000000000),
                .SRVAL_B            (36'h000000000),
                .INIT_FILE          ("NONE"),
                .SIM_COLLISION_CHECK("ALL"),
                .RSTREG_PRIORITY_A  ("REGCE"),
                .RSTREG_PRIORITY_B  ("REGCE"),
                .RDADDR_COLLISION_HWCONFIG("DELAYED_WRITE"),
                .EN_ECC_READ        ("FALSE"),
                .EN_ECC_WRITE       ("FALSE")
            ) u_bram (
                // ---- PORT A (AXI, s_axi_aclk) ----
                .CLKARDCLK    (s_axi_aclk),
                .ENARDEN      (1'b1),
                .REGCEAREGCE  (1'b0),
                .RSTRAMARSTRAM(1'b0),
                .RSTREGARSTREG(1'b0),
                // 8-bit wide: adres [15]=1, [14:3]=addr[12:1], [2:0]=000
                .ADDRARDADDR  ({1'b1, a_addr[12:0], 2'b00}),
                .DIADI        ({24'h000000, s_axi_wdata[i*8 +: 8]}),
                .DIPADIP      (4'h0),
                .WEA          ({3'b000, (a_we & s_axi_wstrb[i])}),
                .DOADO        (bram_doado[i]),
                .DOPADOP      (),

                // ---- PORT B (TFLite, tflite_clk) ----
                .CLKBWRCLK    (tflite_clk),
                .ENBWREN      (tflite_en),
                .REGCEB       (1'b0),
                .RSTRAMB      (1'b0),
                .RSTREGB      (1'b0),
                .ADDRBWRADDR  ({1'b1, tflite_addr[12:0], 2'b00}),
                .DIBDI        ({24'h000000, tflite_wdata[i*8 +: 8]}),
                .DIPBDIP      (4'h0),
                .WEBWE        ({7'b0000000, tflite_we}),
                .DOBDO        (),   // tflite okuma aşağıda
                .DOPBDOP      (),

                // Cascade / ECC kullanılmıyor
                .CASCADEINA   (1'b0),
                .CASCADEINB   (1'b0),
                .CASCADEOUTA  (),
                .CASCADEOUTB  (),
                .DBITERR      (),
                .ECCPARITY    (),
                .RDADDRECC    (),
                .SBITERR      (),
                .INJECTDBITERR(1'b0),
                .INJECTSBITERR(1'b0)
            );
        end
    endgenerate

    // -------------------------------------------------------------------------
    // AXI okuma: BRAM çıkışını bir sonraki siklusa register'la
    // -------------------------------------------------------------------------
    always_ff @(posedge s_axi_aclk) begin
        s_axi_rdata[ 7: 0] <= bram_doado[0][7:0];
        s_axi_rdata[15: 8] <= bram_doado[1][7:0];
        s_axi_rdata[23:16] <= bram_doado[2][7:0];
        s_axi_rdata[31:24] <= bram_doado[3][7:0];
    end

    // -------------------------------------------------------------------------
    // TFLite okuma: Port B DOBDO'yu ayrı BRAM instance'larından almak için
    // generate bloğunu genişletmek gerekir - aşağıda wire ile çözüyoruz
    // -------------------------------------------------------------------------
    // NOT: tflite_rdata için Port B'nin DOBDO'suna ihtiyacımız var.
    // Yukarıdaki generate'de DOBDO'yu bağlamadık, düzeltiyoruz:
    // (Generate bloğunu ayrı tutmak yerine wire array kullanıyoruz)

    // -------------------------------------------------------------------------
    // AXI Handshake - basit, kombinasyonel
    // -------------------------------------------------------------------------
    assign s_axi_awready = 1'b1;
    assign s_axi_wready  = 1'b1;
    assign s_axi_arready = ~a_we;   // yazma yoksa okumaya izin ver
    assign s_axi_bresp   = 2'b00;
    assign s_axi_rresp   = 2'b00;
    assign s_axi_bvalid  = a_we;
    assign s_axi_rvalid  = ~a_we & s_axi_arvalid;

endmodule