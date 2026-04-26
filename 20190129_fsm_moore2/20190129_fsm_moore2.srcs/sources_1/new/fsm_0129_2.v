`timescale 1ns / 1ps



module fsm_0129_2(
    input  [2:0] sw,
    input  clk,
    input  reset,
    output  [2:0] led

    );

    ///state
    parameter S0 = 3'b000;
    parameter S1=  3'b001;
    parameter S2=  3'b010;
    parameter S3 = 3'b100;
    parameter S4=  3'b111;


     //state variable
    reg [2:0] current_state;
    reg [2:0] next_state;
    reg [2:0] current_led, next_led;


    //output
    assign led = current_led;

    //state register  SL
    always @(posedge clk, posedge reset) begin
    
        if (reset) begin
            current_state <= S0;
            current_led <= 3'b000;
        
        end else begin
            current_state <= next_state;
            current_led <= next_led;
        end

    end
//next state CL
    always @(*) begin
        next_state = current_state;
            //to init led cl output for full case
        next_led = current_led;
        case (current_state)
            S0 : begin
                //output
                next_led = 3'b000;
                if (sw==3'b001) begin
                    next_state = S1;
                   end   else if (sw== 3'b010) begin
                        next_state = S2;
                    end else begin
                    next_state = current_state;
            
                end

            
            
            end 
            S1: begin
                //output
                next_led = 3'b001;
                if(sw==3'b010) begin
                    next_state = S2;
                    end else begin
                    next_state = current_state;
                
                end
            
            end
            
            S2: begin
                //output
                next_led = 3'b010;
                if(sw==3'b100) begin
                    next_state = S3;
                    end else begin
                    next_state = current_state;
                
                end


            end
             S3: begin
                //output
                next_led = 3'b100;
                if(sw==3'b000) begin
                    next_state = S0;
                  end  else if (sw== 3'b011) begin
                        next_state = S1;
                       end else if (sw== 3'b111) begin
                            next_state = S4;
                        end else begin
                    next_state = current_state;
                    
                
                end
            
            end
            
            S4: begin
                //output
                next_led = 3'b111;
                if(sw==3'b100) begin
                    next_state = S0;
                    end else begin
                    next_state = current_state;
                
                end


            end
            

            default: next_state = current_state; 
        endcase
    end


     //output CL
  //  always @(*) begin
  //    case (current_state)
  //      S0 :      led = 3'b000; 
  //      S1 :      led = 3'b001; 
  //      S2 :      led = 3'b010;
  //      S3 :      led = 3'b100;
  //      S4 :      led = 3'b111;
  //      default : led = 3'b000;
  //    endcase
  //  end



endmodule
