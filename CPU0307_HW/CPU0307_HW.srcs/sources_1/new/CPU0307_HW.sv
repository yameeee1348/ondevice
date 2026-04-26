`timescale 1ns / 1ps



module CPU0307_HW (
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


module register_file (
    input clk,
    input rst,
    input we,
    input [1:0] raddr0, raddr1, waddr,
    input [7:0] wdata,
    output [7:0] rdata0, rdata1
);

    logic [7:0] rf [3:0];

    assign rdata0 = rf[raddr0];
    assign rdata1 = rf[raddr1];

    always_ff @( posedge clk, posedge rst ) begin
        if (rst) begin
            rf[0] <= 8'd0;
            rf[1] <= 8'd0;
            rf[2] <= 8'd0;
            rf[3] <= 8'd0;
        end else if (we) begin
            if (waddr != 0) rf[waddr] <= wdata;
        end

    end
    
endmodule

module control_unit (
    input clk,
    input rst,
    input lqt10,
    output logic rfsrcsel,
    output logic [1:0] raddr0, raddr1, waddr,
    output logic we,
    output logic outload
);

    typedef enum logic [2:0] {S0,S1,S2,S3,S4,S5,S6  } state_t;

    state_t c_state, n_state;

    always_ff @(posedge clk, posedge rst)
        if (rst) c_state <= S0;
        else     c_state <= n_state;

    always_comb begin
        n_state = c_state;
        rfsrcsel = 1;
        raddr0 = 0;
        raddr1 = 0;
        we = 0;
        outload = 0;
    

    case (c_state)
        S0: begin
            rfsrcsel = 0;
            waddr = 3;
            we = 1;
            n_state =S1;
        end 
        S1 : begin
            raddr0 = 0;
            raddr1 = 0;
            waddr = 1;
            we = 1;
            n_state = S2;
        end
        S2: begin
            raddr0 = 0;
            raddr1 = 0;
            waddr  = 2;
            we    = 1;
            n_state =S3;
        end
        S3: begin
            raddr0 = 1;
            if (lqt10) n_state = S4;
            else       n_state = S6; 
        end
        S4: begin
            raddr0 = 1;
            raddr1 = 2;
            waddr = 2;
            we = 1;
            n_state = S5;
        end
        S5: begin
            raddr0 = 1;
            raddr1 = 3;
             waddr = 1;
             we = 1;
             n_state = S3;
        end
        S6: begin
            raddr1 = 2;
            outload = 1;
            n_state = S6;
        end
        
    endcase
    end
endmodule



module datapath (
    input clk,
    input rst,
    input rfsrcsel,          // 0: 상수 1(R3 초기화용), 1: ALU 결과
    input [1:0] raddr0,      // 읽기 주소 0
    input [1:0] raddr1,      // 읽기 주소 1
    input [1:0] waddr,       // 쓰기 주소
    input we,                // Write Enable
    input outload,           // 출력 레지스터 로드 신호
    output lqt10,            // i < 10 비교 결과
    output [7:0] out         // 최종 결과물 (sum)
);

    logic [7:0] wdata, rdata0, rdata1, alu_out;
    logic [7:0] sum_val;

    // 1. Register File (R0~R3)
    // 엑셀 설계대로 R0=0, R1=i, R2=sum, R3=1 역할 수행
    register_file U_RF (
        .clk(clk), .rst(rst), .we(we),
        .raddr0(raddr0), .raddr1(raddr1), .waddr(waddr),
        .wdata(wdata),
        .rdata0(rdata0), .rdata1(rdata1)
    );

    // 2. Write Data Mux (rfsrcsel)
    // S0에서 R3에 1을 넣기 위해 0일 때 1을 선택, 그 외엔 ALU 결과 선택
    assign wdata = (rfsrcsel) ? alu_out : 8'd1;

    // 3. ALU (항상 덧셈 수행)
    assign alu_out = rdata0 + rdata1;

    // 4. Comparator (lqt10)
    // S3 상태에서 R1(i) 값을 raddr0로 읽어와서 10과 비교
    assign lqt10 = (rdata0 < 8'd11);

    // 5. Output Register
    // S6(Halt) 상태에서 R2(sum) 값을 밖으로 출력
    register U_OUT_REG (
        .clk(clk), .rst(rst), .load(outload),
        .in_data(rdata1), // S6에서 R2 주소를 raddr1으로 지정한다고 가정
        .out_data(out)
    );

endmodule

module register (
    input              clk,
    input              rst,
    input              load,
    input  logic [7:0] in_data,
    output logic [7:0] out_data

);


    

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            out_data <= 0;

        end else begin
            if (load) begin
                out_data <= in_data;
            end
        end
    end
endmodule