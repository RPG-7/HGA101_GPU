module ALU16(

//操作码 ALU,运算码
//rd数据选择
input wire enable,		//ds1直通
input wire addsel,		//加
input wire subsel,		//减
input wire andsel,		//逻辑&
input wire orsel,		//逻辑|
input wire xorsel,		//逻辑^
input wire sltsel,		//比较大小
input wire maxsel,
input wire minsel,
input wire mulsel,

input wire srasel,
input wire srlsel,
input wire sllsel,



//数据输入							   
input wire [15:0]ds1,		//数据源1，imm/rs1/rs1/csr/pc /pc
input wire [15:0]ds2,		//数据源2，00 /rs2/imm/imm/imm/04


output gt,
output eq,
output [15:0]alu_data_rd,
output [31:0]rd_out

);

wire [15:0]alu_add;		//加法运算
wire [15:0]add_16;		//纯16位加法运算
wire [15:0]sub_16;		//纯16位减法运算
wire [15:0]alu_sub;
wire [15:0]alu_and;
wire [15:0]alu_or;
wire [15:0]alu_xor;
wire [15:0]alu_slt;
wire [15:0]alu_shift;	//移位指令

wire [15:0]alu_lr_sc;
wire [15:0]alu_max;
wire [15:0]alu_min;
//ds1与ds2的数据大小比较
wire ds1_light_than_ds2;
wire ds1_great_than_ds2;
wire ds1_equal_ds2;
wire unsign=1'b0;
assign ds1_light_than_ds2	=	!unsign&((ds1[15]&!ds2[15])|				//ds1是负数，ds2是正数（有符号）
								(ds1[15]==ds2[15]) & (ds1 < ds2))|			//ds1，ds2同符号（有符号）
								unsign&(ds1 < ds2);							//无符号比较
assign gt	=	!unsign&((!ds1[15]&ds2[15])|				//ds1正，ds2负
								(ds1[15]==ds2[15]) & (ds1 > ds2))|			//有符号时候同号比较
								unsign&(ds1 < ds2);							//无符号时直接比较大小
assign eq		=	(ds1 == ds2);

assign add_16			=	ds1 + (subsel?(~ds2):ds2);			//当加法指令时，ds1和ds2正常相加，当减法指令时，对DS2取反
assign sub_16			=	add_16	+	16'b1;						//减法指令时，已经对ds2取反和ds1相加，再加1就相当于ds1-ds2（补码运算）


assign alu_and			=	ds1	& ds2;			//当需要进行清零操作时候，ds2的数据被按位取反，此时是CSRRCx指令，DS1是CSR，DS2是RS1
assign alu_or			=	ds1 | ds2;
assign alu_xor			=	ds1 ^ ds2;

assign alu_max			=	ds1_great_than_ds2?ds1 : ds2;			//在AMO指令中，DS1被切换到MEM的数据
assign alu_min			=	ds1_light_than_ds2?ds1 : ds2;


assign alu_data_rd		=	(!enable 		? ds1		: 16'b0)|			//ds1直通
							(addsel 		? alu_add 	: 16'b0)|		//加
							(subsel 		? alu_sub 	: 16'b0)|		//减
							(andsel			? alu_and 	: 16'b0)|		//逻辑&
							(orsel 			? alu_or 	: 16'b0)|		//逻辑|
							(xorsel 		? alu_xor 	: 16'b0)|		//逻辑^
							((sllsel|srlsel|srasel)	? alu_shift	: 16'b0)|	//移位
							(maxsel			? alu_max 	: 16'b0)|		//逻辑&
							(minsel 		? alu_min 	: 16'b0);

assign rd_out={{17{ds1[15]}},ds1[14:0]};
//筒形移位器
///*
//Type: 00/01=Left Shift
//10=Right Shift, 0 Filled
//11=Right Shift,with symbol extent
//*/
bshifter16 bshifter16
(
    .datain		(ds1),
    .typ		({!sllsel,!srlsel}),
    .shiftnum	(ds2[3:0]),
    .dataout	(alu_shift)
);
endmodule
