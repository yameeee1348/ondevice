`timescale 1ns / 1ps



// module sram(

//     input clk,
//     input rst,
//     input we,
//     input [3:0] addr,
//     input [7:0] wdata,
//     output reg [7:0] rdata
//     );

//     reg [1:0] c_state, n_state;
//     reg  IDLE= 1'b0,WRITE= 1'b1;

//     reg [7:0] mem [0:15];
 
//     always_ff @(  posedge clk, posedge rst ) begin 
//         if (rst) begin
//         c_state <= IDLE;
//         end   else begin
//             c_state <= n_state;
//         end     

//     end

//     always @(*) begin
        
//         n_state = c_state;
//         rdata = mem[addr];

//         case (c_state)
//             IDLE:begin
//                 if (we) 
//                 n_state = WRITE;
//                 else n_state = IDLE;
//             end 
//             WRITE: begin
//                 if (we) n_state = WRITE;
//                 else n_state = IDLE;
//             end
//             default : n_state = IDLE;
//         endcase

        
//     end
//     always_ff @(posedge clk) begin
//         if (c_state == WRITE) begin
//             mem[addr] <= wdata;
//         end
//     end


// endmodule


module sram (
    input clk,
    // input rst,
    input logic we,
    input logic [3:0] addr,
    input logic [7:0] wdata,
    output logic [7:0] rdata
);

    logic [7:0] ram [0:15];
    always_ff @(posedge clk) begin
        if (we) begin
            
            ram[addr] <= wdata;
        end
    end    

    assign rdata = ram[addr];
endmodule