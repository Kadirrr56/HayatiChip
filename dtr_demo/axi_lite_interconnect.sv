module axi_lite_interconnect (
    input  logic        clk, 
    input  logic        rst_n,

    // Master (İşlemci) Arayüzü
    input  logic [31:0] s_axi_awaddr, input  logic s_axi_awvalid, output logic s_axi_awready,
    input  logic [31:0] s_axi_wdata,  input  logic [3:0] s_axi_wstrb, input  logic s_axi_wvalid, output logic s_axi_wready,
    output logic [1:0]  s_axi_bresp,  output logic s_axi_bvalid, input  logic s_axi_bready,
    input  logic [31:0] s_axi_araddr, input  logic s_axi_arvalid, output logic s_axi_arready,
    output logic [31:0] s_axi_rdata,  output logic [1:0] s_axi_rresp, output logic s_axi_rvalid, input  logic s_axi_rready,

    // m0: UART1
    output logic [31:0] m0_axi_awaddr, output logic m0_axi_awvalid, input logic m0_axi_awready, output logic [31:0] m0_axi_wdata, output logic [3:0] m0_axi_wstrb, output logic m0_axi_wvalid, input logic m0_axi_wready, input logic [1:0] m0_axi_bresp, input logic m0_axi_bvalid, output logic m0_axi_bready, output logic [31:0] m0_axi_araddr, output logic m0_axi_arvalid, input logic m0_axi_arready, input logic [31:0] m0_axi_rdata, input logic [1:0] m0_axi_rresp, input logic m0_axi_rvalid, output logic m0_axi_rready,
    // m1: GPIO
    output logic [31:0] m1_axi_awaddr, output logic m1_axi_awvalid, input logic m1_axi_awready, output logic [31:0] m1_axi_wdata, output logic [3:0] m1_axi_wstrb, output logic m1_axi_wvalid, input logic m1_axi_wready, input logic [1:0] m1_axi_bresp, input logic m1_axi_bvalid, output logic m1_axi_bready, output logic [31:0] m1_axi_araddr, output logic m1_axi_arvalid, input logic m1_axi_arready, input logic [31:0] m1_axi_rdata, input logic [1:0] m1_axi_rresp, input logic m1_axi_rvalid, output logic m1_axi_rready,
    // m2: RAM
    output logic [31:0] m2_axi_awaddr, output logic m2_axi_awvalid, input logic m2_axi_awready, output logic [31:0] m2_axi_wdata, output logic [3:0] m2_axi_wstrb, output logic m2_axi_wvalid, input logic m2_axi_wready, input logic [1:0] m2_axi_bresp, input logic m2_axi_bvalid, output logic m2_axi_bready, output logic [31:0] m2_axi_araddr, output logic m2_axi_arvalid, input logic m2_axi_arready, input logic [31:0] m2_axi_rdata, input logic [1:0] m2_axi_rresp, input logic m2_axi_rvalid, output logic m2_axi_rready,
    // m3: TIMER
    output logic [31:0] m3_axi_awaddr, output logic m3_axi_awvalid, input logic m3_axi_awready, output logic [31:0] m3_axi_wdata, output logic [3:0] m3_axi_wstrb, output logic m3_axi_wvalid, input logic m3_axi_wready, input logic [1:0] m3_axi_bresp, input logic m3_axi_bvalid, output logic m3_axi_bready, output logic [31:0] m3_axi_araddr, output logic m3_axi_arvalid, input logic m3_axi_arready, input logic [31:0] m3_axi_rdata, input logic [1:0] m3_axi_rresp, input logic m3_axi_rvalid, output logic m3_axi_rready,
    // m4: UART2
    output logic [31:0] m4_axi_awaddr, output logic m4_axi_awvalid, input logic m4_axi_awready, output logic [31:0] m4_axi_wdata, output logic [3:0] m4_axi_wstrb, output logic m4_axi_wvalid, input logic m4_axi_wready, input logic [1:0] m4_axi_bresp, input logic m4_axi_bvalid, output logic m4_axi_bready, output logic [31:0] m4_axi_araddr, output logic m4_axi_arvalid, input logic m4_axi_arready, input logic [31:0] m4_axi_rdata, input logic [1:0] m4_axi_rresp, input logic m4_axi_rvalid, output logic m4_axi_rready,
    // m5: I2C
    output logic [31:0] m5_axi_awaddr, output logic m5_axi_awvalid, input logic m5_axi_awready, output logic [31:0] m5_axi_wdata, output logic [3:0] m5_axi_wstrb, output logic m5_axi_wvalid, input logic m5_axi_wready, input logic [1:0] m5_axi_bresp, input logic m5_axi_bvalid, output logic m5_axi_bready, output logic [31:0] m5_axi_araddr, output logic m5_axi_arvalid, input logic m5_axi_arready, input logic [31:0] m5_axi_rdata, input logic [1:0] m5_axi_rresp, input logic m5_axi_rvalid, output logic m5_axi_rready,
    // m6: QSPI
    output logic [31:0] m6_axi_awaddr, output logic m6_axi_awvalid, input logic m6_axi_awready, output logic [31:0] m6_axi_wdata, output logic [3:0] m6_axi_wstrb, output logic m6_axi_wvalid, input logic m6_axi_wready, input logic [1:0] m6_axi_bresp, input logic m6_axi_bvalid, output logic m6_axi_bready, output logic [31:0] m6_axi_araddr, output logic m6_axi_arvalid, input logic m6_axi_arready, input logic [31:0] m6_axi_rdata, input logic [1:0] m6_axi_rresp, input logic m6_axi_rvalid, output logic m6_axi_rready,
    // m7: TFLITE
    output logic [31:0] m7_axi_awaddr, output logic m7_axi_awvalid, input logic m7_axi_awready, output logic [31:0] m7_axi_wdata, output logic [3:0] m7_axi_wstrb, output logic m7_axi_wvalid, input logic m7_axi_wready, input logic [1:0] m7_axi_bresp, input logic m7_axi_bvalid, output logic m7_axi_bready, output logic [31:0] m7_axi_araddr, output logic m7_axi_arvalid, input logic m7_axi_arready, input logic [31:0] m7_axi_rdata, input logic [1:0] m7_axi_rresp, input logic m7_axi_rvalid, output logic m7_axi_rready,
    // m8: YZ MEMORY
    output logic [31:0] m8_axi_awaddr, output logic m8_axi_awvalid, input logic m8_axi_awready, output logic [31:0] m8_axi_wdata, output logic [3:0] m8_axi_wstrb, output logic m8_axi_wvalid, input logic m8_axi_wready, input logic [1:0] m8_axi_bresp, input logic m8_axi_bvalid, output logic m8_axi_bready, output logic [31:0] m8_axi_araddr, output logic m8_axi_arvalid, input logic m8_axi_arready, input logic [31:0] m8_axi_rdata, input logic [1:0] m8_axi_rresp, input logic m8_axi_rvalid, output logic m8_axi_rready
);

    logic u_sel_aw, g_sel_aw, r_sel_aw, t_sel_aw, u2_sel_aw, i2_sel_aw, q_sel_aw, tf_sel_aw, yz_sel_aw;
    logic u_sel_ar, g_sel_ar, r_sel_ar, t_sel_ar, u2_sel_ar, i2_sel_ar, q_sel_ar, tf_sel_ar, yz_sel_ar;

    always_comb begin
        u_sel_aw  = (s_axi_awaddr[31:12] == 20'h10000); u_sel_ar  = (s_axi_araddr[31:12] == 20'h10000);
        g_sel_aw  = (s_axi_awaddr[31:12] == 20'h10002); g_sel_ar  = (s_axi_araddr[31:12] == 20'h10002);
        r_sel_aw  = (s_axi_awaddr[31:12] == 20'h20000); r_sel_ar  = (s_axi_araddr[31:12] == 20'h20000);
        t_sel_aw  = (s_axi_awaddr[31:12] == 20'h10004); t_sel_ar  = (s_axi_araddr[31:12] == 20'h10004);
        u2_sel_aw = (s_axi_awaddr[31:12] == 20'h10006); u2_sel_ar = (s_axi_araddr[31:12] == 20'h10006);
        i2_sel_aw = (s_axi_awaddr[31:12] == 20'h10008); i2_sel_ar = (s_axi_araddr[31:12] == 20'h10008);
        q_sel_aw  = (s_axi_awaddr[31:12] == 20'h1000A); q_sel_ar  = (s_axi_araddr[31:12] == 20'h1000A);
        tf_sel_aw = (s_axi_awaddr[31:12] == 20'h1000C); tf_sel_ar = (s_axi_araddr[31:12] == 20'h1000C);
        yz_sel_aw = (s_axi_awaddr[31:12] == 20'h30000); yz_sel_ar = (s_axi_araddr[31:12] == 20'h30000);
    end

    // Yazma Kanalı
    assign m0_axi_awaddr = s_axi_awaddr; assign m0_axi_wdata = s_axi_wdata; assign m0_axi_wstrb = s_axi_wstrb; assign m0_axi_bready = s_axi_bready;
    assign m1_axi_awaddr = s_axi_awaddr; assign m1_axi_wdata = s_axi_wdata; assign m1_axi_wstrb = s_axi_wstrb; assign m1_axi_bready = s_axi_bready;
    assign m2_axi_awaddr = s_axi_awaddr; assign m2_axi_wdata = s_axi_wdata; assign m2_axi_wstrb = s_axi_wstrb; assign m2_axi_bready = s_axi_bready;
    assign m3_axi_awaddr = s_axi_awaddr; assign m3_axi_wdata = s_axi_wdata; assign m3_axi_wstrb = s_axi_wstrb; assign m3_axi_bready = s_axi_bready;
    assign m4_axi_awaddr = s_axi_awaddr; assign m4_axi_wdata = s_axi_wdata; assign m4_axi_wstrb = s_axi_wstrb; assign m4_axi_bready = s_axi_bready;
    assign m5_axi_awaddr = s_axi_awaddr; assign m5_axi_wdata = s_axi_wdata; assign m5_axi_wstrb = s_axi_wstrb; assign m5_axi_bready = s_axi_bready;
    assign m6_axi_awaddr = s_axi_awaddr; assign m6_axi_wdata = s_axi_wdata; assign m6_axi_wstrb = s_axi_wstrb; assign m6_axi_bready = s_axi_bready;
    assign m7_axi_awaddr = s_axi_awaddr; assign m7_axi_wdata = s_axi_wdata; assign m7_axi_wstrb = s_axi_wstrb; assign m7_axi_bready = s_axi_bready;
    assign m8_axi_awaddr = s_axi_awaddr; assign m8_axi_wdata = s_axi_wdata; assign m8_axi_wstrb = s_axi_wstrb; assign m8_axi_bready = s_axi_bready;

    assign m0_axi_awvalid = (u_sel_aw) ? s_axi_awvalid : 0; assign m0_axi_wvalid = (u_sel_aw) ? s_axi_wvalid : 0;
    assign m1_axi_awvalid = (g_sel_aw) ? s_axi_awvalid : 0; assign m1_axi_wvalid = (g_sel_aw) ? s_axi_wvalid : 0;
    assign m2_axi_awvalid = (r_sel_aw) ? s_axi_awvalid : 0; assign m2_axi_wvalid = (r_sel_aw) ? s_axi_wvalid : 0;
    assign m3_axi_awvalid = (t_sel_aw) ? s_axi_awvalid : 0; assign m3_axi_wvalid = (t_sel_aw) ? s_axi_wvalid : 0;
    assign m4_axi_awvalid = (u2_sel_aw)? s_axi_awvalid : 0; assign m4_axi_wvalid = (u2_sel_aw)? s_axi_wvalid : 0;
    assign m5_axi_awvalid = (i2_sel_aw)? s_axi_awvalid : 0; assign m5_axi_wvalid = (i2_sel_aw)? s_axi_wvalid : 0;
    assign m6_axi_awvalid = (q_sel_aw) ? s_axi_awvalid : 0; assign m6_axi_wvalid = (q_sel_aw) ? s_axi_wvalid : 0;
    assign m7_axi_awvalid = (tf_sel_aw)? s_axi_awvalid : 0; assign m7_axi_wvalid = (tf_sel_aw)? s_axi_wvalid : 0;
    assign m8_axi_awvalid = (yz_sel_aw)? s_axi_awvalid : 0; assign m8_axi_wvalid = (yz_sel_aw)? s_axi_wvalid : 0;

    assign s_axi_awready = (u_sel_aw)? m0_axi_awready : (g_sel_aw)? m1_axi_awready : (r_sel_aw)? m2_axi_awready : (t_sel_aw)? m3_axi_awready : (u2_sel_aw)? m4_axi_awready : (i2_sel_aw)? m5_axi_awready : (q_sel_aw)? m6_axi_awready : (tf_sel_aw)? m7_axi_awready : (yz_sel_aw)? m8_axi_awready : 0;
    assign s_axi_wready  = (u_sel_aw)? m0_axi_wready  : (g_sel_aw)? m1_axi_wready  : (r_sel_aw)? m2_axi_wready  : (t_sel_aw)? m3_axi_wready  : (u2_sel_aw)? m4_axi_wready  : (i2_sel_aw)? m5_axi_wready  : (q_sel_aw)? m6_axi_wready  : (tf_sel_aw)? m7_axi_wready  : (yz_sel_aw)? m8_axi_wready  : 0;
    assign s_axi_bvalid  = (u_sel_aw)? m0_axi_bvalid  : (g_sel_aw)? m1_axi_bvalid  : (r_sel_aw)? m2_axi_bvalid  : (t_sel_aw)? m3_axi_bvalid  : (u2_sel_aw)? m4_axi_bvalid  : (i2_sel_aw)? m5_axi_bvalid  : (q_sel_aw)? m6_axi_bvalid  : (tf_sel_aw)? m7_axi_bvalid  : (yz_sel_aw)? m8_axi_bvalid  : 0;
    assign s_axi_bresp   = (u_sel_aw)? m0_axi_bresp   : (g_sel_aw)? m1_axi_bresp   : (r_sel_aw)? m2_axi_bresp   : (t_sel_aw)? m3_axi_bresp   : (u2_sel_aw)? m4_axi_bresp   : (i2_sel_aw)? m5_axi_bresp   : (q_sel_aw)? m6_axi_bresp   : (tf_sel_aw)? m7_axi_bresp   : (yz_sel_aw)? m8_axi_bresp   : 2'b00;

    // Okuma Kanalı
    assign m0_axi_araddr = s_axi_araddr; assign m0_axi_rready = s_axi_rready; assign m0_axi_arvalid = (u_sel_ar) ? s_axi_arvalid : 0;
    assign m1_axi_araddr = s_axi_araddr; assign m1_axi_rready = s_axi_rready; assign m1_axi_arvalid = (g_sel_ar) ? s_axi_arvalid : 0;
    assign m2_axi_araddr = s_axi_araddr; assign m2_axi_rready = s_axi_rready; assign m2_axi_arvalid = (r_sel_ar) ? s_axi_arvalid : 0;
    assign m3_axi_araddr = s_axi_araddr; assign m3_axi_rready = s_axi_rready; assign m3_axi_arvalid = (t_sel_ar) ? s_axi_arvalid : 0;
    assign m4_axi_araddr = s_axi_araddr; assign m4_axi_rready = s_axi_rready; assign m4_axi_arvalid = (u2_sel_ar)? s_axi_arvalid : 0;
    assign m5_axi_araddr = s_axi_araddr; assign m5_axi_rready = s_axi_rready; assign m5_axi_arvalid = (i2_sel_ar)? s_axi_arvalid : 0;
    assign m6_axi_araddr = s_axi_araddr; assign m6_axi_rready = s_axi_rready; assign m6_axi_arvalid = (q_sel_ar) ? s_axi_arvalid : 0;
    assign m7_axi_araddr = s_axi_araddr; assign m7_axi_rready = s_axi_rready; assign m7_axi_arvalid = (tf_sel_ar)? s_axi_arvalid : 0;
    assign m8_axi_araddr = s_axi_araddr; assign m8_axi_rready = s_axi_rready; assign m8_axi_arvalid = (yz_sel_ar)? s_axi_arvalid : 0;

    assign s_axi_arready = (u_sel_ar)? m0_axi_arready : (g_sel_ar)? m1_axi_arready : (r_sel_ar)? m2_axi_arready : (t_sel_ar)? m3_axi_arready : (u2_sel_ar)? m4_axi_arready : (i2_sel_ar)? m5_axi_arready : (q_sel_ar)? m6_axi_arready : (tf_sel_ar)? m7_axi_arready : (yz_sel_ar)? m8_axi_arready : 0;
    assign s_axi_rdata   = (u_sel_ar)? m0_axi_rdata   : (g_sel_ar)? m1_axi_rdata   : (r_sel_ar)? m2_axi_rdata   : (t_sel_ar)? m3_axi_rdata   : (u2_sel_ar)? m4_axi_rdata   : (i2_sel_ar)? m5_axi_rdata   : (q_sel_ar)? m6_axi_rdata   : (tf_sel_ar)? m7_axi_rdata   : (yz_sel_ar)? m8_axi_rdata   : 0;
    assign s_axi_rvalid  = (u_sel_ar)? m0_axi_rvalid  : (g_sel_ar)? m1_axi_rvalid  : (r_sel_ar)? m2_axi_rvalid  : (t_sel_ar)? m3_axi_rvalid  : (u2_sel_ar)? m4_axi_rvalid  : (i2_sel_ar)? m5_axi_rvalid  : (q_sel_ar)? m6_axi_rvalid  : (tf_sel_ar)? m7_axi_rvalid  : (yz_sel_ar)? m8_axi_rvalid  : 0;
    assign s_axi_rresp   = (u_sel_ar)? m0_axi_rresp   : (g_sel_ar)? m1_axi_rresp   : (r_sel_ar)? m2_axi_rresp   : (t_sel_ar)? m3_axi_rresp   : (u2_sel_ar)? m4_axi_rresp   : (i2_sel_ar)? m5_axi_rresp   : (q_sel_ar)? m6_axi_rresp   : (tf_sel_ar)? m7_axi_rresp   : (yz_sel_ar)? m8_axi_rresp   : 2'b00;

endmodule