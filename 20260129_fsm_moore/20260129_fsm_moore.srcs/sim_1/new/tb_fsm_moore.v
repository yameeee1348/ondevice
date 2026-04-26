`timescale 1ns / 1ps



module tb_fsm_moore();


    reg clk, reset;
    reg [2:0] sw;
    wire [2:0] led;


    fsm_moore0129 dut(
    .sw(sw),
    .clk(clk),
    .reset(reset),
    .led(led)
    );

    always #5 clk = ~clk;

    initial begin
        #0;
        clk = 0;
        reset = 1;
        sw = 3'b000;


        #10;
        reset =0;
        sw = 3'b001;
        #20;
        sw = 3'b010;
        #20;
        sw = 3'b100;
        #100;
        $stop;

    end



endmodule
