// =============================================================================
// Modül: data_ram
// İşlev: İşlemci için AXI-Lite uyumlu Veri Belleği (Data RAM - BRAM Uyumlu)
// =============================================================================

module data_ram #(
    parameter int ADDR_WIDTH = 12, // 4KB RAM boyutu (1024 adet 32-bit kelime)
    parameter int DATA_WIDTH = 32
)(
    input  logic        s_axi_aclk,
    input  logic        s_axi_aresetn,

    // --- YAZMA ADRES KANALI ---
    input  logic [31:0] s_axi_awaddr,
    input  logic        s_axi_awvalid,
    output logic        s_axi_awready,

    // --- YAZMA VERİ KANALI ---
    input  logic [31:0] s_axi_wdata,
    input  logic [3:0]  s_axi_wstrb,
    input  logic        s_axi_wvalid,
    output logic        s_axi_wready,

    // --- YAZMA CEVAP KANALI ---
    output logic [1:0]  s_axi_bresp,
    output logic        s_axi_bvalid,
    input  logic        s_axi_bready,

    // --- OKUMA ADRES KANALI ---
    input  logic [31:0] s_axi_araddr,
    input  logic        s_axi_arvalid,
    output logic        s_axi_arready,

    // --- OKUMA VERİ KANALI ---
    output logic [31:0] s_axi_rdata,
    output logic [1:0]  s_axi_rresp,
    output logic        s_axi_rvalid,
    input  logic        s_axi_rready
);

    // RAM Hafıza Dizisi
    localparam int RAM_DEPTH = 2**(ADDR_WIDTH-2);
    logic [DATA_WIDTH-1:0] ram [0:RAM_DEPTH-1];

    assign s_axi_bresp = 2'b00; // "İşlem Başarılı" Cevabı
    assign s_axi_rresp = 2'b00; // "İşlem Başarılı" Cevabı

    logic aw_en, w_en, ar_en;
    assign s_axi_awready = aw_en;
    assign s_axi_wready  = w_en;
    assign s_axi_arready = ar_en;

    logic write_en, read_en;
    assign write_en = s_axi_awvalid && s_axi_awready && s_axi_wvalid && s_axi_wready;
    assign read_en  = s_axi_arvalid && s_axi_arready;

    // =========================================================
    // 1. AXI KONTROL MANTIĞI (Asenkron Resetli)
    // =========================================================
    always_ff @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            aw_en        <= 1'b1;
            w_en         <= 1'b1;
            s_axi_bvalid <= 1'b0;
            ar_en        <= 1'b1;
            s_axi_rvalid <= 1'b0;
        end else begin
            // YAZMA El Sıkışması
            if (write_en) begin
                aw_en        <= 1'b0;
                w_en         <= 1'b0;
                s_axi_bvalid <= 1'b1;
            end else if (s_axi_bready && s_axi_bvalid) begin
                aw_en        <= 1'b1;
                w_en         <= 1'b1;
                s_axi_bvalid <= 1'b0;
            end

            // OKUMA El Sıkışması
            if (read_en) begin
                ar_en        <= 1'b0;
                s_axi_rvalid <= 1'b1;
            end else if (s_axi_rready && s_axi_rvalid) begin
                ar_en        <= 1'b1;
                s_axi_rvalid <= 1'b0;
            end
        end
    end

    // =========================================================
    // 2. VIVADO BRAM UYUMLU BELLEK ERİŞİMİ (Reset YOK!)
    // =========================================================
    always_ff @(posedge s_axi_aclk) begin
        // Yazma İşlemi
        if (write_en) begin
            if (s_axi_wstrb[0]) ram[s_axi_awaddr[ADDR_WIDTH-1:2]][7:0]   <= s_axi_wdata[7:0];
            if (s_axi_wstrb[1]) ram[s_axi_awaddr[ADDR_WIDTH-1:2]][15:8]  <= s_axi_wdata[15:8];
            if (s_axi_wstrb[2]) ram[s_axi_awaddr[ADDR_WIDTH-1:2]][23:16] <= s_axi_wdata[23:16];
            if (s_axi_wstrb[3]) ram[s_axi_awaddr[ADDR_WIDTH-1:2]][31:24] <= s_axi_wdata[31:24];
        end

        // Okuma İşlemi (Senkron)
        if (read_en) begin
            s_axi_rdata <= ram[s_axi_araddr[ADDR_WIDTH-1:2]];
        end
    end

endmodule