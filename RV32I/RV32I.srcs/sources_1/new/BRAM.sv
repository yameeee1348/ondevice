`timescale 1ns / 1ps




module BRAM (
    //Soc internal sig
    input logic PCLK,
    // input       PRESET,

    //APB IF SIG
    input        PENABLE,
    input        PWRITE,
    input [31:0] PADDR,
    input [31:0] PWDATA,
    input        PSEL,     //RAM
    output logic [31:0] PRDATA,  //RAM
    output logic PREADY  //RAM



);
    logic [31:0] bmem[0:1023];

    assign PREADY = (PENABLE & PSEL) ? 1'b1 : 1'b0;

    always_ff @(posedge PCLK) begin
        if (PSEL & PENABLE & PWRITE)  bmem[PADDR[27:2]] <= PWDATA;  // SW
        end


    assign PRDATA = bmem[PADDR[27:2]];


endmodule


//`timescale 1ns / 1ps
//
//module BRAM (
//    // SoC internal sig
//    input  logic PCLK,
//    // input       PRESET, // 메모리는 보통 리셋을 하지 않습니다 (초기화 파일 사용)
//
//    // APB IF SIG
//    input  logic        PENABLE,
//    input  logic        PWRITE,
//    input  logic [31:0] PADDR,
//    input  logic [31:0] PWDATA,
//    input  logic        PSEL,      // RAM Select
//    output logic [31:0] PRDATA,    // RAM Data Out
//    output logic        PREADY     // RAM Ready
//);
//
//    // 💡 1024개(4KB)의 32비트 메모리 공간 선언 (0 ~ 1023)
//    logic [31:0] bmem[0:1023];
//
//    // BRAM은 항상 준비되어 있으므로 Ready는 바로 1을 줍니다.
//    assign PREADY = 1'b1;
//
//    always_ff @(posedge PCLK) begin
//        // 1. 쓰기 동작 (Synchronous Write)
//        if (PSEL && PENABLE && PWRITE) begin
//            bmem[PADDR[27:2]] <= PWDATA;
//        end
//        
//        // 2. 💡 읽기 동작 (Synchronous Read) - 진짜 BRAM으로 합성되기 위한 필수 조건!
//        // PSEL이 들어왔을 때 클럭에 맞춰 데이터를 읽어옵니다.
//        // APB 버스는 SETUP -> ACCESS 2클럭이 걸리므로 동기식으로 읽어도 타이밍이 완벽히 맞습니다.
//        if (PSEL && !PWRITE) begin
//            PRDATA <= bmem[PADDR[27:2]];
//        end
//    end
//
//endmodule