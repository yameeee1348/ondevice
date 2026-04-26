`timescale 1ns / 1ps



module Top_Slave(   
    input logic clk,
    input logic reset,

    input logic [7:0] sw,
    input logic sclk,
    input logic mosi,
    input logic cs_n,
    output logic miso,

    output logic [3:0] fnd_digit,
    output logic [7:0] fnd_data

    );


    logic [7:0] rx_data;
    logic   spi_done;
    logic [3:0] cnt_1, cnt_10, cnt_100, cnt_1000;

    SPI_slave u_spi_slave(
    .clk(clk),
    .reset(reset),
    .cpol(1'b0),
    .cpha(1'b0),
    .tx_data(sw),
    .sclk(sclk),
    .mosi(mosi),
    .cs_n(cs_n),
    .miso(miso),
    .rx_data(rx_data),
    .done(spi_done)
    );

    fnd_controller_direct u_fnd_ctrl(
    .clk(clk),
    .reset(reset),
    .digit_1(cnt_1),
    .digit_10(cnt_10),
    .digit_100(cnt_100),
    .digit_1000(cnt_1000),
    .fnd_digit(fnd_digit),
    .fnd_data(fnd_data)
);



    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            cnt_1 <= 0;
            cnt_10 <= 0;
            cnt_100 <= 0;
            cnt_1000<=0;

        end else if (spi_done) begin
            if (rx_data[0]) cnt_1 <= (cnt_1 == 9) ? 0 : cnt_1+1;
            if (rx_data[1]) cnt_10 <= (cnt_10 == 9) ? 0 : cnt_10+1;
            if (rx_data[2]) cnt_100 <= (cnt_100 == 9) ? 0 : cnt_100+1;
            if (rx_data[3]) cnt_1000 <= (cnt_1000 == 9) ? 0 : cnt_1000+1;
        end
    end

    
endmodule
