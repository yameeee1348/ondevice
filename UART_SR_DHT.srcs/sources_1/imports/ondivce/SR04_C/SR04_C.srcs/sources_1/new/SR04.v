`timescale 1ns / 1ps



module SR04 (

    input clk,
    input rst,
    input echo,
    input start,
    output trigger,
    output [23:0] distance


);

    wire w_tick;

sr04_controller  U_SR04_CONTROLLER(
    .clk(clk),
    .rst(rst),
    .tick(w_tick),
    .start(start),
    .echo(echo),
    .trigger(trigger),
    .distance(distance)
);


    tick_gen_1uhz U_tick_gen_1us (
        .clk(clk),
        .rst(rst),
        .o_tick(w_tick)
    );

endmodule



module sr04_controller (
    input clk,
    input rst,
    input tick,
    input start,
    input echo,
    output   trigger,
    output   [23:0] distance
);

    localparam [2:0] IDLE = 3'd0, WAIT = 3'd1;
    localparam [2:0] TRIG = 3'd2, COUNT = 3'd3, STOP = 3'd4;


    reg [ 2:0] c_state;
    reg [ 2:0] n_state;
    reg        trigger_reg, trigger_next;
    reg [23:0] distance_reg, distance_next;


    reg [15:0] trig_cnt_reg, trig_cnt_next;
    reg [23:0] echo_cnt_reg, echo_cnt_next;
    reg [15:0] wait_timeout_reg, wait_timeout_next;
    reg [15:0] cycle_wait_reg, cycle_wait_next;
    // reg [35:0] d_data ;

    localparam integer TRIG_US = 10;
    localparam integer TIMEOUT_US = 30000;
    localparam integer CYCLE_US = 60000;

    localparam integer K = 1131;
    localparam integer SHIFT = 16;

    

 

    assign trigger = trigger_reg;
    assign distance = distance_reg;
    
    reg echo_ff1, echo_ff2;
    reg echo_d;
    
    //2 FF
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            echo_ff1 <= 1'b0;
            echo_ff2 <= 1'b0;
            echo_d <= 1'b0;
            
        end else begin
            echo_ff1 <= echo;
            echo_ff2 <= echo_ff1;
            echo_d <= echo_ff2;
        end
    end

    wire echo_sync = echo_ff2;
    wire echo_rise = echo_sync & ~echo_d;
    wire echo_fall = ~echo_sync & echo_d;
    




    // state register
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state <= IDLE;
            trigger_reg <= 1'b0;
            distance_reg <= 24'd0;

            trig_cnt_reg <= 16'd0;
            echo_cnt_reg <= 24'd0;
            wait_timeout_reg <= 16'd0;
            cycle_wait_reg <= 16'd0;

        end else begin
            c_state <= n_state;

            trigger_reg <= trigger_next;
            distance_reg <= distance_next;

            trig_cnt_reg <= trig_cnt_next;
            echo_cnt_reg <= echo_cnt_next;
            wait_timeout_reg <= wait_timeout_next;
            cycle_wait_reg <= cycle_wait_next;

        end
    end

    //next, output
    always @(*) begin
        n_state = c_state;

            trigger_next = trigger_reg;
            distance_next = distance_reg;

            trig_cnt_next = trig_cnt_reg;
            echo_cnt_next = echo_cnt_reg;
            wait_timeout_next = wait_timeout_reg;
            cycle_wait_next = cycle_wait_reg;



        case (c_state)
            IDLE: begin
                trigger_next = 1'b0;
                trig_cnt_next =16'd0;
                echo_cnt_next = 24'd0;
                wait_timeout_next = 16'd0;
                cycle_wait_next = 16'd0;
                distance_next = 24'd0;

                if (start) begin
                    n_state = TRIG;

                end
            end

            TRIG: begin
                trigger_next = 1'b1;

                 if (tick) begin
                        if (trig_cnt_reg == TRIG_US - 1) begin
                         trigger_next  = 1'b0;
                         trig_cnt_next = 16'd0;
                        n_state       = WAIT;
                        end else begin
                        trig_cnt_next = trig_cnt_reg + 1'b1;
                        end
                     end
                end

            WAIT: begin
                trigger_next = 1'b0;

                if (echo_rise)begin 
                echo_cnt_next = 24'd0;

                n_state = COUNT;

                end else if (tick && (wait_timeout_reg == TIMEOUT_US - 1)) begin
                    wait_timeout_next = 16'd0;

                    
                    n_state = STOP;
                end else begin
                    wait_timeout_next = wait_timeout_reg + 1'b1;
                end
            end


            COUNT: begin

                if (tick && echo_sync) begin
                    echo_cnt_next = echo_cnt_reg + 1'b1;
                end

                if (echo_fall) begin
                    distance_next = (echo_cnt_reg * K) >> SHIFT;
                    // distance_next = echo_cnt_reg/58;

                    cycle_wait_next = 16'd0;
                    wait_timeout_next = 16'd0;
                    n_state = STOP;
                end
            end


            STOP: begin
                if(tick) begin
                if (cycle_wait_reg == CYCLE_US - 1) begin
                cycle_wait_next = 16'd0;
                n_state = IDLE;
                end else begin
                end
                cycle_wait_next = cycle_wait_reg + 1'b1;
            
            end
            end
            default: begin
                n_state = IDLE;
            end
        endcase
    end

    // always @(posedge clk , posedge rst) begin
    //     if (rst) begin
    //         trigger <=1'b0;
    //         distance <=24'd0;
    //         trig_cnt <= 16'd0;
    //         echo_cnt <= 24'd0;
    //         wait_timeout <= 16'd0;
    //         cycle_wait <= 16'd0;
    //     end else begin
        
    //         if (tick) begin
    //             case (c_state)
    //                 IDLE : begin
    //                     trigger <=1'b0;
    //                     distance <=24'd0;
    //                     trig_cnt <= 16'd0;
    //                     echo_cnt <= 24'd0;
    //                     wait_timeout <= 16'd0;
    //                     cycle_wait <= 16'd0;
    //                 end

    //                 TRIG: begin
    //                     trigger <= 1'b1;
    //                     trig_cnt <= trig_cnt + 1;

    //                 end

    //                 WAIT: begin
    //                     trigger <=1'b0;
    //                     wait_timeout <= wait_timeout + 1'b1;
    //                 end

    //                 COUNT : begin
    //                     if (echo_sync)
    //                     echo_cnt <= echo_cnt +1;

    //                 end

    //                 STOP: begin
    //                     cycle_wait <= cycle_wait +1;
    //                 end



    //             endcase

    //         end
    //         if (c_state == COUNT && n_state == STOP) begin
    //            // distance <= echo_cnt/58; //////////1/58 = 0.017241379
    //            ///0.01724 * 2^16 = 1131
    //                 d_data <= echo_cnt * 1131;
    //                 distance <= d_data >> 16;
    //         end
    //         if (c_state == TRIG && n_state == WAIT) begin
    //             trigger <=1'b0;
    //         end
    // end
    // end
    

endmodule





module tick_gen_1uhz (
    input clk,
    input rst,
    output reg o_tick
);



    parameter F_COUNT = 100;
    reg [$clog2(F_COUNT)-1:0] counter_r;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_r <= 0;
            o_tick <= 0;
        end else begin
            if (counter_r == F_COUNT - 1) begin
                counter_r <= 0;
                o_tick <= 1;
            end else begin
                counter_r <= counter_r + 1;
                o_tick <= 0;
            end
        end
    end
endmodule
