`timescale 1ns / 1ps


module clk_divider(
    input clk,
    input reset,
    output reg clk_2,
    output reg clk_10
);

    reg [3:0] counter;

    always @(posedge clk, posedge reset) begin
        if (reset) begin
            clk_2 <= 0;
            clk_10 <= 1'b0;
            counter <= 0;
        end else begin 
            clk_2 <= ~clk_2;
            counter <= counter + 1;
            
            if (counter == 9) begin
                clk_10 <= 1'b1;
                counter <= 0;
            end else begin
                clk_10 <= 1'b0;
            end
        
        end


    end

endmodule
