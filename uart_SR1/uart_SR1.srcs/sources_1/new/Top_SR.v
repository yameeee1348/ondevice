`timescale 1ns / 1ps



module Top_SR(

    );



    SR04 (

    .clk,
    .rst,
    .echo,
    .trigger,
    .distance


);


    fnd_controller (

    .clk,
    .reset,
    .sum,
    .fnd_digit,
    .fnd_data

);


    btn_debounce(
    .clk,
    .reset,
    .i_btn,
    .o_btn

    );


    control_unit(

    .clk,
    .reset,
    .i_mode,
    .i_run_stop,
    .i_clear,
    .o_mode,
    .o_run_stop,
    .o_clear

    );
endmodule
