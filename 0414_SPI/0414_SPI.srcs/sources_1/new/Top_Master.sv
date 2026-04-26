`timescale 1ns / 1ps



module Top_Master(
    input logic clk,
    input logic reset,
    input logic [3:0] btn,

    output logic [7:0] led,
    output logic sclk,
    output logic mosi,
    output logic cs_n,
    input logic miso

    );


    logic [3:0] btn_pulse;

    logic spi_start;
    logic [7:0] spi_tx_data;
    logic  spi_busy;

    logic [7:0] master_rx_data;
    logic       spi_done;

    genvar i;

SPI_master u_spi_master (
        .clk(clk),
        .reset(reset),
        .cpol(1'b0),         // Mode 0
        .cpha(1'b0),         // Mode 0
        .clk_div(8'd49),      // 클럭 분주비 (보드 클럭에 맞게 조절)
        .tx_data(spi_tx_data),
        .start(spi_start),
        .miso(miso),
        .rx_data(master_rx_data), 
        .done(spi_done),
        .busy(spi_busy),
        .sclk(sclk),
        .mosi(mosi),
        .cs_n(cs_n)
    );

    generate
        for (i = 0 ; i < 4 ; i++) begin : debounce_gen
           
            btn_debounce #(.CLK_DIV(1_000)) u_db (
                .clk(clk), 
                .reset(reset), 
                .i_btn(btn[i]), 
                .o_btn(btn_pulse[i]) 
            );
        end
    endgenerate

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            spi_start <= 0;
            spi_tx_data <= 0;

        end else begin
            spi_start <= 0;

            if ((|btn_pulse) && !spi_busy) begin
                spi_start <= 1'b1;
                spi_tx_data <= {4'b0000,btn_pulse};
            end
        end
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            led <=8'b0;
        end else if (spi_done) begin
            led <= master_rx_data;
        end
    end
    
endmodule
