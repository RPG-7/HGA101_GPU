`include "global_defines.vh"
/*
PRV464的执行单元，含算术运算（ALU）和内存访问（LSU）两个部分
LSU单元只进行数据移位
*/

module exu(
input clk,
input rst,

input [3:0]priv,		//当前机器权限
//csr输入
input mprv,			//更改权限
input [3:0]mod_priv,	//要被更改的权限
//=================上一级 ID=====================
//-------------流控信号---------------
output wire EXUo_FC_nop,
output wire EXUo_FC_hold,
output wire EXUo_FC_war,		//产生数据相关
//---数据相关性检查信号---
input [4:0]EXUi_FC_rs1index,
input [4:0]EXUi_FC_rs2index,
input EXUi_FC_warcheck,	//数据相关检查使能
//异常码TVAL
//当非法指时候，该码被更新为instruction，当指令页面错误，被更新为addr
input [63:0]EXUi_DATA_tval,
//当前指令pc
input [63:0]EXUi_DATA_pc,

//操作码 ALU,运算码
//rd数据选择
input EXUi_OP_ALU_ds1,				//ds1直通
input EXUi_OP_ALU_add,				//加
input EXUi_OP_ALU_sub,				//减
input EXUi_OP_ALU_and,				//逻辑&
input EXUi_OP_ALU_or,				//逻辑|
input EXUi_OP_ALU_xor,				//逻辑^
input EXUi_OP_ALU_slt,				//比较大小
input EXUi_OP_ALU_compare,			//比较大小，配合bge0_blt1\beq0_bne1控制线并产生分支信号
input EXUi_OP_ALU_amo_lrsc,		//lr/sc读写成功标志，LR/SC指令总是读写成功

//mem_csr_data数据选择
input EXUi_OP_csr_mem_ds1,
input EXUi_OP_csr_mem_ds2,
input EXUi_OP_csr_mem_add,
input EXUi_OP_csr_mem_and,
input EXUi_OP_csr_mem_or,
input EXUi_OP_csr_mem_xor,
input EXUi_OP_csr_mem_max,
input EXUi_OP_csr_mem_min,
//运算,跳转辅助控制信号
input EXUi_OP_ALU_blt,				
input EXUi_OP_ALU_bge,
input EXUi_OP_ALU_beq,				
input EXUi_OP_ALU_bne,
input EXUi_OP_ALU_jmp,				//无条件跳转，适用于JAL JALR指令
input EXUi_OP_ALU_unsign,			//无符号操作，同时控制mem单元信号的符号拓展
input EXUi_OP_ALU_clr,			//将csr操作的and转换为clr操作
input EXUi_OP_ds1_sel,			//ALU ds1选择，为0选择ds1，为1选择LSU读取的数据
//VPU功能组
input EXUi_VPU_ifsel,//Function integer/float select
input EXUi_VPU_addsel,
input EXUi_VPU_subsel,
input EXUi_VPU_mulsel,
input EXUi_VPU_itfsel, //integer to float
input EXUi_VPU_ftisel, //float to integer
input EXUi_VPU_laneop,
input EXUi_VPU_maxsel,
input EXUi_VPU_minsel,
input EXUi_VPU_andsel,		//逻辑&
input EXUi_VPU_orsel,		//逻辑|
input EXUi_VPU_xorsel,
input EXUi_VPU_srasel,
input EXUi_VPU_srlsel,
input EXUi_VPU_sllsel,
input EXUi_VPU_cgesel,//compare:great equal
input EXUi_VPU_cltsel,
input EXUi_VPU_ceqsel,
input EXUi_VPU_cnqsel,
input EXUi_VPU_enable,//进行VPU存取/指示data_rd&data_fd采用VPU回送信号
//位宽控制
input [3:0]EXUi_OP_size, 		//0001:1Byte 0010:2Byte 0100=4Byte 1000=8Byte
//多周期控制
//多周期控制信号线控制EX单元进行多周期操作
input EXUi_OP_MC_load,
input EXUi_OP_MC_store,
input EXUi_OP_MC_amo,
input EXUi_OP_MC_L1i_flush,		//命令 缓存刷新信号，此信号可以与内存进行同步
input EXUi_OP_MC_L1d_flush,		//命令 缓存复位信号，下次访问内存时重新刷新页表
input EXUi_OP_MC_L1d_force_sync,
input EXUi_OP_MC_L1d_sync_ok,			//检查sync完成
input EXUi_OP_ALU_shift_right,		
input EXUi_OP_ALU_shift_left,			

//写回控制，当valid=0时候，所有写回不有效
input EXUi_WB_CSRwrite,		//注*后缀ID表示是ID传输进来的信号
input EXUi_WB_GPRwrite,
input EXUi_WB_FREGwrite,
input EXUi_WB_VREGwrite,
input [11:0]EXUi_WB_CSRindex,
input [4:0]EXUi_WB_RDindex,
input [4:0]EXUi_WB_FDindex,
input [4:0]EXUi_WB_VDindex,

//数据源&地址源						   
input [63:0]EXUi_DATA_ds1,		//数据源1，imm/rs1/rs1/csr/pc /pc
input [63:0]EXUi_DATA_ds2,		//数据源2，00 /rs2/imm/imm/imm/04
input [`GPU_VDATA_WIDTH-1:0]EXUi_DATA_vs1,
input [`GPU_VDATA_WIDTH-1:0]EXUi_DATA_vs2,
input [`GPU_DDATA_WIDTH-1:0]EXUi_DATA_fs1,		//数据源1，imm/rs1/rs1/csr/pc /pc
input [`GPU_DDATA_WIDTH-1:0]EXUi_DATA_fs2,
input [63:0]EXUi_DATA_as1,		//地址源1,  pc/rs1/rs1
input [63:0]EXUi_DATA_as2,		//地址源2, imm/imm/00
input [7:0]EXUi_DATA_opcount,	//操作次数码，用于AMO指令或移位指令
//流控FC
input EXUi_FC_system,		//system指令，op code=system的时候被置1
input EXUi_FC_jmp,			//会产生跳转的指令 opcode=branch时候置1
//机器控制段
//input id_system_id,		//system指令，op code=system的时候被置1
//input id_jmp_id,			//会产生跳转的指令 opcode=branch时候置1
input EXUi_MSC_ins_acc_fault,	//指令访问失败
input EXUi_MSC_ins_addr_mis, 	//指令地址错误
input EXUi_MSC_ins_page_fault,	//指令页面错误
input EXUi_MSC_interrupt,		//中断接收信号
input EXUi_MSC_valid, 			//指令有效信号
input EXUi_MSC_ill_ins,		//异常指令信号
input EXUi_MSC_mret,			//返回信号
input EXUi_MSC_sret,
input EXUi_MSC_ecall,			//环境调用
input EXUi_MSC_ebreak,			//断点

//到下一级 WB信号
//数据输出
output reg [`GPU_DDATA_WIDTH-1:0]EXUo_DATA_rd,
output reg [`GPU_DDATA_WIDTH-1:0]EXUo_DATA_csr,
output reg [`GPU_VDATA_WIDTH-1:0]EXUo_DATA_vreg,
output reg [`GPU_DDATA_WIDTH-1:0]EXUo_DATA_freg,
output reg [63:0]EXUo_DATA_newpc,
//写回控制
output reg EXUo_WB_CSRwrite,
output reg EXUo_WB_GPRwrite,
output reg EXUo_WB_VREGwrite,
output reg EXUo_WB_FREGwrite,
output reg EXUo_WB_PCjmp,				//新的PC需要被更改，新的PC由pc_new给出，该信号表明WB阶段需要修改PC
output reg [11:0]EXUo_WB_CSRindex,
output reg [4:0]EXUo_WB_RDindex,
output reg [4:0]EXUo_WB_FDindex,
output reg [4:0]EXUo_WB_VDindex,
//异常码
output reg [63:0]EXUo_DATA_pc,
output reg [63:0]EXUo_DATA_tval,		//如果是非法指令异常，则为非法指令，如果是硬件断点和储存器访问失败，则是虚拟地址
//流控信号
output reg EXUo_FC_system,		//system指令，op code=system的时候被置1
output reg EXUo_FC_jmp,			//会产生跳转的指令 opcode=branch时候置1
input EXUi_FC_nop,
input EXUi_FC_hold,
input EXUi_FC_war,			//后一级产生了数据相关问题

//==================Machine Control 机器控制信号======================
//output reg id_system,		//system指令，op code=system的时候被置1
//output reg id_jmp,			//会产生跳转的指令 opcode=branch时候置1
output reg EXUo_MSC_ins_acc_fault,	//指令访问失败
output reg EXUo_MSC_ins_addr_mis, 	//指令地址错误
output reg EXUo_MSC_ins_page_fault,	//指令页面错误
output reg EXUo_MSC_load_addr_mis,		//load地址不对齐
output reg EXUo_MSC_store_addr_mis,		//store地址不对齐
output reg EXUo_MSC_load_acc_fault,	//load访问失败
output reg EXUo_MSC_store_acc_fault,	//store访问失败
output reg EXUo_MSC_load_page_fault,	//load页面错误
output reg EXUo_MSC_store_page_fault,	//store页面错误
output reg EXUo_MSC_interrupt,			//中断接收信号
output reg EXUo_MSC_valid, 			//指令有效信号
output reg EXUo_MSC_ill_ins,			//异常指令信号
output reg EXUo_MSC_mret,			//返回信号
output reg EXUo_MSC_sret,			//
output reg EXUo_MSC_ecall,			//环境调用
output reg EXUo_MSC_ebreak,			//断点

//=================对BIU信号===============
output wire EXUo_BIU_unpage,			//只使用物理地址 命令BIU直接绕开虚拟地址使用物理地址
output wire [3:0]EXUo_BIU_priv,			//ex权限，0001=U 0010=S 0100=H 1000=M 
output reg [63:0]EXUo_BIU_addr,
output reg [`GPU_DDATA_WIDTH-1:0]EXUo_BIU_DATA_write,
input [`GPU_DDATA_WIDTH-1:0]EXUi_BIU_DATA_read,
//input [`GPU_DDATA_WIDTH-1:0]uncache_data,	//没有被缓存的数据
output wire [`GPU_VDATA_WIDTH-1:0]EXUi_VPU_datastore,//VPU的存取默认都是cached，显存的刷新依赖flush和原子操作
input [`GPU_VDATA_WIDTH-1:0]EXUi_VPU_dataload,

output wire [3:0]EXUo_BIU_size,			//0001=1Byte 0010=2Byte 0100=4Byte 1000=8Byte other=fault			
output wire EXUo_BIU_L1i_flush,			//缓存刷新信号，用于执行fence指令的时候使用
output wire EXUo_BIU_L1d_flush,			//缓存载入信号，用于执行fence.vma时候和cache_flush配合使用
output wire EXUo_BIU_L1d_sync,
output wire EXUo_BIU_read,				//读数据信号
output wire EXUo_BIU_write,				//写数据信号
output wire EXUo_BIU_VPUaccess,			//VPU专用存取选择，忽略size，128b直写
input EXUi_BIU_load_acc_fault,
input EXUi_BIU_load_page_fault,
input EXUi_BIU_store_acc_fault,
input EXUi_BIU_store_page_fault,
input EXUi_BIU_cache_ready,		//cache数据准备好信号，此信号比read_data提前一个周期出现
input EXUi_BIU_uncache_ready,		//不可缓存的数据准备好，此信号与uncache_data一个周期出现
input EXUi_BIU_L1d_syncok 		//L1D 写回完成
);
parameter p_stb 		= 4'b0000;	//等待状态
parameter p_mdiv		= 4'b0001;	//乘除指令，需要多周期,除法逃不掉
parameter p_load		= 4'b0010;	//load指令，需要多周期
parameter p_load1		= 4'b0011;	//load指令，第二周期
parameter p_store 		= 4'b0100;	//store指令
parameter p_amo_mem0	= 4'b1000;	//amo指令第一次访问内存
parameter p_amo_mem01	= 4'b1001;	//amo指令第一次访问内存延迟一拍，为了同步sram
parameter p_amo_ex1		= 4'b1010;	//amo指令第二次执行，第一次执行在stb状态时已经完成
parameter p_amo_mem1	= 4'b1011;	//amo指令第二次访问内存
parameter p_fence		= 4'b1100;	//fence指令

//EXU状态机控制线
wire c_stb;		//对系统主状态机译码
wire c_mdiv;    //Multiple cycle divide
wire c_load;
wire c_load_1;
wire c_store;
wire c_amo_mem0;
wire c_amo_mem01;
wire c_amo_ex1;
wire c_amo_mem1;
wire c_fence;

reg [3:0]main_state;			//系统主状态机

//ALU信号
wire [`GPU_DDATA_WIDTH-1:0]ds1_mem_data;		//ALU数据源1选择，当ds1_sel=1时，切换到MEM出来的数据，此举是为了AMO指令
wire [`GPU_DDATA_WIDTH-1:0]alu_data_rd;			//ALU数据数据输出，写回rd寄存器的数据
wire [`GPU_DDATA_WIDTH-1:0]alu_data_mem_csr;	//ALU数据输出，csr数据或者写回内存的数据
wire [`GPU_VDATA_WIDTH-1:0]EXUi_VPU_data_vd;
wire jmp_ok;					//跳转信号，允许跳转，此信号指示WB阶段进行跳转
//AU信号
wire [63:0]au_addr_pc;			//AU数据输出，访问内存所需的地址或者是跳转地址
//LSU信号
wire [63:0]data_out;
wire [`GPU_DDATA_WIDTH-1:0]data_lsu_cache;		//LSU输出数据(被缓存的)，AMO指令或Load指令时使用
//wire [63:0]data_lsu_uncache;	//lsu输出数据（不被缓存的）

wire execute_exception;			//执行错误

//VPU data
wire [`GPU_DDATA_WIDTH-1:0]EXUi_VPU_data_rd;//写回lane/mask



wire load_addr_mis;				//load地址不对齐
wire store_addr_mis;			//store地址不对齐

wire load_precessing;				//load指令正在执行
wire store_processing;				//store指令正在执行
wire fence_processing;				//fence指令正在执行
wire amo_processing;				//amo指令正在执行

wire execute_ready;					//exu执行完毕

assign ds1_mem_data		=	EXUi_OP_ds1_sel ? EXUo_DATA_rd : EXUi_DATA_ds1;	//当ds1_sel为1时，切换到MEM数据，此时MEM的数据已经被存到rd寄存器中

assign load_addr_mis	=  	(EXUi_OP_MC_amo|EXUi_OP_MC_load) & (EXUi_OP_size[1]&(au_addr_pc[2:0]==3'b111) | EXUi_OP_size[2]&(au_addr_pc[1:0]!=2'b00) | EXUi_OP_size[3]&(au_addr_pc[2:0]!=3'b000));
assign store_addr_mis	=	EXUi_OP_MC_store& (EXUi_OP_size[1]&(au_addr_pc[2:0]==3'b111) | EXUi_OP_size[2]&(au_addr_pc[1:0]!=2'b00) | EXUi_OP_size[3]&(au_addr_pc[2:0]!=3'b000));
//xxx_prcessing 信号指示了这些操作正在执行
//-----------------------------------------------NOTE-------------------------------------------------
//CLK			:__/--\__/--\__/--\__/--\__/--\__/--\__/--\__/--\__/--\__
//xxx_processing:__/-----------\______
//cache_ready	:________/-----\______
//DATA_valid	:==============[DATA ]
//uncache_ready	:______________/-----\
//OP_MC_xxx		:__/-----------------\
//Detail		:|<--1 instruction-->| 
assign load_precessing	=	EXUi_MSC_valid & EXUi_OP_MC_load & !(EXUi_BIU_uncache_ready | (main_state==p_load1));
assign store_processing =	EXUi_MSC_valid & EXUi_OP_MC_store & EXUi_BIU_cache_ready;
assign fence_processing =	EXUi_MSC_valid & (EXUi_OP_MC_L1d_flush|EXUi_OP_MC_L1i_flush|EXUi_OP_MC_L1d_force_sync) & EXUi_BIU_cache_ready;
assign amo_processing	=	EXUi_MSC_valid & EXUi_OP_MC_amo & !((main_state==p_amo_mem1) & EXUi_BIU_cache_ready);

assign execute_ready	=	!(load_precessing | store_processing | fence_processing | amo_processing) | execute_exception;
//execute_exception指示了在执行过程中遇到了异常
assign execute_exception	=	load_addr_mis | store_addr_mis | EXUi_BIU_load_acc_fault |
								EXUi_BIU_load_page_fault | EXUi_BIU_store_acc_fault |
								EXUi_BIU_store_page_fault | load_addr_mis|store_addr_mis;
//-------------------------------------------EXU主状态机--------------------------------------
//TODO VPU存取状态机
always@(posedge clk)begin
	if(rst | execute_exception)begin
		main_state	<=	p_stb;			//如果发生异常 立即停止执行
	end
	else if(EXUi_MSC_valid)begin
		case(main_state)
			p_stb	:	if(!execute_exception)begin
							main_state	<=	EXUi_OP_MC_load														?p_load		:
											EXUi_OP_MC_store													?p_store	:
											EXUi_OP_MC_amo														?p_amo_mem0	:
											(EXUi_OP_MC_L1i_flush|EXUi_OP_MC_L1d_flush|EXUi_OP_MC_L1d_force_sync)	?p_fence	:	main_state;
						end
			p_load	:	if(EXUi_BIU_uncache_ready)begin
							main_state	<=	p_stb;
						end
						else if (EXUi_BIU_cache_ready)begin
							main_state	<=	p_load1;
						end
			p_load1	:	main_state	<=	p_stb;
			p_store	:	main_state	<=	(EXUi_BIU_cache_ready | EXUi_BIU_uncache_ready) ? p_stb : main_state;
			p_amo_mem0:	if(EXUi_BIU_uncache_ready)begin
							main_state	<=	p_amo_ex1;
						end
						else if(EXUi_BIU_cache_ready)begin
							main_state	<=	p_amo_mem01;
						end
			p_amo_mem01:	main_state  <=	p_amo_ex1;
			p_amo_ex1:		main_state	<=	p_amo_mem1;
			p_fence:		main_state	<=	(EXUi_BIU_cache_ready | EXUi_BIU_uncache_ready) ? p_stb : main_state;
			p_amo_mem1:		main_state	<=	(EXUi_BIU_cache_ready | EXUi_BIU_uncache_ready) ? p_stb : main_state;
		endcase
	end					
end
assign c_stb 		= (main_state==p_stb);
assign c_load		= (main_state==p_load);
assign c_load_1		= (main_state==p_load1);
assign c_store 		= (main_state==p_store);
assign c_amo_mem0	= (main_state==p_amo_mem0);
assign c_amo_mem01	= (main_state==p_amo_mem01);
assign c_amo_ex1	= (main_state==p_amo_ex1);
assign c_amo_mem1 	= (main_state==p_amo_mem1);
assign c_fence 		= (main_state==p_fence);


//对WB的数据输出
//rd值输出寄存器，移位指令也在其中处理
always@(posedge clk)
begin
	if(rst)
	begin
		EXUo_DATA_rd <= 32'b0;
	end
	else if(EXUi_FC_hold)
	begin
		EXUo_DATA_rd <= EXUo_DATA_rd;
	end

	else if(c_stb)
	begin
		EXUo_DATA_rd 	<=	alu_data_rd;
	end
	else if(EXUi_VPU_enable)
	begin
		EXUo_DATA_rd<=EXUi_VPU_data_rd;
		
	end
	/*
	因为AHB总线的HREADY和数据是同周期出现，而cache是SSRAM，数据和准备好信号之间延迟一个周期，故在这里
	寄存两次来保证数据正确
	*/
	//AMO指令访问内存之后进行数据寄存，以便进行下一步操作
	else if(c_load|c_amo_mem0|c_load_1|c_amo_mem01)
	begin
		EXUo_DATA_rd		<=  data_lsu_cache;		//存储数据
	end
	
end
always@(posedge clk) //VPU写回管理
//TODO 此处写回可靠性存疑
begin
	if(EXUi_FC_hold)
	begin
		EXUo_DATA_vreg <= EXUo_DATA_vreg;
	end

	else if(c_stb)
	begin
		EXUo_DATA_vreg 	<=	EXUi_VPU_data_vd;
	end
	/*
	因为AHB总线的HREADY和数据是同周期出现，而cache是SSRAM，数据和准备好信号之间延迟一个周期，故在这里
	寄存两次来保证数据正确
	*/
	//AMO指令访问内存之后进行数据寄存，以便进行下一步操作
	else if(c_load|c_amo_mem0|c_load_1|c_amo_mem01)
	begin
		EXUo_DATA_vreg		<=  EXUi_VPU_dataload;		//存储数据
	end

end
//data_csr和newpc寄存器
always@(posedge clk)begin
	if(rst)begin
		EXUo_DATA_csr	<=	64'b0;
		EXUo_DATA_newpc	<= 	64'b0;
	end
	else if(EXUi_FC_hold)begin
		EXUo_DATA_csr	<= 	EXUo_DATA_csr;
		EXUo_DATA_newpc	<=	EXUo_DATA_newpc;
	end
	else begin
		EXUo_DATA_csr	<= 	alu_data_mem_csr;
		EXUo_DATA_newpc		<=	au_addr_pc;
	end
end

//传递到下一级的异常码
always@(posedge clk)begin
	if(rst)begin
		EXUo_DATA_pc	<=	64'b0;
		EXUo_DATA_tval<= 	64'b0;
	end
	else if(EXUi_FC_hold)begin
		EXUo_DATA_pc 	<=	EXUo_DATA_pc;
		EXUo_DATA_tval<=	EXUo_DATA_tval;
	end
	else begin
		EXUo_DATA_pc	<= 	EXUi_DATA_pc;
		EXUo_DATA_tval<= 	execute_exception ? au_addr_pc : EXUi_DATA_tval;//只有当发生了异常，才会被更新到异常上
	end
end
//写回控制信号
always@(posedge clk)begin
	if(rst | EXUi_FC_nop)begin
		EXUo_WB_CSRwrite	<=	1'b0;
		EXUo_WB_GPRwrite	<= 	1'b0;
		EXUo_WB_FREGwrite	<= 	1'b0;
		EXUo_WB_VREGwrite	<= 	1'b0;
		EXUo_WB_PCjmp		<=	1'b0;				//新的PC需要被更改，新的PC由pc_new给出，该信号表明WB阶段需要修改PC
		EXUo_WB_CSRindex	<=	12'b0;
		EXUo_WB_RDindex	<=	5'b0;
		EXUo_WB_FDindex	<=	5'b0;
		EXUo_WB_VDindex	<=	5'b0;
	end
	else if(EXUi_FC_hold)begin
		EXUo_WB_CSRwrite	<=	EXUo_WB_CSRwrite;
		EXUo_WB_GPRwrite	<= 	EXUo_WB_GPRwrite;
		EXUo_WB_FREGwrite	<= 	EXUo_WB_FREGwrite;
		EXUo_WB_VREGwrite	<= 	EXUo_WB_VREGwrite;
		EXUo_WB_PCjmp		<=	EXUo_WB_PCjmp;				//新的PC需要被更改，新的PC由pc_new给出，该信号表明WB阶段需要修改PC
		EXUo_WB_CSRindex	<=	EXUo_WB_CSRindex;
		EXUo_WB_RDindex	<=	EXUo_WB_RDindex;
		EXUo_WB_FDindex	<=	EXUo_WB_FDindex;
		EXUo_WB_VDindex	<=	EXUo_WB_VDindex;
	end
	//EX阶段继续传递ID阶段传进来的写回信息
	else begin
		EXUo_WB_CSRwrite	<=	EXUi_WB_CSRwrite;
		EXUo_WB_GPRwrite	<= 	EXUi_WB_GPRwrite;
		EXUo_WB_FREGwrite	<= 	EXUi_WB_FREGwrite;
		EXUo_WB_VREGwrite	<= 	EXUi_WB_VREGwrite;
		EXUo_WB_PCjmp		<=	jmp_ok;				//新的PC需要被更改，新的PC由pc_new给出，该信号表明WB阶段需要修改PC
		EXUo_WB_CSRindex	<=	EXUi_WB_CSRindex;
		EXUo_WB_RDindex		<=	EXUi_WB_RDindex;
		EXUo_WB_FDindex		<=	EXUi_WB_FDindex;
		EXUo_WB_VDindex		<=	EXUi_WB_VDindex;
	end
end

//机器控制段
//机器控制段负责WB阶段时csr的自动更新
always@(posedge clk)begin
	if(rst | EXUi_FC_nop)begin
		EXUo_FC_system				<=	1'b0;		//system指令，op code=system的时候被置1
		EXUo_FC_jmp					<=	1'b0;		//会产生跳转的指令 opcode=branch时候置1
		EXUo_MSC_ins_acc_fault		<=	1'b0;	//指令访问失败
		EXUo_MSC_ins_addr_mis		<=	1'b0;	//指令地址错误
		EXUo_MSC_ins_page_fault		<=	1'b0;	//指令页面错误
		EXUo_MSC_load_addr_mis		<=	1'b0;	//load地址不对齐
		EXUo_MSC_store_addr_mis		<=  1'b0;	//store地址不对齐
		EXUo_MSC_load_acc_fault		<=	1'b0;	//load访问失败
		EXUo_MSC_store_acc_fault	<=	1'b0;	//store访问失败
		EXUo_MSC_load_page_fault	<=	1'b0;	//load页面错误
		EXUo_MSC_store_page_fault	<=	1'b0;	//store页面错误
		EXUo_MSC_interrupt			<=	1'b0;	//中断接收信号
		EXUo_MSC_valid				<=	1'b0;	//指令有效信号
		EXUo_MSC_ill_ins			<=	1'b0;	//异常指令信号
		EXUo_MSC_mret				<=	1'b0;	//返回信号
		EXUo_MSC_sret				<=	1'b0;
		EXUo_MSC_ecall				<=	1'b0;	//环境调用
		EXUo_MSC_ebreak				<=	1'b0;	//断点
	end
	else if(EXUi_FC_hold)begin
		EXUo_FC_system				<=	EXUo_FC_system;		//system指令，op code=system的时候被置1
		EXUo_FC_jmp					<=	EXUo_FC_jmp;		//会产生跳转的指令 opcode=branch时候置1
		EXUo_MSC_ins_acc_fault		<=	EXUo_MSC_ins_acc_fault;	//指令访问失败
		EXUo_MSC_ins_addr_mis		<=	EXUo_MSC_ins_addr_mis;	//指令地址错误
		EXUo_MSC_ins_page_fault		<=	EXUo_MSC_ins_page_fault;	//指令页面错误
		EXUo_MSC_load_addr_mis		<=	EXUo_MSC_ins_addr_mis;	//load地址不对齐
		EXUo_MSC_store_addr_mis		<=  EXUo_MSC_store_addr_mis;	//store地址不对齐
		EXUo_MSC_load_acc_fault		<=	EXUo_MSC_load_acc_fault;	//load访问失败
		EXUo_MSC_store_acc_fault	<=	EXUo_MSC_store_acc_fault;	//store访问失败
		EXUo_MSC_load_page_fault	<=	EXUo_MSC_load_page_fault;	//load页面错误
		EXUo_MSC_store_page_fault	<=	EXUo_MSC_store_page_fault;	//store页面错误
		EXUo_MSC_interrupt			<=	EXUo_MSC_interrupt;	//中断接收信号
		EXUo_MSC_valid				<=	EXUo_MSC_valid;	//指令有效信号
		EXUo_MSC_ill_ins			<=	EXUo_MSC_ill_ins;	//异常指令信号
		EXUo_MSC_mret				<=	EXUo_MSC_mret;	//返回信号
		EXUo_MSC_sret				<=	EXUo_MSC_sret;
		EXUo_MSC_ecall				<=	EXUo_MSC_ecall;	//环境调用
		EXUo_MSC_ebreak				<=	EXUo_MSC_ebreak;	//断点
	end
	else begin
		EXUo_FC_system				<=	EXUi_FC_system | execute_exception;					//当EX出现异常时，system加入更多system信息
		EXUo_FC_jmp					<=	EXUi_FC_jmp;										//会产生跳转的指令 opcode=branch或者JAL JALR时候置1
		EXUo_MSC_ins_acc_fault		<=	EXUi_MSC_ins_acc_fault;								//指令访问失败
		EXUo_MSC_ins_addr_mis		<=	EXUi_MSC_ins_addr_mis;								//指令地址错误
		EXUo_MSC_ins_page_fault		<=	EXUi_MSC_ins_page_fault;								//指令页面错误
		EXUo_MSC_load_addr_mis		<=	load_addr_mis;									//load地址不对齐
		EXUo_MSC_store_addr_mis		<=  (c_amo_mem0 & load_addr_mis) | store_addr_mis;	//store地址不对齐
		EXUo_MSC_load_acc_fault		<=	EXUi_BIU_load_acc_fault;										//load访问失败
		EXUo_MSC_store_acc_fault	<=	(c_amo_mem0 & EXUi_BIU_load_acc_fault) | EXUi_BIU_store_acc_fault;	//store访问失败
		EXUo_MSC_load_page_fault	<=	EXUi_BIU_load_page_fault;									//load页面错误
		EXUo_MSC_store_page_fault	<=	(c_amo_mem0 & EXUi_BIU_load_page_fault) | EXUi_BIU_store_page_fault;	//EXUi_OP_MC_store/AMO页面错误
		EXUo_MSC_interrupt			<=	EXUi_MSC_interrupt;											//中断接收信号
		EXUo_MSC_valid				<=	EXUi_MSC_valid & execute_ready;				//指令有效信号,如果发生异常，valid=1，交给WB
		EXUo_MSC_ill_ins			<=	EXUi_MSC_ill_ins;										//异常指令信号
		EXUo_MSC_mret				<=	EXUi_MSC_mret;										//返回信号
		EXUo_MSC_sret				<=	EXUi_MSC_sret;
		EXUo_MSC_ecall				<=	EXUi_MSC_ecall;											//环境调用
		EXUo_MSC_ebreak				<=	EXUi_MSC_ebreak;											//断点
	end
end


//assign ex_ready			=	EXUi_MSC_valid ? (!(load|store|amo|l1i_reset|l1d_reset) | //没有多周期操作时 1T即执行完成
//							load & load_ready | 
//							store & store_ready | 
//							amo&amo_ready | 
//							(l1i_reset|l1d_reset|EXUi_OP_MC_L1d_force_sync) & fence_ready)  : 1'b1 ; //EXUi_MSC_valid=0时，为空操作，此时EX准备好
										//ID如果发生异常，EX不会执行操作，直接准备好

alu_au					ALU_AU(
//-----------------------操作码 ALU,运算码-----------------
//rd数据选择
	.rd_data_ds1		(EXUi_OP_ALU_ds1),		//ds1直通
	.rd_data_add		(EXUi_OP_ALU_add),		//加
	.rd_data_sub		(EXUi_OP_ALU_sub),		//减
	.rd_data_and		(EXUi_OP_ALU_and),		//逻辑&
	.rd_data_or			(EXUi_OP_ALU_or),		//逻辑|
	.rd_data_xor		(EXUi_OP_ALU_xor),		//逻辑^
	.rd_data_slt		(EXUi_OP_ALU_slt),		//比较大小
	.compare			(EXUi_OP_ALU_compare),			//比较大小
	.amo_lr_sc			(EXUi_OP_ALU_amo_lrsc),		//lr/sc读写成功标志

	.shift_r 			(EXUi_OP_ALU_shift_right),
	.shift_l 			(EXUi_OP_ALU_shift_left),

//mem_csr_data数据选择
	.mem_csr_data_ds1	(EXUi_OP_csr_mem_ds1),
	.mem_csr_data_ds2	(EXUi_OP_csr_mem_ds2),
	.mem_csr_data_add	(EXUi_OP_csr_mem_add),
	.mem_csr_data_and	(EXUi_OP_csr_mem_and),
	.mem_csr_data_or	(EXUi_OP_csr_mem_or),
	.mem_csr_data_xor	(EXUi_OP_csr_mem_xor),
	.mem_csr_data_max	(EXUi_OP_csr_mem_max),
	.mem_csr_data_min	(EXUi_OP_csr_mem_min),
//运算,跳转辅助控制信号
	.blt				(EXUi_OP_ALU_blt),				//条件跳转，blt bltu指令时为1
	.bge				(EXUi_OP_ALU_bge),
	.beq				(EXUi_OP_ALU_beq),				//条件跳转，bne指令时为一
	.bne				(EXUi_OP_ALU_bne),
	.jmp				(EXUi_OP_ALU_jmp),				//无条件跳转，适用于JAL JALR指令
	.unsign				(EXUi_OP_ALU_unsign),			//无符号操作，同时控制mem单元信号的符号
	.and_clr			(EXUi_OP_ALU_clr),			//将csr操作的and转换为clr操作

//位宽控制
	.size				(EXUi_OP_size), 		//0001:1Byte 0010:2Byte 0100=4Byte 1000=8Byte


//数据输入							   
	.ds1				(ds1_mem_data),	//数据源1，imm/rs1/rs1/csr/pc /pc
	.ds2				(EXUi_DATA_ds2),			//数据源2，00 /rs2/imm/imm/imm/04
	.as1				(EXUi_DATA_as1),			//地址源1,  pc/rs1/rs1
	.as2				(EXUi_DATA_as2),			//地址源2, imm/imm/00
	.op_count			(EXUi_DATA_opcount),		//移位次数

//数据输出
	.alu_data_rd		(alu_data_rd),
	.alu_data_mem_csr	(alu_data_mem_csr),
	.au_addr_pc			(au_addr_pc),
//跳转信号输出
	.jmp_ok				(jmp_ok)

);
VPU vpu1(
    .ifsel(EXUi_VPU_ifsel),//Function integer/float select
	.addsel(EXUi_VPU_addsel),
	.subsel(EXUi_VPU_subsel),
	.mulsel(EXUi_VPU_mulsel),
	.itfsel(EXUi_VPU_itfsel),//integer to float
	.ftisel(EXUi_VPU_ftisel),//float to integer
	.ftlsel(EXUi_VPU_laneop),//Lane operation
	.maxsel(EXUi_VPU_maxsel),
	.minsel(EXUi_VPU_minsel),
	.andsel(EXUi_VPU_andsel),//逻辑&
	.orsel(EXUi_VPU_orsel),//逻辑|
	.xorsel(EXUi_VPU_xorsel),
	.srasel(EXUi_VPU_srasel),
	.srlsel(EXUi_VPU_srlsel),
	.sllsel(EXUi_VPU_sllsel),
	.cgesel(EXUi_VPU_cgesel),//compare:great equal
	.cltsel(EXUi_VPU_cltsel),
	.ceqsel(EXUi_VPU_ceqsel),
	.cnqsel(EXUi_VPU_cnqsel),

    .vs1(EXUi_DATA_vs1),
    .vs2(EXUi_DATA_vs2),
    .fs(EXUi_DATA_fs1),
    .rs(EXUi_DATA_ds1),
    .mask_in(EXUi_DATA_ds2),//MASK=maskreg|{32{!masken}}
    .rd(EXUi_VPU_data_rd),
    .fd(EXUi_VPU_data_fd),
    .vd(EXUi_VPU_data_vd)

);
//========================对BIU信号===================================
assign EXUo_BIU_unpage	=	1;				//当启用的MPRV位且MPP位为M时候，绕开分页直接使用物理地址
assign EXUo_BIU_priv	=	4'b1000;		//ex权限，0001=U 0010=S 0100=H 1000=M 
//--------------对BIU的地址/数据进行缓冲----------------
always@(posedge clk)begin
	if(rst)begin
		EXUo_BIU_addr	<=	64'b0;
	end
	else begin
		EXUo_BIU_addr	<=	au_addr_pc;
	end
end
always@(posedge clk)begin
	if(rst)begin
		EXUo_BIU_DATA_write	<=	64'b0;
	end
	else begin
		EXUo_BIU_DATA_write	<=	data_out;
	end
end

assign EXUo_BIU_size			=	EXUi_OP_size;			//0001=1Byte 0010=2Byte 0100=4Byte 1000=8Byte other=fault			
assign EXUo_BIU_L1i_flush 	= 	EXUi_OP_MC_L1i_flush & c_fence;			//缓存刷新信号，用于执行fence指令的时候使用
assign EXUo_BIU_L1d_flush 	= 	EXUi_OP_MC_L1d_flush & c_fence;			//缓存载入信号，用于执行fence.vma时候和cache_flush配合使用
assign EXUo_BIU_L1d_sync 	= 	EXUi_OP_MC_L1d_force_sync & c_fence;
assign EXUo_BIU_read				=	EXUi_OP_MC_load & c_load | EXUi_OP_MC_amo & c_amo_mem0;				//读数据信号
assign EXUo_BIU_write			=	EXUi_OP_MC_store & c_store | EXUi_OP_MC_amo & c_amo_mem1;				//写数据信号

/*
单元的主要作用只有进行数据移位和进行符号位拓展，时序控制完全被交给了EXU中的状态机
所有从EXU中向外送出的数据都要经过byte_shifter进行数据移位。
所有从BIU中读到的数据都要经过byte_shifter进行数据移位和符号拓展。
*/
byte_shifter					byte_shifter(
	.unsign							(EXUi_OP_ALU_unsign),
	.addr							(au_addr_pc[2:0]),//地址低3位 用于指示移位大小
	.size							(EXUi_OP_size),//0001:1Byte 0010:2Byte 0100=4Byte 1000=8Byte

	.data_in						(alu_data_mem_csr),			//要送往BIU的数据
	.data_lsu_cache					(data_lsu_cache),	

//对BIU信号
	.data_write						(data_out),
	.data_read						(EXUi_BIU_DATA_read)

);
//----流控信号------
assign EXUo_FC_hold	=	load_precessing | store_processing | amo_processing | fence_processing | EXUi_FC_hold;
assign EXUo_FC_nop	=	execute_exception | EXUi_FC_system | EXUi_FC_jmp | EXUi_FC_nop ;
assign EXUo_FC_war	=	(EXUi_FC_warcheck & EXUi_WB_GPRwrite & ((EXUi_FC_rs1index==EXUi_WB_RDindex) | (EXUi_FC_rs2index==EXUi_WB_RDindex))) | EXUi_FC_war;



endmodule
