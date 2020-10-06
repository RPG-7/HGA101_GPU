module FVPU (
input wire clk,
input wire rst,



//操作码 ALU,运算码
//rd数据选择
input wire rd_data_ds1,		//ds1直通
input wire rd_data_add,		//加
input wire rd_data_sub,		//减
input wire rd_data_and,		//逻辑&
input wire rd_data_or,		//逻辑|
input wire rd_data_xor,		//逻辑^
input wire rd_data_slt,		//比较大小
input wire compare,			//比较大小，配合bge0_blt1\beq0_bne1控制线并产生分支信号
input wire amo_lr_sc,		//lr/sc读写成功标志，LR/SC指令总是读写成功

//mem_csr_data数据选择
input wire mem_csr_data_ds1,
input wire mem_csr_data_ds2,
input wire mem_csr_data_add,
input wire mem_csr_data_and,
input wire mem_csr_data_or,
input wire mem_csr_data_xor,
input wire mem_csr_data_max,
input wire mem_csr_data_min,
//运算,跳转辅助控制信号
input wire blt,				
input wire bge,
input wire beq,				
input wire bne,
input wire jmp,				//无条件跳转，适用于JAL JALR指令
input wire unsign,			//无符号操作，同时控制mem单元信号的符号拓展
input wire and_clr,			//将csr操作的and转换为clr操作
input wire ds1_sel,			//ALU ds1选择，为0选择ds1，为1选择LSU读取的数据

//位宽控制
input wire [3:0]size, 		//0001:1Byte 0010:2Byte 0100=4Byte 1000=8Byte
//多周期控制
//多周期控制信号线控制EX单元进行多周期操作
input wire load,
input wire store,
input wire amo,
input wire l1i_reset,		//命令 缓存刷新信号，此信号可以与内存进行同步
input wire l1d_reset,		//命令 缓存复位信号，下次访问内存时重新刷新页表
input wire TLB_reset,
input wire shift_r,			//左移位
input wire shift_l,			//右移位

//写回控制，当valid=0时候，所有写回不有效
input wire csr_write_id,		//注*后缀ID表示是ID传输进来的信号
input wire gpr_write_id,
input wire [11:0]csr_index_id,
input wire [4:0]rs1_index_id,
input wire [4:0]rs2_index_id,
input wire [4:0]rd_index_id,

//数据输出							   
input wire [63:0]ds1,		//数据源1，imm/rs1/rs1/csr/pc /pc
input wire [63:0]ds2,		//数据源2，00 /rs2/imm/imm/imm/04
input wire [63:0]as1,		//地址源1,  pc/rs1/rs1
input wire [63:0]as2,		//地址源2, imm/imm/00
input wire [7:0]op_count,	//操作次数码，用于AMO指令或移位指令
//机器控制段
//机器控制段负责WB阶段时csr的自动更新
input wire id_system_id,		//system指令，op code=system的时候被置1
input wire id_jmp_id,			//会产生跳转的指令 opcode=branch时候置1
input wire ins_acc_fault_id,	//指令访问失败
input wire ins_addr_mis_id, 	//指令地址错误
input wire ins_page_fault_id,	//指令页面错误
input wire int_acc_id,			//中断接收信号
input wire valid_id, 			//指令有效信号
input wire ill_ins_id,			//异常指令信号
input wire m_ret_id,				//返回信号
input wire s_ret_id,
input wire ecall_id,			//环境调用
input wire ebreak_id,			//断点
//到EX信号完

//到下一级 WB信号
//数据输出
output reg [63:0]data_rd,
output reg [63:0]data_csr,
output reg [63:0]new_pc,
//写回控制
output reg fgpr_write,
output reg [11:0]csr_index,
output reg [4:0]fd_index,
//异常码
output reg [63:0]exc_code,		//如果是非法指令异常，则为非法指令，如果是硬件断点和储存器访问失败，则是虚拟地址
//机器控制段
//机器控制段负责WB阶段时csr的自动更新
output reg id_system,		//system指令，op code=system的时候被置1
output reg id_jmp,			//会产生跳转的指令 opcode=branch时候置1
output reg ins_acc_fault,	//指令访问失败
output reg ins_addr_mis, 	//指令地址错误
output reg ins_page_fault,	//指令页面错误
output reg ld_addr_mis,		//load地址不对齐
output reg st_addr_mis,		//store地址不对齐
output reg ld_acc_fault,	//load访问失败
output reg st_acc_fault,	//store访问失败
output reg ld_page_fault,	//load页面错误
output reg st_page_fault,	//store页面错误
output reg int_acc,			//中断接收信号
output reg valid, 			//指令有效信号
output reg ill_ins,			//异常指令信号
output reg m_ret,			//返回信号
output reg s_ret,			//
output reg ecall,			//环境调用
output reg ebreak,			//断点


//对BIU信号
output wire unpage,				//只使用物理地址 data_from_biu
output wire [3:0]ex_priv,		//ex权限，0001=U 0010=S 0100=H 1000=M 
output reg [63:0]addr_ex,
output wire [63:0]data_write,
input wire [63:0]data_read,
input wire [63:0]uncache_data,	//没有被缓存的数据
output wire [3:0]size_biu,			//0001=1Byte 0010=2Byte 0100=4Byte 1000=8Byte other=fault			
output wire cache_l1i_reset,			//缓存刷新信号，用于执行fence指令的时候使用
output wire cache_l1d_reset,			//缓存载入信号，用于执行fence.vma时候和cache_flush配合使用
output wire cache_TLB_reset,
output wire read,				//读数据信号
output wire write,				//写数据信号

input wire load_acc_fault,
input wire load_page_fault,
input wire store_acc_fault,
input wire store_page_fault,
input wire cache_ready_ex,		//cache数据准备好信号，此信号比read_data提前一个周期出现
input wire uncache_data_ready,	//不可缓存的数据准备好，此信号与uncache_data一个周期出现

//pip_ctrl信号
//pip_ctrl负责检查这些信号并控制整个流水线的操作

//ex独有pipctrl信号
output wire ex_exception,				//ex发生错误，此信号比WB阶段的信号提早1T出现，
output wire ex_ready,					//ex准备好信号,和同步sram信号一样，这个信号在T1出现，T2才会更新出有效数据

input wire ex_hold,						//ID等待
input wire ex_nop						//ID插空
);



endmodule