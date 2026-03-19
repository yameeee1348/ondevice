`timescale 1ns / 1ps



module TOP_main(
    input        clk,
    input        rst,
    input  [5:0] sw,           //up/down   
    input        btn_r,        //i_run_stop
    input        btn_l,        //i_clear
    input        btn_s,
    input        btn_min_up,   //분 증가
    input        btn_hour_up,  //시간 증가
    input        uart_rx, 
    input        echo,
    output       uart_tx,     
    output [3:0] fnd_digit,
    output [7:0] fnd_data,
    output       trigger,
    inout        dhtio,
    output       dht11_valid
 

    );

    wire [7:0] w_tx_data;
    wire        w_tx_start;
    wire [7:0] w_rx_data;
    wire        w_rx_done;
    wire        w_rx_busy;


    top_stopwatch U_STOPWATCH(

    .clk(clk),
    .rst(rst),
    .sw(sw),           //up/down   
    .btn_r(btn_r),        //i_run_stop
    .btn_l(btn_l),        //i_clear
    .btn_min_up(btn_min_up),   //분 증가
    .btn_hour_up(btn_hour_up),
    .btn_s(btn_s),  //시간 증가        
    .fnd_digit(fnd_digit),
    .fnd_data(fnd_data),
    .i_rx_data_p(w_rx_data),
    .i_rx_done_p(w_rx_done),
    .i_rx_busy_p(w_rx_busy),
    .echo(echo),
    .o_tx_data(w_tx_data),
    .dhtio(dhtio),
    .trigger(trigger),
    .o_tx_start(w_tx_start),
    .dht11_valid(dht11_valid)
  
);

    UART_TOP U_UART_MAIN(
    .clk(clk),
    .rst(rst),
    .uart_rx(uart_rx),
    .i_tx_start_req(w_tx_start), // 
    .i_tx_data_req(w_tx_data),  //
    .uart_tx(uart_tx),
    .o_tx_busy(w_rx_busy),     
    .o_rx_done(w_rx_done),      
    .o_rx_data(w_rx_data)       
);
endmodule
