`timescale 1ns/1ps


module tick_generator 
(
    input clk, reset,
    input [31:0] prescaler,
    output clk_out
);


    reg r_tick;
    reg [31 : 0] r_tick_counter;

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            r_tick <= 0;
            r_tick_counter <= 0;
        end else if(r_tick_counter == prescaler - 1) begin
            r_tick <= 1;
            r_tick_counter <= 0;
        end else begin
            r_tick <= 0;
            r_tick_counter <= r_tick_counter + 1;
        end
    end

    assign clk_out = r_tick;

endmodule