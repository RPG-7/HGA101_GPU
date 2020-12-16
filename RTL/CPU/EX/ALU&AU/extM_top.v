module extM_top
(
    input clk,
    input rst_n,
    input rd_data_mdiv,
    input rd_mdiv_mdivsel,
    input rd_mdiv_hlowsel,
    input rd_mdiv_signsel,
    input [31:0]ds1,
    input [31:0]ds2,
    output [31:0]rd,
    output div_done

);
wire [63:0]MULO,DIVO,MDIVMUX,MDIVADJ;
wire [31:0]op1,op2,abs1,abs2;
wire sgn_out;
assign sgn_out=ds1[31]^ds2[31];
assign abs1=(ds1[31])?((~ds1[30:0])+1):ds1[30:0];
assign abs2=(ds1[31])?((~ds1[30:0])+1):ds1[30:0];
assign MDIVADJ=(rd_mdiv_mdivsel)?DIVO:MULO;
assign MDIVMUX=(rd_mdiv_hlowsel&sgn_out)?((~MDIVADJ)+1):MDIVADJ;
assign rd=(rd_mdiv_hlowsel)?MDIVMUX[63:32]:MDIVMUX[31:0];
assign op1=rd_mdiv_signsel?ds1:abs1;
assign op2=rd_mdiv_signsel?ds2:abs2;
MUL multiply_1t
(
    .rs1(op1),
    .rs2(op2),
    .rd(MULO)
);
MulCyc_Div divide_33t
(
    .clk(clk),
	.rst_n(rst_n),
	.DIVIDEND(op1),
	.DIVIDSOR(op2),
	.start(rd_data_mdiv&rd_mdiv_mdivsel),
	.DIV(DIVO[31:0]),
	.MOD(DIVO[63:32]),
	.ready(div_done) //Calculate done
);

endmodule
