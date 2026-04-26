`timescale 1ns / 1ps



module tb_fsm_mealy();

        reg clk, reset, din_bit;
        wire dout_bit;
        
        
        
        fsm_mealy dut(
            .clk(clk),
            .reset(reset),
            .din_bit(din_bit),
            . dout_bit(dout_bit)
        );
        always #5 clk = ~clk;

        initial begin

            #0;
            clk = 0;
            reset = 1;
            din_bit = 0;

            #20;
            reset =0;
            din_bit = 1;
            #30;
            din_bit = 0;
            #10;
            din_bit = 1;
            #30
            $stop;
        end
endmodule
