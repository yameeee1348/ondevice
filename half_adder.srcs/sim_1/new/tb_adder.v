`timescale 1ns / 1ps



module tb_adder ();

    reg a, b;
    wire sum, carry;

    half_adder dut (
        .a(a),
        .b(b),
        .sum(sum),
        .carry(carry)

    );


    initial begin
        #0;
        a = 0;
        b = 0;
        #10;
    
        a = 1;
        b = 0;
        #10; 

        a = 0;
        b = 1;
        #10; 
 
        a = 1;
        b = 1;
        #10; 

        
        $stop;
        #100;
        $finish;
 
    end

endmodule
