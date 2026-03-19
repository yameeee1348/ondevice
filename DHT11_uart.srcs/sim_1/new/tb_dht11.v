`timescale 1ns / 1ps



module tb_dht11();

    reg clk, rst, start;
    reg dht11_sensor_io, sensor_io_sel;
    reg [39:0] dht11_sensor_data;
    wire dhtio;
    integer i;

    assign dhtio = (sensor_io_sel) ? 1'bz : dht11_sensor_io;

DHT11_controller dut (
    .clk(clk),
    .rst(rst),
    .start(start),
    .huminity(),
    .temperature(),
    .DHT11_done(),
    .DHT11_valid(),
    .debug(),
    .dhtio(dhtio)
);
    always #5 clk = ~clk;

    initial begin
        #0;
        clk = 0;
        rst = 1;
        start = 0;
        dht11_sensor_io = 1'b0;
        sensor_io_sel = 1'b1;
        i = 0;
                            //huminity integral, decimal, temperature integral, decimal, checksum
        dht11_sensor_data = {8'h32,8'h00,8'h19,8'h00,8'h4b};

        // reset
        #20;
        rst = 0;
        #20;
        start = 1;
        #10;
        start = 0;

        //19msec + 30usec
        //start signal + wait
        #(1900*10*1000 + 30_000);

        //to output to sensor to fpga
        sensor_io_sel = 0;

        //sync_L, sync_H
        dht11_sensor_io = 1'b0;
        #(80_000);
        dht11_sensor_io = 1'b1;
        #(80_000);

        //40bit data pattern
        for (i = 39 ; i >=0; i = i-1)begin
            //data sync_L
        dht11_sensor_io = 1'b0;
        #(50_000);
        //data_value_H
        if (dht11_sensor_data[i] == 0) begin
            dht11_sensor_io = 1'b1;
            #(28_000);

        end else begin
            dht11_sensor_io = 1'b1;
            #(70_000);
        end
        end

        dht11_sensor_io = 0;
        #(50_000);
        //to output , fpga to sensor
        sensor_io_sel = 1;
        #(100_000);


        #1000;
        $stop;

    end

endmodule
