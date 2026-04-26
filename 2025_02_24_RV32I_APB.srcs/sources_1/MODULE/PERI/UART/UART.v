`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/05/2025 03:08:58 PM
// Design Name: 
// Module Name: UART
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



module TRANSMITTER(
    input clk, reset,
    input start, br_tick, br_tick_16_divide,
    input [7:0] tx_DATA,
    output tx_busy, tx_done,
    output tx
    );

    localparam IDLE = 4'b0000, START = 4'b0001, STOP = 4'b1111,
            DATA = 4'b0010;
            /*
            D0 = 4'b0010, D1 = 4'b0011, D2 = 4'b0100, D3 = 4'b0101, 
            D4 = 4'b0110, D5 = 4'b0111, D6 = 4'b1000, D7 = 4'b1001;
            */

    reg [3:0] state, next_state;
    reg [7:0] temp_DATA, next_temp_DATA;
    reg [4:0] r_br_tick_16_divide_counter;
    reg [3:0] BIT_COUNT;
    reg r_tx_busy, next_r_tx_busy;
    reg r_tx_done, next_r_tx_done;
    reg r_tx, next_r_tx;


    always @(posedge clk, posedge reset) begin
        if(reset) begin
            state <= IDLE;
            temp_DATA <= 0;
            r_tx_busy <= 0;
            r_tx_done <= 0;
            r_tx <= 0;
        end else begin
            state <= next_state;
            temp_DATA <= next_temp_DATA;
            r_tx_busy <= next_r_tx_busy;
            r_tx_done <= next_r_tx_done;
            r_tx <= next_r_tx;
        end
    end

    always @(posedge clk, posedge reset) begin
        if(reset) begin
            r_br_tick_16_divide_counter <= 0;
            BIT_COUNT <= 0;
        end else if(state != next_state) begin
            r_br_tick_16_divide_counter <= 0;
            BIT_COUNT <= 0;
        end else begin
            if(r_br_tick_16_divide_counter == 16) begin
                BIT_COUNT <= BIT_COUNT + 1;
                r_br_tick_16_divide_counter <= 0;
            end else begin
                BIT_COUNT <= BIT_COUNT;

                if(br_tick_16_divide) begin
                    r_br_tick_16_divide_counter <= r_br_tick_16_divide_counter + 1;
                end else begin
                    r_br_tick_16_divide_counter <= r_br_tick_16_divide_counter;
                end
                
            end
        end
    end


    always @(*) begin
        next_state = state;
        next_temp_DATA = temp_DATA;
        next_r_tx_busy = r_tx_busy;
        next_r_tx_done = r_tx_done;
        next_r_tx = r_tx;

        case (state)
            IDLE: begin
                next_r_tx = 1;
                next_r_tx_done = 0;
                next_r_tx_busy = 0;
                
                if(start) begin
                    next_state = START;
                    next_temp_DATA = tx_DATA;
                    next_r_tx_busy = 1;
                end
            end

            START: begin
                next_r_tx = 0;

                if(r_br_tick_16_divide_counter == 16) begin
                    next_state = DATA;
                end
            end

            DATA: begin
               next_r_tx = temp_DATA[BIT_COUNT];
               
               if(BIT_COUNT == 8) begin
                    next_state = STOP;
               end
               
            end
            
        /*
            D0: begin
                next_r_tx = temp_DATA[0];

                if(r_br_tick_16_divide_counter == 16) begin
                    next_state = D1;
                end
            end

            D1: begin
                next_r_tx = temp_DATA[1];

                if(r_br_tick_16_divide_counter == 16) begin
                    next_state = D2;
                end
            end

            D2: begin
                next_r_tx = temp_DATA[2];

                if(r_br_tick_16_divide_counter == 16) begin
                    next_state = D3;
                end
            end

            D3: begin
                next_r_tx = temp_DATA[3];

                if(r_br_tick_16_divide_counter == 16) begin
                    next_state = D4;
                end
            end

            D4: begin
                next_r_tx = temp_DATA[4];

                if(r_br_tick_16_divide_counter == 16) begin
                    next_state = D5;
                end
            end

            D5: begin
                next_r_tx = temp_DATA[5];

                if(r_br_tick_16_divide_counter == 16) begin
                    next_state = D6;
                end
            end

            D6: begin
                next_r_tx = temp_DATA[6];

                if(r_br_tick_16_divide_counter == 16) begin
                    next_state = D7;
                end
            end

            D7: begin
                next_r_tx = temp_DATA[7];
                if(r_br_tick_16_divide_counter == 16) begin
                    next_state = STOP;
                end
            end
        */        

            STOP: begin
                next_r_tx = 1;

                if(r_br_tick_16_divide_counter == 16) begin
                    next_state = IDLE;
                    next_r_tx_done = 1;
                end
            end
        endcase

    end

   assign tx = r_tx;
   assign tx_busy = r_tx_busy;
   assign tx_done = r_tx_done; 

endmodule




module RECEIVER (
    input clk, reset, 
    input rx_data, br_tick, br_tick_16_divide,
    output rx_done, rx_busy,
    output [7:0] rx
);
    
    localparam IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;

    reg [1:0] state, next_state;
    reg [4:0] r_br_tick_16_divide_counter;
    reg [3:0] BIT_COUNT;
    reg r_rx_busy, next_r_rx_busy;
    reg r_rx_done, next_r_rx_done;
    reg [7:0] r_rx, next_r_rx;


    always @(posedge clk, posedge reset) begin
        if(reset) begin
            state <= IDLE;
            r_rx_busy <= 0;
            r_rx_done <= 0;
            r_rx <= 0;
        end else begin
            state <= next_state;
            r_rx_busy <= next_r_rx_busy;
            r_rx_done <= next_r_rx_done;
            r_rx <= next_r_rx;
        end
    end




    always @(posedge clk, posedge reset) begin
        if(reset) begin
            r_br_tick_16_divide_counter <= 0;
            BIT_COUNT <= 0;
        end else if(state != next_state) begin
            r_br_tick_16_divide_counter <= 0;
            BIT_COUNT <= 0;
        end else begin
            if(r_br_tick_16_divide_counter == 16) begin
                BIT_COUNT <= BIT_COUNT + 1;
                r_br_tick_16_divide_counter <= 0;
            end else begin
                BIT_COUNT <= BIT_COUNT;

                if(br_tick_16_divide) begin
                    r_br_tick_16_divide_counter <= r_br_tick_16_divide_counter + 1;
                end else begin
                    r_br_tick_16_divide_counter <= r_br_tick_16_divide_counter;
                end
                
            end
        end
    end




    always @(*) begin
        
        next_state = state;
        next_r_rx_busy = r_rx_busy;
        next_r_rx_done = r_rx_done;
        next_r_rx = r_rx;

        case (state)
            IDLE: begin
                next_r_rx = 0;
                next_r_rx_done = 0;
                next_r_rx_busy = 0;
                
                if(!rx_data) begin
                    next_state = START;
                    next_r_rx_busy = 1;
                end
            end

            START: begin
                if(r_br_tick_16_divide_counter == 16) begin
                    next_state = DATA;
                end
            end

            DATA: begin
               if (r_br_tick_16_divide_counter == 8) begin
                    next_r_rx[BIT_COUNT] = rx_data;
               end

               if(BIT_COUNT == 8) begin
                    next_state = STOP;
               end
               
            end
            
            STOP: begin
                if(r_br_tick_16_divide_counter == 16) begin
                    next_state = IDLE;
                    next_r_rx_done = 1;
                end
            end
        endcase

    end

    assign rx = r_rx;
    assign rx_done = r_rx_done;
    assign rx_busy = r_rx_busy;

endmodule