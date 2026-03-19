`timescale 1ns / 1ps



module control_unit (

    input clk,
    input rst,
    input [3:0] i_sw_mode,
    input i_run_stop,
    input i_clear,
    input i_min_up,
    input i_hour_up,
    input i_tx_busy,////////////////////////////////////////////////////////////

    output reg o_tx_start,
    output reg [7:0] o_tx_data,////////////////////////////////////////////////////////////
    output o_mode,
    output reg o_run_stop,
    output reg o_clear,
    output reg o_min_tick,
    output reg o_hour_tick

);


    localparam STOP = 2'b00, RUN = 2'b01, CLEAR = 2'B10, ADJ = 2'b11;

    // reg variable
    reg [1:0] current_state, next_state;
    assign o_mode = i_sw_mode[0];

    // state register SL
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            current_state <= STOP;

        end else begin
            current_state <= next_state;

        end
    end

    // next CL
    ////////////////////////////////////////////////////////////////////////////////////////////////
    always @(*) begin
        next_state  = current_state;
        o_run_stop  = 1'b0;
        o_clear     = 1'b0;
        o_tx_start  = 1'b0;
        o_tx_data   = 8'h00;
        o_min_tick  = 1'b0;
        o_hour_tick = 1'b0;
        case (current_state)
            STOP: begin
                // moore output
                o_run_stop = 1'b0;
                o_clear =    1'b0;
                if (i_run_stop) begin
                    next_state = RUN;

                    if (!i_tx_busy) begin
                        o_tx_start = 1'b1; 
                        o_tx_data  = 8'h72;  ///r
                    end
                end else if (i_clear) begin
                    next_state = CLEAR;

                    if (!i_tx_busy) begin
                        o_tx_start = 1'b1; 
                        o_tx_data  = 8'h63;  //c
                    end
                end else if (i_sw_mode == 4'b1010) begin
                    if (i_min_up) begin
                        o_min_tick = 1'b1;
                        if (!i_tx_busy) begin
                            o_tx_start = 1'b1;
                            o_tx_data  = 8'h75;  //u
                        end
                    end else if (i_hour_up) begin
                        o_hour_tick = 1'b1;
                        if (!i_tx_busy) begin
                            o_tx_start = 1'b1;
                            o_tx_data  = 8'h64;  //d
                        end
                    end

                end
            end
            RUN: begin
                o_run_stop = 1'b1;
                o_clear    = 1'b0;
                if (i_run_stop) begin
                    next_state = STOP;

                    if (!i_tx_busy) begin
                        o_tx_start = 1'b1;
                        o_tx_data  = 8'h72;  //r
                    end
                end
            end
            CLEAR: begin
                o_run_stop = 1'b0;
                o_clear = 1'b1;
                next_state = STOP;
            end
        endcase
    end////////////////////////////////////////////////////////////////////////////////
    // always @(posedge clk, posedge rst) begin
    //     if (rst) begin
    //         o_min_tick <=1'b0;
    //         o_hour_tick <= 1'b0;
    //     end else begin
    //         o_min_tick <= 1'b0;
    //         o_hour_tick <= 1'b0;
    //         if (i_adj_mode)begin
    //             if (i_min_up) 
    //             o_min_tick <= 1'b1;

    //             if (i_hour_up)
    //             o_hour_tick <= 1'b1;

    //         end
    //     end
    // end



endmodule
