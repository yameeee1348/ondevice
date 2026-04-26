`timescale 1ns / 1ps



module tb_ctrl_unit( );

    reg clk;
    reg reset;
    reg i_mode;
    reg i_run_stop;
    reg i_clear;
    wire o_mode;
    wire o_run_stop;
    wire o_clear;




    control_unit dut(

    .clk(clk),
    .reset(reset),
    .i_mode(i_mode),
    .i_run_stop(i_run_stop),
    .i_clear(i_clear),
    .o_mode(o_mode),
    .o_run_stop(o_run_stop),
    .o_clear(o_clear)
    );

    always #5 clk = ~clk;


    initial begin
        #0;
        clk = 0;
        reset =1;
        i_mode =0;
        i_run_stop =1;
        i_clear = 0;
        #10;
        reset = 0;
        i_mode = 0;
        i_run_stop = 0;
        i_clear = 0;
        #100;
        i_run_stop =1 ;
        #100;
        i_run_stop = 0;
         #100;
        i_run_stop =1 ;
        #100;
        i_run_stop = 0;
        #100;
        i_clear = 1;
        #100;
        i_clear = 0;
        #100;
        $stop;
    end

endmodule
