`timescale 1ns / 1ps



module instruction_memory(
    input [31:0] instr_addr,
    output [31:0]  instr_data 
);

    logic [31:0] rom[0:255];

    initial begin
        // rom[1] = 32'h12345537;
       // $readmemh("riscv_rv32I_rom_data.mem",rom);
    //$readmemh("slave_ram.mem",rom);
    //$readmemh("APB_GPO.mem",rom);
    $readmemh("APB_Ram_GPO_GPI.mem",rom);
    //$readmemh("APB_BLINKMEM.mem",rom);
    //$readmemh("FND_MEM.mem",rom);
    //$readmemh("CMEM.mem",rom);

     end

      assign instr_data = rom[instr_addr[31:2]];
     
endmodule
