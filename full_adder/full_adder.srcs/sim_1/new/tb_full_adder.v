`timescale 1ns / 1ps



module tb_full_adder ();


    reg a, b, cin;
    wire sum, carry;

    full_adder dut (
        .a  (a),
        .b  (b),
        .cin(cin),
        .sum(sum),
        .c  (carry)

    );

    initial begin
        #0;
        a = 0;
        b = 0;
        cin = 0;
        #10;

#10;
        a = 1;
        b = 0;
        cin = 0;
        #10;

#10;
        a = 0;
        b = 1;
        cin = 0;
        #10;

#10;
        a = 1;
        b = 1;
        cin = 0;
        #10;

#10;
        a = 0;
        b = 0;
        cin = 1;
        #10;

#10;
        a = 1;
        b = 0;
        cin = 1;
        #10;

#10;
        a = 0;
        b = 1;
        cin = 1;
        #10;

#10;
        a = 1;
        b = 1;
        cin = 1;
        #100;


        

    end

endmodule

