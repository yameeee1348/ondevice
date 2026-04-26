`timescale 1ns / 1ps



 
module decoder_2x4 (
    input [1:0] x,
    input control,
    output reg [3:0] y
);

    always @(*) begin
        if(!control) begin
            y = 4'b1111;
        end else begin
            y = 4'b1111;
            case (x)
                2'b00: y = 4'b1110;
                2'b01: y = 4'b1101;
                2'b10: y = 4'b1011;
                2'b11: y = 4'b0111; 
                default: y = 4'b1111;
            endcase
        end
    end

endmodule



module counter_2bit (
    input clk, reset, tick,
    output reg [1:0] count
);
   always @(posedge clk, posedge reset) begin
        if(reset) begin
            count <= 0;
        end else begin
            if(tick) begin
                count <= count + 1;
            end
        end
   end 
endmodule





module clk_div_fnd ( 
    input clk, reset,
    output reg tick
);

    reg [$clog2(100_000) - 1 : 0] counter;

    always @(posedge clk, posedge reset) begin
       if(reset) begin
            counter <= 0;
            tick <= 1'b0;
       end else begin
            if(counter == 100_000 - 1) begin
                counter <= 0;
                tick <= 1'b1;
            end else begin
                counter <= counter +1;
                tick <= 1'b0;
            end
       end
    end
endmodule


module digit_splitter (
    input [31:0] digit,
    output [3:0] digit_1,
    output [3:0] digit_10,
    output [3:0] digit_100,
    output [3:0] digit_1000
);
   
    assign digit_1 = digit % 10;
    assign digit_10 = (digit / 10) % 10;
    assign digit_100 = (digit / 100) % 10; 
    assign digit_1000 = (digit / 1000) % 10;


endmodule


module mux_4x1 (
    input [1:0] sel,
    input [3:0] x0,
    input [3:0] x1,
    input [3:0] x2,
    input [3:0] x3,
    output reg [3:0] y
);
    
    always @(*) begin
        y = 4'b1111;
        case (sel)
            2'b00: y = x0;
            2'b01: y = x1;
            2'b10: y = x2;
            2'b11: y = x3;
            default: y = 4'b1111;
        endcase     
    end

endmodule


module BCDtoSEG_decoder (
    input      [3:0] bcd, input [1:0] sel,
    output reg [7:0] seg
);


    always @(bcd, sel) begin
                case (bcd)
                    4'h0: seg = 8'hc0;
                    4'h1: seg = 8'hf9;
                    4'h2: seg = 8'ha4;
                    4'h3: seg = 8'hb0;
                    4'h4: seg = 8'h99;
                    4'h5: seg = 8'h92;
                    4'h6: seg = 8'h82;
                    4'h7: seg = 8'hf8;
                    4'h8: seg = 8'h80;
                    4'h9: seg = 8'h90;
                    4'ha: seg = 8'h88;
                    4'hb: seg = 8'h83;
                    4'hc: seg = 8'hc6;
                    4'hd: seg = 8'ha1;
                    4'he: seg = 8'h86;
                    4'hf: seg = 8'h8e;
                    default: seg = 8'hff;
                endcase

    end
endmodule
