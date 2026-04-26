`timescale 1ns / 1ps



module SPI_slave(
    input logic clk,
    input logic reset,
    input logic cpol,
    input logic cpha,
    input logic [7:0] tx_data,
    input logic sclk,
    input logic mosi,
    input logic cs_n,
    output logic miso,

    output logic [7:0] rx_data,
    output logic done

    );

    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        START,
        DATA,
        STOP
    } spi_state_e;

    logic [2:0] sclk_sync;
    logic [1:0] cs_n_sync;
    logic [1:0] mosi_sync;

    logic sclk_rise, sclk_fall;
    logic cs_n_fall, cs_n_active;

    
    
    logic [2:0] bit_cnt;
    logic [7:0] tx_shift_reg, rx_shift_reg;
    
    logic sample_edge, drive_edge;

    always_ff @( posedge clk or posedge reset ) begin 
        if (reset) begin
            sclk_sync <= {3{cpol}};
            cs_n_sync <= 2'b11;
            mosi_sync <= 2'b11;

        end else begin
            sclk_sync <= {sclk_sync[1:0], sclk};
            cs_n_sync <= {cs_n_sync[0], cs_n};
            mosi_sync <= {mosi_sync[0], mosi};
        end
    end

    assign sclk_rise = (sclk_sync[2:1] == 2'b01);
    assign sclk_fall = (sclk_sync[2:1] == 2'b10);

    assign cs_n_fall = (cs_n_sync[2:1] == 2'b10);
    assign cs_n_active = ~cs_n_sync[1];

    always_comb begin 
        case ({cpol, cpha})
            2'b00: begin
               sample_edge = sclk_rise;
               drive_edge = sclk_fall; 
            end
            2'b01: begin
                sample_edge = sclk_fall;
               drive_edge = sclk_rise;                
            end
            2'b10: begin
                sample_edge = sclk_rise;
               drive_edge = sclk_fall;
                
            end
            2'b11: begin
                sample_edge = sclk_rise;
               drive_edge = sclk_fall;
                
            end 
            
        endcase
        
    end

    spi_state_e state;

    always_ff @( posedge clk or posedge reset ) begin 
        if (reset) begin
            state <= IDLE;
            rx_data <=0;
            done <=0;
            bit_cnt <=0;
            tx_shift_reg <= 0;
            rx_shift_reg <= 0;
            miso <= 1'b1;

        end else begin
            done <= 1'b0;

            if (cs_n_sync[1] == 1'b1) begin
                state <= IDLE;
                miso <= 1'b1;
            end else begin
                //CS_n이 LOW일 때
                case (state)
                    IDLE: begin
                        bit_cnt <= 0;
                        tx_shift_reg <= tx_data;

                        if (!cpha) begin
                            miso <= tx_data[7];
                            tx_shift_reg <= {tx_data[6:0], 1'b0};
                        end
                        state <= DATA;
                    end

                    DATA: begin
                        if (sample_edge) begin
                            rx_shift_reg <= {rx_shift_reg[6:0], mosi_sync[1]};

                            if (bit_cnt == 7) begin
                                state <= STOP;
                                done <= 1'b1;
                                rx_data <= {rx_shift_reg[6:0], mosi_sync[1]};
                            end else begin
                                bit_cnt <= bit_cnt +1;
                            end
                        end
                        if (drive_edge) begin
                            miso <= tx_shift_reg[7];
                            tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                        end    
                    end
                    STOP: begin
                        miso <= 1'b1;
                    end
                    default: begin
                        
                    state <= IDLE;
                    end
                endcase
            end
        end
    end


endmodule
