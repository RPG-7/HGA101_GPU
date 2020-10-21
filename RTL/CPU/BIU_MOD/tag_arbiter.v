
module tag_arbiter
#(
    parameter ENTRY_NUM=8,
    SEL_WIDTH = ((ENTRY_NUM > 1) ? $clog2(ENTRY_NUM) : 1),
    TAG_MSB=32,
    TAG_LSB=11//1K per page
)(
//entry0
input clk,
input rst,
input entry_read,   //Core interface
input entry_write,
input [31:0]access_addr,	

input valid_clear, //flush

input [31:0]refill_pa,//BIU interface
input line_refill,
output line_miss,//refill req
output [SEL_WIDTH-1:0]entry_replace_sel, //for BIU

output [SEL_WIDTH-1:0]entry_select_addr//addr for access 
);
integer i,j;
genvar k;
reg [7:0]access_cnt[ENTRY_NUM-1:0];//
reg [(TAG_MSB-TAG_LSB):0]tag_addr[ENTRY_NUM-1:0];
reg [ENTRY_NUM-1:0]access_zero;
reg [ENTRY_NUM-1:0]line_valid;
reg [ENTRY_NUM-1:0]line_dirty;


reg [ENTRY_NUM-1:0]entry_hit;
reg [ENTRY_NUM-1:0]replaceable_indicator;


assign line_miss	=	(entry_read | entry_write) & (entry_hit==0);


always @(*)
    for ( i=0;i<ENTRY_NUM;i=i+1 ) 
    begin
        entry_hit[i]=(access_addr[TAG_MSB-1:TAG_LSB-1]==tag_addr[i])&line_valid[i];
        replaceable_indicator[i] = access_cnt[i]==0;
        
        //entry_replace_sel=(replaceable_indicator[i]==1)?i:entry_replace_sel;
    end
reg [SEL_WIDTH-1:0]entry_replace_encode[ENTRY_NUM-1:0];
reg [SEL_WIDTH-1:0]entry_select_encode[ENTRY_NUM-1:0];
assign entry_replace_sel=entry_replace_encode[ENTRY_NUM-1];
assign entry_select_sel=entry_select_encode[ENTRY_NUM-1];
always @(*)//替换选择优先编码器
begin
    entry_replace_encode[0]=0;
    entry_select_encode[0]=0;
    for ( i=1;i<ENTRY_NUM;i=i+1 ) 
    begin
        entry_replace_encode[i]=sel_entry_cell(entry_replace_encode[i-1],i,replaceable_indicator[i]);
        entry_select_encode[i]=sel_entry_cell(entry_select_encode[i-1],i,entry_hit[i]);
    end
end
    
always@(posedge clk)//Tag management
begin
    for(i=0;i<ENTRY_NUM;i=i+1)
    begin
        if(rst|valid_clear)
        begin
            line_valid[i]	<=	0;
        end
        else if(entry_replace_sel==i&line_refill)
        begin
            tag_addr[i]	<=	refill_pa[TAG_MSB-1:TAG_LSB-1];
            line_valid[i]	<=	1'b1;
        end
//        else if(entry_write&entry_hit[i]) //WIP:脏位和write back缓存
//        begin
            
//        end
    end
end

always@(posedge clk)
begin
    for(i=0;i<ENTRY_NUM;i=i+1)
    begin
        if(rst)
        begin
            access_cnt[i]	<=	0;
        end
        else if(access_cnt[i] == 8'b11111111)
        begin
            access_cnt[i]	<=	access_cnt[i];
        end
        else if(entry_hit[i]&(entry_read|entry_write))
        begin
            if((~replaceable_indicator)!=0)
                access_cnt[i]	<=	access_cnt[i] + 8'h1;
            else
                for (j=0;j<ENTRY_NUM;j=j+1) 
                begin
                    if(j!=i)
                        access_cnt[j]	<=	access_cnt[j] - 8'h1;
                end
        end
    end
end


function [SEL_WIDTH-1:0]sel_entry_cell;
    input [SEL_WIDTH-1:0]prev_entry_num;
    input [SEL_WIDTH-1:0]cur_entry_num;
    input cur_entry_bit;
    begin
   		sel_entry_cell=(cur_entry_bit)?cur_entry_num:prev_entry_num;
   	end
endfunction

endmodule