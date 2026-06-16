module instr_ram #(
    parameter ADDR_WIDTH = 12 // Top modülden gelen 12-bitlik adres genişliği
)(
    input  logic                  clk, 
    input  logic                  en, 
    input  logic [ADDR_WIDTH-1:0] addr, 
    output logic [31:0]           rdata
);
    // 2^12 = 4096 Word kapasite
    localparam RAM_SIZE_WORDS = 2**ADDR_WIDTH;
    logic [31:0] mem [0:RAM_SIZE_WORDS-1];

    initial begin
        // 1. Önce belleği güvenli NOP ile dolduralım
        for (integer i = 0; i < RAM_SIZE_WORDS; i = i + 1) begin
            mem[i] = 32'h00000013; 
        end

        // 1. UART1'e (0x10000004) "HAY" yaz
        mem[0] = 32'h10000537; // lui a0, 0x10000
        mem[1] = 32'h00450513; // addi a0, a0, 4
        mem[2] = 32'h04800293; // addi t0, zero, 0x48 ('H')
        mem[3] = 32'h00552023; // sw t0, 0(a0)
        mem[4] = 32'h04100293; // addi t0, zero, 0x41 ('A')
        mem[5] = 32'h00552023; // sw t0, 0(a0)
        mem[6] = 32'h05900293; // addi t0, zero, 0x59 ('Y')
        mem[7] = 32'h00552023; // sw t0, 0(a0)

        // 2. Timer'ı Başlat (0x10004000) CMP=50, CTRL=1
        mem[8] = 32'h100045b7; // lui a1, 0x10004
        mem[9] = 32'h03200293; // addi t0, zero, 50
        mem[10]= 32'h0055a223; // sw t0, 4(a1)
        mem[11]= 32'h00100293; // addi t0, zero, 1
        mem[12]= 32'h0055a023; // sw t0, 0(a1)

        // 3. TFLite AI Hızlandırıcıyı Tetikle (0x1000C000 adresine 1 yaz)
        mem[13]= 32'h1000c637; // lui a2, 0x1000C
        mem[14]= 32'h00100293; // addi t0, zero, 1
        mem[15]= 32'h00562023; // sw t0, 0(a2)

        // 4. Sonsuz Döngü
        mem[16]= 32'h0000006f; // j .
    end

    always_ff @(posedge clk) begin
        // Top modül zaten adresi 4'e bölüp gönderiyor (instr_addr[13:2] - 0x400)
        // O yüzden burada dümdüz adresi okuyoruz! Çifte bölme tuzağı bitti!
        if (en) rdata <= mem[addr]; 
    end
endmodule