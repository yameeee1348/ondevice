`timescale 1ns / 1ps

module DHT11(
      input clk, reset_p,
      inout dht11_data,             // 데이터 선, input는 레지스터를 지정해 줄 수 없다.
      output reg [7:0] humidity, temperature,
      output [15:0] led);           //보드에 이상이 있는지 확인하기 위함, 2024.7.3
      
      parameter S_IDLE = 6'b00_0001;
      parameter S_LOW_18MS = 6'b00_0010;
      parameter S_HIGH_20US = 6'b00_0100;
      parameter S_LOW_80US = 6'b00_1000;
      parameter S_HIGH_80US = 6'b01_0000;
      parameter S_READ_DATA = 6'b10_0000;
      
      parameter S_WAIT_PEDGE = 2'b01;
      parameter S_WAIT_NEDGE = 2'b10;
      
      reg [21:0] count_usec;
      wire clk_usec;
      reg count_usec_e;
      clock_div_100 us_clk(.clk(clk), .reset_p(reset_p), .clk_div_100(clk_usec));
      
      always @(negedge clk or posedge reset_p) begin
            if(reset_p) count_usec = 0;
            else if(clk_usec && count_usec_e)count_usec = count_usec + 1;
            else if(count_usec_e == 0)count_usec = 0;
      end
      
      wire dht_pedge, dht_nedge;
      edge_detector_n ed(
            .clk(clk), .reset_p(reset_p), .cp(dht11_data), 
            .p_edge(dht_pedge), .n_edge(dht_nedge));   
      
      reg [5:0] state, next_state;
      reg [1:0] read_state;
      
      always @(negedge clk or posedge reset_p) begin
            if(reset_p)state = S_IDLE;
            else state = next_state;
      end
      
      /////////////////추가한 부분, 2024.7.3
      assign led[5:0] = state;      //0번부터 5번까지 led가 켜질 것임
      
      reg [39:0] temp_data;
      reg [5:0] data_count;
      reg dht11_buffer;
      
      assign dht11_data = dht11_buffer;               // 임피던스는 끊는 것, 읽을 때는 dht11_buffer에서 임피던스를 출력을 하고 읽어야함
      
      always @(posedge clk or posedge reset_p) begin
            if(reset_p) begin
                  count_usec_e = 0;
                  next_state = S_IDLE;
                  read_state = S_WAIT_PEDGE;
                  data_count = 0;
                  dht11_buffer = 'bz;
            end
            else begin
                  case(state)
                        S_IDLE: begin     
                              if(count_usec < 22'd3_000_000)begin       //3초 기다림-->3,000,000us, 시뮬레이션에서 보기 위해 30으로 설정
                                    count_usec_e = 1;
                                    dht11_buffer = 'bz;
                              end
                              else begin
                                    next_state = S_LOW_18MS;
                                    count_usec_e = 0;
                              end
                        end
                        //
                        S_LOW_18MS: begin
                              if(count_usec < 22'd18_000)begin       // 18ms
                                    dht11_buffer = 0;
                                    count_usec_e = 1;
                              end
                              else begin
                                    next_state = S_HIGH_20US;
                                    count_usec_e = 0;
                                    dht11_buffer = 'bz;
                              end
                        end      
                        //
                        S_HIGH_20US: begin
                              count_usec_e = 1;
                              if(count_usec > 22'd100_000)begin         //100us동안 응답이 없으면 다시 IDLE로 돌아간다.
                                    next_state = S_IDLE;
                                    count_usec_e = 0;                               //값을 놓치거나 할 때 초기화 해서 다시 측정하도록 하기 위함
                              end
                              if(dht_nedge)begin
                                    next_state = S_LOW_80US;
                                    count_usec_e = 0;
                              end      
                        end
                        //
                        S_LOW_80US: begin
                              count_usec_e = 1;
                              if(count_usec > 22'd100_000)begin         //100us동안 응답이 없으면 다시 IDLE로 돌아간다.
                                    next_state = S_IDLE;
                                    count_usec_e = 0;                               //값을 놓치거나 할 때 초기화 해서 다시 측정하도록 하기 위함
                              end
                              if(dht_pedge) begin
                                    next_state = S_HIGH_80US;
                              end
                        end
                        //
                        S_HIGH_80US: begin
                              if(dht_nedge) begin
                                    next_state = S_READ_DATA;
                              end
                        end
                        //
                        S_READ_DATA: begin
                              case(read_state)
                                    S_WAIT_PEDGE: begin
                                          if(dht_pedge)read_state = S_WAIT_NEDGE;
                                          count_usec_e = 0;
                                    end
                                    //
                                    S_WAIT_NEDGE: begin
                                          if(dht_nedge)begin
                                                if(count_usec < 45)begin
                                                      temp_data = {temp_data[38:0], 1'b0};            //쉬프트
                                                end
                                                else begin
                                                      temp_data = {temp_data[38:0], 1'b1};            //쉬프트
                                                end
                                                data_count = data_count + 1;
                                                read_state = S_WAIT_PEDGE;
                                          end
                                          else count_usec_e = 1;
                                          if(count_usec > 22'd700_000)begin               //700us동안 응답이 없으면 다시 IDLE로 돌아간다.
                                                next_state = S_IDLE;
                                                count_usec_e = 0;
                                                data_count = 0;
                                                read_state = S_WAIT_PEDGE;
                                          end
                                    end
                              endcase
                              if(data_count >= 40)begin
                                    data_count = 0;
                                    next_state = S_IDLE;
                                    if((temp_data[39:32] + temp_data[31:24] + temp_data[23:16] + temp_data[15:8]) == temp_data[7:0])begin
                                          humidity = temp_data[39:32];              //31~24까지는 소수부, 의미 없어서 뺌
                                          temperature = temp_data[23:16];
                                    end
                              end
                        end
                        default: next_state = S_IDLE;
                  endcase
            end
      end
      
endmodule

module clock_div_100 (
    input  clk,
    input  reset_p,
    output reg clk_div_100   // 1클럭짜리 tick (1us마다 1)
);
    // 100MHz면 1us = 100 cycles
    reg [6:0] cnt; // 0~99

    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            cnt         <= 0;
            clk_div_100 <= 1'b0;
        end else begin
            if (cnt == 7'd99) begin
                cnt         <= 0;
                clk_div_100 <= 1'b1;  // tick
            end else begin
                cnt         <= cnt + 1;
                clk_div_100 <= 1'b0;
            end
        end
    end
endmodule


module edge_detector_n (
    input  clk,
    input  reset_p,
    input  cp,
    output reg p_edge,
    output reg n_edge
);
    reg sync1, sync2;
    reg prev;

    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            sync1  <= 1'b0;
            sync2  <= 1'b0;
            prev   <= 1'b0;
            p_edge <= 1'b0;
            n_edge <= 1'b0;
        end else begin
            // 2FF synchronizer
            sync1 <= cp;
            sync2 <= sync1;

            // edge pulses (1clk)
            p_edge <= (~prev) &  sync2;
            n_edge <= ( prev) & ~sync2;

            prev <= sync2;
        end
    end
endmodule