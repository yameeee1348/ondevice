`timescale 1ns / 1ps



module UART_T (
    input  logic        PCLK,
    input  logic        PRESET,
    input  logic [31:0] PADDR,
    input  logic        PWRITE,
    input  logic        PSEL,
    input  logic        PENABLE,
    input  logic [31:0] PWDATA,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    ///nput  logic [ 7:0] rx,
    //output logic        control,
    //output logic [31:0] status,
    //output logic [ 7:0] tx

    input  logic uart_rx,
    output logic uart_tx

);

    localparam STATUS_ADDR = 12'h000;
    localparam APB_CTL_ADDR = 12'h004;
    localparam APB_TX_DATA_ADDR = 12'h008;
    localparam APB_RX_DATA_ADDR = 12'h00c;
    


    logic [31:0] APB_TX_DATA_REG;
    logic [31:0] APB_RX_DATA_REG;
    logic [31:0] APB_CTL_REG;
    logic [31:0] STATUS_REG;
    //logic [ 1:0] BUAD_REG;

    //assign control = APB_CTL_REG[0];
    //assign status = STATUS_REG;
    //assign tx = APB_TX_DATA_REG[7:0];
    //assign APB_RX_DATA_REG = {24'b0, rx};

    logic w_b_tick;
    logic w_tx_busy;
    logic w_rx_done;
    logic [7:0] w_rx_data;

    //assign PREADY = 1'b1; // 대기 없음

    // TX Start 트리거: CPU가 TX 레지스터에 데이터를 쓰는 순간 1클럭 펄스 발생
    logic tx_start_pulse;
    //assign tx_start_pulse = (PSEL && PENABLE && PWRITE && (PADDR[11:0] == APB_TX_DATA_ADDR));

    // 기존 assign tx_start_pulse = ... 삭제 후 대체
always_ff @(posedge PCLK, posedge PRESET) begin
    if (PRESET) tx_start_pulse <= 1'b0;
    else tx_start_pulse <= (PSEL && PENABLE && PWRITE && (PADDR[11:0] == APB_TX_DATA_ADDR));
end

//    always_ff @(posedge PCLK, posedge PRESET) begin
//        if (PRESET) begin
//            APB_CTL_REG     <= 0;
//            STATUS_REG      <= 0;
//            APB_TX_DATA_REG <= 0;
//            APB_RX_DATA_REG <= 0;
//        end else begin
//            PREADY <= 1'b0;
//
//            if (PSEL && PENABLE && PWRITE) begin
//                PREADY <= 1'b1;
//                case (PADDR[3:0])
//                    APB_CTL_ADDR: APB_CTL_REG <= PWDATA;
//                    STATUS_ADDR: STATUS_REG <= PWDATA;
//                    APB_TX_DATA_ADDR: APB_TX_DATA_REG <= PWDATA;
//
//                    default: ;
//                endcase
//
//
//            end else if (PSEL && PENABLE && !PWRITE) begin
//                PREADY <= 1'b1;
//                case (PADDR[3:0])
//                    APB_CTL_ADDR: PRDATA <= APB_CTL_REG;
//                    STATUS_ADDR: PRDATA <= STATUS_REG;
//                    APB_RX_DATA_ADDR: PRDATA <= APB_RX_DATA_REG;
//                    default: PRDATA = 'x;
//                endcase
//            end
//        end
//    end


    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            APB_CTL_REG     <= 32'h0;
            STATUS_REG      <= 32'h0;
            APB_TX_DATA_REG <= 32'h0;
            APB_RX_DATA_REG <= 32'h0;
        end else begin
            // 하드웨어 상태를 레지스터에 자동 업데이트
            STATUS_REG[0] <= w_tx_busy; 

            // RX 모듈에서 데이터가 도착하면 레지스터에 저장하고 플래그 띄움
            if (w_rx_done) begin
                STATUS_REG[1]   <= 1'b1; // RX Ready 켬
                PREADY = 1'b1;
                APB_RX_DATA_REG <= {24'h0, w_rx_data};
                
            end else begin
                    PREADY = 1'b0;
                end

            // CPU의 APB Write 동작
            if (PSEL && PENABLE && PWRITE) begin
                PREADY = 1'b1;
                case (PADDR[11:0])
                    APB_CTL_ADDR:     APB_CTL_REG     <= PWDATA;
                    APB_TX_DATA_ADDR: APB_TX_DATA_REG <= PWDATA; // CPU가 보낼 데이터 저장
                    // STATUS와 RX는 읽기 전용이므로 CPU 쓰기에서 제외하는 것이 안전함
                endcase
            end 
            // CPU의 APB Read 동작 (읽으면 RX Ready 플래그를 자동으로 끔)
            else if (PSEL && PENABLE && !PWRITE) begin
                PREADY = 1'b1;
                if (PADDR[11:0] == APB_RX_DATA_ADDR) begin
                    STATUS_REG[1] <= 1'b0; // Clear on Read
                end
            end else begin
                    PREADY = 1'b0;
                end
        end
    end

    // ==========================================
    // 2. 레지스터 읽기 (Read)
    // ==========================================
    always_comb begin
        PRDATA = 32'h0;
        if (PSEL && PENABLE && !PWRITE) begin
            case (PADDR[11:0])
                STATUS_ADDR:      PRDATA = STATUS_REG;
                APB_CTL_ADDR:     PRDATA = APB_CTL_REG;
                APB_RX_DATA_ADDR: PRDATA = APB_RX_DATA_REG;
                default:          PRDATA = 32'h0;
            endcase
        end
    end

// ==========================================
    // 3. 하위 UART 코어 모듈 인스턴스화
    // ==========================================
    baud_tick U_BAUD_TICK (
        .clk(PCLK),
        .rst(PRESET),
        .b_tick(w_b_tick)
    );

    uart_tx U_UART_TX (
        .clk(PCLK),
        .rst(PRESET),
        .tx_start(tx_start_pulse),
        .b_tick(w_b_tick),
        .tx_data(APB_TX_DATA_REG[7:0]), 
        .uart_tx(uart_tx),
        .tx_busy(w_tx_busy),
        .tx_done()
    );

    uart_rx U_UART_RX (
        .clk(PCLK),
        .rst(PRESET),
        .rx(uart_rx),
        .b_tick(w_b_tick),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done)
    );

endmodule









module top_uart (
    input        clk,
    input        rst,
    input        start,
    input        uart_rx,
    output [7:0] rx_data,
    output       uart_tx

);

    wire w_b_tick, w_rx_done;
    wire [7:0] w_rx_data;
    //  btn_debounce U_BD_TX_START (
    //      .clk  (clk),
    //      .reset(rst),
    //      .i_btn(btn_down),
    //      .o_btn(w_tx_start)
    //
    //  );
    //
    uart_rx U_UART_RX (
        .clk(clk),
        .rst(rst),
        .rx(uart_rx),
        .b_tick(w_b_tick),
        .rx_data(w_rx_data),
        .rx_done(w_rx_done)

    );


    uart_tx U_UART_TX (
        .clk(clk),
        .rst(rst),
        .tx_start(start),
        .b_tick(w_b_tick),
        .tx_data(w_rx_data),
        .tx_busy(),
        .tx_done(),
        .uart_tx(uart_tx)
    );



    baud_tick U_BAUD_TICK (
        .clk(clk),
        .rst(rst),
        .b_tick(w_b_tick)

    );
endmodule



module uart_rx (
    input        clk,
    input        rst,
    input        rx,
    input        b_tick,
    output [7:0] rx_data,
    output       rx_done
);

    localparam IDLE = 2'd0, START = 2'd1;
    localparam DATA = 2'd2, STOP = 2'd3;

    reg [1:0] c_state, n_state;
    reg [4:0] b_tick_cnt_reg, b_tick_cnt_next;
    reg [3:0] bit_cnt_next, bit_cnt_reg;
    reg done_reg, done_next;
    reg [7:0] buf_reg, buf_next;


    assign rx_data = buf_reg;
    assign rx_done = done_reg;


    // state register
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state        <= 2'd0;
            b_tick_cnt_reg <= 5'd0;
            bit_cnt_reg    <= 3'd0;
            done_reg       <= 1'b0;
            buf_reg        <= 8'd0;

        end else begin
            c_state        <= n_state;
            b_tick_cnt_reg <= b_tick_cnt_next;
            bit_cnt_reg    <= bit_cnt_next;
            done_reg       <= done_next;
            buf_reg        <= buf_next;
        end
    end

    //next, output
    always @(*) begin
        n_state         = c_state;
        b_tick_cnt_next = b_tick_cnt_reg;
        bit_cnt_next    = bit_cnt_reg;
        done_next       = done_reg;
        buf_next        = buf_reg;

        case (c_state)
            IDLE: begin
                done_next       = 3'd0;
                bit_cnt_next    = 3'd0;
                b_tick_cnt_next = 5'd0;
                //done_next       = 1'b0;
                buf_next        = 8'd0;
                if (b_tick & !rx) begin
                    n_state = START;
                end
            end
            START: begin
                if (b_tick)
                    if (b_tick & (b_tick_cnt_reg == 7)) begin
                        b_tick_cnt_next = 0;
                        // bit_cnt_next = bit_cnt_reg + 1;
                        // buf_next[7] = rx;
                        n_state = DATA;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
            end
            DATA: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        b_tick_cnt_next = 0;
                        buf_next = {rx, buf_reg[7:1]};
                        if (bit_cnt_reg == 7) begin
                            n_state = STOP;

                        end else begin
                            bit_cnt_next = bit_cnt_reg + 1;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
            STOP: begin
                if (b_tick)
                    if (b_tick_cnt_reg == 16) begin

                        n_state   = IDLE;
                        done_next = 1'b1;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
            end
        endcase
    end


endmodule

module uart_tx (
    input        clk,
    input        rst,
    input        tx_start,
    input        b_tick,
    input  [7:0] tx_data,
    output       uart_tx,
    output       tx_busy,
    output       tx_done

);

    localparam IDLE = 2'd0, START = 2'd1;
    localparam DATA = 2'd2, STOP = 2'd3;


    // state reg
    reg [1:0] c_state, n_state;
    reg tx_reg, tx_next;  //output SL
    //bit_cont
    reg [2:0] bit_cnt_reg, bit_cnt_next;

    //busy, done
    reg done_reg, done_next;
    reg busy_reg, busy_next;
    //b_tick_count
    reg [3:0] b_tick_cnt_reg, b_tick_cnt_next;

    //data_in_buf
    reg [7:0] data_in_buf_reg, data_in_buf_next;

    assign uart_tx = tx_reg;
    assign tx_busy = busy_reg;
    assign tx_done = done_reg;

    // state regiset SL
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            c_state         <= IDLE;
            tx_reg          <= 1'b1;
            bit_cnt_reg     <= 1'b0;
            b_tick_cnt_reg  <= 4'h0;
            busy_reg        <= 1'b0;
            done_reg        <= 1'b0;
            data_in_buf_reg <= 8'h00;
        end else begin
            c_state         <= n_state;
            tx_reg          <= tx_next;
            bit_cnt_reg     <= bit_cnt_next;
            b_tick_cnt_reg  <= b_tick_cnt_next;
            done_reg        <= done_next;
            busy_reg        <= busy_next;
            data_in_buf_reg <= data_in_buf_next;
        end
    end

    // next CL
    always @(*) begin
        n_state          = c_state;             //래치 방지를 위해 현재값을 기본값으로 설정 및 초기화
        tx_next = tx_reg;
        bit_cnt_next = bit_cnt_reg;
        b_tick_cnt_next = b_tick_cnt_reg;
        busy_next = busy_reg;
        done_next = done_reg;
        data_in_buf_next = data_in_buf_reg;
        case (c_state)

            IDLE: begin
                tx_next         = 1'b1;
                bit_cnt_next    = 1'b0;
                b_tick_cnt_next = 4'h0;
                busy_next       = 1'b0;
                done_next       = 1'b0;
                if (tx_start) begin
                    n_state = START;
                    busy_next = 1'b1;
                    data_in_buf_next = tx_data;
                end
            end



            START: begin
                //to start uart fram start bit
                tx_next = 1'b0;
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        n_state = DATA;
                        b_tick_cnt_next = 4'h0;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end

            DATA: begin
                tx_next = data_in_buf_reg[0];
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        b_tick_cnt_next = 4'h0;
                        if (bit_cnt_reg == 7) begin
                            n_state = STOP;

                        end else begin
                            b_tick_cnt_next = 4'h0;
                            bit_cnt_next = bit_cnt_reg + 1;
                            n_state = DATA;
                            data_in_buf_next = {1'b0, data_in_buf_reg[7:1]};
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end


            STOP: begin
                tx_next = 1'b1;
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        done_next = 1'b1;
                        busy_next = 1'b0;
                        n_state   = IDLE;
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end
        endcase
    end
endmodule


module baud_tick (
    input clk,
    input rst,
    output reg b_tick

);

    parameter BAUDRATE = 9600 * 16;
    parameter F_count = 100_000_000 / BAUDRATE;
    //reg for counter
    reg [$clog2(F_count)-1:0] counter_reg;
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 0;
            b_tick <= 1'b0;

        end else begin
            counter_reg <= counter_reg + 1;
            if (counter_reg == (F_count - 1)) begin
                counter_reg <= 0;
                b_tick <= 1'b1;
            end else begin
                b_tick <= 1'b0;
            end
        end
    end
endmodule
