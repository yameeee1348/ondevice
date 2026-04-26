`timescale 1ns / 1ps

// ============================================================
// TB for dht11_ctrl (or DHT11_controller)
// - Emulates DHT11 sensor on single-wire bus (with pull-up)
// - Waits for DUT START low pulse (>=18ms) then responds
// - Sends 40-bit frame: RH_int, RH_dec, T_int, T_dec, checksum
// ============================================================
module tb_dht11;

    // -----------------------------
    // Clock / reset / start
    // -----------------------------
    reg clk;
    reg rst;
    reg start;

    // -----------------------------
    // Single-wire bus model
    // -----------------------------
    // Sensor drive enable (1=drive, 0=release)
    reg  sensor_drive_en;
    reg  sensor_drive_val;

    // DUT inout
    tri dhtio;          // resolved net
    pullup (dhtio);     // external pull-up like real module

    // Sensor drives LOW/HIGH only when enabled; else Z.
    assign dhtio = (sensor_drive_en) ? sensor_drive_val : 1'bz;

    // -----------------------------
    // DUT outputs (observe)
    // -----------------------------
    wire [15:0] humidity;
    wire [15:0] temperature;
    wire        DHT11_done;
    wire        DHT11_valid;
    wire [2:0]  debug;

    // -----------------------------
    // Instantiate DUT
    // -----------------------------
    // NOTE:
    // - If your module name is "dht11_ctrl", change instance accordingly.
    // - If your module name is "DHT11_controller", change it back.
    dht11_ctrl dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .humidity(humidity),
        .temperature(temperature),
        .DHT11_done(DHT11_done),
        .DHT11_valid(DHT11_valid),
        .debug(debug),
        .dhtio(dhtio)
    );

    // -----------------------------
    // 100MHz clock: 10ns period
    // -----------------------------
    always #5 clk = ~clk;

    // -----------------------------
    // Time helpers
    // -----------------------------
    localparam integer NS_PER_US = 1000;

    task delay_us(input integer us);
        begin
            #(us * NS_PER_US);
        end
    endtask

    // -----------------------------
    // Sensor tasks
    // -----------------------------
    // Wait for DUT to issue START: line held LOW for >= 18ms
    task sensor_wait_start_low;
        integer low_cnt_us;
        begin
            low_cnt_us = 0;

            // Ensure sensor is releasing bus before start
            sensor_drive_en  = 1'b0;
            sensor_drive_val = 1'b1;

            // Wait until bus goes low
            while (dhtio !== 1'b0) begin
                delay_us(1);
            end

            // Measure how long it's kept low (1us resolution)
            while (dhtio === 1'b0) begin
                delay_us(1);
                low_cnt_us = low_cnt_us + 1;
            end

            $display("[%0t] Sensor saw START low for %0d us", $time, low_cnt_us);
            if (low_cnt_us < 18000) begin
                $display("[%0t] WARNING: START low shorter than 18ms (%0d us)", $time, low_cnt_us);
            end
        end
    endtask

    // DHT11 response: 80us LOW then 80us HIGH
    task sensor_send_sync;
        begin
            // Drive LOW 80us
            sensor_drive_en  = 1'b1;
            sensor_drive_val = 1'b0;
            delay_us(80);

            // Drive HIGH 80us (optional; with pull-up you could release instead)
            sensor_drive_val = 1'b1;
            delay_us(80);

            // Then drive LOW to start first bit's 50us LOW (DHT begins bit stream with LOW)
            sensor_drive_val = 1'b0;
            // don't delay here; the next task will handle 50us LOW
        end
    endtask

    // Send one data bit:
    // 50us LOW, then HIGH for 26~28us (0) or ~70us (1)
    task sensor_send_bit(input b);
        begin
            // 50us LOW
            sensor_drive_en  = 1'b1;
            sensor_drive_val = 1'b0;
            delay_us(50);

            // HIGH pulse width encodes bit
            sensor_drive_val = 1'b1;
            if (b == 1'b0)
                delay_us(28);
            else
                delay_us(70);

            // After HIGH, go LOW to prepare next bit (or end)
            sensor_drive_val = 1'b0;
        end
    endtask

    // Send full 40-bit frame MSB-first (bit 39 down to 0)
    task sensor_send_frame(input [39:0] frame);
        integer k;
        begin
            for (k = 39; k >= 0; k = k - 1) begin
                sensor_send_bit(frame[k]);
            end

            // Final trailing LOW (often present)
            delay_us(50);

            // Release bus after sending
            sensor_drive_en  = 1'b0;
            sensor_drive_val = 1'b1;
        end
    endtask

    // Convenience: build correct checksum and send
    task sensor_send_measurement(
        input [7:0] rh_int,
        input [7:0] rh_dec,
        input [7:0] t_int,
        input [7:0] t_dec
    );
        reg [7:0] sum;
        reg [39:0] frame;
        begin
            sum   = (rh_int + rh_dec + t_int + t_dec) & 8'hFF;
            frame = {rh_int, rh_dec, t_int, t_dec, sum};

            $display("[%0t] Sensor frame = %h (RH=%0d.%0d, T=%0d.%0d, SUM=%02h)",
                     $time, frame, rh_int, rh_dec, t_int, t_dec, sum);

            sensor_send_frame(frame);
        end
    endtask

    // -----------------------------
    // TB main
    // -----------------------------
    initial begin
        // init
        clk = 1'b0;
        rst = 1'b1;
        start = 1'b0;

        sensor_drive_en  = 1'b0; // release
        sensor_drive_val = 1'b1;

        // Reset
        #100;
        rst = 1'b0;

        // Kick DUT
        #100;
        start = 1'b1;
        #20;
        start = 1'b0;

        // 1) Wait DUT start low pulse (>=18ms)
        sensor_wait_start_low;

        // 2) After DUT releases, DHT11 typically waits 20~40us before response.
        //    We'll wait 30us.
        delay_us(30);

        // 3) Send DHT11 sync response (80us low + 80us high)
        sensor_send_sync;

        // 4) Send 40-bit data (example: RH=0x32=50, T=0x19=25)
        //    DHT11 decimals usually 0
        sensor_send_measurement(8'h32, 8'h00, 8'h19, 8'h00);

        // 5) Observe DUT result
        // Wait for done pulse (up to a few ms)
        fork
            begin : wait_done
                integer tmo_us;
                tmo_us = 0;
                while (DHT11_done !== 1'b1 && tmo_us < 20000) begin
                    delay_us(1);
                    tmo_us = tmo_us + 1;
                end
                if (DHT11_done !== 1'b1) begin
                    $display("[%0t] ERROR: timeout waiting DHT11_done", $time);
                end else begin
                    $display("[%0t] DONE! valid=%0d hum=0x%04h temp=0x%04h",
                             $time, DHT11_valid, humidity, temperature);
                end
            end
        join

        // small extra time
        delay_us(200);
        $stop;
    end

endmodule
