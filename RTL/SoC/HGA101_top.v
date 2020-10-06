module HGA101_top
(
    input clk,
    input rsti,
    //VGA/RGB LCD
    output [7:0]VGAR,
    output [7:0]VGAG,
    output [7:0]VGAB,
    output PCLK,
    output HSYNC,
    output VSYNC,
    output DE,
    inout SCL,
    inout SDA,
    output PWML,
    output PWMR,
    //DDR3 Databus
    output [13:0]DDR_A,
    output [2:0]DDR_BA,
    inout [15:0]DDR_DQ,
    output [1:0]DDR_DM,
    output DDR_CKE,
    output DDR_CKN,
    output DDR_CKP,
    
);


endmodule
