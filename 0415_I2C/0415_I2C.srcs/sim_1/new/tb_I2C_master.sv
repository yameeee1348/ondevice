`timescale 1ns / 1ps



module tb_I2C_master ();
    logic       clk;
    logic       reset;
    logic       cmd_master;
    logic       cmd_write;
    logic       cmd_read;
    logic       cmd_stop;
    logic       cmd_start;
    logic [7:0] tx_data;
    logic       ack_in;
    logic [7:0] rx_data;
    logic       done;
    logic       ack_out;
    logic       busy;
    logic       scl;
    wire       sda;

    //assign sda = 1'b1;
    pullup(sda);

    localparam SLA = 8'h12;

    I2C_Master dut (.*,
    .scl(scl),
    .sda(sda));

    always #5 clk = ~clk;

    task  i2c_start();
        cmd_start = 1'b1;
        cmd_write = 1'b0;
        cmd_read = 1'b0;
        cmd_stop = 1'b0;
        @(posedge clk);
        wait(done);
        @(posedge clk);
    endtask //

      task  i2c_write(byte addr);
         tx_data = addr;
        cmd_start = 1'b0;
        cmd_write = 1'b1;
        cmd_read = 1'b0;
        cmd_stop = 1'b0;
        @(posedge clk);
        wait(done);
        @(posedge clk);
    endtask //

     task i2c_addr(byte data);
         tx_data = data;
        cmd_start = 1'b0;
        cmd_write = 1'b1;
        cmd_read = 1'b0;
        cmd_stop = 1'b0;
        @(posedge clk);
        wait(done);
        @(posedge clk);
    endtask //

      task  i2c_read();
        cmd_start = 1'b0;
        cmd_write = 1'b0;
        cmd_read = 1'b1;
        cmd_stop = 1'b0;
        @(posedge clk);
        wait(done);
        @(posedge clk);
    endtask //

      task  i2c_stop();
        cmd_start = 1'b0;
        cmd_write = 1'b0;
        cmd_read = 1'b0;
        cmd_stop = 1'b1;
        @(posedge clk);
        wait(done);
        @(posedge clk);
    endtask //



    initial begin
        clk = 0;
        reset =1;
        repeat(3) @(posedge clk);
        reset = 0;
        @(posedge clk);

        i2c_start();
        i2c_addr(SLA << 1 + 1'b0);
        i2c_write(8'h55);
        i2c_write(8'haa);
        i2c_write(8'h01);
        i2c_write(8'h02);
        i2c_write(8'h03);
        i2c_write(8'h04);
        i2c_write(8'h05);
        i2c_write(8'hff);
        i2c_stop();


        //start
//        cmd_start = 1'b1;
//        cmd_write = 1'b0;
//        cmd_read = 1'b0;
//        cmd_stop = 1'b0;
//        @(posedge clk);
//        wait(done);
//        @(posedge clk);
//
//        //tx_data = address(8'h12) + rw
//        tx_data = (SLA << 1) + 1'b0;
//        cmd_start = 1'b0;
//        cmd_write = 1'b1;
//        cmd_read = 1'b0;
//        cmd_stop = 1'b0;
//        @(posedge clk);
//        wait(done);
//        @(posedge clk);
//
//        //tx_data = data
//        tx_data = 5'h55;
//        cmd_start = 1'b0;
//        cmd_write = 1'b1;
//        cmd_read = 1'b0;
//        cmd_stop = 1'b0;
//        @(posedge clk);
//        wait(done);
//        @(posedge clk);
//
//        //stop
//        cmd_start = 1'b0;
//        cmd_write = 1'b0;
//        cmd_read = 1'b0;
//        cmd_stop = 1'b1;
//        @(posedge clk);
//        wait(done);
//        @(posedge clk);

        //IDLE
        #50;
        $finish;
    end
endmodule
