`timescale 1ns / 1ps



module tb_clk_divider();
        
    reg clk, reset;
    wire clk_2, clk_10; 
        
clk_divider dut(
    .clk(clk),
    .reset(reset),
    .clk_2(clk_2),
    .clk_10(clk_10)


    );


    always #5 clk = ~ clk;

    initial begin
        #0;
        clk = 0;
        reset = 1;

        #20;
        reset = 0;

        #1000;
        $stop;
    end
endmodule
