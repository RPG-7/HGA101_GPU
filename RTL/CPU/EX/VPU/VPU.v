module VPU(
	 input vec_en,
    input ifsel,//Function integer/float select
    input addsel,
    input subsel,
    input mulsel,
    input itfsel, //integer to float
    input ftisel, //float to integer
    input lanesel,
    input maxsel,
    input minsel,
    input andsel,		//逻辑&
    input orsel,		//逻辑|
    input xorsel,
    input srasel,
    input srlsel,
    input sllsel,
    input cgesel,//compare:great equal
    input cltsel,
    input ceqsel,
    input cnqsel,
    input [127:0]vs1,
    input [127:0]vs2,
    input [31:0]fs,
    input [31:0]rs,
    input [31:0]mask_in,//MASK=maskreg|{32{!masken}}
    output [31:0]rd,
    output [31:0]fd,
    output [127:0]vd

);
wire [127:0]FPUout,ALUout;
wire [31:0]Fcmpout,Acmpout;
wire [7:0]fgt,feq,fcmpo;
wire [7:0]igt,ieq,icmpo;
wire [31:0]fd_arr[7:0];
wire [31:0]rd_arr[7:0];
assign vd=(ifsel)?FPUout:ALUout;
assign fd=  (fd_arr[0]&{32{mask_in[0]}})|
            (fd_arr[1]&{32{mask_in[1]}})|
            (fd_arr[2]&{32{mask_in[2]}})|
            (fd_arr[3]&{32{mask_in[3]}})|
            (fd_arr[4]&{32{mask_in[4]}})|
            (fd_arr[5]&{32{mask_in[5]}})|
            (fd_arr[6]&{32{mask_in[6]}})|
            (fd_arr[7]&{32{mask_in[7]}});
assign rd=  (cgesel|cltsel|ceqsel|cnqsel)?
            {24'h0,(ifsel)?fcmpo:icmpo}:
           ((rd_arr[0]&{32{mask_in[0]}})|
            (rd_arr[1]&{32{mask_in[1]}})|
            (rd_arr[2]&{32{mask_in[2]}})|
            (rd_arr[3]&{32{mask_in[3]}})|
            (rd_arr[4]&{32{mask_in[4]}})|
            (rd_arr[5]&{32{mask_in[5]}})|
            (rd_arr[6]&{32{mask_in[6]}})|
            (rd_arr[7]&{32{mask_in[7]}}));
assign fcmpo=   (cgesel ?   (fgt|feq)   : 7'h00)|
                (cltsel ?   !(fgt|feq)  : 7'h00)|
                (ceqsel ?       feq     : 7'h00)|
                (cnqsel ?   !   feq     : 7'h00);
assign icmpo=   (cgesel ?   (igt|ieq)   : 7'h00)|
                (cltsel ?   !(igt|ieq)  : 7'h00)|
                (ceqsel ?       ieq     : 7'h00)|
                (cnqsel ?   !   ieq     : 7'h00);


genvar i;//Array gen
generate 
    for(i=0;i<8;i=i+1) 
    begin : VPU_FPU
        FALU16 FPU16_ARR
        (
            .enable(mask_in[i]),//if not enabled, send out s1
            .op1(vs1[15+16*i:16*i]),
            .op2(vs2[15+16*i:16*i]),
            .vec_en(vec_en),
            .addsel(addsel),//add/sub select
            .subsel(subsel),
            .mulsel(mulsel), //multiply select
            .itfsel(itfsel), //integer to float
            .ftisel(ftisel), //float to integer
            .maxsel(maxsel),
            .minsel(minsel),
            .fullin(fs),//Full range float in 
            .ftlsel(lanesel),
            .fullout(fd_arr[i]),//float out to float reg
            .opout(FPUout[15+16*i:16*i]),
            .gt(fgt[i]),
            .eq(feq[i])
        );
    end                
endgenerate
generate  
for(i=0;i<8;i=i+1) 
    begin : VPU_ALU
        IALU_16 IALU16_ARR
        (
            .vec_en(vec_en),
            .enable(mask_in[i]),		//ds1直通
            .addsel(addsel),		//加
            .subsel(subsel),		//减
            .andsel(andsel),		//逻辑&
            .orsel(orsel),		//逻辑|
            .xorsel(xorsel),		//逻辑^
            .maxsel(maxsel),
            .minsel(minsel),
            .srasel(srasel),
            .srlsel(srlsel),
            .sllsel(sllsel),	
            .itlsel(lanesel),		
            .rs(rs[15:0]),
            .ds1(vs1[15+16*i:16*i]),		//数据源1，imm/rs1/rs1/csr/pc /pc
            .ds2_in(vs2[15+16*i:16*i]),		//数据源2，00 /rs2/imm/imm/imm/04

        //input wire [3:0]shiftcnt,	//操作计数，用于移位指令

            .gt(igt[i]),
            .eq(ieq[i]),
            .rd_out(rd_arr[i]),
            .alu_data_rd(ALUout[15+16*i:16*i])
        );
    end
endgenerate



endmodule
