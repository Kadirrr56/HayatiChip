// =============================================================================
// Modül: axi_uart_stub (Kördüğüm Giderilmiş "Açık Kapı" Modeli)
// =============================================================================

module axi_uart_stub (
    input  logic        s_axi_aclk,
    input  logic        s_axi_aresetn,
    input  logic        rx,
    output logic        tx,

    input  logic [3:0]  s_axi_awaddr,
    input  logic        s_axi_awvalid,
    output logic        s_axi_awready,
    input  logic [31:0] s_axi_wdata,
    input  logic [3:0]  s_axi_wstrb,
    input  logic        s_axi_wvalid,
    output logic        s_axi_wready,
    output logic [1:0]  s_axi_bresp,
    output logic        s_axi_bvalid,
    input  logic        s_axi_bready,

    input  logic [3:0]  s_axi_araddr,
    input  logic        s_axi_arvalid,
    output logic        s_axi_arready,
    output logic [31:0] s_axi_rdata,
    output logic [1:0]  s_axi_rresp,
    output logic        s_axi_rvalid,
    input  logic        s_axi_rready
);

    logic tx_busy;
    logic write_triggered;

    // --- YAZMA KANALI (KÖRDÜĞÜM ÇÖZÜCÜ) ---
    // İşlemciye kapılar hep açık! (Sadece meşgulken veya onay verirken kapat)
    assign s_axi_awready = !tx_busy && !s_axi_bvalid;
    assign s_axi_wready  = !tx_busy && !s_axi_bvalid;
    assign s_axi_bresp   = 2'b00;

    always_ff @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_bvalid <= 1'b0;
            write_triggered <= 1'b0;
        end else begin
            // İşlemci rahat rahat içeri girdikten sonra onay (BVALID) ver
            if (s_axi_awvalid && s_axi_wvalid && !tx_busy && !s_axi_bvalid) begin
                s_axi_bvalid <= 1'b1;
                write_triggered <= 1'b1; // Veriyi UART'a çekmesi için tetikle
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
                write_triggered <= 1'b0;
            end else begin
                write_triggered <= 1'b0;
            end
        end
    end

    // --- OKUMA KANALI (Aynı Bırakıldı) ---
    logic axi_arready_reg;
    logic axi_rvalid_reg;
    
    assign s_axi_arready = axi_arready_reg;
    assign s_axi_rvalid  = axi_rvalid_reg;
    assign s_axi_rdata   = 32'h00000008; 
    assign s_axi_rresp   = 2'b00;
    
    always_ff @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            axi_arready_reg <= 1'b0;
            axi_rvalid_reg  <= 1'b0;
        end else begin
            if (~axi_arready_reg && s_axi_arvalid) axi_arready_reg <= 1'b1;
            else axi_arready_reg <= 1'b0;

            if (axi_arready_reg && s_axi_arvalid && ~axi_rvalid_reg) axi_rvalid_reg <= 1'b1;
            else if (axi_rvalid_reg && s_axi_rready) axi_rvalid_reg <= 1'b0;
        end
    end

    // --- UART TX (GÖNDERİM) MANTIĞI ---
    logic [3:0]  tx_bit_cnt;
    logic [31:0] tx_clk_cnt;
    logic [9:0]  tx_shift;

    localparam BAUD_DIV = 868; 

    always_ff @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            tx          <= 1'b1;
            tx_busy     <= 1'b0;
            tx_bit_cnt  <= 4'd0;
            tx_clk_cnt  <= 32'd0;
            tx_shift    <= 10'h3FF;
        end else begin
            // Veri tetiklendiği an içeri al ve kapıları kapat
            if (write_triggered) begin
                tx_shift   <= {1'b1, s_axi_wdata[7:0], 1'b0}; 
                tx_busy    <= 1'b1;                           
                tx_bit_cnt <= 4'd0;
                tx_clk_cnt <= 32'd0;
            end else if (tx_busy) begin
                if (tx_clk_cnt == BAUD_DIV - 1) begin
                    tx_clk_cnt <= 32'd0;
                    tx         <= tx_shift[0];           
                    tx_shift   <= {1'b1, tx_shift[9:1]}; 
                    tx_bit_cnt <= tx_bit_cnt + 1;
                    
                    if (tx_bit_cnt == 4'd9) begin        
                        tx_busy <= 1'b0;                 
                        tx      <= 1'b1;                 
                    end
                end else begin
                    tx_clk_cnt <= tx_clk_cnt + 1;
                end
            end
        end
    end

endmodule