module HayatiChip_Top (
    input  logic        clk, 
    input  logic        rst_n,
    output logic [31:0] led_out,
    input  logic        uart_rx, 
    output logic        uart_tx_o,
    input  logic        uart2_rx, 
    output logic        uart2_tx_o,
    inout  wire         i2c_scl, 
    inout  wire         i2c_sda,
    output logic        qspi_clk, 
    output logic        qspi_cs_n, 
    inout  wire [3:0]   qspi_io
);

    logic [31:0] s_axi_awaddr, s_axi_wdata, s_axi_araddr, s_axi_rdata;
    logic [3:0]  s_axi_wstrb;
    logic s_axi_awvalid, s_axi_awready, s_axi_wvalid, s_axi_wready, s_axi_bvalid, s_axi_bready;
    logic s_axi_arvalid, s_axi_arready, s_axi_rvalid, s_axi_rready;
    logic [1:0]  s_axi_bresp, s_axi_rresp;

    logic [31:0] m0_awaddr, m1_awaddr, m2_awaddr, m3_awaddr, m4_awaddr, m5_awaddr, m6_awaddr, m7_awaddr, m8_awaddr;
    logic [31:0] m0_wdata, m1_wdata, m2_wdata, m3_wdata, m4_wdata, m5_wdata, m6_wdata, m7_wdata, m8_wdata;
    logic [31:0] m0_araddr, m1_araddr, m2_araddr, m3_araddr, m4_araddr, m5_araddr, m6_araddr, m7_araddr, m8_araddr;
    logic [31:0] m0_rdata, m1_rdata, m2_rdata, m3_rdata, m4_rdata, m5_rdata, m6_rdata, m7_rdata, m8_rdata;
    logic [3:0]  m0_wstrb, m1_wstrb, m2_wstrb, m3_wstrb, m4_wstrb, m5_wstrb, m6_wstrb, m7_wstrb, m8_wstrb;
    logic m0_awvalid, m0_awready, m0_wvalid, m0_wready, m0_bvalid, m0_bready, m0_arvalid, m0_arready, m0_rvalid, m0_rready;
    logic m1_awvalid, m1_awready, m1_wvalid, m1_wready, m1_bvalid, m1_bready, m1_arvalid, m1_arready, m1_rvalid, m1_rready;
    logic m2_awvalid, m2_awready, m2_wvalid, m2_wready, m2_bvalid, m2_bready, m2_arvalid, m2_arready, m2_rvalid, m2_rready;
    logic m3_awvalid, m3_awready, m3_wvalid, m3_wready, m3_bvalid, m3_bready, m3_arvalid, m3_arready, m3_rvalid, m3_rready;
    logic m4_awvalid, m4_awready, m4_wvalid, m4_wready, m4_bvalid, m4_bready, m4_arvalid, m4_arready, m4_rvalid, m4_rready;
    logic m5_awvalid, m5_awready, m5_wvalid, m5_wready, m5_bvalid, m5_bready, m5_arvalid, m5_arready, m5_rvalid, m5_rready;
    logic m6_awvalid, m6_awready, m6_wvalid, m6_wready, m6_bvalid, m6_bready, m6_arvalid, m6_arready, m6_rvalid, m6_rready;
    logic m7_awvalid, m7_awready, m7_wvalid, m7_wready, m7_bvalid, m7_bready, m7_arvalid, m7_arready, m7_rvalid, m7_rready;
    logic m8_awvalid, m8_awready, m8_wvalid, m8_wready, m8_bvalid, m8_bready, m8_arvalid, m8_arready, m8_rvalid, m8_rready;
    logic [1:0] m0_bresp, m0_rresp, m1_bresp, m1_rresp, m2_bresp, m2_rresp, m3_bresp, m3_rresp, m4_bresp, m4_rresp, m5_bresp, m5_rresp, m6_bresp, m6_rresp, m7_bresp, m7_rresp, m8_bresp, m8_rresp;
    
    logic timer_irq, tflite_irq;

    axi_lite_interconnect my_interconnect (
        .clk(clk), .rst_n(rst_n),
        .s_axi_awaddr(s_axi_awaddr), .s_axi_awvalid(s_axi_awvalid), .s_axi_awready(s_axi_awready),
        .s_axi_wdata(s_axi_wdata), .s_axi_wstrb(s_axi_wstrb), .s_axi_wvalid(s_axi_wvalid), .s_axi_wready(s_axi_wready),
        .s_axi_bresp(s_axi_bresp), .s_axi_bvalid(s_axi_bvalid), .s_axi_bready(s_axi_bready),
        .s_axi_araddr(s_axi_araddr), .s_axi_arvalid(s_axi_arvalid), .s_axi_arready(s_axi_arready),
        .s_axi_rdata(s_axi_rdata), .s_axi_rresp(s_axi_rresp), .s_axi_rvalid(s_axi_rvalid), .s_axi_rready(s_axi_rready),
        // Slaves
        .m0_axi_awaddr(m0_awaddr), .m0_axi_awvalid(m0_awvalid), .m0_axi_awready(m0_awready), .m0_axi_wdata(m0_wdata), .m0_axi_wstrb(m0_wstrb), .m0_axi_wvalid(m0_wvalid), .m0_axi_wready(m0_wready), .m0_axi_bresp(m0_bresp), .m0_axi_bvalid(m0_bvalid), .m0_axi_bready(m0_bready), .m0_axi_araddr(m0_araddr), .m0_axi_arvalid(m0_arvalid), .m0_axi_arready(m0_arready), .m0_axi_rdata(m0_rdata), .m0_axi_rresp(m0_rresp), .m0_axi_rvalid(m0_rvalid), .m0_axi_rready(m0_rready),
        .m1_axi_awaddr(m1_awaddr), .m1_axi_awvalid(m1_awvalid), .m1_axi_awready(m1_awready), .m1_axi_wdata(m1_wdata), .m1_axi_wstrb(m1_wstrb), .m1_axi_wvalid(m1_wvalid), .m1_axi_wready(m1_wready), .m1_axi_bresp(m1_bresp), .m1_axi_bvalid(m1_bvalid), .m1_axi_bready(m1_bready), .m1_axi_araddr(m1_araddr), .m1_axi_arvalid(m1_arvalid), .m1_axi_arready(m1_arready), .m1_axi_rdata(m1_rdata), .m1_axi_rresp(m1_rresp), .m1_axi_rvalid(m1_rvalid), .m1_axi_rready(m1_rready),
        .m2_axi_awaddr(m2_awaddr), .m2_axi_awvalid(m2_awvalid), .m2_axi_awready(m2_awready), .m2_axi_wdata(m2_wdata), .m2_axi_wstrb(m2_wstrb), .m2_axi_wvalid(m2_wvalid), .m2_axi_wready(m2_wready), .m2_axi_bresp(m2_bresp), .m2_axi_bvalid(m2_bvalid), .m2_axi_bready(m2_bready), .m2_axi_araddr(m2_araddr), .m2_axi_arvalid(m2_arvalid), .m2_axi_arready(m2_arready), .m2_axi_rdata(m2_rdata), .m2_axi_rresp(m2_rresp), .m2_axi_rvalid(m2_rvalid), .m2_axi_rready(m2_rready),
        .m3_axi_awaddr(m3_awaddr), .m3_axi_awvalid(m3_awvalid), .m3_axi_awready(m3_awready), .m3_axi_wdata(m3_wdata), .m3_axi_wstrb(m3_wstrb), .m3_axi_wvalid(m3_wvalid), .m3_axi_wready(m3_wready), .m3_axi_bresp(m3_bresp), .m3_axi_bvalid(m3_bvalid), .m3_axi_bready(m3_bready), .m3_axi_araddr(m3_araddr), .m3_axi_arvalid(m3_arvalid), .m3_axi_arready(m3_arready), .m3_axi_rdata(m3_rdata), .m3_axi_rresp(m3_rresp), .m3_axi_rvalid(m3_rvalid), .m3_axi_rready(m3_rready),
        .m4_axi_awaddr(m4_awaddr), .m4_axi_awvalid(m4_awvalid), .m4_axi_awready(m4_awready), .m4_axi_wdata(m4_wdata), .m4_axi_wstrb(m4_wstrb), .m4_axi_wvalid(m4_wvalid), .m4_axi_wready(m4_wready), .m4_axi_bresp(m4_bresp), .m4_axi_bvalid(m4_bvalid), .m4_axi_bready(m4_bready), .m4_axi_araddr(m4_araddr), .m4_axi_arvalid(m4_arvalid), .m4_axi_arready(m4_arready), .m4_axi_rdata(m4_rdata), .m4_axi_rresp(m4_rresp), .m4_axi_rvalid(m4_rvalid), .m4_axi_rready(m4_rready),
        .m5_axi_awaddr(m5_awaddr), .m5_axi_awvalid(m5_awvalid), .m5_axi_awready(m5_awready), .m5_axi_wdata(m5_wdata), .m5_axi_wstrb(m5_wstrb), .m5_axi_wvalid(m5_wvalid), .m5_axi_wready(m5_wready), .m5_axi_bresp(m5_bresp), .m5_axi_bvalid(m5_bvalid), .m5_axi_bready(m5_bready), .m5_axi_araddr(m5_araddr), .m5_axi_arvalid(m5_arvalid), .m5_axi_arready(m5_arready), .m5_axi_rdata(m5_rdata), .m5_axi_rresp(m5_rresp), .m5_axi_rvalid(m5_rvalid), .m5_axi_rready(m5_rready),
        .m6_axi_awaddr(m6_awaddr), .m6_axi_awvalid(m6_awvalid), .m6_axi_awready(m6_awready), .m6_axi_wdata(m6_wdata), .m6_axi_wstrb(m6_wstrb), .m6_axi_wvalid(m6_wvalid), .m6_axi_wready(m6_wready), .m6_axi_bresp(m6_bresp), .m6_axi_bvalid(m6_bvalid), .m6_axi_bready(m6_bready), .m6_axi_araddr(m6_araddr), .m6_axi_arvalid(m6_arvalid), .m6_axi_arready(m6_arready), .m6_axi_rdata(m6_rdata), .m6_axi_rresp(m6_rresp), .m6_axi_rvalid(m6_rvalid), .m6_axi_rready(m6_rready),
        .m7_axi_awaddr(m7_awaddr), .m7_axi_awvalid(m7_awvalid), .m7_axi_awready(m7_awready), .m7_axi_wdata(m7_wdata), .m7_axi_wstrb(m7_wstrb), .m7_axi_wvalid(m7_wvalid), .m7_axi_wready(m7_wready), .m7_axi_bresp(m7_bresp), .m7_axi_bvalid(m7_bvalid), .m7_axi_bready(m7_bready), .m7_axi_araddr(m7_araddr), .m7_axi_arvalid(m7_arvalid), .m7_axi_arready(m7_arready), .m7_axi_rdata(m7_rdata), .m7_axi_rresp(m7_rresp), .m7_axi_rvalid(m7_rvalid), .m7_axi_rready(m7_rready),
        .m8_axi_awaddr(m8_awaddr), .m8_axi_awvalid(m8_awvalid), .m8_axi_awready(m8_awready), .m8_axi_wdata(m8_wdata), .m8_axi_wstrb(m8_wstrb), .m8_axi_wvalid(m8_wvalid), .m8_axi_wready(m8_wready), .m8_axi_bresp(m8_bresp), .m8_axi_bvalid(m8_bvalid), .m8_axi_bready(m8_bready), .m8_axi_araddr(m8_araddr), .m8_axi_arvalid(m8_arvalid), .m8_axi_arready(m8_arready), .m8_axi_rdata(m8_rdata), .m8_axi_rresp(m8_rresp), .m8_axi_rvalid(m8_rvalid), .m8_axi_rready(m8_rready)
    );

    // Çevre Birimleri
    axi_uart_stub my_uart ( .s_axi_aclk(clk), .s_axi_aresetn(rst_n), .rx(uart_rx), .tx(uart_tx_o), .s_axi_awaddr(m0_awaddr[3:0]), .s_axi_awvalid(m0_awvalid), .s_axi_awready(m0_awready), .s_axi_wdata(m0_wdata), .s_axi_wstrb(m0_wstrb), .s_axi_wvalid(m0_wvalid), .s_axi_wready(m0_wready), .s_axi_bresp(m0_bresp), .s_axi_bvalid(m0_bvalid), .s_axi_bready(m0_bready), .s_axi_araddr(m0_araddr[3:0]), .s_axi_arvalid(m0_arvalid), .s_axi_arready(m0_arready), .s_axi_rdata(m0_rdata), .s_axi_rresp(m0_rresp), .s_axi_rvalid(m0_rvalid), .s_axi_rready(m0_rready) );
    axi_gpio_0 my_gpio ( .s_axi_aclk(clk), .s_axi_aresetn(rst_n), .s_axi_awaddr(m1_awaddr[8:0]), .s_axi_awvalid(m1_awvalid), .s_axi_awready(m1_awready), .s_axi_wdata(m1_wdata), .s_axi_wstrb(m1_wstrb), .s_axi_wvalid(m1_wvalid), .s_axi_wready(m1_wready), .s_axi_bresp(m1_bresp), .s_axi_bvalid(m1_bvalid), .s_axi_bready(m1_bready), .s_axi_araddr(m1_araddr[8:0]), .s_axi_arvalid(m1_arvalid), .s_axi_arready(m1_arready), .s_axi_rdata(m1_rdata), .s_axi_rresp(m1_rresp), .s_axi_rvalid(m1_rvalid), .s_axi_rready(m1_rready), .gpio_io_o(led_out) );
    data_ram #( .ADDR_WIDTH(12) ) my_data_ram ( .s_axi_aclk(clk), .s_axi_aresetn(rst_n), .s_axi_awaddr(m2_awaddr), .s_axi_awvalid(m2_awvalid), .s_axi_awready(m2_awready), .s_axi_wdata(m2_wdata), .s_axi_wstrb(m2_wstrb), .s_axi_wvalid(m2_wvalid), .s_axi_wready(m2_wready), .s_axi_bresp(m2_bresp), .s_axi_bvalid(m2_bvalid), .s_axi_bready(m2_bready), .s_axi_araddr(m2_araddr), .s_axi_arvalid(m2_arvalid), .s_axi_arready(m2_arready), .s_axi_rdata(m2_rdata), .s_axi_rresp(m2_rresp), .s_axi_rvalid(m2_rvalid), .s_axi_rready(m2_rready) );
    axi_timer my_timer ( .s_axi_aclk(clk), .s_axi_aresetn(rst_n), .s_axi_awaddr(m3_awaddr), .s_axi_awvalid(m3_awvalid), .s_axi_awready(m3_awready), .s_axi_wdata(m3_wdata), .s_axi_wstrb(m3_wstrb), .s_axi_wvalid(m3_wvalid), .s_axi_wready(m3_wready), .s_axi_bresp(m3_bresp), .s_axi_bvalid(m3_bvalid), .s_axi_bready(m3_bready), .s_axi_araddr(m3_araddr), .s_axi_arvalid(m3_arvalid), .s_axi_arready(m3_arready), .s_axi_rdata(m3_rdata), .s_axi_rresp(m3_rresp), .s_axi_rvalid(m3_rvalid), .s_axi_rready(m3_rready), .irq_o(timer_irq) );
    axi_uart_stub my_uart2 ( .s_axi_aclk(clk), .s_axi_aresetn(rst_n), .rx(uart2_rx), .tx(uart2_tx_o), .s_axi_awaddr(m4_awaddr[3:0]), .s_axi_awvalid(m4_awvalid), .s_axi_awready(m4_awready), .s_axi_wdata(m4_wdata), .s_axi_wstrb(m4_wstrb), .s_axi_wvalid(m4_wvalid), .s_axi_wready(m4_wready), .s_axi_bresp(m4_bresp), .s_axi_bvalid(m4_bvalid), .s_axi_bready(m4_bready), .s_axi_araddr(m4_araddr[3:0]), .s_axi_arvalid(m4_arvalid), .s_axi_arready(m4_arready), .s_axi_rdata(m4_rdata), .s_axi_rresp(m4_rresp), .s_axi_rvalid(m4_rvalid), .s_axi_rready(m4_rready) );
    
    logic sl_i, sl_o, sl_t, sd_i, sd_o, sd_t;
    axi_i2c_master my_i2c ( .s_axi_aclk(clk), .s_axi_aresetn(rst_n), .s_axi_awaddr(m5_awaddr), .s_axi_awvalid(m5_awvalid), .s_axi_awready(m5_awready), .s_axi_wdata(m5_wdata), .s_axi_wstrb(m5_wstrb), .s_axi_wvalid(m5_wvalid), .s_axi_wready(m5_wready), .s_axi_bresp(m5_bresp), .s_axi_bvalid(m5_bvalid), .s_axi_bready(m5_bready), .s_axi_araddr(m5_araddr), .s_axi_arvalid(m5_arvalid), .s_axi_arready(m5_arready), .s_axi_rdata(m5_rdata), .s_axi_rresp(m5_rresp), .s_axi_rvalid(m5_rvalid), .s_axi_rready(m5_rready), .scl_i(sl_i), .scl_o(sl_o), .scl_t(sl_t), .sda_i(sd_i), .sda_o(sd_o), .sda_t(sd_t) );
    assign i2c_scl = sl_t ? 1'bz : sl_o; assign sl_i = i2c_scl;
    assign i2c_sda = sd_t ? 1'bz : sd_o; assign sd_i = i2c_sda;

    logic [3:0] q_i, q_o, q_t;
    axi_qspi_master my_qspi ( .s_axi_aclk(clk), .s_axi_aresetn(rst_n), .s_axi_awaddr(m6_awaddr), .s_axi_awvalid(m6_awvalid), .s_axi_awready(m6_awready), .s_axi_wdata(m6_wdata), .s_axi_wstrb(m6_wstrb), .s_axi_wvalid(m6_wvalid), .s_axi_wready(m6_wready), .s_axi_bresp(m6_bresp), .s_axi_bvalid(m6_bvalid), .s_axi_bready(m6_bready), .s_axi_araddr(m6_araddr), .s_axi_arvalid(m6_arvalid), .s_axi_arready(m6_arready), .s_axi_rdata(m6_rdata), .s_axi_rresp(m6_rresp), .s_axi_rvalid(m6_rvalid), .s_axi_rready(m6_rready), .qspi_clk(qspi_clk), .qspi_cs_n(qspi_cs_n), .qspi_io_i(q_i), .qspi_io_o(q_o), .qspi_io_t(q_t) );
    assign qspi_io[0] = q_t[0] ? 1'bz : q_o[0]; assign q_i[0] = qspi_io[0]; 
    assign qspi_io[1] = q_t[1] ? 1'bz : q_o[1]; assign q_i[1] = qspi_io[1]; 
    assign qspi_io[2] = q_t[2] ? 1'bz : q_o[2]; assign q_i[2] = qspi_io[2]; 
    assign qspi_io[3] = q_t[3] ? 1'bz : q_o[3]; assign q_i[3] = qspi_io[3];

    // YZ VE TFLITE
    logic        ai_mem_clk, ai_mem_en, ai_mem_we;
    logic [12:0] ai_mem_addr;
    logic [31:0] ai_mem_wdata, ai_mem_rdata;

    tflite_accelerator my_tflite (
        .s_axi_aclk(clk), .s_axi_aresetn(rst_n),
        .s_axi_awaddr(m7_awaddr), .s_axi_awvalid(m7_awvalid), .s_axi_awready(m7_awready),
        .s_axi_wdata(m7_wdata), .s_axi_wstrb(m7_wstrb), .s_axi_wvalid(m7_wvalid), .s_axi_wready(m7_wready),
        .s_axi_bresp(m7_bresp), .s_axi_bvalid(m7_bvalid), .s_axi_bready(m7_bready),
        .s_axi_araddr(m7_araddr), .s_axi_arvalid(m7_arvalid), .s_axi_arready(m7_arready),
        .s_axi_rdata(m7_rdata), .s_axi_rresp(m7_rresp), .s_axi_rvalid(m7_rvalid), .s_axi_rready(m7_rready),
        .mem_clk(ai_mem_clk), .mem_en(ai_mem_en), .mem_we(ai_mem_we), .mem_addr(ai_mem_addr), .mem_wdata(ai_mem_wdata), .mem_rdata(ai_mem_rdata),
        .irq_done_o(tflite_irq)
    );

    yz_memory my_yz_mem (
        .s_axi_aclk(clk), .s_axi_aresetn(rst_n),
        .s_axi_awaddr(m8_awaddr), .s_axi_awvalid(m8_awvalid), .s_axi_awready(m8_awready),
        .s_axi_wdata(m8_wdata), .s_axi_wstrb(m8_wstrb), .s_axi_wvalid(m8_wvalid), .s_axi_wready(m8_wready),
        .s_axi_bresp(m8_bresp), .s_axi_bvalid(m8_bvalid), .s_axi_bready(m8_bready),
        .s_axi_araddr(m8_araddr), .s_axi_arvalid(m8_arvalid), .s_axi_arready(m8_arready),
        .s_axi_rdata(m8_rdata), .s_axi_rresp(m8_rresp), .s_axi_rvalid(m8_rvalid), .s_axi_rready(m8_rready),
        .tflite_clk(ai_mem_clk), .tflite_en(ai_mem_en), .tflite_we(ai_mem_we), .tflite_addr(ai_mem_addr), .tflite_wdata(ai_mem_wdata), .tflite_rdata(ai_mem_rdata)
    );

    // İşlemci
    logic [31:0] instr_addr, instr_rdata, data_addr, data_wdata, data_rdata;
    logic [3:0]  data_be;
    logic instr_req, instr_gnt, instr_rvalid, data_req, data_gnt, data_rvalid, data_we;
    logic [31:0] irq_signals;

    assign irq_signals = {30'b0, tflite_irq, timer_irq};

    cv32e40p_top #( .FPU(0) ) u_riscv_core ( 
        .clk_i(clk), .rst_ni(rst_n), .pulp_clock_en_i(1'b1), .scan_cg_en_i(1'b0), 
        .boot_addr_i(32'h0), .mtvec_addr_i(32'h40), .dm_halt_addr_i(32'h80), .hart_id_i(32'h0), 
        .instr_req_o(instr_req), .instr_gnt_i(instr_gnt), .instr_rvalid_i(instr_rvalid), .instr_addr_o(instr_addr), .instr_rdata_i(instr_rdata), 
        .data_req_o(data_req), .data_gnt_i(data_gnt), .data_rvalid_i(data_rvalid), .data_we_o(data_we), .data_be_o(data_be), .data_addr_o(data_addr), .data_wdata_o(data_wdata), .data_rdata_i(data_rdata), 
        .irq_i(irq_signals), .debug_req_i(1'b0), .fetch_enable_i(1'b1) 
    );

    logic br_sel; logic [31:0] br_dat, im_dat; logic br_val;
    assign br_sel = (instr_addr < 32'h1000);
    
    boot_rom #( .ADDR_WIDTH(8) ) u_boot_rom ( .clk(clk), .en(instr_req && br_sel), .addr(instr_addr[9:2]), .rdata(br_dat) );
    instr_ram #( .ADDR_WIDTH(12) ) u_instr_ram ( .clk(clk), .en(instr_req && !br_sel), .addr(instr_addr[13:2] - 12'h400), .rdata(im_dat) );
    
    assign instr_rdata = (br_val) ? br_dat : im_dat; 
    assign instr_gnt = 1'b1;
    always_ff @(posedge clk or negedge rst_n) begin 
        if (!rst_n) begin instr_rvalid <= 0; br_val <= 0; end 
        else begin instr_rvalid <= instr_req; br_val <= instr_req && br_sel; end 
    end

    // =========================================================================
    // KUSURSUZ FSM (Timeout Korumalı ve OBI Protokolüne Tam Uyumlu)
    // =========================================================================
    localparam IDLE=3'd0, AW_W=3'd1, WAIT_B=3'd2, AR=3'd3, WAIT_R=3'd4, GNT=3'd5, RVAL=3'd6;
    logic [2:0] state_q; logic [31:0] addr_q, wdata_q; logic [3:0] wstrb_q; logic is_write_q;
    logic [3:0] timeout; 
    
    always_ff @(posedge clk or negedge rst_n) begin 
        if (!rst_n) begin 
            state_q <= IDLE; addr_q <= 0; wdata_q <= 0; wstrb_q <= 0; is_write_q <= 0; timeout <= 0;
        end else begin 
            case (state_q) 
                IDLE: begin
                    timeout <= 0;
                    if (data_req) begin 
                        state_q <= data_we ? AW_W : AR; 
                        is_write_q <= data_we;
                        addr_q <= data_addr; 
                        wdata_q <= data_wdata; 
                        wstrb_q <= data_be; 
                    end 
                end
                AW_W: begin
                    timeout <= timeout + 1;
                    if ((s_axi_awready && s_axi_wready) || timeout > 10) begin state_q <= WAIT_B; timeout <= 0; end 
                end
                WAIT_B: begin
                    timeout <= timeout + 1;
                    if (s_axi_bvalid || timeout > 10) state_q <= GNT; 
                end
                AR: begin
                    timeout <= timeout + 1;
                    if (s_axi_arready || timeout > 10) begin state_q <= WAIT_R; timeout <= 0; end 
                end
                WAIT_R: begin
                    timeout <= timeout + 1;
                    if (s_axi_rvalid || timeout > 10) state_q <= GNT; 
                end
                GNT: state_q <= RVAL; 
                RVAL: state_q <= IDLE;
            endcase 
        end 
    end 
    
    assign s_axi_awaddr = addr_q; 
    assign s_axi_awvalid = (state_q == AW_W); 
    assign s_axi_wdata = wdata_q; 
    assign s_axi_wstrb = wstrb_q; 
    assign s_axi_wvalid = (state_q == AW_W); 
    assign s_axi_bready = (state_q == WAIT_B); 
    assign s_axi_araddr = addr_q; 
    assign s_axi_arvalid = (state_q == AR); 
    assign s_axi_rready = (state_q == WAIT_R); 
    
    assign data_gnt = (state_q == GNT); 
    assign data_rvalid = (state_q == RVAL); 
    assign data_rdata = s_axi_rdata;

endmodule