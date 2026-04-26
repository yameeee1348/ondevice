// `timescale 1ns / 1ps



// module control_unit (

//     input clk,
//     input rst,
//     input i_mode,
//     input i_run_stop,
//     input i_clear,
//     input i_min_up,
//     input i_hour_up,
//     input i_adj_mode,
//     input i_tx_busy,////////////////////////////////////////////////////////////
//     input i_start,
//     output reg o_tx_start,
//     output reg [7:0] o_tx_data,////////////////////////////////////////////////////////////
//     output o_mode,
//     output reg o_run_stop,
//     output reg o_clear,
//     output reg o_min_tick,
//     output reg o_hour_tick,
//     output o_start

// );


//     localparam STOP = 2'b000, RUN = 2'b001, CLEAR = 2'b010, ADJ = 2'b011 ;

//     // reg variable
//     reg [1:0] current_state, next_state;
//     assign o_mode = i_mode;
//     assign o_start = i_start;
//     // state register SL
//     always @(posedge clk, posedge rst) begin
//         if (rst) begin
//             current_state <= STOP;

//         end else begin
//             current_state <= next_state;

//         end
//     end

//     // next CL
//     ////////////////////////////////////////////////////////////////////////////////////////////////
//     always @(*) begin
//         next_state  = current_state;
//         o_run_stop  = 1'b0;
//         o_clear     = 1'b0;
//         o_tx_start  = 1'b0;
//         o_tx_data   = 8'h00;
//         o_min_tick  = 1'b0;
//         o_hour_tick = 1'b0;
//         case (current_state)
//             STOP: begin
//                 // moore output
//                 o_run_stop = 1'b0;
//                 o_clear =    1'b0;
//                 if (i_run_stop ) begin
//                     next_state = RUN;

//                     if (!i_tx_busy) begin
//                         o_tx_start = 1'b1; 
//                         o_tx_data  = 8'h72;  ///r
//                     end
//                 end else if (i_clear) begin
//                     next_state = CLEAR;

//                     if (!i_tx_busy) begin
//                         o_tx_start = 1'b1; 
//                         o_tx_data  = 8'h6C;  //c
//                     end
//                 end else if (i_adj_mode) begin
//                     if (i_min_up) begin
//                         o_min_tick = 1'b1;
//                         if (!i_tx_busy) begin
//                             o_tx_start = 1'b1;
//                             o_tx_data  = 8'h75;  //u
//                         end
//                     end else if (i_hour_up) begin
//                         o_hour_tick = 1'b1;
//                         if (!i_tx_busy) begin
//                             o_tx_start = 1'b1;
//                             o_tx_data  = 8'h64;  //d
//                         end
//                     end

//                 end
//             end
//             RUN: begin
//                 o_run_stop = 1'b1;
//                 o_clear    = 1'b0;
//                 if (i_run_stop) begin
//                     next_state = STOP;

//                     if (!i_tx_busy) begin
//                         o_tx_start = 1'b1;
//                         o_tx_data  = 8'h72;  //r
//                     end
//                 end
//             end
//             CLEAR: begin
//                 o_run_stop = 1'b0;
//                 o_clear = 1'b1;
//                 next_state = STOP;
//             end
//         endcase
//     end////////////////////////////////////////////////////////////////////////////////
//     // always @(posedge clk, posedge rst) begin
//     //     if (rst) begin
//     //         o_min_tick <=1'b0;
//     //         o_hour_tick <= 1'b0;
//     //     end else begin
//     //         o_min_tick <= 1'b0;
//     //         o_hour_tick <= 1'b0;
//     //         if (i_adj_mode)begin
//     //             if (i_min_up) 
//     //             o_min_tick <= 1'b1;

//     //             if (i_hour_up)
//     //             o_hour_tick <= 1'b1;

//     //         end
//     //     end
//     // end



// endmodule
`timescale 1ns / 1ps

module control_unit (
    input clk,
    input rst,
    input i_mode,
    input i_run_stop,
    input i_clear,
    input i_min_up,
    input i_hour_up,
    input i_adj_mode,
    input i_tx_busy,
    input i_start,
    output reg o_tx_start,
    output reg [7:0] o_tx_data,
    output o_mode,
    output reg o_run_stop,
    output reg o_clear,
    output reg o_min_tick,
    output reg o_hour_tick,
    output o_start
);

    // [수정] 레지스터 폭을 3비트로 확장하여 localparam과 일치시킴
    reg [2:0] current_state, next_state; 
    
    // 상태 정의 (3비트로 통일)
    localparam STOP = 3'b000, RUN = 3'b001, CLEAR = 3'b010, ADJ = 3'b011;

    assign o_mode = i_mode;
    assign o_start = i_start;

    // State Register
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            current_state <= STOP;
        end else begin
            current_state <= next_state;
        end
    end

    // Next State & Output Logic
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
                o_run_stop = 1'b0;
                o_clear    = 1'b0;
                
                if (i_run_stop) begin
                    next_state = RUN;
                    if (!i_tx_busy) begin
                        o_tx_start = 1'b1; 
                        o_tx_data  = 8'h52; // 'R' (Run) - 대문자로 변경하여 루프 차단
                    end
                end else if (i_clear) begin
                    next_state = CLEAR;
                    if (!i_tx_busy) begin
                        o_tx_start = 1'b1; 
                        o_tx_data  = 8'h43; // 'C' (Clear) - 'l' 대신 'C' 사용 추천
                    end
                end else if (i_adj_mode) begin
                    // 시간 조정 모드
                    if (i_min_up) begin
                        o_min_tick = 1'b1;
                        if (!i_tx_busy) begin
                            o_tx_start = 1'b1;
                            o_tx_data  = 8'h55; // 'U' (Up)
                        end
                    end else if (i_hour_up) begin
                        o_hour_tick = 1'b1;
                        if (!i_tx_busy) begin
                            o_tx_start = 1'b1;
                            o_tx_data  = 8'h44; // 'D' (Down/Hour Up)
                        end
                    end
                end
            end

            RUN: begin
                o_run_stop = 1'b1;
                if (i_run_stop) begin
                    next_state = STOP;
                    if (!i_tx_busy) begin
                        o_tx_start = 1'b1;
                        o_tx_data  = 8'h53; // 'S' (Stop) - 정지 상태임을 명확히 함
                    end
                end
            end

            CLEAR: begin
                o_clear = 1'b1;
                next_state = STOP;
            end
            
            default: next_state = STOP;
        endcase
    end

endmodule