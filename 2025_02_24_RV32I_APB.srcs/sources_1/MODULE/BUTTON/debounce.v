`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/04/2025 03:23:55 PM
// Design Name: 
// Module Name: debounce
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module button_detector (
    input clk, reset, button,
    output rising_edge, falling_edge, both_edge
);

    reg [$clog2(100_000) - 1 : 0] counter;
    reg tick;
    reg [7:0] shift_reg;
    reg q_reg;

    wire debounce;

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            counter <= 0;
            tick <= 0;    
        end else begin
            if (counter == 100_000 - 1) begin
                counter <= 0;
                tick <= 1;
            end else begin
                counter <= counter + 1;
                tick <= 0;
            end
        end
    end


    always @(posedge clk, posedge reset) begin
        if(reset)begin
            shift_reg <= 0;
        end else begin
            if(tick) begin
                shift_reg <= {button, shift_reg[7:1]};
            end
        end
    end

    assign debounce = &shift_reg;


    always @(posedge clk, posedge reset) begin
        if(reset) begin
            q_reg <= 0;
        end else begin
            q_reg <= debounce;
        end
    end

    assign rising_edge = debounce & ~q_reg;
    assign falling_edge = ~debounce & q_reg;
    assign both_edge = rising_edge | falling_edge;

endmodule