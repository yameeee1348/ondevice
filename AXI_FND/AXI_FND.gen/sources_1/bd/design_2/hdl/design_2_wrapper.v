//Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2020.2 (win64) Build 3064766 Wed Nov 18 09:12:45 MST 2020
//Date        : Wed Apr 22 21:19:36 2026
//Host        : DESKTOP-7CFQ9ND running 64-bit major release  (build 9200)
//Command     : generate_target design_2_wrapper.bd
//Design      : design_2_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_2_wrapper
   (btnL,
    btnR,
    fnd_seg_0,
    fnd_sel_0,
    reset,
    sys_clock,
    usb_uart_rxd,
    usb_uart_txd);
  input btnL;
  input btnR;
  output [7:0]fnd_seg_0;
  output [3:0]fnd_sel_0;
  input reset;
  input sys_clock;
  input usb_uart_rxd;
  output usb_uart_txd;

  wire btnL;
  wire btnR;
  wire [7:0]fnd_seg_0;
  wire [3:0]fnd_sel_0;
  wire reset;
  wire sys_clock;
  wire usb_uart_rxd;
  wire usb_uart_txd;

  design_2 design_2_i
       (.btnL(btnL),
        .btnR(btnR),
        .fnd_seg_0(fnd_seg_0),
        .fnd_sel_0(fnd_sel_0),
        .reset(reset),
        .sys_clock(sys_clock),
        .usb_uart_rxd(usb_uart_rxd),
        .usb_uart_txd(usb_uart_txd));
endmodule
