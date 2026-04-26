`timescale 1ns / 1ps



module tb_fsm();

    reg clk, reset;
    reg sw;
    wire led;


    fsm_moore dut(
    .sw(sw),
    .clk(clk),
    .reset(reset),
    .led(led)
);
    always #5 clk = ~clk;


    always @(posedge clk, posedge reset) begin
        #0;
        sw = 0;
        clk = 0;
        reset = 1;
        
        #10;
        reset = 0;
        sw = 1;
         #50;
         sw= 0;
         #50;
         $stop;
        


    end
endmodule
