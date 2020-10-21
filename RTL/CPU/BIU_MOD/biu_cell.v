/*
biu_cell单元，是PRV464SX2处理器总线接口部件中的一个部分
*/
`include "global_defines.vh"
module biu_cell(
//全局信号
input wire clk,
input wire rst,

input wire cache_only,
input wire [31:0]cacheability_block,	//可缓存的区，即物理地址[63:31],这个区间里的内存是可以缓存的

//csr信号
//访问接口
input wire unpage,				//只使用物理地址
input wire [3:0]priv,			//权限，0001=U 0010=S 0100=H 1000=M 
input wire [63:0]v_addr,
input wire [`FCU_DDATA_WIDTH-1:0]data_write,
output wire[`FCU_DDATA_WIDTH-1:0]data_read,
output wire[`FCU_DDATA_WIDTH-1:0]data_uncache,
input wire [3:0]size,			//0001=1Byte 0010=2Byte 0100=4Byte 1000=8Byte other=fault			
input wire L1_clear,

input wire read,				//读数据信号
input wire write,				//写数据信号
input wire execute,

output wire ins_page_fault,
output wire ins_acc_falt,
output wire load_acc_fault,
output wire load_page_fault,
output wire store_acc_fault,
output wire store_page_fault,
output wire cache_data_ready,		//cache数据准备好
output wire uncache_data_rdy,	//不可cache的数据准备好


input wire ready,
input wire entry_write,
input wire TLB_D_set,
input wire page_fault,

//对Cache bus unit信号
output wire L1_write_through_req,	//请求写穿 
output wire read_req,			//请求读一次
output wire read_line_req,		//请求读一行
output wire [3:0]L1_size,
output wire [`FCU_IADDR_WIDTH-1:0]pa,			//
output wire [`FCU_DDATA_WIDTH-1:0]wt_data,
input wire [63:0]line_data,
input wire [10:0]addr_count,
input wire line_write,			//cache写
input wire cache_entry_write,	//更新缓存entry
input wire trans_rdy,			//传输完成
input wire bus_error			//访问失败
);

wire [`FCU_IADDR_WIDTH-1:0]PA;			//最终生成的PA




//对l1信号
wire L1_write;
wire L1_read;
wire L1_execute;
//TODO 这里还要改，接驳总线
wire PTE_C=1;			//页面可以缓存



//物理地址
//当虚拟内存打开并且没有禁用页表时，使用转换后的地址
assign PA	=	 v_addr ;  



//L1控制信号
	
assign L1_read		=read;
assign L1_write		=write;
assign L1_execute	=execute;


//L1缓存

l1				L1(
//配置信号
.cache_only			(cache_only),
.cacheability_block	(cacheability_block),
.clk				(clk),
.rst				(rst),

//访问信号
.read				(L1_read),
.write				(L1_write),
.execute			(L1_execute),
.L1_clear			(L1_clear),			//L1缓存清零，用于fence指令同步数据

.size				(size),				//

.PTE_C				(PTE_C),			//页表项表示可缓存

.addr_pa			(PA),
.data_write			(data_write),
.data_read			(data_read),
//应答通道
.load_acc_fault		(load_acc_fault),
.store_acc_fault	(store_acc_fault),
.ins_acc_fault		(ins_acc_falt),
.cache_data_ready	(cache_data_ready),	//可缓存的数据准备好
.uncache_data_ready	(uncache_data_rdy),	//不可缓存的数据准备好

//cache控制器逻辑
.write_through_req	(L1_write_through_req),	//请求写穿
.read_req			(read_req),			//请求读一次
.read_line_req		(read_line_req),		//请求读一行
.L1_size			(L1_size),
.pa					(pa),			//
.wt_data			(wt_data),
.line_data			(line_data),
.addr_count			(addr_count),
.line_write			(line_write),			//cache写
.cache_entry_write	(cache_entry_write),	//更新缓存entry
.trans_rdy			(trans_rdy),			//传输完成
.bus_error			(bus_error)			//访问失败
);
assign data_uncache	=	data_read;


endmodule















