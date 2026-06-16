// =============================================================================
// Proje: Hayati Chip - SoC
// Modül: axi_i2c_master
// İşlev: AXI-Lite Uyumlu I2C Master (Senkronizasyon Bug'ı Giderilmiş)
// =============================================================================

module axi_i2c_master (
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

    // --- I2C FİZİKSEL SİNYALLER ---
    input  logic        scl_i,
    output logic        scl_o,
    output logic        scl_t, 
    
    input  logic        sda_i,
    output logic        sda_o,
    output logic        sda_t  
);

    // --- KAYDEDİCİLER (REGISTERS) ---
    logic [31:0] ctrl_reg;  
    logic [31:0] addr_reg;  
    logic [31:0] dout_reg;  
    logic [31:0] stat_reg;  

    logic aw_en, w_en, ar_en;
    assign s_axi_awready = aw_en;
    assign s_axi_wready  = w_en;
    assign s_axi_arready = ar_en;
    assign s_axi_bresp   = 2'b00;
    assign s_axi_rresp   = 2'b00;

    logic busy;
    logic [7:0] rx_data_internal;
    logic i2c_done; // FSM'den AXI'ye "iş bitti" sinyali
    
    assign stat_reg = {busy, 23'b0, rx_data_internal};

    // =========================================================
    // AXI-LITE YAZMA / OKUMA (İşlemci Arayüzü)
    // =========================================================
    always_ff @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            aw_en <= 1'b1; w_en <= 1'b1; s_axi_bvalid <= 1'b0; ar_en <= 1'b1; s_axi_rvalid <= 1'b0;
            ctrl_reg <= 0; addr_reg <= 0; dout_reg <= 0; s_axi_rdata <= 0;
        end else begin
            // YAZMA İŞLEMİ
            if (s_axi_awvalid && s_axi_awready && s_axi_wvalid && s_axi_wready) begin
                aw_en <= 1'b0; w_en <= 1'b0; s_axi_bvalid <= 1'b1;
                case (s_axi_awaddr[7:0])
                    8'h00: ctrl_reg <= s_axi_wdata;
                    8'h04: addr_reg <= s_axi_wdata;
                    8'h08: dout_reg <= s_axi_wdata;
                endcase
            end else if (s_axi_bready && s_axi_bvalid) begin
                aw_en <= 1'b1; w_en <= 1'b1; s_axi_bvalid <= 1'b0;
            end

            // OKUMA İŞLEMİ
            if (s_axi_arvalid && s_axi_arready) begin
                ar_en <= 1'b0; s_axi_rvalid <= 1'b1;
                case (s_axi_araddr[7:0])
                    8'h00: s_axi_rdata <= ctrl_reg;
                    8'h04: s_axi_rdata <= addr_reg;
                    8'h08: s_axi_rdata <= dout_reg;
                    8'h0C: s_axi_rdata <= stat_reg;
                    default: s_axi_rdata <= 32'h0;
                endcase
            end else if (s_axi_rready && s_axi_rvalid) begin
                ar_en <= 1'b1; s_axi_rvalid <= 1'b0;
            end
            
            // İşlemci "Başla" dediyse ve FSM işi bitirdiyse Start bitini (ctrl_reg[0]) temizle
            if (i2c_done) begin
                ctrl_reg[0] <= 1'b0;
            end
        end
    end

    // =========================================================
    // I2C MASTER DURUM MAKİNESİ (FSM)
    // =========================================================
    typedef enum logic [3:0] {
        IDLE, START_COND, SEND_ADDR, WAIT_ACK1, 
        DATA_PHASE, WAIT_ACK2, STOP_COND
    } state_t;
    state_t state;

    // Saat Bölücü
    logic [7:0] clk_div;
    logic i2c_tick;
    always_ff @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin clk_div <= 0; i2c_tick <= 0; end
        else begin
            if (clk_div == 8'd125) begin clk_div <= 0; i2c_tick <= 1'b1; end
            else begin clk_div <= clk_div + 1; i2c_tick <= 1'b0; end
        end
    end

    logic [7:0] shift_reg;
    logic [2:0] bit_cnt;
    logic       rw_bit;

    always_ff @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            state <= IDLE;
            busy <= 0; scl_o <= 0; scl_t <= 1; sda_o <= 0; sda_t <= 1;
            bit_cnt <= 0; shift_reg <= 0; rx_data_internal <= 0; rw_bit <= 0;
            i2c_done <= 0;
        end else begin
            i2c_done <= 0; // Her zaman 0, sadece STOP'ta 1 olacak
            if (i2c_tick) begin
                case (state)
                    IDLE: begin
                        scl_t <= 1; sda_t <= 1; busy <= 0;
                        if (ctrl_reg[0]) begin // İşlemciden Start emri kalıcı olarak geldi!
                            busy <= 1;
                            shift_reg <= addr_reg[7:0];
                            rw_bit <= addr_reg[0];
                            state <= START_COND;
                        end
                    end
                    START_COND: begin
                        sda_o <= 0; sda_t <= 0; scl_t <= 1; 
                        bit_cnt <= 7;
                        state <= SEND_ADDR;
                    end
                    SEND_ADDR: begin
                        scl_t <= 0; scl_o <= 0; 
                        sda_o <= shift_reg[7]; sda_t <= 0; 
                        shift_reg <= {shift_reg[6:0], 1'b0};
                        if (bit_cnt == 0) state <= WAIT_ACK1;
                        else bit_cnt <= bit_cnt - 1;
                    end
                    WAIT_ACK1: begin
                        scl_t <= 0; scl_o <= 0; 
                        sda_t <= 1; 
                        if (rw_bit == 0) shift_reg <= dout_reg[7:0]; 
                        bit_cnt <= 7;
                        state <= DATA_PHASE;
                    end
                    DATA_PHASE: begin
                        scl_t <= 0; scl_o <= 0; 
                        if (rw_bit == 0) begin 
                            sda_o <= shift_reg[7]; sda_t <= 0;
                            shift_reg <= {shift_reg[6:0], 1'b0};
                        end else begin         
                            sda_t <= 1; 
                            rx_data_internal <= {rx_data_internal[6:0], sda_i}; 
                        end
                        if (bit_cnt == 0) state <= WAIT_ACK2;
                        else bit_cnt <= bit_cnt - 1;
                    end
                    WAIT_ACK2: begin
                        scl_t <= 0; scl_o <= 0;
                        if (rw_bit == 1) begin sda_o <= 0; sda_t <= 0; end 
                        else sda_t <= 1;
                        state <= STOP_COND;
                    end
                    STOP_COND: begin
                        scl_t <= 1; 
                        sda_o <= 0; sda_t <= 0; 
                        i2c_done <= 1; // İşlemciye "Bitti" de ki CTRL bitini düşürsün
                        state <= IDLE;
                    end
                endcase
            end
        end
    end

endmodule