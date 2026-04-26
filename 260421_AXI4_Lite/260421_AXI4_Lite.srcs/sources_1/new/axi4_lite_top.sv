`timescale 1ns / 1ps

module axi4_lite_top (
    input  logic        ACLK,
    input  logic        ARESETn,

    // 외부 제어 인터페이스 (Master를 움직이기 위한 신호)
    input  logic        transfer,    // 트랜잭션 시작
    input  logic [31:0] addr,        // 읽기/쓰기 주소
    input  logic [31:0] wdata,       // 쓰기 데이터
    input  logic        write,       // 1: Write, 0: Read
    output logic [31:0] rdata,       // 읽기 데이터 결과
    output logic        ready        // 완료 신호
);

    // 내부 AXI4-Lite 버스 신호 (Master <-> Slave 연결용)
    // Write Address Channel
    logic [31:0] m_awaddr;
    logic        m_awvalid;
    logic        m_awready;

    // Write Data Channel
    logic [31:0] m_wdata;
    logic        m_wvalid;
    logic        m_wready;

    // Write Response Channel
    logic        m_bresp; // 사용자 코드에 따라 1비트 연결
    logic        m_bvalid;
    logic        m_bready;

    // Read Address Channel
    logic [31:0] m_araddr;
    logic        m_arvalid;
    logic        m_arready;

    // Read Data Channel
    logic [31:0] m_rdata;
    logic        m_rvalid;
    logic        m_rready;
    logic [1:0]  m_rresp;

    // ---------------------------------------------------------
    // 1. AXI4-Lite Master Instance
    // ---------------------------------------------------------
    axi4_lite_master u_master (
        .ACLK    (ACLK),
        .ARESETn (ARESETn),
        // AW
        .AWADDR  (m_awaddr),
        .AWVALID (m_awvalid),
        .AWREADY (m_awready),
        // W
        .WDATA   (m_wdata),
        .WVALID  (m_wvalid),
        .WREADY  (m_wready),
        // B
        .BRESP   (m_bresp),
        .BVALID  (m_bvalid),
        .BREADY  (m_bready),
        // AR
        .ARADDR  (m_araddr),
        .ARVALID (m_arvalid),
        .ARREADY (m_arready),
        // R
        .RDATA   (m_rdata),
        .RVALID  (m_rvalid),
        .RREADY  (m_rready),
        .RRESP   (m_rresp),
        // User Internal Signals
        .transfer(transfer),
        .ready   (ready),
        .addr    (addr),
        .wdata   (wdata),
        .write   (write),
        .rdata   (rdata)
    );

    // ---------------------------------------------------------
    // 2. AXI4-Lite Slave Instance
    // ---------------------------------------------------------
    axi4_lite_slave_hw u_slave (
        .ACLK    (ACLK),
        .ARESETn (ARESETn),
        // AW
        .AWADDR  (m_awaddr),
        .AWVALID (m_awvalid),
        .AWREADY (m_awready),
        // W
        .WDATA   (m_wdata),
        .WVALID  (m_wvalid),
        .WREADY  (m_wready),
        // B
        .BRESP   (m_bresp),
        .BVALID  (m_bvalid),
        .BREADY  (m_bready),
        // AR
        .ARADDR  (m_araddr),
        .ARVALID (m_arvalid),
        .ARREADY (m_arready),
        // R
        .RDATA   (m_rdata),
        .RVALID  (m_rvalid),
        .RREADY  (m_rready),
        .RRESP   (m_rresp)
    );

endmodule