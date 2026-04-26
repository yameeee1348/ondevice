`timescale 1ns / 1ps



module fsm_mealy_HW(
    input clk,
    input reset,
    input din_bit,
    output dout_bit

    );

    reg [3:0] state_reg, next_state;

    parameter S0= 3'b000;
    parameter S1= 3'b001;
    parameter S2= 3'b010;
    parameter S3= 3'b011;
    parameter start = 3'b100;
    

    always @(state_reg or din_bit) begin
        

        case (state_reg)
            start :     if       (reset == 0)         next_state = S0;
                        else                          next_state = start;
            S0 :        if       (din_bit == 0)       next_state = S1;
                        else if  (din_bit == 1)       next_state = S0;
                        else                          next_state = start;
            S1 :        if       (din_bit == 0)       next_state = S1;
                        else if  (din_bit == 1)       next_state = S2;
                        else                          next_state = start;
            S2 :         if      (din_bit == 0)       next_state = S3;
                        else if  (din_bit == 1)       next_state = S0;
                        else                          next_state = start;
            S3 :         if       (din_bit == 0)      next_state = S1;
                        else if   (din_bit == 1)      next_state = S0;
                        else                          next_state = start;
            
 
            default:                              next_state = start; 
        endcase

    end

    always @(posedge clk, posedge reset) begin
        
        if (reset == 1) state_reg <= start;
        else          state_reg <= next_state;
        end

    assign dout_bit = (((state_reg == S3) && (din_bit == 1))) ? 1:0;
    
endmodule