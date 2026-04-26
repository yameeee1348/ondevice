`timescale 1ns / 1ps



module fsm_moore (
    input  sw,
    input  clk,
    input  reset,
    output led

);
    ///state
    parameter S0 = 1'b0, S1= 1'b1;

    //state variable
    reg current_state, next_state;

    //state register  SL
    always @(posedge clk, posedge reset) begin
    
        if (reset) begin
            current_state <= S0;
        
        end else begin
            current_state <= next_state;

        end

    end

    //next state CL
    always @(*) begin
        next_state = current_state;
        case (current_state)
            S0 : begin
                if (sw==1'b1) begin
                    next_state = S1;
                end
            
            
            end 
            S1: begin

                if(sw==1'b0) begin
                    next_state = S0;
                end
            
            end

            default: next_state = current_state; 
        endcase
    end

    //output CL
    assign led = (current_state == S1) ?  1'b1 : 1'b0;


endmodule
