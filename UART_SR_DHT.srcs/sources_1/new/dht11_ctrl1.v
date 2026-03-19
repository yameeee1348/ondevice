
`timescale 1ns / 1ps


module dht11_ctrl1 (
    input            clk,
    input            rst,
    input            start,
    output  [15:0] humidity,   
    output  [15:0] temperature, 
    output        DHT11_done,
    output       DHT11_valid,
    output [3:0]     debug,
    inout            dhtio
);

    
    wire tick_10u;

    // FSM States
    parameter IDLE = 0, START = 1, WAIT = 2, SYNC_L = 3, SYNC_H = 4, DATA_SYNC = 5, DATA_C = 6, STOP = 7;
    reg [2:0] c_state, n_state;

    // Registers
    reg dhtio_reg, dhtio_next;
    reg io_sel_reg, io_sel_next;
    reg [11:0] tick_cnt_reg, tick_cnt_next; // 19ms까지 카운트 가능하게 확장
    reg [5:0]  bit_cnt_reg, bit_cnt_next;
    reg [39:0] data_reg, data_next;
    reg [15:0] humidity_reg, humidity_next;
    reg [15:0] temperature_reg, temperature_next;
    reg [7:0]  checksum_reg, checksum_next;
    reg [7:0]  for_checksum_reg , for_checksum_next;
    reg done_next, done_reg;    

    reg dhtio_sync1, dhtio_sync2;

    // Tristate Buffer for Half-duplex
    assign dhtio = (io_sel_reg) ? dhtio_reg : 1'bz;
    assign debug = c_state;
    assign humidity = humidity_reg;
    assign temperature = temperature_reg;
    assign DHT11_done = done_reg;
    assign DHT11_valid = (for_checksum_reg == checksum_reg) ? 1'b1 : 1'b0;


    always @(posedge clk, posedge rst) begin
        if (rst) begin
            dhtio_sync1 <= 1'b1;
            dhtio_sync2 <= 1'b1;
        end else begin
            dhtio_sync1 <= dhtio;
            dhtio_sync2 <= dhtio_sync1;
        end
    end
    tick_gen_10usec_DHT U_TCIK_10u (
        .clk(clk),
        .rst(rst), 
        .tick_10u(tick_10u)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            c_state      <= IDLE;
            dhtio_reg    <= 1'b1;
            io_sel_reg   <= 1'b1;
            tick_cnt_reg <= 0;
            bit_cnt_reg  <= 0;
            data_reg     <= 40'd0;
            humidity_reg <= 0;
            temperature_reg <= 0;
            checksum_reg <= 0;
            done_reg <= 0;
            for_checksum_reg<= 0;


           
        end else begin
            c_state      <= n_state;
            dhtio_reg    <= dhtio_next;
            io_sel_reg   <= io_sel_next;
            tick_cnt_reg <= tick_cnt_next;
            bit_cnt_reg  <= bit_cnt_next;
            data_reg     <= data_next;
            humidity_reg <= humidity_next;
            temperature_reg <= temperature_next;
            checksum_reg <= checksum_next;
            done_reg <= done_next;
            for_checksum_reg<= for_checksum_next;
            
            
        //     if (c_state == STOP && tick_cnt_reg == 0) begin
        //         DHT11_done <= 1'b1;
        //         // Checksum 
        //         if (data_reg[39:32] + data_reg[31:24] + data_reg[23:16] + data_reg[15:8] == data_reg[7:0]) begin
        //             humidity    <= data_reg[39:24];
        //             temperature <= data_reg[23:8];
        //             DHT11_valid <= 1'b1;
        //         end else begin
        //             DHT11_valid <= 1'b0;
        //         end
        //     end else if (c_state == IDLE) begin
        //         DHT11_done  <= 1'b0;
        //         DHT11_valid <= 1'b0;
        //     end
         end
    end

    always @(*) begin
        n_state       = c_state;
        tick_cnt_next = tick_cnt_reg;
        dhtio_next    = dhtio_reg;
        io_sel_next   = io_sel_reg;
        bit_cnt_next  = bit_cnt_reg;
        data_next     = data_reg;
        humidity_next =   humidity_reg; 
        temperature_next = temperature_reg ;
        checksum_next = checksum_reg ;
        done_next = done_reg ;
        for_checksum_next = for_checksum_reg;

        case (c_state)
            IDLE: begin
                io_sel_next   = 1'b1;
                dhtio_next    = 1'b1;
                tick_cnt_next = 0;
                bit_cnt_next  = 0;
                if (start) n_state = START;
            end

            START: begin
                dhtio_next = 1'b0; //MCU
                if (tick_10u) begin
                        tick_cnt_next = tick_cnt_reg + 1;
                    if (tick_cnt_reg == 1900) begin // 18ms 유지
                        tick_cnt_next = 0;
                        n_state       = WAIT;
                    
                    end
                end
            end

            WAIT: begin
                dhtio_next = 1'b1; 
                if (tick_10u) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                    if (tick_cnt_reg == 3) begin // 30us 
                        tick_cnt_next = 0;
                        io_sel_next   = 1'b0; 
                        n_state       = SYNC_L;
                    end
                end
            end

            SYNC_L: begin //  (80us)
            if (tick_10u) begin
                
                if (dhtio_sync2 == 1'b1) begin 
                    n_state = SYNC_H;
                end
            end
            end

            SYNC_H: begin //  (80us)
                if (tick_10u) begin
                if (dhtio_sync2 == 1'b0) begin
                    n_state      = DATA_SYNC;
                    bit_cnt_next = 0;
                end
                end
            end

            DATA_SYNC: begin 
                tick_cnt_next = 0;
                if (dhtio_sync2 == 1'b1) begin
                    n_state = DATA_C;
                end
            end

            DATA_C: begin // Measure High duration
                if (tick_10u) 
                    if (dhtio_sync2 == 1'b1) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                end else begin
                    // Falling Edge: 판별 및 데이터 저장
                    data_next = {data_reg[38:0], (tick_cnt_reg >= 4) ? 1'b1 : 1'b0};
                        tick_cnt_next = 0;
                        bit_cnt_next = bit_cnt_reg + 1;
                    if (bit_cnt_reg >= 40) begin
                        n_state = STOP;
                        
                        data_next = 0;
                    end else begin
                        n_state      = DATA_SYNC;
                    end
                end
            end

             STOP: begin
                humidity_next = data_reg[39:24];
                temperature_next = data_reg[23:8];
                checksum_next = data_reg[7:0];
                for_checksum_next= data_reg[39:32]+data_reg[31:24]+data_reg[23:16]+data_reg[15:8];
                if (tick_10u) begin
                    tick_cnt_next = tick_cnt_reg + 1;
                    
                    if (tick_cnt_reg == 5) begin
                        //output mode
                        dhtio_next = 1'b1;
                        io_sel_next = 1'b1;
                        n_state = IDLE;
                        done_next =1'b0;
                    end
                end
            end


            default: n_state = IDLE;
        endcase
    end
endmodule



module tick_gen_10usec_DHT (
    input      clk,      // 100MHz 메인 클락
    input      rst,
    output reg tick_10u   // 1us마다 한 번씩 1이 되는 펄스
);

    parameter F_COUNT = 1000; 
    reg [9:0] counter_reg; 

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            tick_10u     <= 1'b0;
        end else begin
            if (counter_reg == F_COUNT - 1) begin
                counter_reg <= 0;
                tick_10u     <= 1'b1; // 100번째 클락에서 펄스 발생
            end else begin
                counter_reg <= counter_reg + 1;
                tick_10u     <= 1'b0;
            end
        end
    end
endmodule