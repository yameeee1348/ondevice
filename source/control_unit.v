`timescale 1ns / 1ps



module control_unit(

    input clk,
    input reset,
    input i_mode,
    input i_run_stop,
    input i_clear,
    output o_mode,
    output reg o_run_stop,
    output reg o_clear

    );


    localparam STOP = 2'b00, RUN = 2'b01, CLEAR = 2'B10 ;


    

    // reg variable
    reg [1:0] current_state, next_state;



    assign o_mode = i_mode;
    

    // state register SL
    always @(posedge clk, posedge reset) begin
        
        if (reset) begin
            current_state <= STOP;


        end else begin
            current_state <= next_state;

        end
    end




    // next CL
    always @(*) begin
         next_state = current_state;
         o_run_stop =   1'b0;
         o_clear =      1'b0;
            case (current_state)
                STOP : begin
                    // moore output
                    o_run_stop = 1'b0;
                    o_clear =    1'b0;
                    if (i_run_stop) begin
                        next_state = RUN;

                    end else if (i_clear) begin
                        next_state = CLEAR;
                    end
                end
                RUN: begin
                    o_run_stop = 1'b1;
                    o_clear    = 1'b0;
                    if (i_run_stop) begin
                        next_state = STOP;

                    end
                
                
                end
                CLEAR: begin
                    o_run_stop = 1'b0;
                    o_clear = 1'b1;
                    next_state = STOP;
                end


               
            endcase


    end
endmodule
