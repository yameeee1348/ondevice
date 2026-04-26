`timescale 1ns / 1ps

module adder (


    input [3:0] a,
    input [3:0] b,
    output [3:0] sum,
    output c

);
 fourbit_full_adder U_FA_4bit (
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
    .c(c)
 


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

    assign sum   = a ^ b;
    assign carry = a & b;

endmodule
