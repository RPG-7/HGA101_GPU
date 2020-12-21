module normalize_shifter
#(
    parameter result_width=11,
    normalize_width=10,
    SEL_WIDTH = ((result_width > 1) ? $clog2(result_width) : 1)
)
(
    input [result_width-1:0]datai,
    output [SEL_WIDTH:0]left_shift_width,
    output [normalize_width-1:0]datao
);
reg [7:0]shiftcnt_encode[result_width:0];
wire [2**SEL_WIDTH:0]aligned;
integer i;
always @(*)//规格化优先编码器 选择级联结构，找到MSB侧最后一个1
begin
    shiftcnt_encode[0]=1;
    for ( i=1;i<=result_width;i=i+1) 
    begin
        shiftcnt_encode[i]=sel_entry_cell(shiftcnt_encode[i-1],i+1,datai[i-1]);
    end
end
assign left_shift_width=shiftcnt_encode[result_width];
defparam LEFT_ALIGNER.IN_WIDTH = result_width;
left_bshifter LEFT_ALIGNER
(
    .datain(datai),
    .shiftnum(left_shift_width),
    .dataout(aligned)
);
assign datao=aligned[result_width:(result_width-normalize_width)];
function [SEL_WIDTH-1:0]sel_entry_cell;
    input [SEL_WIDTH-1:0]prev_entry_num;
    input [SEL_WIDTH-1:0]cur_entry_num;
    input cur_entry_bit;
    begin
   		sel_entry_cell=(cur_entry_bit)?cur_entry_num:prev_entry_num;
   	end
endfunction

endmodule
