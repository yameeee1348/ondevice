`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/28/2025 01:07:32 PM
// Design Name: 
// Module Name: clock_gate
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
   

module clock_gate (
    input  logic clk_in,    
    input  logic enable,    
    output logic clk_out    
);


    assign clk_out = clk_in & enable;

endmodule