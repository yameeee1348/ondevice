`timescale 1ns / 1ps



// module APB_slave_RAM(
//     input logic PCLK,
//     input logic PRESET,
//     input logic [31:0] PWDATA,
//     input logic [31:0] PADDR,
//     input logic PWRITE,
//     input logic PENABLE,
//     input logic PSEL,
//     input logic  [2:0] i_funct3,
//     output logic [31:0] PRDATA,
//     output logic PREADY
//     );

   

//     always_comb begin
//         if (PSEL && PENABLE) begin
//             PREADY = 1'b1;
//         end else begin
            
//             PREADY = 0;
//         end
//     end

//     data_mem U_ATA_RAM(
//     .clk(PCLK),
//     .rst(PRESET),
//     .dwe(PWRITE & PSEL),
//     .i_funct3(i_funct3),
//     .daddr(PADDR),      // ALU에서 계산된 주소
//     .dwdata(PWDATA),     // rs2 데이터 (저장할 값)
//     .drdata(PRDATA)
// );
// endmodule
