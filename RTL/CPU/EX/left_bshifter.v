/*
Type: 00/01=Left Shift
10=Right Shift, 0 Filled
11=Right Shift,with symbol extent
*/
module left_bshifter
#(
    parameter IN_WIDTH = 32,
    SHIFT_STAGE= ((IN_WIDTH > 1) ? $clog2(IN_WIDTH) : 1),
    SHIFT_WIDTH=2**(SHIFT_STAGE)
)
(
    input [IN_WIDTH-1:0]datain,
    input [SHIFT_STAGE-1:0]shiftnum,
    output [IN_WIDTH-1:0]dataout
);
reg [SHIFT_WIDTH-1:0]shift_stages[SHIFT_STAGE:0];
wire [SHIFT_WIDTH-1:0]shift_o;
wire sign;
integer i,j;
always @(*)
begin
    shift_stages[0]=datain;
    for(i=1;i<=SHIFT_STAGE;i=i+1)
    begin
        if(shiftnum[i-1])shift_stages[i]=shift_stages[i-1]<<(2**(i-1));
        else shift_stages[i]=shift_stages[i-1];
    end
end
assign shift_o=shift_stages[SHIFT_STAGE];
assign dataout=shift_o[IN_WIDTH-1:0];
endmodule 

