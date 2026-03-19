// `timescale 1ns / 1ps



// module data_mem(
//    input clk,
//    input rst,
//    input dwe,
//    input [2:0] i_funct3,
//    input [31:0] daddr,
//    input [31:0] dwdata,
//    output [31:0] drdata
//    );
// //byte addressing
//    // logic [7:0] dmem[0:31];


//    // always_ff @(posedge clk) begin
       
//    //         if (dwe) begin
//    //             dmem[daddr+0] <= dwdata[7:0];
//    //             dmem[daddr+1] <= dwdata[15:8];
//    //             dmem[daddr+2] <= dwdata[23:16];
//    //             dmem[daddr+3] <= dwdata[31:24];
//    //         end
       
//    // end

//    // assign drdata = {dmem[daddr],dmem[daddr+1],dmem[daddr+2],dmem[daddr+3]};

//    logic [31:0] dmem[0:255];
//     //    always_ff @( posedge clk ) begin 
//     //        if (dwe) begin
//     //            if(i_funct3 == 3'b010)

//     //            dmem[daddr[31:2]] <= dwdata; //SW
//     //        end
           
//     //    end


//         always_ff @(posedge clk) begin 
//     if (dwe) begin
//         case (i_funct3)
//             3'b000: dmem[daddr[31:2]][7:0]  <= dwdata[7:0];  // SB
//             3'b001: dmem[daddr[31:2]][15:0] <= dwdata[15:0]; // SH
//             3'b010: dmem[daddr[31:2]]       <= dwdata;       // SW
//             default: dmem[daddr[31:2]]      <= dwdata;
//         endcase
//     end
// end

//        assign drdata = dmem[daddr[31:2]];


//      initial begin
//          for (int i = 0; i < 256; i++) begin
//          dmem[i] = 32'h0; // 주소마다 고유 값 대입
//          end
//      end


// endmodule


// `timescale 1ns / 1ps

// module data_mem(
//     input clk,
//     input rst,
//     input dwe,
//     input [2:0] i_funct3,
//     input [31:0] daddr,      // ALU에서 계산된 주소
//     input [31:0] dwdata,     // rs2 데이터
//     output logic [31:0] drdata
// );

//     logic [31:0] dmem[0:255]; // 1KB 워드 메모리

//     // --- [1] Store Logic (Word Aligned) ---
//     always_ff @(posedge clk) begin 
//         if (dwe) begin
//             // 바이트/하프워드 명령어(SB, SH)가 들어와도 
//             // 무조건 해당 주소가 포함된 32비트 전체를 덮어씁니다.
//             dmem[daddr[31:2]] <= dwdata; 
//         end
//     end

//     // --- [2] Load Logic (Word Aligned + 가공) ---
//     logic [31:0] raw_data;
//     assign raw_data = dmem[daddr[31:2]]; // 주소 하위 2비트 무시하고 워드 단위 읽기

//     always_comb begin
//         case (i_funct3)
//             // 비록 워드 단위로 읽지만, 명령어(funct3)가 
//             // 바이트나 하프워드를 요구하면 읽어온 워드의 하위 부분만 잘라서 확장합니다.
//             3'b000: drdata = {{24{raw_data[7]}}, raw_data[7:0]};   // LB (워드의 [7:0]만 사용)
//             3'b001: drdata = {{16{raw_data[15]}}, raw_data[15:0]}; // LH (워드의 [15:0]만 사용)
//             3'b010: drdata = raw_data;                             // LW (32비트 전체)
//             3'b100: drdata = {24'b0, raw_data[7:0]};               // LBU
//             3'b101: drdata = {16'b0, raw_data[15:0]};              // LHU
//             default: drdata = raw_data;
//         endcase 
//     end

//     // 초기화
//     initial begin
//         for (int i = 0; i < 256; i++) dmem[i] = 32'h0;
//     end

// endmodule



// `timescale 1ns / 1ps

// module data_mem(
//     input clk,
//     input rst,
//     input dwe,
//     input [2:0] i_funct3,
//     input [31:0] daddr,      // ALU에서 계산된 주소
//     input [31:0] dwdata,     // rs2 데이터 (저장할 값)
//     output logic [31:0] drdata
// );

//     // 1KB (256 x 32-bit) 메모리 선언
//     logic [31:0] dmem[0:255]; 

//     // --- [1] Store Logic (always_ff) ---
//     // S-Type 명령어(SB, SH, SW)는 메모리 상태를 변화시키므로 동기식으로 처리합니다.
//     always_ff @(posedge clk) begin 
//         if (dwe) begin
//             case (i_funct3)
//                 3'b000: begin // SB (Store Byte)
//                     // 주소의 하위 2비트를 고려하지 않은 간략화 버전: 하위 8비트만 교체
//                     // 실제 정교한 설계에서는 daddr[1:0]에 따라 해당 위치의 8비트만 바꿔야 합니다.
//                     dmem[daddr[31:2]][7:0] <= dwdata[7:0]; 
//                 end
//                 3'b001: begin // SH (Store Halfword)
//                     // 하위 16비트만 교체
//                     dmem[daddr[31:2]][15:0] <= dwdata[15:0];
//                 end
//                 3'b010: begin // SW (Store Word)
//                     // 32비트 전체 교체
//                     dmem[daddr[31:2]] <= dwdata;
//                 end
//             endcase
//         end
//     end

//     // --- [2] Load Logic (always_comb) ---
//     // I-Type(Load) 명령어는 비동기식으로 읽어와서 즉시 가공합니다.
//     logic [31:0] raw_data;
//     assign raw_data = dmem[daddr[31:2]];

//     always_comb begin
//         case (i_funct3)
//             3'b000: drdata = {{24{raw_data[7]}}, raw_data[7:0]};   // LB (Signed)
//             3'b001: drdata = {{16{raw_data[15]}}, raw_data[15:0]}; // LH (Signed)
//             3'b010: drdata = raw_data;                             // LW
//             3'b100: drdata = {24'b0, raw_data[7:0]};               // LBU (Unsigned)
//             3'b101: drdata = {16'b0, raw_data[15:0]};              // LHU (Unsigned)
//             default: drdata = raw_data;
//         endcase 
//     end

//     // 초기화 (Reset 또는 Initial)
//     initial begin
//         for (int i = 0; i < 256; i++) dmem[i] = 32'h0;
//     end

// endmodule




`timescale 1ns / 1ps

module data_mem(
    input clk,
    input rst,
    input dwe,
    input [2:0] i_funct3,
    input [31:0] daddr,      // ALU에서 계산된 주소
    input [31:0] dwdata,     // rs2 데이터 (저장할 값)
    output logic [31:0] drdata
);

    // 1KB (256 x 32-bit) 메모리 선언
    logic [31:0] dmem[0:255]; 

    // =========================================================================
    // [1] Store Logic (Write) - daddr[1:0]에 맞춰 정확한 위치에 덮어쓰기
    // =========================================================================
    always_ff @(posedge clk) begin 
        if (dwe) begin
            case (i_funct3)
                3'b000: begin // SB (Store Byte)
                    case (daddr[1:0])
                        2'b00: dmem[daddr[31:2]][7:0]   <= dwdata[7:0];
                        2'b01: dmem[daddr[31:2]][15:8]  <= dwdata[7:0];
                        2'b10: dmem[daddr[31:2]][23:16] <= dwdata[7:0];
                        2'b11: dmem[daddr[31:2]][31:24] <= dwdata[7:0];
                    endcase
                end
                3'b001: begin // SH (Store Halfword)
                    case (daddr[1]) // 하프워드는 2바이트 단위이므로 끝에서 두번째 비트만 확인
                        1'b0: dmem[daddr[31:2]][15:0]  <= dwdata[15:0];
                        1'b1: dmem[daddr[31:2]][31:16] <= dwdata[15:0];
                    endcase
                end
                3'b010: begin // SW (Store Word)
                    dmem[daddr[31:2]] <= dwdata; // 32비트 전체 교체
                end
            endcase
        end
    end

    // =========================================================================
    // [2] Load Logic (Read) - daddr[1:0]에 맞춰 정확한 데이터 솎아내기
    // =========================================================================
    logic [31:0] raw_data;
    logic [7:0]  byte_data;
    logic [15:0] half_data;

    assign raw_data = dmem[daddr[31:2]]; // 32비트 뭉치 읽어오기

    // 1바이트 솎아내기 MUX
    always_comb begin
        case (daddr[1:0])
            2'b00: byte_data = raw_data[7:0];
            2'b01: byte_data = raw_data[15:8];
            2'b10: byte_data = raw_data[23:16];
            2'b11: byte_data = raw_data[31:24];
        endcase
    end

    // 2바이트(하프워드) 솎아내기 MUX
    always_comb begin
        case (daddr[1])
            1'b0: half_data = raw_data[15:0];
            1'b1: half_data = raw_data[31:16];
        endcase
    end

    // 최종 데이터 조립 (부호 확장 / 제로 확장)
    always_comb begin
        case (i_funct3)
            3'b000: drdata = {{24{byte_data[7]}}, byte_data};    // LB (Signed)
            3'b001: drdata = {{16{half_data[15]}}, half_data};   // LH (Signed)
            3'b010: drdata = raw_data;                           // LW
            3'b100: drdata = {24'b0, byte_data};                 // LBU (Unsigned)
            3'b101: drdata = {16'b0, half_data};                 // LHU (Unsigned)
            default: drdata = raw_data;
        endcase 
    end

    // 초기화
    initial begin
        for (int i = 0; i < 256; i++) dmem[i] = 32'h0;
    end

endmodule