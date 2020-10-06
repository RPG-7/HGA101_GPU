/****************************************
This is 16bit FPU, can only do half add/sub/mul 
for HGA101 project

****************************************/
module FALU16
(
    input [15:0]op1,
    input [15:0]op2,
    input ASC, //Add/subtract control 0=add,1=subtract
    output reg[15:0]ASout,
    output reg[15:0]Mout,
    input clk
);
wire sign1,sign2;
wire [4:0]exp1;
wire [4:0]exp2;
wire exp_sgn1,exp_sgn2;
//wire [4:0]exp_diff;

wire [9:0]val1;
wire [9:0]val2;
wire inf1,inf2,nan1,nan2;
wire zero1,zero2;
assign sign1=op1[15];
assign sign2=op2[15];
assign exp1=op1[14:10];
assign exp2=op2[14:10];
assign val1=op1[9:0];
assign val2=op2[9:0];
assign exp_sgn1=exp1[4];
assign exp_sgn2=exp2[4];
//op status generation
assign nan1=(val1!=0&(exp1==5'h1f));//NaN Gen
assign nan2=(val2!=0&(exp2==5'h1f));
assign inf1=(val1==0&(exp1==5'h1f));//Inf Gen
assign inf2=(val2==0&(exp2==5'h1f));
assign zero1=(exp1==0&val1==0);
assign zero2=(exp2==0&val2==0);
//FCMP
wire [1:0]exp_cmp; //00=expA>expB,01=expA<expB,10=expA=expB
wire [5:0]exp_diff;
wire [5:0]exp_dif1,exp_dif2;
wire [10:0]base_smaller;
wire [10:0]base_larger;
wire much_larger;
assign diff_sym=sign1^sign2;
assign exp_diff=exp_dif1-exp_dif2;
assign much_larger=(exp_diff>5'd10);
//generate difference of exponential word
assign exp_cmp=(exp1==exp2)?2'b10:
        (exp1>exp2)?2'b00:2'b01;
assign exp_dif1=(exp_cmp[0])?exp1:exp2;
assign exp_dif2=(!exp_cmp[0])?exp1:exp2;
assign base_larger=(exp_cmp[0])?{1'b1,val1}:{1'b1,val2};
assign base_smaller=(!exp_cmp[0])?{1'b1,val1}:{1'b1,val2};
//FASUB
wire [15:0]acalc;
wire [9:0]aval;
wire asctrl;
wire [10:0]add,sub;
wire [10:0]aligned_out;
wire sigout_as;
LRS16 fshifter1
(
    .din(base_smaller),
    .shift(exp_diff),
    .dout(aligned_out)
);
assign sigout_as=(sign1);
assign acalc=(much_larger)?
            (exp_cmp[0]?op1:op2)://in case one is much larger than another, just output the larger
            ({sigout_as,exp_dif1,aval[9:0]});
assign aval=((sign1^sign2)^ASC)?((sub[10])?sub:((~sub)+1)):add;
assign add=(base_larger+aligned_out);
assign sub=(base_larger+(~aligned_out)+1);
always@(posedge clk)
begin
    ASout=acalc;
end
//FMUL
wire [19:0]valmul;
wire [5:0]expmul;
assign valmul=val1*val2;
assign expmul=exp1+exp2-5'd15;
always @(posedge clk) 
begin
    Mout={sign1^sign2,expmul[4:0],valmul[19:10]};
end



endmodule
