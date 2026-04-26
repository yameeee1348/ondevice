`timescale 1ns / 1ps



module CPU0307 (
    input clk,
    input rst,
    output [7:0] out
);
    // 내부 연결 신호
    logic rfsrcsel, we, outload, lqt10;
    logic [1:0] raddr0, raddr1, waddr;

    // Control Unit 인스턴스 (앞서 만든 엑셀 기반 로직)
    control_unit U_CU (
        .clk(clk), .rst(rst), .lqt10(lqt10),
        .rfsrcsel(rfsrcsel), .raddr0(raddr0), .raddr1(raddr1), 
        .waddr(waddr), .we(we), .outload(outload)
    );

    // Datapath 인스턴스
    datapath U_DP (
        .clk(clk), .rst(rst), .rfsrcsel(rfsrcsel),
        .raddr0(raddr0), .raddr1(raddr1), .waddr(waddr),
        .we(we), .outload(outload), .lqt10(lqt10), .out(out)
    );

endmodule


module control_unit (
    input clk,
    input rst,
    input lqt10,
    output logic rfsrcsel,
    output 
);
    
endmodule