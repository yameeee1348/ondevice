`timescale 1ns / 1ps


module top_adder (
    input clk,
    input reset,

    input [7:0] a,
    input [7:0] b,
    
    output [3:0] fnd_digit,
    output [7:0] fnd_data,
    output c
);

    wire [7:0]w_sum;
    wire w_c;

fnd_controller  U_fnd_cntl(
        .clk(clk),
        .reset(reset),
        .sum({w_c,w_sum}),
        .fnd_digit(fnd_digit),
        .fnd_data(fnd_data)
);


 adder U_ADDER(
    .a(a),
    .b(b),
    .sum(w_sum),
    .c(c)
);
endmodule



module adder (
    input [7:0] a,
    input [7:0] b,
    output [7:0] sum,
    output c
);
    wire w_FA0_c;
    fourbit_full_adder U_FA1_4bit (
        .a0(a[4]),
        .a1(a[5]),
        .a2(a[6]),
        .a3(a[7]),
        .b0(b[4]),
        .b1(b[5]),
        .b2(b[6]),
        .b3(b[7]),
        .cin(w_FA0_c),
        .sum0(sum[4]),
        .sum1(sum[5]),
        .sum2(sum[6]),
        .sum3(sum[7]),
        .c(c)
    );

    fourbit_full_adder U_FA0_4bit (
        .a0(a[0]),
        .a1(a[1]),
        .a2(a[2]),
        .a3(a[3]),
        .b0(b[0]),
        .b1(b[1]),
        .b2(b[2]),
        .b3(b[3]),
        .cin(1'b0),
        .sum0(sum[0]),
        .sum1(sum[1]),
        .sum2(sum[2]),
        .sum3(sum[3]),
        .c(w_FA0_c)

    );

endmodule



module fourbit_full_adder (
    input  a0,
    a1,
    a2,
    a3,
    input  b0,
    b1,
    b2,
    b3,
    input  cin,
    output sum0,
    sum1,
    sum2,
    sum3,
    output c
);
    wire c0, c1, c2;


    full_adder U_FA0 (
        .a  (a0),
        .b  (b0),
        .cin(cin),
        .sum(sum0),
        .c  (c0)

    );
    full_adder U_FA1 (
        .a  (a1),
        .b  (b1),
        .cin(c0),
        .sum(sum1),
        .c  (c1)

    );
    full_adder U_FA2 (
        .a  (a2),
        .b  (b2),
        .cin(c1),
        .sum(sum2),
        .c  (c2)

    );
    full_adder U_FA3 (
        .a  (a3),
        .b  (b3),
        .cin(c2),
        .sum(sum3),
        .c  (c)

    );




endmodule





module full_adder (
    input  a,
    input  b,
    input  cin,
    output sum,
    output c

);

    wire w_ha_sum, w_ha0_c, w_ha1_c;
    assign c = w_ha0_c | w_ha1_c;

    half_adder U_HA1 (
        .a(w_ha_sum  /*from HA0 output sum*/),
        .b(cin),
        .sum(sum  /*to full adder sum*/),
        .carry(w_ha1_c)

    );
    half_adder U_HA0 (
        .a(a  /*from full adder*/),
        .b(b),
        .sum(w_ha_sum),
        .carry(w_ha0_c)

    );

endmodule

module half_adder (
    input  a,
    input  b,
    output sum,
    output carry

);

   // assign sum   = a ^ b;
    //assign carry = a & b;

    //half adder
    xor(sum,a,b);
    and(carry,a,b);

endmodule
