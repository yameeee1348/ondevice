`timescale 1ns / 1ps




module register (
   input clk,
    input rst,
    input we,
    input [7:0] wdata,
    output logic [7:0] rdata

);

    

    always_ff @( posedge clk, posedge rst ) begin 
        if (rst) begin
            rdata <= 0;

        end else begin
           if(we)
            rdata <= wdata;        
        end
    
    end
    
    
endmodule