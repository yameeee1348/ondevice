`timescale 1ns / 1ps


module gates(
    input a,
    input b,
    output y0,
    output y1,
    output y2,
    output y3,
    output y4,
    output y5,
    output y6
);
    //and,nand
    assign y0 = a & b;
    assign y1 = ~(a & b);
    //or,nor
    assign y2 = a | b;
    assign y3 = ~(a | b);
    //xor
    assign y4 = a ^ b;
    assign y5 = ~(a ^ b);
    //not
    assign y6 = ~a;
    


endmodule
