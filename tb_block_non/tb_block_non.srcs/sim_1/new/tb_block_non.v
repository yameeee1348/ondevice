`timescale 1ns / 1ps


module tb_block_non ();


    reg a, b, c;

    initial begin
        #0;

        a = 1;
        b = 0;

        #10;
        a = b;
        b = a;
        c = a + b;
        #10;

        a = 1;
        b = 0;

        #10;
        a <= b;
        b <= a;
        c <= a + b;
        #10;

        $stop;

    end
endmodule
