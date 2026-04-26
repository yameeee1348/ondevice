`timescale 1ns / 1ps



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
