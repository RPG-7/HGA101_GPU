/*
Type: 00/01=Left Shift
10=Right Shift, 0 Filled
11=Right Shift,with symbol extent
*/
module bshifter16(
    input [15:0]datain,
    input [1:0]type,
    input [3:0]shiftnum,
    output [15:0]dataout
);
wire [15:0]shift0;
wire [15:0]shift1;
wire [15:0]shift2;
wire [15:0]shift3;
assign shift0=(
    (shiftnum[0])?
    (type[1]?{{1{datain[15]&type[0]}},datain[15:1]}:{datain[14:0],1'b0}):
    (datain));
assign shift1=(
    (shiftnum[1])?
    (type[1]?{{2{datain[15]&type[0]}},shift0[15:2]}:{shift0[13:0],2'b0}):
    (shift0)
    );
assign shift2=(
    (shiftnum[2])?
    (type[1]?{{4{datain[15]&type[0]}},shift1[15:4]}:{shift1[11:0],4'b0}):
    (shift1)
    );
assign shift3=(
    (shiftnum[3])?
    (type[1]?{{8{datain[15]&type[0]}},shift2[15:8]}:{shift2[7:0],8'b0}):
    (shift2)
    );
assign dataout=shift3;




endmodule 