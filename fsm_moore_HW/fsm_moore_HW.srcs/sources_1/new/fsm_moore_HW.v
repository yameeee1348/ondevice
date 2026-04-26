`timescale 1ns / 1ps



module fsm_moore_HW(
    input  i_dbit,
    input  clk,
    input  reset,
    output reg out_dbit
    );

    ///state
    parameter S0 = 3'b000;
    parameter S1=  3'b001;
    parameter S2=  3'b010;
    parameter S3 = 3'b011;
    parameter S4=  3'b100;


    //state variable
    reg [3:0] current_state;
    reg [3:0] next_state;
    reg  out_data;

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
                 
                
                if (i_dbit==1'b0) begin
                    next_state = S1;
                end else if (i_dbit == 1'b1) begin
                    next_state = current_state;
                end

            
            
            end 
            S1: begin
                
                if(i_dbit==1'b1) begin
                    next_state = S2;
                end else begin
                    next_state = current_state;
                end
            
            end
            
            S2: begin
                
                if(i_dbit==1'b0) begin
                    next_state = S3;
                end else  begin
                    next_state = S0;
                end
            end

            S3: begin
                
                if(i_dbit==1'b1) begin
                    next_state = S4;
                end else begin
                    next_state = S1;
                end
            
            end
            
            S4: begin
                

                     if(i_dbit==1'b1 || i_dbit == 1'b0) begin
                    next_state = S1;
                end else begin
                    next_state = current_state;
                end
            end


            default: next_state = current_state; 
        endcase
    end



    //output CL
    always @(*) begin
      case (current_state)
          S0 :      out_dbit = 1'b0; 
          S1 :      out_dbit = 1'b0; 
          S2 :      out_dbit = 1'b0;
          S3 :      out_dbit = 1'b0; 
          S4 :      out_dbit = 1'b1;
          default : out_dbit = 1'b00;
      endcase
    end
   
endmodule
