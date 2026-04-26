`timescale 1ns / 1ps


module top_adder1 (
    input clk,
    input reset,
    input sw,           //up/down
    input btn_r,        //i_run_stop
    input btn_l,        //i_clear
    output [3:0] fnd_digit,
    output [7:0] fnd_data
    
);

    wire [13:0] counter;
    wire i_tick;
    wire w_run_stop, w_clear, w_mode;
    wire o_btn_run_stop, o_btn_clear;

btn_debounce U_BD_L(
    .clk(clk),
    .reset(reset),
    .i_btn(btn_l),
    .o_btn(o_btn_clear)

    );

btn_debounce U_BD_R(
    .clk(clk),
    .reset(clk),
    .i_btn(btn_r),
    .o_btn(o_btn_run_stop)

    );

control_unit U_control_unit(

    .clk(clk),
    .reset(reset),
    .i_mode(sw),
    .i_run_stop(o_btn_run_stop),
    .i_clear(o_btn_clear),
    .o_mode(w_mode),
    .o_run_stop(w_run_stop),
    .o_clear(w_clear)

    );
fnd_controller  U_fnd_cntl(
        .clk(clk),
        .reset(reset),
        .sum(counter),
        .fnd_digit(fnd_digit),
        .fnd_data(fnd_data)
);



tick_gen U_tick_gen(

    .clk(clk),
    .reset(reset),
    .i_run_stop(w_run_stop),
    .o_tick_10(i_tick)

);
counter_9999 U_fnd_counter(

    .clk(clk),
    .reset(reset),
    .mode(w_mode),
    .clear(w_clear),
    .run_stop(w_run_stop),
    .counter(counter),
    .i_tick(i_tick)
);
endmodule



module counter_9999 (

    input clk,
    input reset,
    input i_tick,
    input mode,
    input clear,
    input run_stop,
    output [13:0] counter

);
    reg [13:0] counter_r;
    assign counter = counter_r;

    always @(posedge clk, posedge reset) begin
        if (reset | clear) begin
            //init counter_r
            counter_r <= 14'b0;
        end else begin
            if (run_stop) begin           
                if (mode) begin
                
                    if (i_tick) begin
                        counter_r <= counter_r -1;
                
                        if (counter_r == 0) begin
                            counter_r <=14'd9999;
                    end
                end
            end else begin  



                 if (i_tick ) begin
                     counter_r <= counter_r +1;
                    if (counter_r == (10000 - 1)) begin
                        counter_r <= 14'b0;
                
                
                    end
            
                end
            

            end
        end

    end
end
endmodule


module tick_gen(

    input clk,
    input reset,
    input i_run_stop,
    output reg o_tick_10
);

    reg [$clog2(10_000_000)-1:0] counter_r;

    always @(posedge clk, posedge reset) begin
    
        if (reset) begin
            
                counter_r <= 0;
                o_tick_10 <= 1'b0;
        
        end else begin
            if (i_run_stop) begin
            counter_r <= counter_r +1;
            
                
            end
            if (counter_r == (10_000_000 - 1)) begin
                counter_r <= 0;
                o_tick_10 <= 1'b1;
            
            
            end else begin
                o_tick_10 <= 1'b0;
            end       
        end
    end
endmodule