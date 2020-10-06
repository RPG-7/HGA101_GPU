/*****************module information*******************
this is the simple VGA-RAM interface
for 800*600 SVGA 60fps
It needs 1875KB Framebuffer in RAM 
PCLK=40M 

************************************/

module vga_intf
(
    //VGA INTERFACE
    output [7:0]VGAR,
    output [7:0]VGAG,
    output [7:0]VGAB,
    output PCLK,
    output HSYNC,
    output VSYNC,
    output DE,
    //SYS Bus Interface
    input sys_pclk,
    input [31:0]colbuf_data,
    output [9:0]colbuf_addr,
    output buffill_int,
    output frame_int,
    input rst_n
);

`define HOR_PXL      800
`define VER_PXL      600
`define TOL_PXL      (`HOR_PXL * `VER_PXL)
`define HSYNC_POL    1 //positive
`define VSYNC_POL    1 //positive
`define HBACK_POCH   64
`define HFRNT_POCH   56
`define HSYNC_TIME   120
`define VBACK_POCH   23
`define VFRNT_POCH   37
`define VSYNC_TIME   6

`define HTOL_TIME    (`HBACK_POCH + `HFRNT_POCH + `HSYNC_TIME + `HOR_PXL)
`define VTOL_TIME    (`VBACK_POCH + `VFRNT_POCH + `VSYNC_TIME + `VER_PXL)

`define HPXL_BEIGN   (`HSYNC_TIME + `HBACK_POCH )
`define VPXL_BEGIN   (`VSYNC_TIME + `VBACK_POCH)
reg [13:0]x;
reg [12:0]y;
assign frame_int=VSYNC;
assign buffill_int = HSYNC;
always@(posedge sys_pclk or negedge rst_n) //timing counter
begin
    if(!rst_n)
    begin
        x<=0;
        y<=0;
    end
    else 
    begin
        if(x==HTOL_TIME)
        begin
            x<=0;
            if (y==VTOL_TIME) 
            begin
                y<=0
            end
            else y<=y+1;
        end
        else x <= x+1;
    end
end

always @(posedge sys_pclk or negedge rst_n) //timing generator
begin
    
end

endmodule


