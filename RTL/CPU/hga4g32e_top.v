
/*
 *    author : PAN Xinyu HONG Xiaoyu
 *    e-mail : 2320025806@qq.com xiaoyu-hong@outlook.com
 *    date   : 20201209
 *    desc   : 4G32e Top level file
 *    version: 0.1
 
Family 	: HGA1
Module 	: 4G32e Unified Shader Core
ISA		: RISC-V 32IMF with 16Bit x 8Lane Conditional SIMD extension
L1I		: Full speed Sync 1KWord x 64, 4-Lines ， 1KWord per line
L1D		: Full speed Sync 1KWord x 128,  8-Lines ， 512Word per line
*/
`include "global_defines.vh"
module hga4g32e_top(
//用户配置信号

input wire clk,			//时钟信号，和AHB总线同步
input wire rst,			//复位信号，高有效，AHB总线的复位信号是空脚
//AHB总线
output wire [`GLOBAL_BUSADDRWID-1:0]haddr,
output wire hwrite,
output wire [2:0]hsize,
output wire [2:0]hburst,	//固定值
output wire [3:0]hprot,		//固定值
output wire [1:0]htrans,
output wire hmastlock,
output wire [`GLOBAL_BUSDATAWID-1:0]hwdata,

input wire hready,
input wire hresp,
input wire hreset_n,
input wire [`GLOBAL_BUSDATAWID-1:0]hrdata,

input wire bus_master_req,	//总线主机请求，当其他主机需要占用总线时候发出此请求
output wire bus_master_ack,	//总线主机允许，当464SX处理器结束总线访问且有主机请求之后，此位为1，表示总线可以被占用

//外部中断信号
input wire m_time_int,
input wire m_soft_int,
input wire m_ext_int,	//对M模式的中断信号
input wire s_ext_int	//对S模式的中断信号
//外部时钟信号

);
//CSR信号
wire [63:0]CUo_satp;                    //CSR data satp
wire [3:0]CUo_priv;		                //CSR data, privage
wire [3:0]CUo_mod_priv;                 //CSR data, privage that been modified
wire CUo_tvm;                           //TVM, Trap Virtual Memory
wire CUo_tsr;                           //TSR, Trap Supervisior Return
wire CUo_sum;                           //SUM, Supervisior User Memory?
wire CUo_mxr;                           //MXR, Make Executeable Readable
wire CUo_mprv;                          //MPRV, modified prvivage
wire CUo_tw;                            //Trap wait 
wire [63:0]CU_IDi_DATA_csr;             //CSR DATA been read
wire [31:0]CU_IDi_DATA_rs1;             //RS1 DATA been read
wire [31:0]CU_IDi_DATA_rs2;             //RS2 DATA
wire [31:0]CU_IDi_DATA_fs1;             //FS1 DATA been read
wire [31:0]CU_IDi_DATA_fs2;             //FS2 DATA
wire [127:0]CU_IDi_DATA_vs1;             //VS1 DATA been read
wire [127:0]CU_IDi_DATA_vs2;             //VS2 DATA
//-------------------------------CU to IFU signals---------------------------------
wire [63:0]IFi_new_pc;                  //new PC for IF
wire CUo_int_req;                       /*insert an interrupt to instruction flow, which will cause the pipline stop 
                                          instruction fetch before interrupt been execute*/
wire IFi_pip_flush;                     //pipline flush signal, make IF to load new PC

//--------------------------------IF to BIU signals---------------------------------------
wire [3:0]IF_BIUi_priv;                 //BIU input, privage.
wire [63:0]IF_BIUi_addr;                //BIU input, address of the instruction
wire IF_BIUi_fetch;                     //BIU input, fetch command
wire [63:0]IF_BIUo_DATA_instruction;	//BIU output, instruction DATA output
wire IF_BIUo_ins_acc_fault;             //BIU output, instruction access fault
wire IF_BIUo_ins_page_fault;            //BIU output, instruction page fault
wire IF_BIUo_cache_ready;               //BIU output, instruction is ready
//-----------------------------------IF to ID signals--------------------------------------
wire [31:0]IF_IDi_DATA_ins;             //IFU output, instruction output 
wire [63:0]IF_IDi_DATA_ins_pc;          //IFU output, the Program Counter of current instruction
wire IF_IDi_FC_system;                  //IFU output, the current instruction is a system-type instruction(When a interrupt is insert in or some exception happened)
wire IF_IDo_FC_hold;                    //IFU input, instruction output will be hold
wire IF_IDo_FC_nop;                     //IFU input, a nop will be insert
wire IF_IDi_MSC_ins_acc_fault;          //IFU output, an instruction access fault happen
wire IF_IDi_MSC_ins_addr_mis;           //IFU output, an instruction adress misland happen 
wire IF_IDi_MSC_ins_page_fault;         //IFU output, an instruction page fault happen
wire IF_IDi_MSC_int_acc;                //IFU output, an interrupt has been insert
wire IF_IDi_MSC_valid;                  //IFU output, means this instruction is valid(can be decode and execute)
//------------------------------------------IDU to EXU signals---------------------------------
//---------DATAs-----------
wire [7:0]ID_EXi_DATA_opcount;          //opeartion count, use for shift instruction
wire [63:0]ID_EXi_DATA_as1;             //address source 1
wire [63:0]ID_EXi_DATA_as2;             //address source 2
wire [31:0]ID_EXi_DATA_ds1;             //data source 1
wire [31:0]ID_EXi_DATA_ds2;             //data source 2
wire [31:0]ID_EXi_DATA_fs1;             //FREG data source 1
wire [31:0]ID_EXi_DATA_fs2;             //data source 2
wire [127:0]ID_EXi_DATA_vs1;             //VREG data source 1
wire [127:0]ID_EXi_DATA_vs2;             //data source 2
wire [63:0]ID_EXi_DATA_tval;            //Trap value          
wire [63:0]ID_EXi_DATA_pc;              //program counter of current instruction
//-------ALU Opeartion signals-----
wire ID_EXi_OP_ALU_ds1;                 // rd data = data source 1
wire ID_EXi_OP_ALU_add;                 // rd data = data source 2
wire ID_EXi_OP_ALU_sub;                 // rd data = data source 1 - 2
wire ID_EXi_OP_ALU_and;                 // rd data = data source 1 & 2(bit)
wire ID_EXi_OP_ALU_or;                  // rd data = data source 1 | 2
wire ID_EXi_OP_ALU_xor;                 // rd data = data source 1 ^ 2(bit)
wire ID_EXi_OP_ALU_slt;                 // rd data = data source 1 compare to 2
wire ID_EXi_OP_ALU_compare;             // compare two data (Branch instructions will use this)
wire ID_EXi_OP_ALU_amo_lrsc;            // amo instruction use this to set right data in RD
wire ID_EXi_OP_ALU_ShiftLeft;           //Shift Left by (Opcount)
wire ID_EXi_OP_ALU_ShiftRight;          //Shift Right by (Opcount)
wire ID_EXi_OP_ALU_mdiv;
wire ID_EXi_OP_MDIV_hlowsel;
wire ID_EXi_OP_MDIV_mdivsel;
wire ID_EXi_OP_MDIV_signsel;
//VPU Operation Signals

wire ID_EXi_OP_VPU_ifsel;//Function integer/float select
wire ID_EXi_OP_VPU_addsel;
wire ID_EXi_OP_VPU_subsel;
wire ID_EXi_OP_VPU_mulsel;
wire ID_EXi_OP_VPU_divsel;
wire ID_EXi_OP_VPU_itfsel; //integer to float
wire ID_EXi_OP_VPU_ftisel; //float to integer
wire ID_EXi_OP_VPU_laneop;
wire ID_EXi_OP_VPU_maxsel;
wire ID_EXi_OP_VPU_minsel;
wire ID_EXi_OP_VPU_andsel;		//逻辑&
wire ID_EXi_OP_VPU_orsel;		//逻辑|
wire ID_EXi_OP_VPU_xorsel;
wire ID_EXi_OP_VPU_srasel;
wire ID_EXi_OP_VPU_srlsel;
wire ID_EXi_OP_VPU_sllsel;
wire ID_EXi_OP_VPU_cgqsel;//compare:great equal
wire ID_EXi_OP_VPU_cltsel;
wire ID_EXi_OP_VPU_ceqsel;
wire ID_EXi_OP_VPU_cnqsel;
wire ID_EXi_OP_VPU_enable;
wire ID_EXi_OP_VPU_memacc;
wire ID_EXi_OP_VPU_memrd;
wire ID_EXi_OP_VPU_memwr;
wire ID_EXi_OP_VPU_masken;
wire ID_EXi_OP_VPU_vecen;
//-------ALU part2 opeartion signals------
wire ID_EXi_OP_csr_mem_ds1;             // csr data or memory data  = data source 1
wire ID_EXi_OP_csr_mem_ds2;             // csr data or memory data  = data source 2
wire ID_EXi_OP_csr_mem_add;             // csr data or memory data  = data source 1 + 2
wire ID_EXi_OP_csr_mem_and;             // csr data or memory data  = data source 1 & 2
wire ID_EXi_OP_csr_mem_or;              // csr data or memory data  = data source 1 | 2
wire ID_EXi_OP_csr_mem_xor;             // csr data or memory data  = data source 1 ^ 2
wire ID_EXi_OP_csr_mem_max;             // csr data or memory data  = maxiume one of 1 or 2
wire ID_EXi_OP_csr_mem_min;             // csr data or memory data  = minimal one of 1 or 2  
//-----Jump and Extended signals-----
wire ID_EXi_OP_ALU_blt;                 //Branch if ds1 < ds2
wire ID_EXi_OP_ALU_bge;                 //Branch if ds1 > ds2
wire ID_EXi_OP_ALU_beq;                 //Branch if ds1 = ds2
wire ID_EXi_OP_ALU_bne;                 //Branch if ds1 != ds2
wire ID_EXi_OP_ALU_jmp;                 //JUMP!
wire ID_EXi_OP_ALU_unsign;              //use unsign data formate
wire ID_EXi_OP_ALU_clr;                 //change & to clear, for csr opeartion
wire ID_EXi_OP_ALU_sel;                 //Select the data source input 2 of alu, 0=origin data source 2; 1 = memory read data
wire [3:0]ID_EXi_OP_size;               //Operation size, for the memory read/write
//-----Multi Cycle control------
wire ID_EXi_OP_MC_load;                 //Load
wire ID_EXi_OP_MC_store;                //Store
wire ID_EXi_OP_MC_amo;                  //Atom
wire ID_EXi_OP_MC_L1i_flush;            //L1i cache flush(Fence.i)
wire ID_EXi_OP_MC_L1d_flush;            //L1d cache flush(Fence)
wire ID_EXi_OP_MC_L1d_sync;            //TLB flush(Fence.vma)
//----Write Back signals-----
wire [4:0]ID_EXi_WB_RDindex;            //Writeback rd index
wire [4:0]ID_EXi_WB_FDindex;            //Writeback rd index
wire [4:0]ID_EXi_WB_VDindex;            //Writeback rd index
wire [11:0]ID_EXi_WB_CSRindex;          //writeback csr index
wire ID_EXi_WB_CSRwrite;                //writeback to CSR enable
wire ID_EXi_WB_GPRwrite;                //writeback to GPR enable
wire ID_EXi_WB_FREGwrite;                //writeback to GPR enable
wire ID_EXi_WB_VREGwrite;                //writeback to GPR enable
//------Machine Control Signals------
wire ID_EXi_MSC_ins_acc_fault;
wire ID_EXi_MSC_ins_addr_mis;
wire ID_EXi_MSC_ins_page_fault;
wire ID_EXi_MSC_ill_ins;
wire ID_EXi_MSC_interrupt;
wire ID_EXi_MSC_valid;
wire ID_EXi_MSC_mret;
wire ID_EXi_MSC_sret;
wire ID_EXi_MSC_ecall;
wire ID_EXi_MSC_ebreak;
//--------Flow Control signals-------
wire ID_EXi_FC_system;                  //Flow Control, current instruction is a system-type 
wire ID_EXi_FC_jmp;                     //Flow Control, current instruction will cause a jump
wire ID_EXo_FC_hold;                    //Flow Control, EXU request IDU to hold output value
wire ID_EXo_FC_nop;                     //Flow Control, EXU request IDU to insert a NOP
wire ID_EXo_FC_war;                     // There is a WAR!
//---------------IDU decode signals-------------
wire IDo_DEC_warcheck;                  //Enable all the warcheck
wire [4:0]IDo_DEC_rs1index;             //RS1 index decode
wire [4:0]IDo_DEC_rs2index;             //RS2 index decode
wire [11:0]IDo_DEC_csrindex;
wire [4:0]IDo_DEC_fs1index;             //FS1 index decode
wire [4:0]IDo_DEC_fs2index;             //FS2 index decode
wire [4:0]IDo_DEC_vs1index;             //VS1 index decode
wire [4:0]IDo_DEC_vs2index;             //VS2 index decode
//-----------------------------------EXU to CU/RU signals-------------------------------------
wire [31:0]EX_CUi_DATA_rd;
wire [31:0]EX_CUi_DATA_fd;
wire [127:0]EX_CUi_DATA_vd;
wire [63:0]EX_CUi_DATA_newpc;
wire [63:0]EX_CUi_DATA_csr;
wire [63:0]EX_CUi_DATA_tval;
wire [63:0]EX_CUi_DATA_pc;
//----write Back signals----
wire EX_CUi_WB_CSRwrite;
wire EX_CUi_WB_GPRwrite;
wire EX_CUi_WB_FREGwrite;
wire EX_CUi_WB_VREGwrite;
wire EX_CUi_WB_PCjmp;
wire [11:0]EX_CUi_WB_CSRindex;
wire [4:0]EX_CUi_WB_RDindex;
wire [4:0]EX_CUi_WB_FDindex;
wire [4:0]EX_CUi_WB_VDindex;
//----Machine Control Signals----
wire EX_CUi_MSC_ins_acc_fault;
wire EX_CUi_MSC_ins_addr_mis;
wire EX_CUi_MSC_ins_page_fault;
wire EX_CUi_MSC_load_acc_fault;
wire EX_CUi_MSC_load_addr_mis;
wire EX_CUi_MSC_load_page_fault;
wire EX_CUi_MSC_store_acc_fault;
wire EX_CUi_MSC_store_addr_mis;
wire EX_CUi_MSC_store_page_fault;
wire EX_CUi_MSC_interrupt;
wire EX_CUi_MSC_valid;
wire EX_CUi_MSC_ill_ins;
wire EX_CUi_MSC_mret;
wire EX_CUi_MSC_sret;
wire EX_CUi_MSC_ecall;
wire EX_CUi_MSC_ebreak;
//-----Flow control signals------
wire EX_CUi_FC_jmp;
wire EX_CUi_FC_system;

wire EX_CUo_FC_nop;
wire EX_CUo_FC_war;
//----------------------------------EXU to BIU signals------------------------------------
wire [3:0]EX_BIUi_priv;
wire [3:0]EX_BIUi_size;             //opearting DATA size, 0001=1Byte 0010=2Byte 0100=4Byte 1000=8Byte
wire EX_BIUi_unpage;
wire EX_BIUi_write;
wire EX_BIUi_read;
wire EX_BIUi_VPUaccess;
wire EX_BIUi_L1d_sync;
wire EX_BIUo_L1d_syncok;
wire EX_BIUi_L1i_flush;
wire EX_BIUi_L1d_flush;
wire [63:0]EX_BIUo_DATA_read;       //DATA been read from BIU
wire [63:0]EX_BIUi_DATA_write;      //DATA will write to BIU
wire [127:0]EX_BIUi_VPU_datastore;
wire [127:0]EX_BIUo_VPU_dataload;

wire [63:0]EX_BIUi_addr;            //ADDR 
wire EX_BIUo_load_acc_fault;        //Load access fault error happen
wire EX_BIUo_load_page_fault;       //Load page fault
wire EX_BIUo_store_acc_fault;       //Store access fault
wire EX_BIUo_store_page_fault;      //Store page fault
wire EX_BIUo_cache_ready;           //cache data ready; or flush operation finished
wire EX_BIUo_uncache_ready;         //uncache data ready
/*-----------------NOTE-------------------------------
CLK          :/-\__/-\__/-\__/-\_
cache ready  :_____/----\_________
uncache_ready:__________/----\___
DATA         :----------[DATA]---
NOTE: cache_ready signal occuar ahead of the valid DATA
uncache_ready signal occuar in the same cycle of valid DATA
----------------------------------------------------*/
//BIU 总线接口单元，此单元包含了L1和总线的所有存取逻辑
biu biu(
.clk					(clk),
.rst					(!hreset_n),

//.cacheability_block		(cacheability_block),

.satp					(CUo_satp),		
.sum					(CUo_sum),			
.mxr					(CUo_mxr),				


//---------------------IFU信号-------------------------
.if_priv				(IF_BIUi_priv),	                //privage to fetch an instruction
.addr_if				(IF_BIUi_addr),                 //
.rd_ins					(IF_BIUi_fetch),				//command to BIU, fetch an instruction
.ins_read				(IF_BIUo_DATA_instruction),     //output DATA

.ins_acc_fault			(IF_BIUo_ins_acc_fault), 		
//.ins_page_fault			(IF_BIUo_ins_page_fault),	
.cache_ready_if			(IF_BIUo_cache_ready),		

//-------------------EXU信号-------------------------
.unpage					(EX_BIUi_unpage),				
.ex_priv				(EX_BIUi_priv),				    //0001=U 0010=S 0100=H 1000=M 
.addr_ex				(EX_BIUi_addr),
.data_write				(EX_BIUi_DATA_write),
.data_read				(EX_BIUo_DATA_read),
.size					(EX_BIUi_size),					//0001=1Byte 0010=2Byte 0100=4Byte 1000=8Byte other=fault			
.l1i_reset				(EX_BIUi_L1i_flush),            //command to BIU, L1i cache flush (fence.i or fence),L1I will reload
.l1d_reset				(EX_BIUi_L1d_flush),		    //command to BIU, L1d cache flush (fence), L1d will reload
.force_sync				(EX_BIUi_L1d_sync),
.sync_ok                (EX_BIUo_L1d_syncok),
.read					(EX_BIUi_read),					//command to BIU, read a data
.write					(EX_BIUi_write),				//command to BIU, write a data
.vpu_write              (EX_BIUi_VPU_datastore),
.vpu_read               (EX_BIUo_VPU_dataload),
.vpu_access             (EX_BIUi_VPUaccess),
.load_acc_fault			(EX_BIUo_load_acc_fault),       //exceptions happen
//.load_page_fault		(EX_BIUo_load_page_fault),      //-------------------------------NOTE---------------------------------------//
.store_acc_fault		(EX_BIUo_store_acc_fault),      //When an exception happen, cache_ready or uncache_ready signal won't enable//
//.store_page_fault		(EX_BIUo_store_page_fault),     //only xxx_xxx_fault signal will enable.                               //
                                                        //--------------------------------------------------------------------------//
.cache_ready_ex			(EX_BIUo_cache_ready),
.uncache_data_rdy		(EX_BIUo_uncache_ready),

//AHB信号
.haddr					(haddr),
.hwrite					(hwrite),
.hsize					(hsize),
.hburst					(hburst),
.hprot					(hprot),
.htrans					(htrans),
.hmastlock				(hmastlock),
.hwdata					(hwdata),

.hready					(hready),
.hresp					(hresp),
.hreset_n(),
.hrdata					(hrdata),

.bus_master_req			(bus_master_req),
.bus_master_ack			(bus_master_ack)

);

ins_fetch               IFU(

.clk                    (clk),
.rst                   (!hreset_n),
.priv                   (CUo_priv),		


.int_req                (CUo_int_req),	
		
.IFi_FC_hold            (IF_IDo_FC_hold),			
.IFi_FC_nop             (IF_IDo_FC_nop),			

.IFi_pip_flush          (IFi_pip_flush),
.IFi_new_pc             (IFi_new_pc),	

.IFo_BIU_addr           (IF_BIUi_addr),
.IFo_BIU_fetch          (IF_BIUi_fetch),				
.IFo_BIU_priv           (IF_BIUi_priv),			
.IFi_BIU_ins_in         (IF_BIUo_DATA_instruction),
.IFi_BIU_ins_acc_fault  (IF_BIUo_ins_acc_fault), 		
.IFi_BIU_ins_page_fault (IF_BIUo_ins_page_fault),		
.IFi_BIU_cache_ready    (IF_BIUo_cache_ready),			

.IFo_DATA_ins           (IF_IDi_DATA_ins),

.IFo_DATA_ins_pc        (IF_IDi_DATA_ins_pc),

.IFo_MSC_ins_acc_fault  (IF_IDi_MSC_ins_acc_fault),	
.IFo_MSC_ins_addr_mis   (IF_IDi_MSC_ins_addr_mis), 	
.IFo_MSC_ins_page_fault (IF_IDi_MSC_ins_page_fault),	
.IFo_MSC_int_acc        (IF_IDi_MSC_int_acc),			
.IFo_MSC_valid          (IF_IDi_MSC_valid),			
.IFo_FC_system          (IF_IDi_FC_system)


);



//指令解码单元
ins_dec                         IDU(
//---全局时钟和复位信号---
.clk                    (clk),
.rst                    (!hreset_n),
//---CSR信号输入---
//.CSR_priv               (CUo_priv),		        //current privage
.CSR_tvm                (CUo_tvm),
.CSR_tsr                (CUo_tsr),
.CSR_tw                 (CUo_tw),
.CSR_data               (CU_IDi_DATA_csr),
//----GPR输入----
.GPR_rs1_data           (CU_IDi_DATA_rs1),
.GPR_rs2_data           (CU_IDi_DATA_rs2),
//----FGPR输入----
.FREG_fs1_data           (CU_IDi_DATA_fs1),
.FREG_fs2_data           (CU_IDi_DATA_fs2),
//----VGPR输入----
.VREG_vs1_data           (CU_IDi_DATA_vs1),
.VREG_vs2_data           (CU_IDi_DATA_vs2),
//================上一级（IF）信号===================

.IDi_DATA_instruction   (IF_IDi_DATA_ins),

.IDi_DATA_pc            (IF_IDi_DATA_ins_pc),

.IDi_MSC_ins_acc_fault  (IF_IDi_MSC_ins_acc_fault),	
.IDi_MSC_ins_addr_mis   (IF_IDi_MSC_ins_addr_mis), 	
.IDi_MSC_ins_page_fault (IF_IDi_MSC_ins_page_fault),	
.IDi_MSC_interrupt      (IF_IDi_MSC_int_acc),	
.IDi_MSC_valid          (IF_IDi_MSC_valid),		

.IDo_FC_hold            (IF_IDo_FC_hold),
.IDo_FC_nop             (IF_IDo_FC_nop),
.IDi_FC_system          (IF_IDi_FC_system),

//下一级（EX）信号
//异常码
//当非法指时候，该码被更新为ins，当指令页面错误，被更新为addr
.IDo_DATA_trap_value    (ID_EXi_DATA_tval),
//当前指令pc
.IDo_DATA_pc            (ID_EXi_DATA_pc),

//操作码 ALU,运算码
//rd数据选择
.IDo_OP_ALU_ds1         (ID_EXi_OP_ALU_ds1),		//ds1直通
.IDo_OP_ALU_add         (ID_EXi_OP_ALU_add),		//加
.IDo_OP_ALU_sub         (ID_EXi_OP_ALU_sub),		//减
.IDo_OP_ALU_and         (ID_EXi_OP_ALU_and),		//逻辑&
.IDo_OP_ALU_or          (ID_EXi_OP_ALU_or),		//逻辑|
.IDo_OP_ALU_xor         (ID_EXi_OP_ALU_xor),		//逻辑^
.IDo_OP_ALU_slt         (ID_EXi_OP_ALU_slt),		//比较大小
.IDo_OP_ALU_compare     (ID_EXi_OP_ALU_compare),		//比较大小，配合IDo_OP_ALU_bge0_IDo_OP_ALU_blt1\IDo_OP_ALU_beq0_IDo_OP_ALU_bne1控制线并产生分支信号
.IDo_OP_ALU_amo_lrsc    (ID_EXi_OP_ALU_amo_lrsc),		//lr/sc读写成功标志
.IDo_OP_ALU_ShiftRight  (ID_EXi_OP_ALU_ShiftRight),		//左移位
.IDo_OP_ALU_ShiftLeft   (ID_EXi_OP_ALU_ShiftLeft),		//右移位
.IDo_OP_ALU_mdiv        (ID_EXi_OP_ALU_mdiv),				//ALU选择输出乘除
//M extension
.IDo_OP_MDIV_mdivsel    (ID_EXi_OP_MDIV_mdivsel),			//0=MUL 1=DIV		
.IDo_OP_MDIV_hlowsel    (ID_EXi_OP_MDIV_hlowsel),			//0=LOW XLEN	1=HIGH XLEN
.IDo_OP_MDIV_signsel    (ID_EXi_OP_MDIV_signsel),			//0=SIGNED		1=UNSIGN
//VPU操作组
.IDo_OP_VPU_ifsel(ID_EXi_OP_VPU_ifsel),//Function integer/float select
.IDo_OP_VPU_addsel(ID_EXi_OP_VPU_addsel),
.IDo_OP_VPU_subsel(ID_EXi_OP_VPU_subsel),
.IDo_OP_VPU_mulsel(ID_EXi_OP_VPU_mulsel),
.IDo_OP_VPU_itfsel(ID_EXi_OP_VPU_itfsel), //integer to float
.IDo_OP_VPU_ftisel(ID_EXi_OP_VPU_ftisel), //float to integer
.IDo_OP_VPU_laneop(ID_EXi_OP_VPU_laneop),
.IDo_OP_VPU_maxsel(ID_EXi_OP_VPU_maxsel),
.IDo_OP_VPU_minsel(ID_EXi_OP_VPU_minsel),
.IDo_OP_VPU_andsel(ID_EXi_OP_VPU_andsel),		//逻辑&
.IDo_OP_VPU_orsel(ID_EXi_OP_VPU_orsel),		//逻辑|
.IDo_OP_VPU_xorsel(ID_EXi_OP_VPU_xorsel),
.IDo_OP_VPU_srasel(ID_EXi_OP_VPU_srasel),
.IDo_OP_VPU_srlsel(ID_EXi_OP_VPU_srlsel),
.IDo_OP_VPU_sllsel(ID_EXi_OP_VPU_sllsel),
.IDo_OP_VPU_cgqsel(ID_EXi_OP_VPU_cgqsel),//IDo_OP_ALU_compare:great equal
.IDo_OP_VPU_cltsel(ID_EXi_OP_VPU_cltsel),
.IDo_OP_VPU_ceqsel(ID_EXi_OP_VPU_ceqsel),
.IDo_OP_VPU_cnqsel(ID_EXi_OP_VPU_cnqsel),
.IDo_OP_VPU_enable(ID_EXi_OP_VPU_enable),
.IDo_OP_VPU_memacc(ID_EXi_OP_VPU_memacc),
.IDo_OP_VPU_memrd (ID_EXi_OP_VPU_memrd),
.IDo_OP_VPU_memwr (ID_EXi_OP_VPU_memwr),
.IDo_OP_VPU_masken(ID_EXi_OP_VPU_masken),
.IDo_OP_VPU_vecen (ID_EXi_OP_VPU_vecen),
//mem_CSR_data数据选择
.IDo_OP_csr_mem_ds1     (ID_EXi_OP_csr_mem_ds1),
.IDo_OP_csr_mem_ds2     (ID_EXi_OP_csr_mem_ds2),
.IDo_OP_csr_mem_add     (ID_EXi_OP_csr_mem_add),
.IDo_OP_csr_mem_and     (ID_EXi_OP_csr_mem_and),
.IDo_OP_csr_mem_or      (ID_EXi_OP_csr_mem_or),
.IDo_OP_csr_mem_xor     (ID_EXi_OP_csr_mem_xor),
.IDo_OP_csr_mem_max     (ID_EXi_OP_csr_mem_max),
.IDo_OP_csr_mem_min     (ID_EXi_OP_csr_mem_min),
//运算,跳转辅助控制信号
.IDo_OP_ALU_blt         (ID_EXi_OP_ALU_blt),				//条件跳转，IDo_OP_ALU_blt IDo_OP_ALU_bltu指令时为1
.IDo_OP_ALU_bge         (ID_EXi_OP_ALU_bge),
.IDo_OP_ALU_beq         (ID_EXi_OP_ALU_beq),				//条件跳转，IDo_OP_ALU_bne指令时为一
.IDo_OP_ALU_bne         (ID_EXi_OP_ALU_bne),				//
.IDo_OP_ALU_jmp         (ID_EXi_OP_ALU_jmp),				//无条件跳转，适用于JAL JALR指令
.IDo_OP_ALU_unsign      (ID_EXi_OP_ALU_unsign),			//无符号操作，同时控制mem单元信号的符号
.IDo_OP_ALU_clr         (ID_EXi_OP_ALU_clr),				//将csr操作的and转换为clr操作
.IDo_OP_ds1_sel         (ID_EXi_OP_ALU_sel),					//ALU ds1选择，为0选择ds1，为1选择MEM读取信号

//位宽控制
.IDo_OP_size            (ID_EXi_OP_size), 			//0001:1Byte 0010:2Byte 0100=4Byte 1000=8Byte
//多周期控制
//多周期控制信号线控制EX单元进行多周期操作
.IDo_OP_MC_load         (ID_EXi_OP_MC_load),
.IDo_OP_MC_store        (ID_EXi_OP_MC_store),
.IDo_OP_MC_amo          (ID_EXi_OP_MC_amo),
.IDo_OP_MC_L1i_flush    (ID_EXi_OP_MC_L1i_flush),		
.IDo_OP_MC_L1d_flush    (ID_EXi_OP_MC_L1d_flush),			//缓存复位信号，下次访问内存时重新刷新页表
.IDo_OP_MC_L1d_sync    (ID_EXi_OP_MC_L1d_sync),			//TLB复位

//写回控制，当valid=0时候，所有写回不有效
.IDo_WB_CSRwrite        (ID_EXi_WB_CSRwrite),
.IDo_WB_GPRwrite        (ID_EXi_WB_GPRwrite),
.IDo_WB_FREGwrite        (ID_EXi_WB_FREGwrite),
.IDo_WB_VREGwrite        (ID_EXi_WB_VREGwrite),
.IDo_WB_CSRindex        (ID_EXi_WB_CSRindex),
.IDo_WB_RDindex         (ID_EXi_WB_RDindex),
.IDo_WB_FDindex         (ID_EXi_WB_FDindex),
.IDo_WB_VDindex         (ID_EXi_WB_VDindex),
//数据输出							   
.IDo_DATA_ds1           (ID_EXi_DATA_ds1),		//数据源1，imm/rs1/rs1/csr/pc /pc
.IDo_DATA_ds2           (ID_EXi_DATA_ds2),
.IDo_DATA_fs1           (ID_EXi_DATA_fs1),		//数据源1，
.IDo_DATA_fs2           (ID_EXi_DATA_fs2),
.IDo_DATA_vs1           (ID_EXi_DATA_vs1),		//数据源1，
.IDo_DATA_vs2           (ID_EXi_DATA_vs2),
.IDo_DATA_as1           (ID_EXi_DATA_as1),		//地址源1,  pc/rs1/rs1
.IDo_DATA_as2           (ID_EXi_DATA_as2),		//地址源2, imm/imm/00
.IDo_DATA_opcount       (ID_EXi_DATA_opcount),	//操作次数码，用于移位指令
//机器控制段
//机器控制段负责WB阶段时csr的自动更新

.IDo_MSC_ins_acc_fault  (ID_EXi_MSC_ins_acc_fault),	//指令访问失败
.IDo_MSC_ins_addr_mis   (ID_EXi_MSC_ins_addr_mis), 	//指令地址错误
.IDo_MSC_ins_page_fault (ID_EXi_MSC_ins_page_fault),	//指令页面错误
.IDo_MSC_interrupt      (ID_EXi_MSC_interrupt),		//中断接收信号
.IDo_MSC_valid          (ID_EXi_MSC_valid), 			//指令有效信号
.IDo_MSC_ill_ins        (ID_EXi_MSC_ill_ins),			//异常指令信号
.IDo_MSC_mret           (ID_EXi_MSC_mret),			//返回信号
.IDo_MSC_sret           (ID_EXi_MSC_sret),
.IDo_MSC_ecall          (ID_EXi_MSC_ecall),			//环境调用
.IDo_MSC_ebreak         (ID_EXi_MSC_ebreak),			//断点

//--------------------流控信号--------------------
//---下一级输入的流控信号---
.IDi_FC_hold            (ID_EXo_FC_hold),			
.IDi_FC_nop             (ID_EXo_FC_nop),			
.IDi_FC_war             (ID_EXo_FC_war),			
//---输出到下一级的流控信号---
.IDo_FC_system          (ID_EXi_FC_system),			
.IDo_FC_jmp             (ID_EXi_FC_jmp),				
.IDo_DEC_warcheck       (IDo_DEC_warcheck),		
.IDo_DEC_rs1index       (IDo_DEC_rs1index),	        
.IDo_DEC_rs2index       (IDo_DEC_rs2index),
.IDo_DEC_fs1index       (IDo_DEC_fs1index),	        
.IDo_DEC_fs2index       (IDo_DEC_fs2index),
.IDo_DEC_vs1index       (IDo_DEC_vs1index),	        
.IDo_DEC_vs2index       (IDo_DEC_vs2index),                      //unuse
.IDo_DEC_csrindex       (IDo_DEC_csrindex)           

);

//============================EXU 执行单元=========================
exu                 EXU
(
.clk                    (clk),
.rst                    (!hreset_n),

//.priv                   (CUo_priv),		//当前机器权限
//csr输入
//.mprv                   (CUo_mprv),			//更改权限
//.mod_priv               (CUo_mod_priv),	//要被更改的权限
//=================上一级 ID=====================
//-------------流控信号---------------
.EXUo_FC_nop            (ID_EXo_FC_nop),
.EXUo_FC_hold           (ID_EXo_FC_hold),
.EXUo_FC_war            (ID_EXo_FC_war),		//产生数据相关
//---数据相关性检查信号---
.EXUi_FC_rs1index       (IDo_DEC_rs1index),
.EXUi_FC_rs2index       (IDo_DEC_rs2index),
.EXUi_FC_warcheck       (IDo_DEC_warcheck),	//数据相关检查使能
//异常码TVAL
//当非法指时候，该码被更新为instruction，当指令页面错误，被更新为addr
.EXUi_DATA_tval         (ID_EXi_DATA_tval),
//当前指令pc
.EXUi_DATA_pc           (ID_EXi_DATA_pc),

//操作码 ALU,运算码
//rd数据选择
.EXUi_OP_ALU_ds1        (ID_EXi_OP_ALU_ds1),				//ds1直通
.EXUi_OP_ALU_add        (ID_EXi_OP_ALU_add),				//加
.EXUi_OP_ALU_sub        (ID_EXi_OP_ALU_sub),				//减
.EXUi_OP_ALU_and        (ID_EXi_OP_ALU_and),				//逻辑&
.EXUi_OP_ALU_or         (ID_EXi_OP_ALU_or),				//逻辑|
.EXUi_OP_ALU_xor        (ID_EXi_OP_ALU_xor),				//逻辑^
.EXUi_OP_ALU_slt        (ID_EXi_OP_ALU_slt),				//比较大小
.EXUi_OP_ALU_compare    (ID_EXi_OP_ALU_compare),			//比较大小，配合bge0_blt1\beq0_bne1控制线并产生分支信号
.EXUi_OP_ALU_amo_lrsc   (ID_EXi_OP_ALU_amo_lrsc),		//lr/sc读写成功标志，LR/SC指令总是读写成功
.EXUi_OP_ALU_shift_right(ID_EXi_OP_ALU_ShiftRight),		
.EXUi_OP_ALU_shift_left (ID_EXi_OP_ALU_ShiftLeft),
//M extension
.EXUi_OP_ALU_mdiv        (ID_EXi_OP_ALU_mdiv),				//ALU选择输出乘除
.EXUi_OP_MDIV_mdivsel    (ID_EXi_OP_MDIV_mdivsel),			//0=MUL 1=DIV		
.EXUi_OP_MDIV_hlowsel    (ID_EXi_OP_MDIV_hlowsel),			//0=LOW XLEN	1=HIGH XLEN
.EXUi_OP_MDIV_signsel    (ID_EXi_OP_MDIV_signsel),          //0=UNSIGN 1=SIGNED

//mem_csr_data数据选择
.EXUi_OP_csr_mem_ds1    (ID_EXi_OP_csr_mem_ds1),
.EXUi_OP_csr_mem_ds2    (ID_EXi_OP_csr_mem_ds2),
.EXUi_OP_csr_mem_add    (ID_EXi_OP_csr_mem_add),
.EXUi_OP_csr_mem_and    (ID_EXi_OP_csr_mem_and),
.EXUi_OP_csr_mem_or     (ID_EXi_OP_csr_mem_or),
.EXUi_OP_csr_mem_xor    (ID_EXi_OP_csr_mem_xor),
.EXUi_OP_csr_mem_max    (ID_EXi_OP_csr_mem_max),
.EXUi_OP_csr_mem_min    (ID_EXi_OP_csr_mem_min),
//运算,跳转辅助控制信号
.EXUi_OP_ALU_blt        (ID_EXi_OP_ALU_blt),				
.EXUi_OP_ALU_bge        (ID_EXi_OP_ALU_bge),
.EXUi_OP_ALU_beq        (ID_EXi_OP_ALU_beq),				
.EXUi_OP_ALU_bne        (ID_EXi_OP_ALU_bne),
.EXUi_OP_ALU_jmp        (ID_EXi_OP_ALU_jmp),				//无条件跳转，适用于JAL JALR指令
.EXUi_OP_ALU_unsign     (ID_EXi_OP_ALU_unsign),			//无符号操作，同时控制mem单元信号的符号拓展
.EXUi_OP_ALU_clr        (ID_EXi_OP_ALU_clr),			//将csr操作的and转换为clr操作
.EXUi_OP_ds1_sel        (ID_EXi_OP_ALU_sel),			//ALU ds1选择，为0选择ds1，为1选择LSU读取的数据

//VPU功能组
.EXUi_VPU_ifsel(ID_EXi_OP_VPU_ifsel),//Function integer/float select
.EXUi_VPU_addsel(ID_EXi_OP_VPU_addsel),
.EXUi_VPU_subsel(ID_EXi_OP_VPU_subsel),
.EXUi_VPU_mulsel(ID_EXi_OP_VPU_mulsel),
.EXUi_VPU_itfsel(ID_EXi_OP_VPU_itfsel), //integer to float
.EXUi_VPU_ftisel(ID_EXi_OP_VPU_ftisel), //float to integer
.EXUi_VPU_laneop(ID_EXi_OP_VPU_laneop),
.EXUi_VPU_maxsel(ID_EXi_OP_VPU_maxsel),
.EXUi_VPU_minsel(ID_EXi_OP_VPU_minsel),
.EXUi_VPU_andsel(ID_EXi_OP_VPU_andsel),		//逻辑&
.EXUi_VPU_orsel(ID_EXi_OP_VPU_orsel),		//逻辑|
.EXUi_VPU_xorsel(ID_EXi_OP_VPU_xorsel),
.EXUi_VPU_srasel(ID_EXi_OP_VPU_srasel),
.EXUi_VPU_srlsel(ID_EXi_OP_VPU_srlsel),
.EXUi_VPU_sllsel(ID_EXi_OP_VPU_sllsel),
.EXUi_VPU_cgqsel(ID_EXi_OP_VPU_cgqsel),//compare:great equal
.EXUi_VPU_cltsel(ID_EXi_OP_VPU_cltsel),
.EXUi_VPU_ceqsel(ID_EXi_OP_VPU_ceqsel),
.EXUi_VPU_cnqsel(ID_EXi_OP_VPU_cnqsel),
.EXUi_VPU_enable(ID_EXi_OP_VPU_enable),//进行VPU存取/指示data_rd&data_fd采用VPU回送信号
.EXUi_VPU_memacc(ID_EXi_OP_VPU_memacc),//VPU访存
.EXUi_VPU_memwr(ID_EXi_OP_VPU_memwr),
.EXUi_VPU_memrd(ID_EXi_OP_VPU_memrd),
.EXUi_VPU_masken(ID_EXi_OP_VPU_masken),
.EXUi_VPU_vecen(ID_EXi_OP_VPU_vecen),
//位宽控制
.EXUi_OP_size           (ID_EXi_OP_size), 		//0001:1Byte 0010:2Byte 0100=4Byte 1000=8Byte
//多周期控制
//多周期控制信号线控制EX单元进行多周期操作
.EXUi_OP_MC_load        (ID_EXi_OP_MC_load),
.EXUi_OP_MC_store       (ID_EXi_OP_MC_store),
.EXUi_OP_MC_amo         (ID_EXi_OP_MC_amo),
.EXUi_OP_MC_L1i_flush   (ID_EXi_OP_MC_L1i_flush),		//命令 缓存刷新信号，此信号可以与内存进行同步
.EXUi_OP_MC_L1d_flush   (ID_EXi_OP_MC_L1d_flush),		//命令 缓存复位信号，下次访问内存时重新刷新页表
.EXUi_OP_MC_L1d_force_sync				(ID_EXi_OP_MC_L1d_sync),	
.EXUi_OP_MC_L1d_sync_ok                (EX_BIUo_L1d_syncok),
			

//写回控制，当valid=0时候，所有写回不有效
.EXUi_WB_CSRwrite       (ID_EXi_WB_CSRwrite),		//注*后缀ID表示是ID传输进来的信号
.EXUi_WB_GPRwrite       (ID_EXi_WB_GPRwrite),
.EXUi_WB_FREGwrite       (ID_EXi_WB_FREGwrite),
.EXUi_WB_VREGwrite       (ID_EXi_WB_VREGwrite),
.EXUi_WB_CSRindex       (ID_EXi_WB_CSRindex),
.EXUi_WB_RDindex        (ID_EXi_WB_RDindex),
.EXUi_WB_FDindex        (ID_EXi_WB_FDindex),
.EXUi_WB_VDindex        (ID_EXi_WB_VDindex),
//数据源&地址源						   
.EXUi_DATA_ds1          (ID_EXi_DATA_ds1),		//数据源1，imm/rs1/rs1/csr/pc /pc
.EXUi_DATA_ds2          (ID_EXi_DATA_ds2),		//数据源2，00 /rs2/imm/imm/imm/04
.EXUi_DATA_vs1          (ID_EXi_DATA_vs1),
.EXUi_DATA_vs2          (ID_EXi_DATA_vs2),
.EXUi_DATA_fs1          (ID_EXi_DATA_fs1),		
.EXUi_DATA_fs2          (ID_EXi_DATA_fs2),
.EXUi_DATA_as1          (ID_EXi_DATA_as1),		//地址源1,  pc/rs1/rs1
.EXUi_DATA_as2          (ID_EXi_DATA_as2),		//地址源2, imm/imm/00
.EXUi_DATA_opcount      (ID_EXi_DATA_opcount),	//操作次数码，用于AMO指令或移位指令
//流控FC
.EXUi_FC_system         (ID_EXi_FC_system),		//system指令，op code=system的时候被置1
.EXUi_FC_jmp            (ID_EXi_FC_jmp),			//会产生跳转的指令 opcode=branch时候置1
//机器控制段
.EXUi_MSC_ins_acc_fault (ID_EXi_MSC_ins_acc_fault),	//指令访问失败
.EXUi_MSC_ins_addr_mis  (ID_EXi_MSC_ins_addr_mis), 	//指令地址错误
.EXUi_MSC_ins_page_fault(ID_EXi_MSC_ins_page_fault),	//指令页面错误
.EXUi_MSC_interrupt     (ID_EXi_MSC_interrupt),		//中断接收信号
.EXUi_MSC_valid         (ID_EXi_MSC_valid), 			//指令有效信号
.EXUi_MSC_ill_ins       (ID_EXi_MSC_ill_ins),		//异常指令信号
.EXUi_MSC_mret          (ID_EXi_MSC_mret),			//返回信号
.EXUi_MSC_sret          (ID_EXi_MSC_sret),
.EXUi_MSC_ecall         (ID_EXi_MSC_ecall),			//环境调用
.EXUi_MSC_ebreak        (ID_EXi_MSC_ebreak),			//断点

//====================到下一级 WB信号=================
//数据输出
.EXUo_DATA_rd           (EX_CUi_DATA_rd),
.EXUo_DATA_csr          (EX_CUi_DATA_csr),
.EXUo_DATA_vreg         (EX_CUi_DATA_vd),
.EXUo_DATA_freg         (EX_CUi_DATA_fd),
.EXUo_DATA_newpc        (EX_CUi_DATA_newpc),
//写回控制
.EXUo_WB_CSRwrite       (EX_CUi_WB_CSRwrite),
.EXUo_WB_GPRwrite       (EX_CUi_WB_GPRwrite),
.EXUo_WB_VREGwrite      (EX_CUi_WB_VREGwrite),
.EXUo_WB_FREGwrite      (EX_CUi_WB_FREGwrite),
.EXUo_WB_PCjmp          (EX_CUi_WB_PCjmp),				//新的PC需要被更改，新的PC由pc_new给出，该信号表明WB阶段需要修改PC
.EXUo_WB_CSRindex       (EX_CUi_WB_CSRindex),
.EXUo_WB_RDindex        (EX_CUi_WB_RDindex),
.EXUo_WB_FDindex        (EX_CUi_WB_FDindex),
.EXUo_WB_VDindex        (EX_CUi_WB_VDindex),
//异常码
.EXUo_DATA_pc           (EX_CUi_DATA_pc),
.EXUo_DATA_tval         (EX_CUi_DATA_tval),		//如果是非法指令异常，则为非法指令，如果是硬件断点和储存器访问失败，则是虚拟地址
//流控信号
.EXUo_FC_system         (EX_CUi_FC_system),		//system指令，op code=system的时候被置1
.EXUo_FC_jmp            (EX_CUi_FC_jmp),			//会产生跳转的指令 opcode=branch时候置1
.EXUi_FC_nop            (EX_CUo_FC_nop),
.EXUi_FC_hold           (1'b0),                     //CU don't generate hold signal
.EXUi_FC_war            (EX_CUo_FC_war),			//后一级产生了数据相关问题

//==================Machine Control 机器控制信号======================
.EXUo_MSC_ins_acc_fault     (EX_CUi_MSC_ins_acc_fault),	//指令访问失败
.EXUo_MSC_ins_addr_mis      (EX_CUi_MSC_ins_addr_mis), 	//指令地址错误
.EXUo_MSC_ins_page_fault    (EX_CUi_MSC_ins_page_fault),	//指令页面错误
.EXUo_MSC_load_addr_mis     (EX_CUi_MSC_load_addr_mis),		//load地址不对齐
.EXUo_MSC_store_addr_mis    (EX_CUi_MSC_store_addr_mis),		//store地址不对齐
.EXUo_MSC_load_acc_fault    (EX_CUi_MSC_load_acc_fault),	//load访问失败
.EXUo_MSC_store_acc_fault   (EX_CUi_MSC_store_acc_fault),	//store访问失败
.EXUo_MSC_load_page_fault   (EX_CUi_MSC_load_page_fault),	//load页面错误
.EXUo_MSC_store_page_fault  (EX_CUi_MSC_store_page_fault),	//store页面错误
.EXUo_MSC_interrupt         (EX_CUi_MSC_interrupt),			//中断接收信号
.EXUo_MSC_valid             (EX_CUi_MSC_valid), 			//指令有效信号
.EXUo_MSC_ill_ins           (EX_CUi_MSC_ill_ins),			//异常指令信号
.EXUo_MSC_mret              (EX_CUi_MSC_mret),			//返回信号
.EXUo_MSC_sret              (EX_CUi_MSC_sret),			//
.EXUo_MSC_ecall             (EX_CUi_MSC_ecall),			//环境调用
.EXUo_MSC_ebreak            (EX_CUi_MSC_ebreak),			//断点


//=================对BIU信号===============
.EXUo_BIU_unpage            (EX_BIUi_unpage),			//只使用物理地址 命令BIU直接绕开虚拟地址使用物理地址
.EXUo_BIU_priv              (EX_BIUi_priv),			//ex权限，0001=U 0010=S 0100=H 1000=M 
.EXUo_BIU_addr              (EX_BIUi_addr),
.EXUo_BIU_DATA_write        (EX_BIUi_DATA_write),
.EXUi_BIU_DATA_read         (EX_BIUo_DATA_read),
.EXUo_BIU_size              (EX_BIUi_size),			//0001=1Byte 0010=2Byte 0100=4Byte 1000=8Byte other=fault			
.EXUo_BIU_L1i_flush         (EX_BIUi_L1i_flush),			//缓存刷新信号，用于执行fence指令的时候使用
.EXUo_BIU_L1d_flush         (EX_BIUi_L1d_flush),			//缓存载入信号，用于执行fence.vma时候和cache_flush配合使用
.EXUo_BIU_L1d_sync		    (EX_BIUi_L1d_sync),
.EXUo_BIU_read              (EX_BIUi_read),				//读数据信号
.EXUo_BIU_write             (EX_BIUi_write),				//写数据信号
.EXUo_VPU_datastore         (EX_BIUi_VPU_datastore),
.EXUi_VPU_dataload          (EX_BIUo_VPU_dataload),
.EXUo_BIU_VPUaccess         (EX_BIUi_VPUaccess),
.EXUi_BIU_load_acc_fault    (EX_BIUo_load_acc_fault),
.EXUi_BIU_load_page_fault   (EX_BIUo_load_page_fault),
.EXUi_BIU_store_acc_fault   (EX_BIUo_store_acc_fault),
.EXUi_BIU_store_page_fault  (EX_BIUo_store_page_fault),
.EXUi_BIU_cache_ready       (EX_BIUo_cache_ready),		//cache数据准备好信号，此信号比read_data提前一个周期出现
.EXUi_BIU_uncache_ready     (EX_BIUo_uncache_ready),		//不可缓存的数据准备好，此信号与uncache_data一个周期出现
.EXUi_BIU_L1d_syncok        (EX_BIUo_L1d_syncok)
);
//CU RW\U  控制 寄存器单元
cu_ru cu_ru(
.clk					(clk),
.rst					(!hreset_n),

//外部中断信号
.m_time_int				(m_time_int),
.m_soft_int				(m_soft_int),
.m_ext_int				(m_ext_int),	//对M模式的中断信号

//对IF信号
.int_req				(CUo_int_req),		//中断请求信号
.flush_pc				(IFi_new_pc),	//新的PC值
.pip_flush				(IFi_pip_flush),		//流水线冲刷信号

//对ID信号
.tvm					(CUo_tvm),
.tsr					(CUo_tsr),
.tw						(CUo_tw),
.id_csr_index			(IDo_DEC_csrindex),
.csr_data				(CU_IDi_DATA_csr),	//被ID读取的CSR值
.rs1_index				(IDo_DEC_rs1index),
.rs1_data				(CU_IDi_DATA_rs1),
.rs2_index				(IDo_DEC_rs2index),
.rs2_data				(CU_IDi_DATA_rs2),

.fs1_index				(IDo_DEC_fs1index),
.fs1_data				(CU_IDi_DATA_fs1),
.fs2_index				(IDo_DEC_fs2index),
.fs2_data				(CU_IDi_DATA_fs2),

.vs1_index				(IDo_DEC_vs1index),
.vs1_data				(CU_IDi_DATA_vs1),
.vs2_index				(IDo_DEC_vs2index),
.vs2_data				(CU_IDi_DATA_vs2),

//对EX信号
//.mprv					(mprv),
//.mod_priv				(mod_priv),

//WB输入信号

.data_rd				(EX_CUi_DATA_rd),
.data_fd				(EX_CUi_DATA_fd),
.data_vd				(EX_CUi_DATA_vd),
.data_csr				(EX_CUi_DATA_csr),
.new_pc					(EX_CUi_DATA_newpc),


//对BIU信号

//写回控制
.csr_write				(EX_CUi_WB_CSRwrite),
.gpr_write				(EX_CUi_WB_GPRwrite),
.fgpr_write			    (EX_CUi_WB_FREGwrite),
.vgpr_write			    (EX_CUi_WB_VREGwrite),
.pc_jmp					(EX_CUi_WB_PCjmp),				//新的PC需要被更改，新的PC由pc_new给出，该信号表明WB阶段需要修改PC
.csr_index				(EX_CUi_WB_CSRindex),
.rd_index				(EX_CUi_WB_RDindex),
.fd_index               (EX_CUi_WB_FDindex),
.vd_index               (EX_CUi_WB_VDindex),
//异常码
.ins_pc					(EX_CUi_DATA_pc),
.exc_code				(EX_CUi_DATA_tval),		//如果是非法指令异常，则为非法指令，如果是硬件断点和储存器访问失败，则是虚拟地址

//机器控制段
//机器控制段负责WB阶段时csr的自动更新
.id_system				(EX_CUi_FC_system),		//system指令，op code=system的时候被置1
.id_jmp					(EX_CUi_FC_jmp),			//会产生跳转的指令 opcode=branch时候置1
.ins_acc_fault			(EX_CUi_MSC_ins_acc_fault),	//指令访问失败
.ins_addr_mis			(EX_CUi_MSC_ins_addr_mis), 	//指令地址错误
.ins_page_fault			(EX_CUi_MSC_ins_page_fault),	//指令页面错误
.ld_addr_mis			(EX_CUi_MSC_load_addr_mis),		//load地址不对齐
.st_addr_mis			(EX_CUi_MSC_store_addr_mis),		//store地址不对齐
.ld_acc_fault			(EX_CUi_MSC_load_acc_fault),	//load访问失败
.st_acc_fault			(EX_CUi_MSC_store_acc_fault),	//store访问失败
.ld_page_fault			(EX_CUi_MSC_load_page_fault),	//load页面错误
.st_page_fault			(EX_CUi_MSC_store_page_fault),	//store页面错误
.int_acc				(EX_CUi_MSC_interrupt),			//中断接收信号
.valid					(EX_CUi_MSC_valid), 			//指令有效信号
.ill_ins				(EX_CUi_MSC_ill_ins),			//异常指令信号
.m_ret					(EX_CUi_MSC_mret),			//返回信号
.s_ret					(EX_CUi_MSC_sret),			//
.ecall					(EX_CUi_MSC_ecall),			//环境调用
.ebreak					(EX_CUi_MSC_ebreak),			//断点
//-------------流控信号--------------
.CUo_FC_nop             (EX_CUo_FC_nop),
.CUi_FC_system          (EX_CUi_FC_system),
.CUi_FC_jmp             (EX_CUi_FC_jmp),
.CUo_FC_war             (EX_CUo_FC_war),
.CUi_FC_rs1index        (IDo_DEC_rs1index),
.CUi_FC_rs2index        (IDo_DEC_rs2index),
.CUi_FC_warcheck        (IDo_DEC_warcheck)	//数据相关检查使能


);


endmodule