`include  "global_defines.vh"
/*
适用于PRV464的控制单元CU和寄存器单元ru
寄存器单元含32个通用寄存器
控制单元含csr寄存器
对外的接口只有和IF，ID和WB
*/
module cu_ru(
input wire clk,
input wire rst,

//外部中断信号
input wire m_time_int,
input wire m_soft_int,
input wire m_ext_int,	//对M模式的中断信号
//外部时钟信号

//对IF信号
output wire int_req,		//中断请求信号
output wire [63:0]flush_pc,	//新的PC值
output wire pip_flush,		//流水线冲刷信号

//对ID信号
output wire tvm,
output wire tsr,
output wire tw,
input wire [11:0]id_csr_index,
output wire [`GPU_DDATA_WIDTH-1:0]csr_data,	//读取的CSR值
input wire [4:0]rs1_index,
output wire [`GPU_DDATA_WIDTH-1:0]rs1_data,
input wire [4:0]rs2_index,
output wire [`GPU_DDATA_WIDTH-1:0]rs2_data,

input wire [4:0]fs1_index,
output wire [`GPU_DDATA_WIDTH-1:0]fs1_data,
input wire [4:0]fs2_index,
output wire [`GPU_DDATA_WIDTH-1:0]fs2_data,

input wire [4:0]vs1_index,
output wire [`GPU_VDATA_WIDTH-1:0]vs1_data,
input wire [4:0]vs2_index,
output wire [`GPU_VDATA_WIDTH-1:0]vs2_data,
//对EX信号
output wire mprv,
output wire [3:0]mod_priv,

//对WB信号
input wire [`GPU_DDATA_WIDTH-1:0]data_rd,
input wire [`GPU_DDATA_WIDTH-1:0]data_fd,
input wire [`GPU_VDATA_WIDTH-1:0]data_vd,
input wire [`GPU_DDATA_WIDTH-1:0]data_csr,
input wire [`GPU_IADDR_WIDTH-1:0]new_pc,


//写回控制
input wire csr_write,
input wire gpr_write,
input wire fgpr_write,
input wire vgpr_write,
input wire pc_jmp,				//新的PC需要被更改，新的PC由pc_new给出，该信号表明WB阶段需要修改PC
input wire [11:0]csr_index,
input wire [4:0]rd_index,
input wire [4:0]fd_index,
input wire [4:0]vd_index,
//异常码
input wire [63:0]ins_pc,
input wire [63:0]exc_code,		//如果是非法指令异常，则为非法指令，如果是硬件断点和储存器访问失败，则是虚拟地址
//机器控制段
//机器控制段负责WB阶段时csr的自动更新
input wire id_system,		//system指令，op code=system的时候被置1
input wire id_jmp,			//会产生跳转的指令 opcode=branch时候置1
input wire ins_acc_fault,	//指令访问失败
input wire ins_addr_mis, 	//指令地址错误
input wire ins_page_fault,	//指令页面错误
input wire ld_addr_mis,		//load地址不对齐
input wire st_addr_mis,		//store地址不对齐
input wire ld_acc_fault,	//load访问失败
input wire st_acc_fault,	//store访问失败
input wire ld_page_fault,	//load页面错误
input wire st_page_fault,	//store页面错误
input wire int_acc,			//中断接收信号
input wire valid, 			//指令有效信号
input wire ill_ins,			//异常指令信号
input wire m_ret,			//返回信号
input wire s_ret,			//
input wire ecall,			//环境调用
input wire ebreak			//断点

);

//机器权限

wire mie;			//M模式中断使能
wire sie;			//S模式中断使能
//中断原因
wire [63:0]trap_cause;
//生成的新的向量PC值
wire [63:0]tvec;	//mtvec,stvec寄存器生成的tvec
//最终生成的跳转地址
wire [63:0]vec_pc;
//int cause
wire [63:0]int_cause;	//中断原因
wire [63:0]exc_cause;	//异常原因
wire [31:0]mepc;
//发生了异常
wire exception;

//异常/中断受理目标
wire int_target_s;		//中断的目标权限是S，此信号由中断控制单元int_ctrl发出
wire int_target_m;		//中断的目标权限是M，此信号由中断控制单元int_ctrl发出
wire exc_target_s;		//异常的目标权限是S，此信号由异常控制单元exc_ctrl发出
wire exc_target_m;		//异常的目标权限是M，此信号由异常控制单元exc_ctrl发出

wire trap_target_m;		//m模式立即受理trap，当此位为1时候，m模式下受理trap的寄存器将会被影响，s模式的不动
wire trap_target_s;		//s模式立即受理trap，当此位为1时，s模式下受理trap的寄存器将会被影响，M模式的不动
wire next_pc;			//控制epc寄存器保存下一个pc,所有int指令 ecall和ebreak指令会用到这个信号

assign exception	=	valid&(ins_acc_fault | ins_addr_mis | ins_page_fault | ill_ins | ld_acc_fault|ld_page_fault|st_acc_fault|st_page_fault|ld_addr_mis|st_addr_mis|ecall|ebreak);

//如果指令遭遇了异常，异常被优先处理，而不管中断
assign trap_target_m=	!exception & valid & int_target_m & int_req & int_acc | valid & exc_target_m;	
assign trap_target_s=	!exception & valid & int_target_s & int_req & int_acc | valid & exc_target_s;

//要求使用下一个指令的PC
//EBREAK异常发生时候，要求使用下一个指令地址，其余情况mepc都保存当前指令地址
assign next_pc		=	ebreak	|	int_target_m	|	int_target_s;
assign trap_cause	=	exception ? exc_cause : int_cause;

//中断向量地址
assign vec_pc	= exception ? {2'b0,tvec[63:2]} : tvec[0] ? ({2'b0,tvec[63:2]} + {trap_cause[61:0],2'b00}) : {2'b0,tvec[63:2]};


Anlogic_GPR_Sample	 	GPR(
.clk		(clk),
.clk_en		(gpr_write & valid),

.rd0_data	(data_rd) ,
.rd0_addr	(rd_index) ,
.rs1_addr	(rs1_index) ,
.rs2_addr	(rs2_index) ,
.rs1_data	(rs1_data) ,
.rs2_data 	(rs2_data) 
);
FGPR fgpr(
    .rs1(fs1_index),
    .rs2(fs2_index),
    .rs1o(fs1_data),
    .rs2o(fs2_data),
    .rdi(data_fd),
    .rd(fd_index),
    .rdw(fgpr_write),
    .clk(clk)
);
VGPR vgpr(
    .rs1(vs1_index),
    .rs2(vs2_index),
    .rs1o(vs1_data),
    .rs2o(vs2_data),
    .rdi(data_vd),
    .rd(vd_index),
    .rdw(vgpr_write),
    .clk(clk)
);

//对IF 控制指令流信号
//返回的时候，使用xepc地址；发生中断时使用向量PC：VEC_PC；跳转指令使用WB传回的new_pc
assign flush_pc	=	(valid&m_ret) ? mepc :  (trap_target_m ) ? vec_pc : new_pc;	//新的PC值
assign pip_flush=	valid & ((trap_target_m ) | pc_jmp)	;		//当写回指令有效时候，发出流水线冲刷信号

csr_top CSR(
    .clk(clk),
    .rst(rst),
    .csr_read_index(id_csr_index),
    .csr_write_index(csr_index),
    .csr_write(csr_write),
    .csr_data_w(data_csr),
    .csr_data_r(csr_data),



    .id_system(id_system),		//system指令，op code=system的时候被置1
    .id_jmp(id_jmp),			//会产生跳转的指令 opcode=branch时候置1
    .ins_acc_fault(ins_acc_fault),	//指令访问失败
    .ins_addr_mis(ins_addr_mis), 	//指令地址错误
    .ins_page_fault(ins_page_fault),	//指令页面错误
    .ld_addr_mis(ld_addr_mis),		//load地址不对齐
    .st_addr_mis(st_addr_mis),		//store地址不对齐
    .ld_acc_fault(ld_acc_fault),	//load访问失败
    .st_acc_fault(st_acc_fault),	//store访问失败
    .ld_page_fault(ld_page_fault),	//load页面错误
    .st_page_fault(st_page_fault),	//store页面错误
    .int_acc(int_acc),			//中断接收信号
    .valid(valid), 			//指令有效信号
    .ill_ins(ill_ins),			//异常指令信号
    .m_ret(m_ret),			//返回信号
    .s_ret(s_ret),			//
    .ecall(ecall),			//环境调用
    .ebreak(ebreak)			//断点

    .mepc(mepc)
);


endmodule






















