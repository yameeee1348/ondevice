`timescale 1ns / 1ps



module cpu0_hw (
    input clk,
    input rst,
    output [7:0] out

);

    logic
        isrcsel,
        sumsrcsel,
        iload,
        sumload,
        alusrcsel,
        outload,
        ilqt10;

    control_unit U_CONTROL_UNIT (.*);

    datapath U_DATAPATH (.*);

endmodule



module control_unit (
    input        clk,
    input        rst,
    input        ilqt10,
    output logic isrcsel,
    output logic sumsrcsel,
    output logic iload,
    output logic sumload,
    output logic alusrcsel,
    output logic outload
);

    typedef enum logic [2:0] {
        S0,
        S1,
        S2,
        S3,
        S4,
        S5

    } state_t;

    state_t c_state, n_state;

    always_ff @(posedge clk, posedge rst) begin

        if (rst) begin
            c_state <= S0;
        end else begin
            c_state <= n_state;
        end
    end


    always_comb begin
        n_state   = c_state;
        isrcsel   = 0;
        sumsrcsel = 0;
        iload     = 0;
        sumload   = 0;
        alusrcsel = 0;
        outload   = 0;


        case (c_state)
            S0: begin
                isrcsel   = 0;
                sumsrcsel = 0;
                iload     = 1;
                sumload   = 1;
                alusrcsel = 0;
                outload   = 0;
                n_state   = S1;



            end

            S1: begin
                isrcsel   = 0;
                sumsrcsel = 0;
                iload     = 0;
                sumload   = 0;
                alusrcsel = 0;
                outload   = 0;
                if (ilqt10) n_state = S2;
                else n_state = S5;
            end

            S2: begin
                isrcsel   = 0;
                sumsrcsel = 1;
                iload     = 0;
                sumload   = 1;
                alusrcsel = 0;
                outload   = 0;
                n_state   = S3;
            end

            S3: begin


                isrcsel   = 1;
                sumsrcsel = 0;
                iload     = 1;
                sumload   = 0;
                alusrcsel = 1;
                outload   = 1;
                n_state   = S4;
            end

            S4: begin
                isrcsel   = 0;
                sumsrcsel = 0;
                iload     = 0;
                sumload   = 0;
                alusrcsel = 0;
                outload   = 1;
                n_state   = S1;
            end

            S5: begin
                isrcsel   = 0;
                sumsrcsel = 0;
                iload     = 0;
                sumload   = 0;
                alusrcsel = 0;
                outload   = 0;
            end
        endcase

    end
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

module alu (
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] alu_out
);
    assign alu_out = a + b;
endmodule

module mux_2x1 (
    input  [7:0] a,
    input  [7:0] b,
    input        sel,
    output [7:0] mux_out
);
    assign mux_out = (sel) ? b : a;
endmodule

module ilqt10 (
    input [7:0] in_data,
    output ilqt10
);
    assign ilqt10 = (in_data <= 10);
endmodule

module datapath (
    input clk,
    input rst,
    input isrcsel,
    input sumsrcsel,
    input iload,
    input sumload,
    input alusrcsel,
    input outload,
    output ilqt10,
    output [7:0] out
);

    logic [7:0] ireg_src_data, alu_out;
    logic [7:0] sumreg_src_data, alu_src_data;
    logic [7:0] ireg_out, sumreg_out;

    register U_OUTREG (
        .clk(clk),
        .rst(rst),
        .load(outload),
        .in_data(sumreg_out),
        .out_data(out)
    );

    ilqt10 U_ILQT (
        .in_data(ireg_out),
        .ilqt10  (ilqt10)
    );
    mux_2x1 U_MUX (
        .a(0),
        .b(alu_out),
        .sel(isrcsel),
        .mux_out(ireg_src_data)
    );

    register U_IREG (
        .clk(clk),
        .rst(rst),
        .load(iload),
        .in_data(ireg_src_data),
        .out_data(ireg_out)
    );

    mux_2x1 U_SUM_MUX (
        .a(0),
        .b(alu_out),
        .sel(sumsrcsel),
        .mux_out(sumreg_src_data)
    );

    register U_IREG_SUM (
        .clk(clk),
        .rst(rst),
        .load(sumload),
        .in_data(sumreg_src_data),
        .out_data(sumreg_out)
    );

    mux_2x1 U_ALU_SRC_MUX (
        .a(sumreg_out),
        .b(1),
        .sel(alusrcsel),
        .mux_out(alu_src_data)
    );

    alu U_ALU_A (
        .a(ireg_out),
        .b(alu_src_data),
        .alu_out(alu_out)
    );

endmodule






