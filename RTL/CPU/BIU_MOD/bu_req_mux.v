/*

*/
module bu_req_mux(
input wire clk,
input wire rst,
//cache bug unit
//L1-I
input wire I_read_line_req,		//请求读一行
input wire [3:0]I_size,
input wire [63:0]I_pa,			//
input wire [63:0]I_wt_data,
output wire [63:0]I_line_data,
output wire [10:0]I_addr_count,
output wire I_line_write,			//cache写
output wire I_cache_entry_write,	//更新缓存entry
output wire I_trans_rdy,			//传输完成
output wire I_bus_error,			//访问失败
//L1-D
input wire D_write_through_req,	//请求写穿
input wire D_write_line_req,
input wire D_read_req,			//请求读一次
input wire D_read_line_req,		//请求读一行

input wire [3:0]D_size,
input wire [63:0]D_pa,			//
input wire [63:0]D_wt_data,
output wire [63:0]D_line_data,
output wire [10:0]D_addr_count,
output wire D_line_write,			//cache写
output wire D_cache_entry_write,	//更新缓存entry
output wire D_trans_rdy,			//传输完成
output wire D_bus_error,			//访问失败
//L1 bus unit
output wire write_through_req,	//请求写穿
output wire write_line_req,
output wire read_req,			//请求读一次
output wire read_line_req,		//请求读一行
output wire [3:0]size,
output wire [63:0]pa,			//
output wire [63:0]wt_data,
input wire [63:0]line_data,
input wire [10:0]addr_count,
input wire line_write,			//cache写
input wire cache_entry_write,	//更新缓存entry
input wire trans_rdy,			//传输完成
input wire bus_error			//访问失败
);

//D尝试访问内存
reg [1:0]cache_access_state;
wire D_access;
wire I_access;

always@(posedge clk)begin
	if(rst)begin
		cache_access_state	<=	2'b00;
	end
	else begin
		case(cache_access_state)
			2'b00	:	if(D_read_req|D_read_line_req|D_write_through_req|D_write_line_req)begin
							cache_access_state	<=	2'b01;			//D访问允许
						end
						else if(I_read_line_req)begin
							cache_access_state	<=	2'b10;			//I访问允许
						end
			2'b01	:	cache_access_state	<=	(trans_rdy | bus_error) ? 2'b00 : cache_access_state;
			2'b10	:	cache_access_state	<=	(trans_rdy | bus_error) ? 2'b00 : cache_access_state;
		endcase
	end
end
assign D_access	=	(cache_access_state==2'b01);
assign I_access	=	(cache_access_state==2'b10);

//送cache bus unit信号
//只有access信号需要进行选择
assign write_through_req	=	D_write_through_req;	//请求写穿
assign read_req				=	D_read_req;			//请求读一次
assign write_line_req		=	D_write_line_req;
assign read_line_req		=	D_access & D_read_line_req | I_access & I_read_line_req;		//请求读一行

assign size					=	D_access ? D_size : I_size;
assign pa					=	D_access ? D_pa : I_pa;			
assign wt_data				=	D_access ? D_wt_data : I_wt_data;
//L1-I反馈信号
assign I_line_data	=	line_data;
assign I_addr_count	=	addr_count;
assign I_line_write	=	I_access & line_write;			//cache写
assign I_cache_entry_write	=	I_access & cache_entry_write;	//更新缓存entry
assign I_trans_rdy	=	I_access & trans_rdy;		//传输完成
assign I_bus_error	=	I_access & bus_error;			//访问失败
//L1D反馈信号
assign D_line_data	=	line_data;
assign D_addr_count	=	addr_count;
assign D_line_write	=	D_access & line_write;			//cache写
assign D_cache_entry_write	=	D_access & cache_entry_write;	//更新缓存entry
assign D_trans_rdy	=	D_access & trans_rdy;		//传输完成
assign D_bus_error	=	D_access & bus_error;			//访问失败


endmodule
