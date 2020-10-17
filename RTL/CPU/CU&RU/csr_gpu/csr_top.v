module csr_top
(
    input clk,
    input rst,
    input [11:0]csr_read_index,
    input [11:0]csr_write_index,
    input csr_write,
    input [31:0]csr_data_w,
    output [31:0]csr_data_r,

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


endmodule
