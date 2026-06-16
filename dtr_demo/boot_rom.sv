module boot_rom #(
    parameter ADDR_WIDTH = 8
)(
    input  logic                    clk,
    input  logic                    en,
    input  logic [ADDR_WIDTH-1:0]   addr,
    output logic [31:0]             rdata
);
    logic [31:0] mem [0:(2**ADDR_WIDTH)-1];

    initial begin
        for (integer i = 0; i < (2**ADDR_WIDTH); i = i + 1) begin
            mem[i] = 32'h00000013; // NOP
        end
        // Kusursuz JUMP (0x1000'e zıpla)
        mem[0] = 32'h0000106f; 
    end

    always_ff @(posedge clk) begin
        if (en) rdata <= mem[addr];
    end
endmodule