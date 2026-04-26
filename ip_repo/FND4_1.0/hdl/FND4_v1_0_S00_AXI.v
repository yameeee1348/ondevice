`timescale 1 ns / 1 ps

module FND4_v1_0_S00_AXI #(
    // Width of S_AXI data bus
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    // Width of S_AXI address bus
    parameter integer C_S_AXI_ADDR_WIDTH = 4
) (
    // 물리 버튼을 위한 외부 입력 포트
    input wire ext_btn_start,
    input wire ext_btn_stop,
    input wire ext_btn_reset,

    output reg [3:0] fnd_sel,
    output reg [7:0] fnd_seg,

    input  wire                                S_AXI_ACLK,
    input  wire                                S_AXI_ARESETN,
    input  wire [    C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    input  wire [                       2 : 0] S_AXI_AWPROT,
    input  wire                                S_AXI_AWVALID,
    output wire                                S_AXI_AWREADY,

    input  wire [    C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    input  wire                                S_AXI_WVALID,
    output wire                                S_AXI_WREADY,

    output wire [                       1 : 0] S_AXI_BRESP,
    output wire                                S_AXI_BVALID,
    input  wire                                S_AXI_BREADY,

    input  wire [    C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    input  wire [                       2 : 0] S_AXI_ARPROT,
    input  wire                                S_AXI_ARVALID,
    output wire                                S_AXI_ARREADY,

    output wire [    C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    output wire [                       1 : 0] S_AXI_RRESP,
    output wire                                S_AXI_RVALID,
    input  wire                                S_AXI_RREADY
);

    // AXI4LITE signals
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_awaddr;
    reg                            axi_awready;

    reg                            axi_wready;

    reg [                   1 : 0] axi_bresp;
    reg                            axi_bvalid;

    reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_araddr;
    reg                            axi_arready;

    reg [C_S_AXI_DATA_WIDTH-1 : 0] axi_rdata;
    reg [                   1 : 0] axi_rresp;
    reg                            axi_rvalid;

    localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH / 32) + 1;
    localparam integer OPT_MEM_ADDR_BITS = 1;

    reg     [C_S_AXI_DATA_WIDTH-1:0] slv_reg0;
    reg     [C_S_AXI_DATA_WIDTH-1:0] slv_reg1;
    reg     [C_S_AXI_DATA_WIDTH-1:0] slv_reg2;
    reg     [C_S_AXI_DATA_WIDTH-1:0] slv_reg3;
    
    wire                             slv_reg_rden;
    wire                             slv_reg_wren;
    reg     [C_S_AXI_DATA_WIDTH-1:0] reg_data_out;
    integer                          byte_index;
    reg                              aw_en;

    reg                              is_running;


    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = axi_bresp;
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = axi_rresp;
    assign S_AXI_RVALID  = axi_rvalid;

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_awready <= 1'b0;
            aw_en <= 1'b1;
        end else begin
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
                axi_awready <= 1'b1;
                aw_en <= 1'b0;
            end else if (S_AXI_BREADY && axi_bvalid) begin
                aw_en <= 1'b1;
                axi_awready <= 1'b0;
            end else begin
                axi_awready <= 1'b0;
            end
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_awaddr <= 0;
        end else begin
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
                axi_awaddr <= S_AXI_AWADDR;
            end
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_wready <= 1'b0;
        end else begin
            if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en) begin
                axi_wready <= 1'b1;
            end else begin
                axi_wready <= 1'b0;
            end
        end
    end

    assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            slv_reg0 <= 0;
            slv_reg1 <= 0;
            slv_reg2 <= 0;
            slv_reg3 <= 0;
        end else begin
            if (slv_reg_wren) begin
                case (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
                    2'h0:
                    for (
                        byte_index = 0;
                        byte_index <= (C_S_AXI_DATA_WIDTH / 8) - 1;
                        byte_index = byte_index + 1
                    )
                    if (S_AXI_WSTRB[byte_index] == 1) begin
                        slv_reg0[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    end
                    2'h1:
                    for (
                        byte_index = 0;
                        byte_index <= (C_S_AXI_DATA_WIDTH / 8) - 1;
                        byte_index = byte_index + 1
                    )
                    if (S_AXI_WSTRB[byte_index] == 1) begin
                        slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    end
                    2'h2:
                    for (
                        byte_index = 0;
                        byte_index <= (C_S_AXI_DATA_WIDTH / 8) - 1;
                        byte_index = byte_index + 1
                    )
                    if (S_AXI_WSTRB[byte_index] == 1) begin
                        slv_reg2[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    end
                    2'h3:
                    for (
                        byte_index = 0;
                        byte_index <= (C_S_AXI_DATA_WIDTH / 8) - 1;
                        byte_index = byte_index + 1
                    )
                    if (S_AXI_WSTRB[byte_index] == 1) begin
                        slv_reg3[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
                    end
                    default: begin
                        slv_reg0 <= slv_reg0;
                        slv_reg1 <= slv_reg1;
                        slv_reg2 <= slv_reg2;
                        slv_reg3 <= slv_reg3;
                    end
                endcase
            end
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_bvalid <= 0;
            axi_bresp  <= 2'b0;
        end else begin
            if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
            begin
                axi_bvalid <= 1'b1;
                axi_bresp  <= 2'b0;
            end else begin
                if (S_AXI_BREADY && axi_bvalid) begin
                    axi_bvalid <= 1'b0;
                end
            end
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_arready <= 1'b0;
            axi_araddr  <= 32'b0;
        end else begin
            if (~axi_arready && S_AXI_ARVALID) begin
                axi_arready <= 1'b1;
                axi_araddr  <= S_AXI_ARADDR;
            end else begin
                axi_arready <= 1'b0;
            end
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_rvalid <= 0;
            axi_rresp  <= 0;
        end else begin
            if (axi_arready && S_AXI_ARVALID && ~axi_rvalid) begin
                axi_rvalid <= 1'b1;
                axi_rresp  <= 2'b0;
            end else if (axi_rvalid && S_AXI_RREADY) begin
                axi_rvalid <= 1'b0;
            end
        end
    end

    assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;

    always @(*) begin
        case (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
            2'h0: reg_data_out = slv_reg0;
            2'h1:
            reg_data_out = {
                31'b0, is_running
            };  
            2'h2: reg_data_out = slv_reg2;
            2'h3: reg_data_out = slv_reg3;
            default: reg_data_out = 0;
        endcase
    end

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_rdata <= 0;
        end else begin
            if (slv_reg_rden) begin
                axi_rdata <= reg_data_out;
            end
        end
    end

    // ========================================================
    // Add user logic here (버튼 처리 및 FND 카운터 로직)
    // ========================================================

    // CPU 명령(slv_reg0)과 물리 버튼을 통합 (OR 연산)
    wire start_cmd = slv_reg0[0] | ext_btn_start;
    wire stop_cmd = slv_reg0[1] | ext_btn_stop;
    wire soft_rst = slv_reg0[2] | ext_btn_reset;

    // 1초(100MHz 기준) 및 1ms 타이머 생성
    reg [26:0] cnt_1sec;
    reg [16:0] cnt_1ms;
    wire tick_1sec = (cnt_1sec == 27'd299_999);
    wire tick_1ms = (cnt_1ms == 17'd99_999);

    // BCD 카운터 레지스터
    reg [3:0] bcd3, bcd2, bcd1, bcd0;

    // 제어 상태 및 초 단위 타이머
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN || soft_rst) begin
            is_running <= 1'b0;
            cnt_1sec   <= 27'd0;
        end else begin
            if (start_cmd) is_running <= 1'b1;
            else if (stop_cmd) is_running <= 1'b0;

            if (is_running) begin
                if (tick_1sec) cnt_1sec <= 27'd0;
                else cnt_1sec <= cnt_1sec + 1'b1;
            end
        end
    end

    // 카운팅 동작 (1초 단위)
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN || soft_rst) begin
            {bcd3, bcd2, bcd1, bcd0} <= 16'd0;
        end else if (is_running && tick_1sec) begin
            if (bcd0 == 4'd9) begin
                bcd0 <= 4'd0;
                if (bcd1 == 4'd9) begin
                    bcd1 <= 4'd0;
                    if (bcd2 == 4'd9) begin
                        bcd2 <= 4'd0;
                        if (bcd3 == 4'd9) bcd3 <= 4'd0;
                        else bcd3 <= bcd3 + 1'b1;
                    end else bcd2 <= bcd2 + 1'b1;
                end else bcd1 <= bcd1 + 1'b1;
            end else bcd0 <= bcd0 + 1'b1;
        end
    end

    // FND 1ms 다이내믹 스캔 타이머
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) cnt_1ms <= 17'd0;
        else if (tick_1ms) cnt_1ms <= 17'd0;
        else cnt_1ms <= cnt_1ms + 1'b1;
    end

    // 스캔 인덱스 변경
    reg [1:0] scan_idx;
    reg [3:0] current_bcd;

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) scan_idx <= 2'd0;
        else if (tick_1ms) scan_idx <= scan_idx + 1'b1;
    end

    // 자릿수 선택 (Active Low)
    always @(*) begin
        case (scan_idx)
            2'b00: begin
                fnd_sel = 4'b1110;
                current_bcd = bcd0;
            end
            2'b01: begin
                fnd_sel = 4'b1101;
                current_bcd = bcd1;
            end
            2'b10: begin
                fnd_sel = 4'b1011;
                current_bcd = bcd2;
            end
            2'b11: begin
                fnd_sel = 4'b0111;
                current_bcd = bcd3;
            end
            default: begin
                fnd_sel = 4'b1111;
                current_bcd = 4'd0;
            end
        endcase
    end

    // 세그먼트 데이터 디코더 (Active Low)
    always @(*) begin
        case (current_bcd)
            4'd0: fnd_seg = 8'b11000000;
            4'd1: fnd_seg = 8'b11111001;
            4'd2: fnd_seg = 8'b10100100;
            4'd3: fnd_seg = 8'b10110000;
            4'd4: fnd_seg = 8'b10011001;
            4'd5: fnd_seg = 8'b10010010;
            4'd6: fnd_seg = 8'b10000010;
            4'd7: fnd_seg = 8'b11111000;
            4'd8: fnd_seg = 8'b10000000;
            4'd9: fnd_seg = 8'b10010000;
            default: fnd_seg = 8'b11111111;
        endcase
    end

    // User logic ends

endmodule
