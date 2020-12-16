`include  "global_defines.vh"
//基于PRV464的指令解码单元
//支持RV32IA+4G32E扩展指令解码
//特别注意 RISCV的J和B的立即数编码是混乱的（大草）
module ins_dec(

input wire clk,
input wire rst,

//csr
input wire CSR_tvm,
input wire CSR_tsr,
input wire CSR_tw,
input wire [63:0]CSR_data,
//GPR输入
input wire [31:0]GPR_rs1_data,
input wire [31:0]GPR_rs2_data,

input wire [31:0]FREG_fs1_data,
input wire [31:0]FREG_fs2_data,

input wire [127:0]VREG_vs1_data,
input wire [127:0]VREG_vs2_data,
//上一级（IF）信号
//指令输出
input wire [31:0]IDi_DATA_instruction,
//指令对应的PC值输出
input wire [63:0]IDi_DATA_pc,
//机器控制段
input wire IDi_MSC_ins_acc_fault,	//指令访问失败
input wire IDi_MSC_ins_addr_mis, 	//指令地址错误
input wire IDi_MSC_ins_page_fault,	//指令页面错误
input wire IDi_MSC_interrupt,		//中断接收信号
input wire IDi_MSC_valid,			//指令有效信号
//流控信号
output wire IDo_FC_hold,
output wire IDo_FC_nop,
input wire IDi_FC_system,

//下一级（EX）信号
//异常码
//当非法指时候，该码被更新为ins，当指令页面错误，被更新为addr
output reg [63:0]IDo_DATA_trap_value,
//当前指令pc
output reg [63:0]IDo_DATA_pc,

//操作码 ALU,运算码
//rd数据选择
output reg IDo_OP_ALU_ds1,		//ds1直通
output reg IDo_OP_ALU_add,		//加
output reg IDo_OP_ALU_sub,		//减
output reg IDo_OP_ALU_and,		//逻辑&
output reg IDo_OP_ALU_or,		//逻辑|
output reg IDo_OP_ALU_xor,		//逻辑^
output reg IDo_OP_ALU_slt,		//比较大小
output reg IDo_OP_ALU_compare,		//比较大小，配合IDo_OP_ALU_bge0_IDo_OP_ALU_blt1\IDo_OP_ALU_beq0_IDo_OP_ALU_bne1控制线并产生分支信号
output reg IDo_OP_ALU_amo_lrsc,		//lr/sc读写成功标志
//VPU操作码
output reg IDo_OP_VPU_ifsel,//Function integer/float select
output reg IDo_OP_VPU_addsel,
output reg IDo_OP_VPU_subsel,
output reg IDo_OP_VPU_mulsel,
output reg IDo_OP_VPU_itfsel, //integer to float
output reg IDo_OP_VPU_ftisel, //float to integer
output reg IDo_OP_VPU_laneop,
output reg IDo_OP_VPU_maxsel,
output reg IDo_OP_VPU_minsel,
output reg IDo_OP_VPU_andsel,		//逻辑&
output reg IDo_OP_VPU_orsel,		//逻辑|
output reg IDo_OP_VPU_xorsel,
output reg IDo_OP_VPU_srasel,
output reg IDo_OP_VPU_srlsel,
output reg IDo_OP_VPU_sllsel,
output reg IDo_OP_VPU_cgqsel,//IDo_OP_ALU_compare:great equal
output reg IDo_OP_VPU_cltsel,
output reg IDo_OP_VPU_ceqsel,
output reg IDo_OP_VPU_cnqsel,
output reg IDo_OP_VPU_enable,
output reg IDo_OP_VPU_memacc,
output reg IDo_OP_VPU_memrd ,
output reg IDo_OP_VPU_memwr ,
output reg IDo_OP_VPU_masken,
output reg IDo_OP_VPU_vecen,
//mem_CSR_data数据选择
output reg IDo_OP_csr_mem_ds1,
output reg IDo_OP_csr_mem_ds2,
output reg IDo_OP_csr_mem_add,
output reg IDo_OP_csr_mem_and,
output reg IDo_OP_csr_mem_or,
output reg IDo_OP_csr_mem_xor,
output reg IDo_OP_csr_mem_max,
output reg IDo_OP_csr_mem_min,
//运算,跳转辅助控制信号
output reg IDo_OP_ALU_blt,				//条件跳转，IDo_OP_ALU_blt IDo_OP_ALU_bltu指令时为1
output reg IDo_OP_ALU_bge,
output reg IDo_OP_ALU_beq,				//条件跳转，IDo_OP_ALU_bne指令时为一
output reg IDo_OP_ALU_bne,				//
output reg IDo_OP_ALU_jmp,				//无条件跳转，适用于JAL JALR指令
output reg IDo_OP_ALU_unsign,			//无符号操作，同时控制mem单元信号的符号
output reg IDo_OP_ALU_clr,				//将csr操作的and转换为clr操作
output reg IDo_OP_ds1_sel,				//ALU ds1选择，为0选择ds1，为1选择MEM读取信号
output reg IDo_OP_ALU_mdiv,				//ALU选择输出乘除
//M extension
output reg IDo_OP_MDIV_mdivsel,			//0=MUL 1=DIV		
output reg IDo_OP_MDIV_hlowsel,			//0=LOW XLEN	1=HIGH XLEN
output reg IDo_OP_MDIV_signsel,			//0=SIGNED		1=UNSIGN

//位宽控制
output reg [3:0]IDo_OP_size, 			//0001:1Byte 0010:2Byte 0100=4Byte 1000=8Byte
//多周期控制
//多周期控制信号线控制EX单元进行多周期操作
output reg IDo_OP_MC_load,
output reg IDo_OP_MC_store,
output reg IDo_OP_MC_amo,
output reg IDo_OP_MC_L1i_flush,	//缓存刷新信号，此信号可以与内存进行同步
output reg IDo_OP_MC_L1d_flush,		//缓存复位信号，下次访问内存时重新刷新页表
//output reg TLB_reset,		//TLB复位
output reg IDo_OP_MC_L1d_sync,	//强制L1D写回
output reg IDo_OP_ALU_div,		
output reg IDo_OP_ALU_ShiftRight,	//左移位
output reg IDo_OP_ALU_ShiftLeft,		//右移位

//写回控制，当valid=0时候，所有写回不有效
output reg IDo_WB_CSRwrite,
output reg IDo_WB_GPRwrite,
output reg IDo_WB_FREGwrite,
output reg IDo_WB_VREGwrite,
output reg [11:0]IDo_WB_CSRindex,
output reg [4:0]IDo_WB_RS1index,
output reg [4:0]IDo_WB_RS2index,
output reg [4:0]IDo_WB_RDindex,
output reg [4:0]IDo_WB_FDindex,
output reg [4:0]IDo_WB_VDindex,
//数据输出							   
output reg [63:0]IDo_DATA_ds1,		//数据源1，imm/rs1/rs1/csr/pc /pc
output reg [63:0]IDo_DATA_ds2,		//数据源2，00 /rs2/imm/imm/imm/04
output reg [31:0]IDo_DATA_fs1,		//数据源1，imm/rs1/rs1/csr/pc /pc
output reg [31:0]IDo_DATA_fs2,
output reg [127:0]IDo_DATA_vs1,		//数据源1，imm/rs1/rs1/csr/pc /pc
output reg [127:0]IDo_DATA_vs2,
output reg [63:0]IDo_DATA_as1,		//地址源1,  pc/rs1/rs1
output reg [63:0]IDo_DATA_as2,		//地址源2, imm/imm/00
output reg [7:0]IDo_DATA_opcount,	//操作次数码，用于移位指令
//机器控制段
//机器控制段负责WB阶段时csr的自动更新

output reg IDo_MSC_ins_acc_fault,	//指令访问失败
output reg IDo_MSC_ins_addr_mis, 	//指令地址错误
output reg IDo_MSC_ins_page_fault,	//指令页面错误
output reg IDo_MSC_interrupt,		//中断接收信号
output reg IDo_MSC_valid, 			//指令有效信号
output reg IDo_MSC_ill_ins,			//异常指令信号
output reg IDo_MSC_mret,			//返回信号
output reg IDo_MSC_sret,
output reg IDo_MSC_ecall,			//环境调用
output reg IDo_MSC_ebreak,			//断点
//到EX信号完

//--------------------流控信号--------------------
//---下一级输入的流控信号---
input wire IDi_FC_hold,				//ID输出保持
input wire IDi_FC_nop,				//ID输出插空
input wire IDi_FC_war,				//出现相关性
//---输出到下一级的流控信号---
output reg IDo_FC_system,			//system指令，op code=system的时候被置1
output reg IDo_FC_jmp,				//会产生跳转的指令 opcode=branch时候置1
//---解码信号-----
output wire IDo_DEC_warcheck,		//war check， war输出想关心检查enable
output wire [4:0]IDo_DEC_rs1index,	//立即解码得到的rs1index
output wire [4:0]IDo_DEC_rs2index,
output wire [4:0]IDo_DEC_fs1index,	//立即解码得到的rs1index
output wire [4:0]IDo_DEC_fs2index,
output wire [4:0]IDo_DEC_vs1index,	//立即解码得到的rs1index
output wire [4:0]IDo_DEC_vs2index,
output wire [4:0]IDo_DEC_rdindex,
output wire [11:0]IDo_DEC_csrindex

);
//opcode译码参数,RV低7位是操作码
parameter lui_encode 	= 7'b0110111;
parameter auipc_encode	= 7'b0010111;
parameter jal_encode	= 7'b1101111;
parameter jalr_encode	= 7'b1100111;
parameter branch_encode	= 7'b1100011;
parameter load_encode 	= 7'b0000011;
parameter store_encode	= 7'b0100011;
parameter imm_encode	= 7'b0010011;
parameter imm_32_encode = 7'b0011011;
parameter reg_encode	= 7'b0110011;	//R type指令opcode
parameter reg_32_encode = 7'b0111011;	
parameter mem_encode	= 7'b0001111;	//MISC-MEM指令OPCODE，
parameter system_encode = 7'b0001111;	
parameter amo_encode	= 7'b0101111;
parameter m_32_encode	= 7'b0111011;

//IDo_OP_size参数
parameter sbyte_size	= 4'b0001;		//Singal Byte
parameter dbyte_size	= 4'b0010;		//Double Byte
parameter qbyte_size	= 4'b0100;		//Quad Byte
parameter obyte_size	= 4'b1000;		//Octal Byte
//权限参数
parameter user = 4'b0001;
parameter supe = 4'b0010;
parameter mach = 4'b1000;

//设计非标准GPU指令扩展，占用加长指令/扩展指令槽
parameter custom0_encode=7'b0001011; //group load store
parameter custom1_encode=7'b0101011; //CMP/SFunc
parameter custom2_encode=7'b1011011; //
parameter custom3_encode=7'b1111011; //
parameter longinstr_encode=5'b11111; //Masked-SIMD运算指令槽

//opcode译码
wire [6:0]opcode;
assign opcode=IDi_DATA_instruction[6:0];
wire op_system;		//CSR操作指令
wire op_imm;		//立即数操作指令（I type）
wire op_32_imm;
wire op_lui;		//lui指令
wire op_auipc;		//auipc指令
wire op_jal;
wire op_jalr;
wire op_branch;		//分支指令 (B type)
wire op_store;
wire op_load;
wire op_reg;		//寄存器操作指令（R type）
wire op_32_reg;
wire op_amo;
wire op_m;			// 内存屏障指令
wire op_gpu_scalc;
wire op_gpu_mfunc;
wire op_gpu_sldst;
//funct3译码
wire [2:0]funct3;
assign funct3=IDi_DATA_instruction[14:12];
wire funct3_0; 
wire funct3_1;
wire funct3_2;
wire funct3_3;
wire funct3_4;
wire funct3_5;
wire funct3_6;
wire funct3_7;
//funct5译码
wire [4:0]funct5;
assign funct5=IDi_DATA_instruction[31:27];
wire funct5_0;
wire funct5_1;
wire funct5_2;
wire funct5_3;
wire funct5_4;
wire funct5_5;
wire funct5_6;
wire funct5_7;
wire funct5_8;
wire funct5_9;
wire funct5_10;
wire funct5_11;
wire funct5_12;
wire funct5_13;
wire funct5_14;
wire funct5_15;
wire funct5_16;
wire funct5_17;
wire funct5_18;
wire funct5_19;
wire funct5_20;
wire funct5_21;
wire funct5_22;
wire funct5_23;
wire funct5_24;
wire funct5_25;
wire funct5_26;
wire funct5_27;
wire funct5_28;
wire funct5_29;
wire funct5_30;
wire funct5_31;
//funct6译码	funct6是移位指令用的
wire [5:0]funct6;
assign funct6=IDi_DATA_instruction[31:25];
wire funct6_0;
wire funct6_16;
//funct7译码
wire [6:0]funct7;
assign funct7=IDi_DATA_instruction[31:25];
wire funct7_32;
wire funct7_24;
wire funct7_8;
wire funct7_9;
wire funct7_0;

//funct12译码
wire [11:0]funct12;
assign funct12=IDi_DATA_instruction[31:20];
wire funct12_0;
wire funct12_1;
//立即数译码
wire [63:0]imm20;		//LUI，AUIPC指令使用的20位立即数（进行符号位拓展）
wire [63:0]imm20_jal;	//jal指令使用的20位立即数，左移一位，高位进行符号拓展
wire [63:0]imm12_i;		//I-type，L-type指令使用的12位立即数（进行符号位拓展）
wire [63:0]imm12_b;		//b-type指令使用的12位立即数（进行符号位拓展）
wire [63:0]imm12_s;		//S-type指令使用的12位立即数（进行符号位拓展）
wire [63:0]imm5_csr;	//csr指令使用的5位立即数，高位补0
//操作大小译码
wire sbyte;				//单字节
wire dbyte;				//双字节
wire qbyte;				//四字节
wire obyte;				//8字节
//操作次数译码
wire [7:0]op_count_decode;	//操作次数译码，用于移位指令
//指令译码
//RV32I
wire ins_lui;	
wire ins_auipc;
wire ins_jal;
wire ins_jalr;
wire ins_beq;
wire ins_bne;
wire ins_blt;
wire ins_bge;
wire ins_bltu;
wire ins_bgeu;
wire ins_lb;
wire ins_lbu;
wire ins_lh;
wire ins_lhu;
wire ins_lw;

wire ins_sb;
wire ins_sh;
wire ins_sw;

wire ins_addi;

wire ins_slti;
wire ins_sltiu;
wire ins_xori;
wire ins_ori;
wire ins_andi;
wire ins_slli;
wire ins_srli;
wire ins_srai;
wire ins_add;
wire ins_sub;
wire ins_sll;
wire ins_slt;
wire ins_sltu;
wire ins_xor;
wire ins_srl;
wire ins_sra;
wire ins_or;
wire ins_and;
wire ins_fence;		
wire ins_fence_i;	
wire ins_ecall;
wire ins_ebreak;
wire ins_csrrw;
wire ins_csrrs;
wire ins_csrrc;
wire ins_csrrwi;
wire ins_csrrsi;
wire ins_csrrci;
//RV64I ext
wire ins_lwu;
wire ins_ld;
wire ins_sd;
wire ins_addiw;
wire ins_slliw;
wire ins_srliw;
wire ins_sraiw;
wire ins_addw;
wire ins_subw;
wire ins_sllw;
wire ins_srlw;
wire ins_sraw;
//RV32A
wire ins_lrw;
wire ins_scw;
wire ins_amoswapw;
wire ins_amoaddw;
wire ins_amoxorw;
wire ins_amoandw;
wire ins_amoorw;
wire ins_amominw;
wire ins_amomaxw;
wire ins_amominuw;
wire ins_amomaxuw;
//rv64A
wire ins_lrd;
wire ins_scd;
wire ins_amoswapd;
wire ins_amoaddd;
wire ins_amoxord;
wire ins_amoandd;
wire ins_amoord;
wire ins_amomind;
wire ins_amomaxd;
wire ins_amominud;
wire ins_amomaxud;
//RV-M
wire ins_muldiv;
//RV-M64
wire ins_muldivw;
//RV-M Generic decode wires
wire dec_mdivsel;
wire dec_signsel;
wire dec_hlowsel;
//RV-F
wire op_fxcalc;//F EXPENSION REG-REG CALC
wire op_fxload;
wire op_fxstor;
wire op_fmadd;

wire ins_fadd;
wire ins_fsub;
wire ins_fmul;
wire ins_fdiv;
wire ins_fsqt;
wire ins_fmax;
wire ins_fmin;

wire ins_cfti; //FCVT
wire ins_citf;

wire ins_mfti; //FMOV
wire ins_mitf;

wire ins_fsgnj;

wire ins_fcmp;
wire dec_fclt;
wire dec_fceq;
wire dec_fcle;

//GPU vector calc
wire gins_sfadd;
wire gins_sfsub;
wire gins_sfmul;
wire gins_sadd;
wire gins_ssub;
wire gins_sand;
wire gins_sor;
wire gins_sxor;
wire gins_slsh;
wire gins_srsa;
wire gins_srsl;
//GPU convert&pick&IDo_OP_ALU_compare
wire gins_sfti;//convert
wire gins_sitf;
wire gins_smax;//pick max/min
wire gins_smin;
wire gins_scgq;//IDo_OP_ALU_compare and generate mask
wire gins_sclt;
wire gins_sceq;
wire gins_scnq;
wire gins_slan;//lane operation
wire gins_sload;//load store
wire gins_sstor;
wire gins_forcesync;
wire gins_loop;
wire gins_lbrk;
//Graphic: float writeback
wire gmod_float;
//模式特权指令
wire ins_mret;
wire ins_sret;
wire ins_sfencevma;
wire ins_wfi;

//异常指令解码信号
wire dec_csr_acc_fault;		//访问不该访问的csr
wire dec_ins_unpermit;		//指令不被允许执行
wire dec_ins_dec_fault;		//指令解码失败

wire dec_ill_ins;			//解码之后发现非法指令

wire unexecute_instruction;	//不可执行的指令

wire dec_gpr_write;		//GPR write
wire dec_freg_write;
wire dec_vreg_write;
wire dec_system_mem;
wire dec_branch;			//instructions which will cause branch/jump


//GPU寄存器操作指令集
wire vinst_type,vmask_en;//vector related instr flags
wire [4:0]mask_reg;//向量：16b x 8lane
assign vinst_type=funct3[0];//向量指令是向量+向量or向量+标量
assign vmask_en=funct3[1];//使能向量mask功能（屏蔽向量执行）
//assign vtype_en=;//向量指令指示
assign mask_reg={funct7[1:0],funct3[2],IDi_DATA_instruction[6:5]};//从标量（整数）寄存器中取mask
//32 non-mask+32条masked向量GPU指令

//判断是否需要将ALU输入源ds1转换为MEM单元的数据
wire ds1_mem_iden;
assign ds1_mem_iden = ins_amoswapd|ins_amoswapw|ins_amoaddw|ins_amoaddd|ins_amoxorw|ins_amoxord
		|ins_amoandw|ins_amoandd|ins_amoorw|ins_amoord|ins_amominw|ins_amomind|
		ins_amomaxw|ins_amomaxd||ins_amomaxd|ins_amomaxud|ins_amomind|ins_amominud|
		ins_lb|ins_lbu|ins_lh|ins_lhu|ins_lw|ins_lwu|ins_ld|ins_lrw|ins_lrd;

//首先对opcode进行译码
assign op_system	= (opcode==system_encode);
assign op_imm		= (opcode==imm_encode);
assign op_32_imm	= (opcode==imm_32_encode);
assign op_lui		= (opcode==lui_encode);
assign op_auipc		= (opcode==auipc_encode);
assign op_jal		= (opcode==jal_encode);
assign op_jalr		= (opcode==jalr_encode);
assign op_branch	= (opcode==branch_encode);
assign op_load		= (opcode==load_encode);
assign op_store		= (opcode==store_encode);
assign op_reg		= (opcode==reg_encode);
assign op_32_reg	= (opcode==reg_32_encode);
assign op_amo		= (opcode==amo_encode);

assign op_m			= (opcode==mem_encode);
//TODO GPU OPERATIONS
assign op_gpu_scalc = (opcode[4:0]==longinstr_encode);
assign op_gpu_mfunc=  (opcode==custom1_encode);
assign op_gpu_sldst=  (opcode==custom0_encode);
//对funct3译码
assign funct3_0		= (funct3==3'h0);
assign funct3_1		= (funct3==3'h1);
assign funct3_2		= (funct3==3'h2);
assign funct3_3		= (funct3==3'h3);
assign funct3_4		= (funct3==3'h4);
assign funct3_5		= (funct3==3'h5);
assign funct3_6		= (funct3==3'h6);
assign funct3_7		= (funct3==3'h7);
//funct5
assign funct5_0		= (funct5==5'h00);
assign funct5_1		= (funct5==5'h01);
assign funct5_2		= (funct5==5'h02);
assign funct5_3		= (funct5==5'h03);
assign funct5_4		= (funct5==5'h04);
assign funct5_5		= (funct5==5'h05);
assign funct5_6		= (funct5==5'h06);
assign funct5_7		= (funct5==5'h07);
assign funct5_8		= (funct5==5'h08);
assign funct5_9		= (funct5==5'h09);
assign funct5_10	= (funct5==5'h0a);
assign funct5_11	= (funct5==5'h0b);
assign funct5_12	= (funct5==5'h0c);
assign funct5_13	= (funct5==5'h0d);
assign funct5_14	= (funct5==5'h0e);
assign funct5_15	= (funct5==5'h0f);
assign funct5_16	= (funct5==5'h10);
assign funct5_17	= (funct5==5'h11);
assign funct5_18	= (funct5==5'h12);
assign funct5_19	= (funct5==5'h13);
assign funct5_20	= (funct5==5'h14);
assign funct5_21	= (funct5==5'h15);
assign funct5_22	= (funct5==5'h16);
assign funct5_23	= (funct5==5'h17);
assign funct5_24	= (funct5==5'h18);
assign funct5_25	= (funct5==5'h19);
assign funct5_26	= (funct5==5'h1a);
assign funct5_27	= (funct5==5'h1b);
assign funct5_28	= (funct5==5'h1c);
assign funct5_29	= (funct5==5'h1d);
assign funct5_30	= (funct5==5'h1e);
assign funct5_31	= (funct5==5'h1f);
//funct6
assign funct6_0		= (funct6==6'b000000);
assign funct6_16	= (funct6==6'b010000);
//funct7译码
assign funct7_0		= (funct7==7'h00);
assign funct7_8		= (funct7==7'h08);
assign funct7_9		= (funct7==7'h09);
assign funct7_24	= (funct7==7'h18);
assign funct7_32	= (funct7==7'h20);

//funct12译码
assign funct12_0	= (funct12==12'h0);
assign funct12_1	= (funct12==12'h1);
//指令解码
assign ins_lui 		= op_lui;
assign ins_auipc 	= op_auipc;
assign ins_jal		= op_jal;
assign ins_jalr		= op_jalr;
assign ins_beq		= op_branch&funct3_0;
assign ins_bne		= op_branch&funct3_1;
assign ins_blt		= op_branch&funct3_4;
assign ins_bge		= op_branch&funct3_5;
assign ins_bltu		= op_branch&funct3_6;
assign ins_bgeu		= op_branch&funct3_7;
assign ins_lb		= op_load&funct3_0;
assign ins_lh		= op_load&funct3_1;
assign ins_lw		= op_load&funct3_2;
assign ins_lbu		= op_load&funct3_4;
assign ins_lhu		= op_load&funct3_5;
assign ins_sb		= op_store&funct3_0;
assign ins_sh		= op_store&funct3_1;
assign ins_sw		= op_store&funct3_2;
assign ins_addi		= op_imm&funct3_0;
assign ins_slti		= op_imm&funct3_2;
assign ins_sltiu	= op_imm&funct3_3;
assign ins_xori		= op_imm&funct3_4;
assign ins_ori		= op_imm&funct3_6;
assign ins_andi		= op_imm&funct3_7;
assign ins_slli		= op_imm&funct3_1&funct6_0;
assign ins_srli		= op_imm&funct3_5&funct6_0;
assign ins_srai		= op_imm&funct3_5&funct6_16;
assign ins_add		= op_reg&funct3_0&funct7_0;
assign ins_sub		= op_reg&funct3_0&funct7_32;
assign ins_sll		= op_reg&funct3_1&funct7_0;
assign ins_slt		= op_reg&funct3_2&funct7_0;
assign ins_sltu		= op_reg&funct3_3&funct7_0;
assign ins_xor		= op_reg&funct3_4&funct7_0;
assign ins_srl		= op_reg&funct3_5&funct7_0;
assign ins_sra		= op_reg&funct3_5&funct7_32;
assign ins_or		= op_reg&funct3_6&funct7_0;
assign ins_and		= op_reg&funct3_7&funct7_0;
assign ins_fence	= op_m&funct3_0;
assign ins_fence_i	= op_m&funct3_1;	
assign ins_ecall	= op_system&funct3_0&funct12_0;
assign ins_ebreak	= op_system&funct3_0&funct12_1;
assign ins_csrrw	= op_system&funct3_1;
assign ins_csrrs	= op_system&funct3_2;
assign ins_csrrc	= op_system&funct3_3;
assign ins_csrrwi	= op_system&funct3_5;
assign ins_csrrsi	= op_system&funct3_6;
assign ins_csrrci	= op_system&funct3_7;
//rv64i译码
assign ins_lwu		= op_load&funct3_6;
assign ins_ld		= op_load&funct3_3;
assign ins_sd		= op_store&funct3_3;
assign ins_addiw	= op_32_imm&funct3_0;
assign ins_slliw	= op_32_imm&funct3_1&funct7_0;
assign ins_srliw	= op_32_imm&funct3_5&funct7_0;
assign ins_sraiw	= op_32_imm&funct3_5&funct7_32;
assign ins_addw		= op_32_reg&funct3_0&funct7_0;
assign ins_subw		= op_32_reg&funct3_0&funct7_32;
assign ins_sllw		= op_32_reg&funct3_1&funct7_0;
assign ins_srlw		= op_32_reg&funct3_5&funct7_0;
assign ins_sraw		= op_32_reg&funct3_5&funct7_32;
//amo32译码
assign ins_lrw		= op_amo&funct3_2&funct5_2;
assign ins_scw		= op_amo&funct3_2&funct5_3;
assign ins_amoswapw	= op_amo&funct3_2&funct5_1;
assign ins_amoaddw	= op_amo&funct3_2&funct5_0;
assign ins_amoxorw	= op_amo&funct3_2&funct5_4;
assign ins_amoandw	= op_amo&funct3_2&funct5_12;
assign ins_amoorw	= op_amo&funct3_2&funct5_8;
assign ins_amominw	= op_amo&funct3_2&funct5_16;
assign ins_amomaxw	= op_amo&funct3_2&funct5_20;
assign ins_amominuw	= op_amo&funct3_2&funct5_24;
assign ins_amomaxuw	= op_amo&funct3_2&funct5_28;
//amo64译码
assign ins_lrd		= op_amo&funct3_3&funct5_2;
assign ins_scd		= op_amo&funct3_3&funct5_3;
assign ins_amoswapd	= op_amo&funct3_3&funct5_1;
assign ins_amoaddd	= op_amo&funct3_3&funct5_0;
assign ins_amoxord	= op_amo&funct3_3&funct5_4;
assign ins_amoandd	= op_amo&funct3_3&funct5_12;
assign ins_amoord	= op_amo&funct3_3&funct5_8;
assign ins_amomind	= op_amo&funct3_3&funct5_16;
assign ins_amomaxd	= op_amo&funct3_3&funct5_20;
assign ins_amominud	= op_amo&funct3_3&funct5_24;
assign ins_amomaxud	= op_amo&funct3_3&funct5_28;

assign ins_muldiv	= op_reg&(funct7==7'h01);
assign ins_muldivw  = op_32_reg&(funct7==7'h01);
assign dec_mdivsel	= funct3[2];
assign dec_hlowsel	= (funct3[2:1]==2'b11)|(funct3[2]==0&(funct3[1:0]!=2'b00));
assign dec_signsel	= (funct3[2:1]==2'b01)|({funct3[2],funct3[0]}==2'b11);
//特权指令译码
assign ins_mret		= op_system&(IDo_DEC_rs2index==5'b00010)&funct7_24;
assign ins_sret		= op_system&(IDo_DEC_rs2index==5'b00010)&funct7_8;
assign ins_sfencevma= op_system&funct7_9;
assign ins_wfi		= op_system&funct7_8;								//wfi指令

//TODO: GPU decode
//GPU vector calc
assign gins_sfadd=op_gpu_scalc&funct5_0 ;
assign gins_sfsub=op_gpu_scalc&funct5_1 ;
assign gins_sfmul=op_gpu_scalc&funct5_2 ;
assign gins_sadd=op_gpu_scalc&funct5_16 ;
assign gins_ssub=op_gpu_scalc&funct5_17 ;
assign gins_sand=op_gpu_scalc&funct5_18 ;
assign gins_sor=op_gpu_scalc&funct5_19 ;
assign gins_sxor=op_gpu_scalc&funct5_20 ;
assign gins_slsh=op_gpu_scalc&funct5_21 ;
assign gins_srsa=op_gpu_scalc&funct5_22 ;
assign gins_srsl=op_gpu_scalc&funct5_23 ;
//GPU convert&pick&IDo_OP_ALU_compare
assign gins_sfti=op_gpu_mfunc&(funct7==7'h08);//convert
assign gins_sitf=op_gpu_mfunc&(funct7==7'h09);
assign gins_smax=op_gpu_mfunc&(funct7==7'h0c);//pick max/min
assign gins_smin=op_gpu_mfunc&(funct7==7'h0d);
assign gins_scgq=op_gpu_mfunc&(funct7==7'h10);//IDo_OP_ALU_compare and generate mask
assign gins_sclt=op_gpu_mfunc&(funct7==7'h11);
assign gins_sceq=op_gpu_mfunc&(funct7==7'h12);
assign gins_scnq=op_gpu_mfunc&(funct7==7'h13);
assign gins_slan=op_gpu_mfunc&(funct7==7'h7F);//lane operation
assign gins_forcesync=op_gpu_mfunc&(funct7==7'h78);
assign gins_loop=op_gpu_mfunc&(funct7==7'h77);//HW loop
assign gins_lbrk=op_gpu_mfunc&(funct7==7'h78);//breakloop
assign gins_sload=op_gpu_sldst&(!funct3[0]);//load store
assign gins_sstor=op_gpu_sldst&(funct3[0]);

//译出立即数
assign imm20 	= {{32{IDi_DATA_instruction[31]}},IDi_DATA_instruction[31:12],12'b0};				//LUI，AUIPC指令使用的20位立即数（进行符号位拓展）
assign imm20_jal= {{44{IDi_DATA_instruction[31]}},IDi_DATA_instruction[19:12],IDi_DATA_instruction[20],IDi_DATA_instruction[30:21],1'b0};				//jal指令使用的20位立即数，左移一位，高位进行符号拓展
assign imm12_i	= {{52{IDi_DATA_instruction[31]}},IDi_DATA_instruction[31:20]};						//I-type，L-type指令使用的12位立即数（进行符号位拓展）
assign imm12_b	= {{52{IDi_DATA_instruction[31]}},IDi_DATA_instruction[7],IDi_DATA_instruction[30:25],IDi_DATA_instruction[11:8],1'b0};	//b-type指令使用的12位立即数（进行符号位拓展）
assign imm12_s	= {{52{IDi_DATA_instruction[31]}},IDi_DATA_instruction[31:25],IDi_DATA_instruction[11:7]};		//S-type指令使用的12位立即数（进行符号位拓展）

assign imm5_csr = {59'b0,IDi_DATA_instruction[11:7]};									//csr指令使用的5位立即数，高位补0


//操作大小译码
assign sbyte 	= ins_lb|ins_lbu|ins_sb;													//单字节
assign dbyte	= ins_lh|ins_lhu|ins_sh;													//双字节
assign qbyte	= ins_lw|ins_lwu|ins_sw|op_32_imm|op_32_reg|(op_amo&funct3_2);				//四字节
assign obyte	= !(sbyte|dbyte|qbyte);														//124字节不是，那当然是8字节操作

assign op_count_decode	= 		(ins_slliw|ins_srliw|ins_sraiw)?{3'b0,IDo_DEC_rs2index}:
								(ins_slli|ins_srli|ins_srai)?{3'b0,IDi_DATA_instruction[24:20]}:
								{2'b0,GPR_rs2_data[5:0]};//注意！RV64的移位立即数编码

//-------------------译出当前指令是否需要多周期--------------------
//-------------需要多周期的opcode： 内存组织&system----------------
assign dec_system_mem		= IDi_MSC_valid & (op_system | op_m | dec_ill_ins);
assign dec_branch			= IDi_MSC_valid & (op_branch | ins_jalr | ins_jal);

/*-------------------------------------------------------
译出当前指令是否需要写回寄存器
branch,IDo_OP_MC_store,fence指令没有写回，其他均要写回
注意，在这里译码其实忽略了一些指令也不需要写回寄存器，
但是因为那些指令的RD都是X0寄存器，
X0是常数0寄存器，写回之后毫无影响，故忽略 
----------------------------------------------------------*/
assign dec_gpr_write		= !(op_branch|op_store|ins_fence|ins_mret|ins_sret) & !dec_ill_ins;
assign dec_freg_write		= op_fxcalc|op_fxload;
assign dec_vreg_write		= op_gpu_scalc|gins_sload;

//-----译出当前是否为异常指令-----
//-----译出当前指令是否访问了不该访问的csr----
assign dec_csr_acc_fault= 1'b0;
//-----译出不允许被执行的指令-----
//当CSR_tsr CSR_tvm CSR_tw位为1时候，执行这些指令会被禁止,并且SRET指令不允许在M模式下被执行
		
//TODO:GPU译码这里也要改				  
assign dec_ins_dec_fault= !(op_system|op_imm|op_32_imm|op_lui|op_auipc|op_jal|op_jalr|op_branch|op_store|op_load|op_reg|op_32_reg|op_amo|op_gpu_scalc);
assign dec_ill_ins		= IDi_MSC_valid & (dec_csr_acc_fault | dec_ins_dec_fault);//异常指令
//指令错误 不能操作
assign unexecute_instruction	=	dec_ill_ins | IDi_MSC_ins_acc_fault | IDi_MSC_ins_addr_mis | IDi_MSC_ins_page_fault;
//TODO GPU 指令译码信号输出部分
wire gpu_ifsel;
assign gpu_ifsel=(op_gpu_scalc&(!funct5[4]))|(op_gpu_mfunc&funct3[2]);
//流控信号
//所有的流控信号均为串联结构，由PRV464SXR处理器的实现教训中学习而来
assign IDo_DEC_warcheck	=	IDi_MSC_valid & dec_gpr_write;
assign IDo_DEC_rs1index	=	(op_jal|op_jalr|op_lui|op_auipc) ? 5'b0 :(IDi_DATA_instruction[19:15]);		//立即解码得到的rs1index
assign IDo_DEC_rs2index	=	(op_reg|op_32_reg|op_branch|op_store|op_amo)?(IDi_DATA_instruction[24:20]) : 
							(op_gpu_scalc|op_gpu_sldst|op_gpu_mfunc) ? mask_reg : 5'b0;
assign IDo_DEC_fs1index =	(1'b0) ? 5'b0 :(IDi_DATA_instruction[19:15]);
assign IDo_DEC_fs2index =	(1'b0) ? 5'b0 :(IDi_DATA_instruction[24:20]);
assign IDo_DEC_vs1index =	(op_gpu_scalc|op_gpu_sldst|op_gpu_mfunc) ? (IDi_DATA_instruction[19:15]) :5'b0;
assign IDo_DEC_vs2index =	(op_gpu_scalc|op_gpu_sldst|op_gpu_mfunc) ? (IDi_DATA_instruction[24:20]) : 5'b0;
assign IDo_DEC_rdindex	=	(IDi_DATA_instruction[11:7]);
assign IDo_DEC_csrindex	=	(IDi_DATA_instruction[31:20]);
assign IDo_FC_hold		=	IDi_FC_hold;
//-----------如果后一级要求nop，或者本级出现了异常操作，则直接要求停止取指令------------
assign IDo_FC_nop		=	IDi_FC_nop | IDi_FC_system | dec_system_mem | dec_branch;


//输出寄存器，往EX
always@(posedge clk)begin
	if(rst)begin
	//操作码 ALU,运算码
	//rd数据选择
		IDo_OP_ALU_ds1		<= 1'b0;		//ds1直通	
		IDo_OP_ALU_add		<= 1'b0;		//加
		IDo_OP_ALU_sub		<= 1'b0;
		IDo_OP_ALU_and		<= 1'b0;		//逻辑&
		IDo_OP_ALU_or		<= 1'b0;		//逻辑|
		IDo_OP_ALU_xor		<= 1'b0;		//逻辑^
		IDo_OP_ALU_slt		<= 1'b0;		//比较大小
		IDo_OP_ALU_compare	<= 1'b0;
		IDo_OP_ALU_amo_lrsc	<= 1'b0;		//lr/sc读写成功标志
		IDo_OP_ALU_mdiv		<= 1'b0;
		IDo_OP_MDIV_hlowsel	<= 1'b0;
		IDo_OP_MDIV_mdivsel	<= 1'b0;
		IDo_OP_MDIV_signsel	<= 1'b0;
//mem_CSR_data数据选择
		IDo_OP_csr_mem_ds1	<= 1'b0;
		IDo_OP_csr_mem_ds2	<= 1'b0;
		IDo_OP_csr_mem_add	<= 1'b0;
		IDo_OP_csr_mem_and	<= 1'b0;
		IDo_OP_csr_mem_or	<= 1'b0;
		IDo_OP_csr_mem_xor	<= 1'b0;
		IDo_OP_csr_mem_max	<= 1'b0;
		IDo_OP_csr_mem_min	<= 1'b0;
		IDo_OP_VPU_ifsel<=1'b0;//Function integer/float select
		IDo_OP_VPU_addsel<=1'b0;
		IDo_OP_VPU_subsel<=1'b0;
		IDo_OP_VPU_mulsel<=1'b0;
		IDo_OP_VPU_itfsel<=1'b0; //integer to float
		IDo_OP_VPU_ftisel<=1'b0; //float to integer
		IDo_OP_VPU_laneop<=1'b0;
		IDo_OP_VPU_maxsel<=1'b0;
		IDo_OP_VPU_minsel<=1'b0;
		IDo_OP_VPU_andsel<=1'b0;		//逻辑&
		IDo_OP_VPU_orsel<=1'b0;		//逻辑|
		IDo_OP_VPU_xorsel<=1'b0;
		IDo_OP_VPU_srasel<=1'b0;
		IDo_OP_VPU_srlsel<=1'b0;
		IDo_OP_VPU_sllsel<=1'b0;
		IDo_OP_VPU_cgqsel<=1'b0;//IDo_OP_ALU_compare:great equal
		IDo_OP_VPU_cltsel<=1'b0;
		IDo_OP_VPU_ceqsel<=1'b0;
		IDo_OP_VPU_cnqsel<=1'b0;
		IDo_OP_VPU_enable<=1'b0;
		IDo_OP_VPU_memacc<=1'b0;
		IDo_OP_VPU_memrd <=1'b0;
		IDo_OP_VPU_memwr <=1'b0;
		IDo_OP_VPU_masken<=1'b0;
		IDo_OP_VPU_vecen <=1'b0;
	end
	//当进行hold的时候，输出寄存器均被保持
	else if(IDi_FC_hold)begin
	//操作码 ALU,运算码
	//rd数据选择
		IDo_OP_ALU_ds1		<= IDo_OP_ALU_ds1;		//ds1直通	
		IDo_OP_ALU_add		<= IDo_OP_ALU_add;		//加
		IDo_OP_ALU_sub		<= IDo_OP_ALU_sub;
		IDo_OP_ALU_and		<= IDo_OP_ALU_and;		//逻辑&
		IDo_OP_ALU_or		<= IDo_OP_ALU_or;		//逻辑|
		IDo_OP_ALU_xor		<= IDo_OP_ALU_xor;		//逻辑^
		IDo_OP_ALU_slt		<= IDo_OP_ALU_slt;		//比较大小
		IDo_OP_ALU_compare	<= IDo_OP_ALU_compare;
		IDo_OP_ALU_amo_lrsc	<= IDo_OP_ALU_amo_lrsc;		//lr/sc读写成功标志位
		IDo_OP_ALU_mdiv		<= IDo_OP_ALU_mdiv;
		IDo_OP_MDIV_hlowsel	<= IDo_OP_MDIV_hlowsel;
		IDo_OP_MDIV_mdivsel	<= IDo_OP_MDIV_mdivsel;
		IDo_OP_MDIV_signsel	<= IDo_OP_MDIV_signsel;
	//mem_CSR_data数据选择
		IDo_OP_csr_mem_ds1	<= IDo_OP_csr_mem_ds1;
		IDo_OP_csr_mem_ds2	<= IDo_OP_csr_mem_ds2;
		IDo_OP_csr_mem_add	<= IDo_OP_csr_mem_add;
		IDo_OP_csr_mem_and	<= IDo_OP_csr_mem_and;
		IDo_OP_csr_mem_or	<= IDo_OP_csr_mem_or;
		IDo_OP_csr_mem_xor	<= IDo_OP_csr_mem_xor;
		IDo_OP_csr_mem_max	<= IDo_OP_csr_mem_max;
		IDo_OP_csr_mem_min	<= IDo_OP_csr_mem_min;

		IDo_OP_VPU_ifsel<=IDo_OP_VPU_ifsel;//Function integer/float select
		IDo_OP_VPU_addsel<=IDo_OP_VPU_addsel;
		IDo_OP_VPU_subsel<=IDo_OP_VPU_subsel;
		IDo_OP_VPU_mulsel<=IDo_OP_VPU_mulsel;
		IDo_OP_VPU_andsel<=IDo_OP_VPU_andsel;		//逻辑&
		IDo_OP_VPU_orsel<=IDo_OP_VPU_orsel;		//逻辑|
		IDo_OP_VPU_xorsel<=IDo_OP_VPU_xorsel;
		IDo_OP_VPU_srasel<=IDo_OP_VPU_srasel;
		IDo_OP_VPU_srlsel<=IDo_OP_VPU_srlsel;
		IDo_OP_VPU_sllsel<=IDo_OP_VPU_sllsel;

		IDo_OP_VPU_itfsel<=IDo_OP_VPU_itfsel; //integer to float
		IDo_OP_VPU_ftisel<=IDo_OP_VPU_ftisel; //float to integer
		IDo_OP_VPU_laneop<=IDo_OP_VPU_laneop;
		IDo_OP_VPU_maxsel<=IDo_OP_VPU_maxsel;
		IDo_OP_VPU_minsel<=IDo_OP_VPU_minsel;
		IDo_OP_VPU_cgqsel<=IDo_OP_VPU_cgqsel;//IDo_OP_ALU_compare:great equal
		IDo_OP_VPU_cltsel<=IDo_OP_VPU_cltsel;
		IDo_OP_VPU_ceqsel<=IDo_OP_VPU_ceqsel;
		IDo_OP_VPU_cnqsel<=IDo_OP_VPU_cnqsel;
		IDo_OP_VPU_enable<=IDo_OP_VPU_enable;
		IDo_OP_VPU_memacc<=IDo_OP_VPU_memacc;
		IDo_OP_VPU_memrd <=IDo_OP_VPU_memrd;
		IDo_OP_VPU_memwr <=IDo_OP_VPU_memwr;
		IDo_OP_VPU_masken<=IDo_OP_VPU_masken;
		IDo_OP_VPU_vecen <=IDo_OP_VPU_vecen ;
	end
	//在没有保持的时候，进行指令解码
	else begin
	//操作码 ALU,运算码
	//rd数据选择
		IDo_OP_ALU_ds1 <= ins_lui|ins_csrrc|ins_csrrci|ins_csrrs|ins_csrrsi|ins_csrrw|ins_csrrwi|ds1_mem_iden;		
		//ds1直通，注意：所有移位指令都在RD寄存器被处理，故移位指令时直接让数据通往RD寄存器
		//所有原子指令，内存访问读取的数据，都通过ds1被送往RD寄存器
		IDo_OP_ALU_add <= ins_auipc|ins_jal|ins_jalr|ins_addi|ins_addiw|ins_add|ins_addw;		//加
		IDo_OP_ALU_sub <= ins_sub|ins_subw;
		IDo_OP_ALU_and <= ins_andi|ins_and;		//逻辑&
		IDo_OP_ALU_or	<= ins_ori|ins_or;			//逻辑|
		IDo_OP_ALU_xor <= ins_xori|ins_xor;		//逻辑^
		IDo_OP_ALU_slt <= ins_slti|ins_sltiu|ins_slt|ins_sltu;		//比较大小
		IDo_OP_ALU_compare		<= op_branch;
		IDo_OP_ALU_amo_lrsc	<= ins_scw|ins_scd;		//lr/sc读写成功标志
		IDo_OP_ALU_mdiv		<= ins_muldiv;
		IDo_OP_MDIV_hlowsel	<= dec_hlowsel;
		IDo_OP_MDIV_mdivsel	<= dec_mdivsel;
		IDo_OP_MDIV_signsel	<= dec_signsel;
	//mem_CSR_data数据选择
		
		IDo_OP_csr_mem_ds2	<= ins_csrrw|ins_csrrwi|ins_scw|ins_scd|ins_amoswapd|ins_amoswapw|ins_sb|ins_sh|ins_sw|ins_sd;
		IDo_OP_csr_mem_add	<= ins_amoaddd|ins_amoaddw;
		IDo_OP_csr_mem_and	<= ins_csrrc|ins_csrrci|ins_amoandd|ins_amoandw;
		IDo_OP_csr_mem_or		<= ins_csrrs|ins_csrrsi|ins_amoord|ins_amoorw;
		IDo_OP_csr_mem_xor	<= ins_amoxord|ins_amoxorw;
		IDo_OP_csr_mem_max	<= ins_amomaxw|ins_amomaxuw|ins_amomaxd|ins_amomaxud;
		IDo_OP_csr_mem_min	<= ins_amominw|ins_amominuw|ins_amomind|ins_amominud;
		IDo_OP_VPU_ifsel<=gpu_ifsel;//Function integer/float select
		IDo_OP_VPU_addsel<=(gins_sadd|gins_sfadd);
		IDo_OP_VPU_subsel<=(gins_ssub|gins_sfsub);
		IDo_OP_VPU_mulsel<=(gins_sfmul);
		IDo_OP_VPU_andsel<=gins_sand;		//逻辑&
		IDo_OP_VPU_orsel<=gins_sor;		//逻辑|
		IDo_OP_VPU_xorsel<=gins_sxor;
		IDo_OP_VPU_srasel<=gins_srsa;
		IDo_OP_VPU_srlsel<=gins_srsl;
		IDo_OP_VPU_sllsel<=gins_slsh;
		IDo_OP_VPU_itfsel<=gins_sitf; //integer to float
		IDo_OP_VPU_ftisel<=(gins_sfti); //float to integer
		IDo_OP_VPU_laneop<=gins_slan;
		IDo_OP_VPU_maxsel<=gins_smax;
		IDo_OP_VPU_minsel<=gins_smin;
		IDo_OP_VPU_cgqsel<=gins_scgq;//IDo_OP_ALU_compare:great equal
		IDo_OP_VPU_cltsel<=gins_sclt;
		IDo_OP_VPU_ceqsel<=gins_sceq;
		IDo_OP_VPU_cnqsel<=gins_scnq;
		IDo_OP_VPU_enable<=op_gpu_mfunc|op_gpu_scalc|op_gpu_sldst;
		IDo_OP_VPU_memacc<=gins_sload|gins_sstor;
		IDo_OP_VPU_memrd <=gins_sload;
		IDo_OP_VPU_memwr <=gins_sstor;
		IDo_OP_VPU_masken<=vmask_en;
		IDo_OP_VPU_vecen <=vinst_type;
	end		
end

//运算辅助控制信号
always@(posedge clk)begin
	if(rst)begin
		IDo_OP_ALU_blt		<= 1'b0;
		IDo_OP_ALU_bge		<= 1'b0;
		IDo_OP_ALU_beq		<= 1'b0;
		IDo_OP_ALU_bne		<= 1'b0;
		IDo_OP_ALU_jmp		<= 1'b0;
		IDo_OP_ALU_unsign 	<= 1'b0;			//无符号操作，同时控制mem单元信号的符号
		IDo_OP_ALU_clr	<= 1'b0;			//将csr操作的and转换为clr操作
		IDo_OP_ds1_sel	<= 1'b0;			//ALU ds1选择，为0选择ds1，为1选择MEM读取信号
		
	end
	else if(IDi_FC_hold)begin
		IDo_OP_ALU_blt		<= IDo_OP_ALU_blt;
		IDo_OP_ALU_bge		<= IDo_OP_ALU_bge;
		IDo_OP_ALU_beq		<= IDo_OP_ALU_beq;
		IDo_OP_ALU_bne		<= IDo_OP_ALU_bne;
		IDo_OP_ALU_jmp		<= IDo_OP_ALU_jmp;
		IDo_OP_ALU_unsign 	<= IDo_OP_ALU_unsign;
		IDo_OP_ALU_clr	<= IDo_OP_ALU_clr;
		IDo_OP_ds1_sel	<= IDo_OP_ds1_sel;
		
	end
	else begin
		IDo_OP_ALU_blt		<= ins_blt|ins_bltu;
		IDo_OP_ALU_bge		<= ins_bge|ins_bgeu;
		IDo_OP_ALU_beq		<= ins_beq;
		IDo_OP_ALU_bne		<= ins_bne;
		IDo_OP_ALU_jmp		<= ins_jal|ins_jalr;
		IDo_OP_ALU_unsign 	<= ins_bltu|ins_bgeu|ins_lbu|ins_lhu|ins_lwu|ins_srai|ins_sraiw|
		ins_sraw|ins_sra|ins_amomaxuw|ins_amomaxud|ins_amominud|ins_amominuw;	//所有要求无符号操作的地方 IDo_OP_ALU_unsign都为1
		IDo_OP_ALU_clr	<= ins_csrrc|ins_csrrci;
		IDo_OP_ds1_sel	<= ds1_mem_iden;		//所有ds1要求被置换为mem的地方，IDo_OP_ds1_sel=1
		
	end
end
//IDo_OP_size
always@(posedge clk)begin
	if(rst | unexecute_instruction)begin
		IDo_OP_size <= qbyte_size;
	end
	else if(IDi_FC_hold)begin
		IDo_OP_size <= IDo_OP_size;
	end
	else begin
		IDo_OP_size[0] <= sbyte;
		IDo_OP_size[1] <= dbyte;
		IDo_OP_size[2] <= qbyte;
		IDo_OP_size[3] <= obyte;
	end
end

//多周期控制&写回控制
//多周期信号只在valid=1时候才会有效，否则无效。
always@(posedge clk)begin
	if(rst)begin
		IDo_OP_MC_load		<= 1'b0;
		IDo_OP_MC_store		<= 1'b0;
		IDo_OP_MC_amo			<= 1'b0;
		IDo_OP_MC_L1i_flush	<= 1'b0;		//缓存刷新信号，此信号可以与内存进行同步
		IDo_OP_MC_L1d_flush	<= 1'b0;		//缓存复位信号，sfence.vma指令使用，下次访问内存时重新刷新页表
		IDo_OP_MC_L1d_sync	<= 1'b0;
		IDo_OP_ALU_div		<= 1'b0;						//右移位
		//IDo_OP_ALU_ShiftLeft		<= 1'b0;						//左移位//写回控制，当valid=0时候，所有写回不有效
		IDo_WB_CSRwrite	<= 1'b0;
		IDo_WB_GPRwrite	<= 1'b0;
		IDo_WB_FREGwrite<= 1'b0;
		IDo_WB_VREGwrite<= 1'b0;
		IDo_WB_CSRindex	<= 12'b0;
		IDo_WB_RS1index	<= 5'b0;
		IDo_WB_RS2index	<= 5'b0;
		
	end
	else if(IDi_FC_hold)begin
		IDo_OP_MC_load		<= IDo_OP_MC_load;
		IDo_OP_MC_store		<= IDo_OP_MC_store;
		IDo_OP_MC_amo			<= IDo_OP_MC_amo;
		IDo_OP_MC_L1i_flush	<= IDo_OP_MC_L1i_flush;	//缓存刷新信号，此信号可以与内存进行同步
		IDo_OP_MC_L1d_flush	<= IDo_OP_MC_L1d_flush;	//缓存复位信号，sfence.vma指令使用，下次访问内存时重新刷新页表
		IDo_OP_MC_L1d_sync	<=	IDo_OP_MC_L1d_sync;
		IDo_OP_ALU_div		<= IDo_OP_ALU_div;		//右移位
		//IDo_OP_ALU_ShiftLeft		<= IDo_OP_ALU_ShiftLeft;		//左移位
		IDo_WB_CSRwrite	<= IDo_WB_CSRwrite;
		IDo_WB_GPRwrite	<= IDo_WB_GPRwrite;
		IDo_WB_FREGwrite	<= IDo_WB_FREGwrite;
		IDo_WB_VREGwrite	<= IDo_WB_VREGwrite;
		IDo_WB_CSRindex	<= IDo_WB_CSRindex;
		IDo_WB_RS1index	<= IDo_WB_RS1index;
		IDo_WB_RS2index	<= IDo_WB_RS2index;

	end
	else begin	
		IDo_OP_MC_load			<= op_load;
		IDo_OP_MC_store			<= op_store;
		IDo_OP_MC_amo			<= op_amo;
		IDo_OP_MC_L1i_flush 	<= ins_fence_i	;		//指令缓存刷新信号，sfence.vma或者fence.i指令使用 
		IDo_OP_MC_L1d_flush		<= ins_fence | ins_fence_i 	;	    //数据缓存刷新信号，sfence.vma或者fence指令使用
		IDo_OP_MC_L1d_sync		<= gins_forcesync;
		IDo_OP_ALU_div			<= (ins_muldiv|ins_muldivw)&dec_mdivsel;	//多周期除法					
		IDo_OP_ALU_ShiftRight	<= ins_srli|ins_srliw|ins_srai|ins_sraiw|ins_srl|ins_srlw|ins_sra|ins_sraw;	//右移位
		IDo_OP_ALU_ShiftLeft	<= ins_slli|ins_slliw|ins_sll|ins_sllw;						//左移位
		IDo_WB_CSRwrite			<= (ins_csrrwi|ins_csrrw|ins_csrrci|ins_csrrc|ins_csrrs|ins_csrrsi)&!dec_ill_ins;	//只有CSRRxx指令且没有发生异常指令才会要求写回CSR
		IDo_WB_GPRwrite			<= dec_gpr_write;	//寄存器要被写回
		IDo_WB_FREGwrite		<= dec_freg_write;
		IDo_WB_VREGwrite		<= dec_vreg_write;
		IDo_WB_CSRindex			<= IDo_DEC_csrindex;
		IDo_WB_RS1index			<= IDo_DEC_rs1index;
		IDo_WB_RS2index			<= IDo_DEC_rs2index;
		IDo_WB_RDindex			<= IDo_DEC_rdindex;
		IDo_WB_FDindex			<= IDo_DEC_rdindex;
		IDo_WB_VDindex			<= IDo_DEC_rdindex;
	end
end
//数据源译码
always@(posedge clk)begin
	if(rst | unexecute_instruction)begin
		//数据输出							   
		IDo_DATA_ds1		<= 64'b0;		//数据源1，imm/rs1/rs1/csr/pc /pc
		IDo_DATA_ds2		<= 64'b0;		//数据源2，00 /rs2/imm/imm/imm/04
		IDo_DATA_as1		<= 64'b0;		//地址源1,  pc/rs1/rs1
		IDo_DATA_as2		<= 64'b0;		//地址源2, imm/imm/00
		IDo_DATA_opcount	<= 8'b0;		//操作次数码，用于AMO指令或移位指令
	end
	else if(IDi_FC_hold)begin
		IDo_DATA_ds1		<= IDo_DATA_ds1;			//数据源1，imm/rs1/rs1/csr/pc /pc
		IDo_DATA_ds2		<= IDo_DATA_ds2;			//数据源2，00 /rs2/imm/imm/imm/04
		IDo_DATA_fs1		<= IDo_DATA_fs1;
		IDo_DATA_fs2		<= IDo_DATA_fs2;
		IDo_DATA_vs1		<= IDo_DATA_vs1;
		IDo_DATA_vs2		<= IDo_DATA_vs2;
		IDo_DATA_as1		<= IDo_DATA_as1;			//地址源1,  pc/rs1/rs1
		IDo_DATA_as2		<= IDo_DATA_as2;			//地址源2, imm/imm/00
		IDo_DATA_opcount	<= IDo_DATA_opcount;	//操作次数码，用于AMO指令或移位指令
	end
	//此部分内容参考 Table_ID_DAS
	else begin
		IDo_DATA_ds1 	<= 	(ins_lui										?	imm20	:	64'b0)|
							((op_branch|op_reg|op_32_reg|op_imm|op_32_imm)	?	GPR_rs1_data:	64'b0)|
							(op_system										?	CSR_data:	64'b0)|
							((ins_auipc|ins_jal|ins_jalr)					?	IDi_DATA_pc	:	64'b0);
					
		IDo_DATA_ds2	<= 	((op_branch|op_reg|op_32_reg|op_store|op_amo)	?	GPR_rs2_data:	64'b0)|
							((op_32_imm|op_imm)								?	imm12_i	:	64'b0)|
							((ins_csrrwi|ins_csrrci|ins_csrrsi)				?	imm5_csr:	64'b0)|
							((ins_csrrw|ins_csrrc|ins_csrrs)				?	GPR_rs1_data:	64'b0)|
							(ins_auipc										?	imm20	:	64'b0)|
							((ins_jal|ins_jalr)								?	64'd4	:	64'b0);
		IDo_DATA_fs1	<= 	FREG_fs1_data;
		IDo_DATA_fs2	<= 	FREG_fs2_data;
		IDo_DATA_vs1	<= 	VREG_vs1_data;
		IDo_DATA_vs2	<= 	VREG_vs2_data;

		IDo_DATA_as1	<= 	(op_branch|ins_jal)	?	IDi_DATA_pc		:	GPR_rs1_data;	
		
		IDo_DATA_as2	<= 	((op_branch)		?	imm12_b		:	64'b0)|
							((ins_jalr)			?	imm12_i		:	64'b0)|
							((ins_jal)			?	imm20_jal	:	64'b0)|
							((op_store)			?	imm12_s		:	64'b0)|
							((op_load)			?	imm12_i		:	64'b0);
		IDo_DATA_opcount<=	op_count_decode;
	end
end

//机器控制段 MSC
//机器控制段负责WB阶段时csr的自动更新
always@(posedge clk)begin
	if(rst | IDi_FC_nop | IDi_FC_war)begin
		IDo_FC_system			<=	1'b0;		//system指令，op code=system的时候被置1
		IDo_FC_jmp				<=	1'b0;
		IDo_MSC_ins_acc_fault	<= 	1'b0;		//指令访问失败
		IDo_MSC_ins_addr_mis	<=	1'b0;		//指令地址错误
		IDo_MSC_ins_page_fault	<= 	1'b0;		//指令页面错误
		IDo_MSC_interrupt		<= 	1'b0;		//中断接收信号
		IDo_MSC_valid			<= 	1'b0;		//指令有效信号
		IDo_MSC_ill_ins			<= 	1'b0;		//异常指令信号
		IDo_MSC_mret			<= 	1'b0;		//返回信号
		IDo_MSC_sret			<=	1'b0;
		IDo_MSC_ecall			<=	1'b0;		//环境调用
		IDo_MSC_ebreak			<=	1'b0;		//断点
	end
	else if(IDi_FC_hold)begin
		IDo_FC_system			<=	IDo_FC_system;		//system指令，op code=system的时候被置1
		IDo_FC_jmp				<= 	IDo_FC_jmp;		
		IDo_MSC_ins_acc_fault	<= 	IDo_MSC_ins_acc_fault;	//指令访问失败
		IDo_MSC_ins_addr_mis	<=	IDo_MSC_ins_addr_mis;	//指令地址错误
		IDo_MSC_ins_page_fault	<= 	IDo_MSC_ins_page_fault;	//指令页面错误
		IDo_MSC_interrupt		<= 	IDo_MSC_interrupt;		//中断接收信号
		IDo_MSC_valid			<= 	IDo_MSC_valid;			//指令有效信号
		IDo_MSC_ill_ins			<= 	IDo_MSC_ill_ins;		//异常指令信号
		IDo_MSC_mret			<= 	IDo_MSC_mret;			//返回信号
		IDo_MSC_sret			<=	IDo_MSC_sret;
		IDo_MSC_ecall			<=	IDo_MSC_ecall;			//环境调用
		IDo_MSC_ebreak			<=	IDo_MSC_ebreak;			//断点
	end
	//不需要hold和nop时候，ID直接传递由IF递过来的信号
	else begin
		IDo_FC_system			<=	dec_system_mem;		//system指令，op code=system的时候被置1
		IDo_FC_jmp				<=  op_branch|ins_jal|ins_jalr;
		IDo_MSC_ins_acc_fault	<= 	IDi_MSC_ins_acc_fault;	//指令访问失败
		IDo_MSC_ins_addr_mis	<=	IDi_MSC_ins_addr_mis;	//指令地址错误
		IDo_MSC_ins_page_fault	<= 	IDi_MSC_ins_page_fault;	//指令页面错误
		IDo_MSC_interrupt		<= 	IDi_MSC_interrupt;			//中断接收信号
		IDo_MSC_valid			<= 	IDi_MSC_valid;			//指令有效信号
		IDo_MSC_ill_ins			<= 	dec_ill_ins;		//异常指令信号
		IDo_MSC_mret			<= 	 !dec_ill_ins & ins_mret;			//返回信号,不被trap时才能正常使用返回信号
		IDo_MSC_sret			<=	 !dec_ill_ins & ins_sret;
		IDo_MSC_ecall			<=	ins_ecall;			//环境调用
		IDo_MSC_ebreak			<=	ins_ebreak;			//断点
	end
end
//--------异常码 TVAL--------
always@(posedge clk)begin
	if(rst | !IDi_MSC_valid)begin
		IDo_DATA_trap_value	<=	64'b0;
		//当前指令pc
		IDo_DATA_pc	<= 	64'b0;
	end
	else if(IDi_FC_hold)begin
		IDo_DATA_trap_value	<=  IDo_DATA_trap_value;
		IDo_DATA_pc	<=	IDo_DATA_pc;
	end
	else begin
	//当非法指令的时候，该码被更新为ins
		IDo_DATA_trap_value	<=	dec_ill_ins?{32'b0,IDi_DATA_instruction}:64'b0;
		IDo_DATA_pc			<=	IDi_DATA_pc;
	end
end

endmodule
