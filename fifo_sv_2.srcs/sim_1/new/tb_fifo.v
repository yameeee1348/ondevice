`timescale 1ns / 1ps



module tb_fifo ();

    reg clk, rst, push_pop;
    reg  [7:0] push_data;
    wire [7:0] pop_data;
    wire full, empty;
    reg push, pop;
    reg [7:0] push_cnt;
    reg [7:0] pop_cnt;

    reg rand_pop, rand_push;
    reg [7:0] rand_data;
    reg [7:0] compare_data[0:511];

    integer  i, pass_cnt, Fail_cnt;

    fifo dut (

        .clk(clk),
        .rst(rst),
        .we(push),
        .re(pop),
        .wdata(push_data),
        .rdata(pop_data),
        .full(full),
        .empty(empty)

    );
    always #5 clk = ~clk;

    initial begin
        #0;
        clk       = 0;
        rst       = 1;
        push_data = 0;
        pop       = 0;
        push      = 0;
        i         = 0;
        rand_data = 0;
        rand_pop  = 0;
        rand_push = 0;
        push_cnt  =0;
        pop_cnt =0;
        pass_cnt = 0;
        Fail_cnt = 0;

        @(negedge clk);
        @(negedge clk);


        rst = 0;


        for (i = 0; i < 5; i = i + 1) begin

            push = 1;
            push_data = 8'h61 + i;  //'a'
            @(negedge clk);

        end
        push = 0;

        for (i = 0; i < 5; i = i + 1) begin

            pop = 1;
            // push_data = 8'h61 + 1; //'a'
            @(negedge clk);

        end
        pop = 0;

        push = 1;
        push_data = 8'haa;

        @(negedge clk);
        push = 0;
        @(negedge clk);


        for (i = 0; i < 16; i = i + 1) begin
            push = 1;
            pop = 1;
            push_data = i;

            @(negedge clk);
        end

        push = 0;
        pop  = 1;
        @(negedge clk);
        @(negedge clk);
        pop       = 0;
        @(negedge clk);

        for (i = 0;i<256 ;i = i+1 ) begin
            

        //random test
        rand_push = $random % 2;
        rand_pop  = $random % 2;
        rand_data = $random % 256;
        push      = rand_push;
        pop       = rand_pop;
        push_data = rand_data;
        
        
        #4;
        
        if (!full & push) begin
            compare_data[push_cnt] = rand_data;
            push_cnt = push_cnt + 1;
        end
        if (!empty & pop == 1) begin
            
            if (pop_data == compare_data[pop_cnt]) begin
                $display("%t: pass, pop_data = %h, compare_data=%h",$time,pop_data, compare_data[pop_cnt]);
                pass_cnt = pass_cnt +1;
            end else begin
                 $display("%t: fail!!!!!, pop_data = %h, compare_data=%h",$time,pop_data, compare_data[pop_cnt]);
                Fail_cnt = Fail_cnt + 1;
            end
            pop_cnt = pop_cnt +1;
        end
        //@(posedge clk);
        @(negedge clk);
        end

        $display("%t : pass count = %d, Fail_cnt = %d",$time, pass_cnt, Fail_cnt );

        repeat (5) @(negedge clk);

        $stop;



    end

endmodule
