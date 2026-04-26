`timescale 1ns / 1ps



module FND_T (
    input logic PCLK,
    input logic PRESET,
    input logic [31:0] PADDR,
    input logic [31:0] PWDATA,
    input logic PWRITE,
    input logic PENABLE,
    input logic PSEL,
    output logic [31:0] PRDATA,
    output logic PREADY,
    output logic [3:0] fnd_digit,
    output logic [7:0] fnd_data

);

    localparam [11:0] FND_CTRL_ADDR = 12'h000;
    localparam [11:0] FND_IDATA_ADDR = 12'h004;

    logic [31:0] FND_CTRL_REG;
    logic [15:0] FND_IDATA_REG;

    logic [3:0] w_fnd_digit;

    assign PREADY = (PENABLE & PSEL) ? 1'b1 : 1'b0;

    //assign PRDATA = (PADDR[11:0] == FND_IDATA_ADDR) ? {16'h0000,FND_IDATA_REG}:32'hxxxx_xxxx;

//    always_ff @(posedge PCLK, posedge PRESET) begin
//        if (PRESET) begin
//            FND_IDATA_REG <= 16'd0000;
//
//
//        end else begin
//            if (PREADY) begin
//                if (PWRITE) begin
//                    case (PADDR[11:0])
//
//                        FND_IDATA_ADDR: FND_IDATA_REG <= PWDATA[15:0];
//                    endcase
//                end
//            end
//        end
//    end

// [수정] APB Read (읽기) 멀티플렉서: 주소에 따라 맞는 레지스터 값을 CPU로 보냄
    always_comb begin
        if (PSEL && !PWRITE) begin
            case (PADDR[11:0])
                FND_CTRL_ADDR: PRDATA = FND_CTRL_REG;
                FND_IDATA_ADDR: PRDATA = {16'h0000, FND_IDATA_REG};
                default: PRDATA = 32'h0000_0000;
            endcase
        end else begin
            PRDATA = 32'h0000_0000;
        end
    end

    // [수정] APB Write (쓰기) 로직: 주소에 따라 각각의 레지스터에 데이터 저장
    always_ff @(posedge PCLK, posedge PRESET) begin
        if (PRESET) begin
            FND_CTRL_REG  <= 32'd0;
            FND_IDATA_REG <= 16'd0;
        end else begin
            if (PREADY && PWRITE) begin
                case (PADDR[11:0])
                    FND_CTRL_ADDR: FND_CTRL_REG  <= PWDATA;
                    FND_IDATA_ADDR: FND_IDATA_REG <= PWDATA[15:0];
                endcase
            end
        end
    end

    // [핵심] FND Enable 제어 로직
    // 컨트롤 레지스터의 0번 비트가 1이면 정상 출력, 0이면 4'b1111을 내보내서 FND 전체 소등
    assign fnd_digit = (FND_CTRL_REG[0]) ? w_fnd_digit : 4'b1111;





    FND_Core U_FND_Core (
        .clk(PCLK),
        .reset(PRESET),
        .sum(FND_IDATA_REG),  
        .fnd_digit(w_fnd_digit),//(fnd_digit),
        .fnd_data(fnd_data)
    );

endmodule


module FND_Core (
    input  logic clk,
    input  logic reset,
    input  logic [15:0] sum,
    output logic [3:0] fnd_digit,
    output logic [7:0] fnd_data
);

    logic [3:0] w_digit_1, w_digit_10, w_digit_100, w_digit_1000;
    logic [3:0] w_mux_4x1_out;
    logic [1:0] w_digit_sel;
    logic w_1khz;

    digit_spliter U_digit_spl (
        .in_data(sum),
        .digit_1(w_digit_1),
        .digit_10(w_digit_10),
        .digit_100(w_digit_100),
        .digit_1000(w_digit_1000)
    );

    clk_div U_clk_div (
        .clk(clk), 
        .reset(reset), 
        .o_1khz(w_1khz)
    );

    counter_4 U_counter_4 
    (.clk(clk), 
    .reset(reset), 
    .en_1khz(w_1khz), 
    .digit_sel(w_digit_sel)
    );

    decoder_2to4 U_decoder_2x4(
    .digit_sel(w_digit_sel), 
    .fnd_digit(fnd_digit)
     );

    mux_4x1 U_mux_4 (
        .sel(w_digit_sel), 
        .digit_1(w_digit_1), 
        .digit_10(w_digit_10), 
        .digit_100(w_digit_100),
        .digit_1000(w_digit_1000), 
        .mux_out(w_mux_4x1_out)
    );
    bcd U_BCD (
    .bcd_in(w_mux_4x1_out), 
    .fnd_data(fnd_data)
    );

endmodule


module clk_div (
    input logic clk,
    input logic reset,
    output logic o_1khz
);
    logic [$clog2(100_000):0] counter_r;
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            counter_r <= 0;
            o_1khz <= 1'b0;
        end else if (counter_r == 99_999) begin
            counter_r <= 0;
            o_1khz <= 1'b1; 
        end else begin
            counter_r <= counter_r + 1;
            o_1khz <= 1'b0;
        end
    end
endmodule

module counter_4 (
    input  logic clk,
    input  logic reset,
    input  logic en_1khz, // 
    output logic [1:0] digit_sel
);
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            digit_sel <= 2'b00;
        end else if (en_1khz) begin
            digit_sel <= digit_sel + 1;
        end
    end
endmodule

module decoder_2to4 (
    input  logic [1:0] digit_sel,
    output logic [3:0] fnd_digit
);
    always_comb begin // 
        case (digit_sel)
            2'b00: fnd_digit = 4'b1110;
            2'b01: fnd_digit = 4'b1101;
            2'b10: fnd_digit = 4'b1011;
            2'b11: fnd_digit = 4'b0111;
            default: fnd_digit = 4'b1111; 
        endcase
    end
endmodule

module mux_4x1 (
    input  logic [1:0] sel,
    input  logic [3:0] digit_1,
    input  logic [3:0] digit_10,
    input  logic [3:0] digit_100,
    input  logic [3:0] digit_1000,
    output logic [3:0] mux_out
);
    always_comb begin
        case (sel)
            2'b00: mux_out = digit_1;
            2'b01: mux_out = digit_10;
            2'b10: mux_out = digit_100;
            2'b11: mux_out = digit_1000;
            default: mux_out = 4'b1111;
        endcase
    end
endmodule

// module digit_spliter (
//     input  logic [15:0] in_data, 
//     output logic [3:0] digit_1,
//     output logic [3:0] digit_10,
//     output logic [3:0] digit_100,
//     output logic [3:0] digit_1000
// );

//     assign digit_1    = in_data[3:0];
//     assign digit_10   = in_data[7:4];
//     assign digit_100  = in_data[11:8];
//     assign digit_1000 = in_data[15:12];
// endmodule
//WNS -013ns 였을 때
module digit_spliter (
   input  logic [15:0] in_data, 
   output logic [3:0] digit_1,
   output logic [3:0] digit_10,
   output logic [3:0] digit_100,
   output logic [3:0] digit_1000
);
   assign digit_1    = in_data % 10;
   assign digit_10   = (in_data / 10) % 10;
   assign digit_100  = (in_data / 100) % 10;
   assign digit_1000 = (in_data / 1000) % 10;
endmodule

module bcd (
    input  logic [3:0] bcd_in, 
    output logic [7:0] fnd_data
);
    always_comb begin // 
        case (bcd_in)
            4'd0: fnd_data = 8'hC0;
            4'd1: fnd_data = 8'hF9;
            4'd2: fnd_data = 8'hA4;
            4'd3: fnd_data = 8'hB0;
            4'd4: fnd_data = 8'h99;
            4'd5: fnd_data = 8'h92;
            4'd6: fnd_data = 8'h82;
            4'd7: fnd_data = 8'hF8;
            4'd8: fnd_data = 8'h80;
            4'd9: fnd_data = 8'h90;
            default: fnd_data = 8'hFF;
        endcase
    end
endmodule