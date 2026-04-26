`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/28/2025 09:32:11 AM
// Design Name: 
// Module Name: tb_pwm
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


module tb_pwm;
 

    logic clk, reset, o_pwm_clk;
    logic [31:0] prescaler, duty;

    PWM_TOP #(
    .SYS_CLK(100_000_000)
    ) DUT
    (
    .clk(clk),
    .reset(reset),
    .prescaler(prescaler),
    .duty_cycle(duty),
    .pwm_clk(o_pwm_clk) 
    ); 

    always #5 clk = ~clk;

    initial begin
        clk <= 0;
        reset <= 1;
        prescaler <= 100;
        duty <= 30;
        @(posedge clk);
        reset <= 0;
        
    end


endmodule
