/*
适用于PRV464PRO的IF（取指单元）

2020.11.19
Tags in singals:
i:input(IFi means IF input)
o:output(IFo means IF output)
BIU: Bus Interfence Unit, means the singals is connected to the BIU
DATA: DATA transfer to the next stage
MSC: Machine State Control
FC:Flow Control

*/

module ins_fetch(

input wire clk,
input wire rst,
input wire [3:0]priv,		//当前机器权限状态

//中断控制器信号
input wire int_req,			//中断请求信号，当准备处理中断时为1请求,中断请求信号在IF阶段被插入，只有当机器确保流水线排空之后才会处理中断
//pip控制器信号
//插空信号
input wire IFi_FC_hold,			//if输出保持信号
input wire IFi_FC_nop,				//if插空信号
//流水线刷新信号
input wire IFi_pip_flush,
input wire [63:0]IFi_new_pc,	//新PC输入
//对cache控制器信号
//BIU信号
output wire [63:0]IFo_BIU_addr,
output wire IFo_BIU_fetch,				//取指令信号
output wire [3:0]IFo_BIU_priv,			//取指令用的权限
input wire [63:0]IFi_BIU_ins_in,
input wire IFi_BIU_ins_acc_fault, 		//指令访问失败
input wire IFi_BIU_ins_page_fault,		//指令页面错误
input wire IFi_BIU_cache_ready,			//cache准备好信号

/*

*/

//对下一级（ID）信号
//指令输出
output wire [31:0]IFo_DATA_ins,
//指令对应的PC值输出
output reg [63:0]IFo_DATA_ins_pc,
//MSC Machine State Contral
//机器控制段信号
output reg IFo_MSC_ins_acc_fault,	//指令访问失败
output reg IFo_MSC_ins_addr_mis, 	//指令地址错误
output reg IFo_MSC_ins_page_fault,	//指令页面错误
output reg IFo_MSC_int_acc,			//中断接收信号
output reg IFo_MSC_valid,			//指令有效信号
//流控信号
output reg IFo_FC_system


);
parameter pc_rst = 64'h0000_0000_0000_0000;	//pc复位地址,如果需要改变复位地址修改这里即可

reg hold;		//Hold标志位，表示当前指令正在保持状态

reg [31:0]ins_hold;			//ins保持寄存器

reg [63:0]pc;
wire addr_mis;				//PC不对齐信号

wire [31:0]ins_shift;		//移位后的指令


assign addr_mis = (pc[1:0]!=2'b00);

assign ins_shift= IFo_DATA_ins_pc[2] ? IFi_BIU_ins_in[63:32] : IFi_BIU_ins_in[31:0];


//pc更新逻辑
//当pip_flush时，pc被更新到pc_new
//当nop_if,或者L1没有准备好的时候，pc被保持
always@(posedge clk)begin
	if(rst)begin
		pc <= pc_rst;
	end
	else if(IFi_pip_flush)begin
		pc <= IFi_new_pc;
	end
	else if(IFi_FC_nop | IFi_FC_hold)begin
		pc <= pc;
	end
	else begin
		pc <= (IFi_BIU_cache_ready) ? pc + 64'd4 : pc;
	end
end

always@(posedge clk)begin
	if(rst)begin
		IFo_DATA_ins_pc <= 64'b0;
	end
	else if(IFi_FC_hold)begin
		IFo_DATA_ins_pc <= IFo_DATA_ins_pc;
	end
	else begin
		IFo_DATA_ins_pc <= pc;
	end
end

always@(posedge clk)begin
	if(rst)begin
		ins_hold <= 32'b0;
	end
	else if(IFi_FC_hold & !hold)begin
		ins_hold <= ins_shift;
	end
end
/*
Hold 标志位更新逻辑
*/
always@(posedge clk)begin
	if(rst)begin
		hold <= 1'b0;
	end
	else if(hold==1'b0)begin
		hold <= IFi_FC_hold ? 1'b1 : hold;
	end
	else if(hold==1'b1)begin
		hold <= !IFi_FC_hold ? 1'b0 : hold;
	end
end

//指令错误值更新
always@(posedge clk)begin
	if(rst)begin
		IFo_MSC_ins_acc_fault <= 1'b0;
		IFo_MSC_ins_page_fault<= 1'b0;
		IFo_MSC_ins_addr_mis  <= 1'b0;
		IFo_MSC_int_acc		  <= 1'b0;
		IFo_FC_system		  <= 1'b0;
	end
	else if(IFi_FC_hold)begin
		IFo_MSC_ins_acc_fault <= IFo_MSC_ins_acc_fault;
		IFo_MSC_ins_page_fault<= IFo_MSC_ins_page_fault;
		IFo_MSC_ins_addr_mis  <= IFo_MSC_ins_addr_mis;
		IFo_MSC_int_acc       <= IFo_MSC_int_acc;
		IFo_FC_system		  <= IFo_FC_system;
	end
	else begin
		IFo_MSC_ins_acc_fault <= IFi_BIU_ins_acc_fault;
		IFo_MSC_ins_page_fault<= IFi_BIU_ins_page_fault;
		IFo_MSC_ins_addr_mis  <= addr_mis;
		IFo_MSC_int_acc       <= int_req;
		IFo_FC_system		  <= int_req | IFi_BIU_ins_acc_fault | IFi_BIU_ins_page_fault | addr_mis;
	end
end

//指令有效位更新
//当插入等待状态时，valid保持
always@(posedge clk)begin
	if(rst)begin
		IFo_MSC_valid <= 1'b0;
	end
	else if(IFi_BIU_cache_ready & !IFi_FC_nop)begin
		IFo_MSC_valid <= 1'b1;
	end
	else if(IFi_FC_hold)begin
		IFo_MSC_valid <= IFo_MSC_valid;
	end
	else begin
		IFo_MSC_valid <= 1'b0;
	end
end

assign IFo_DATA_ins 	= hold?ins_hold:ins_shift;
assign IFo_BIU_priv			= priv;
assign IFo_BIU_addr			= pc;
assign IFo_BIU_fetch		= !IFi_FC_nop & !IFi_FC_hold;


endmodule
