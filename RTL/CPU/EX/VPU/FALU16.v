/****************************************
This is 16bit FPU, can only do half add/sub/mul 
for HGA101 project

****************************************/
module FALU16
(
    input enable,
    input [15:0]op1,
    input [15:0]op2,
    input vec_en,//enable VECTOR (replace op2 with fullin)
    input addsel,//Add/subtract control 0=add,1=subtract
    input subsel,//add/sub select
    input mulsel, //multiply select
    input itfsel, //integer to float
    input ftisel, //float to integer
    input maxsel,
    input minsel,
    input [31:0]fullin,//Full range float in 
    input ftlsel,
    output [31:0]fullout,//float out to float reg
    output [15:0]opout,
    output gt,
    output eq
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
assign sign1=(ftlsel)?ftlout[15]:op1[15];
assign sign2=(vec_en)?ftlout[15]:op2[15];
assign exp1=(ftlsel)?ftlout[14:10]:op1[14:10];
assign exp2=(vec_en)?ftlout[14:10]:op2[14:10];
assign val1=(ftlsel)?ftlout[9:0]:op1[9:0];
assign val2=(vec_en)?ftlout[9:0]:op2[9:0];
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
wire much_larger,diff_sym;
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
assign eq=(op1==op2);
assign gt=(diff_sym)?((sign1==0)?1'b1:1'b0)://Condition:Different symbol
        ((sign1==0)?                           //condition:both positive
                ((exp_cmp[1])?(!exp_cmp[0]):(val1>val2))://if so,if exp1!=exp2,larger exp,eles larger val
                ((exp_cmp[1])?(exp_cmp[0]):(val1<val2)));//both neg case
//FASUB
wire [15:0]acalc;
wire [9:0]aval;
wire [10:0]aout;
wire [10:0]aligned_out;
bshifter16 fshifter1
(
    .datain(base_smaller),
    .shiftnum(exp_diff),
    .typ(2'b10),
    .dataout(aligned_out)
);

assign acalc=(much_larger)?
            (exp_cmp[0]?op1:op2)://in case one is much larger than another, just output the larger
            ({sign1,exp_dif1,aval[9:0]});
assign aval=((sign1^sign2)^subsel)?((aout[10])?aout:((~aout)+1)):aout;//always give out abs
assign aout=(base_larger+(subsel)?(~aligned_out)+1:aligned_out);
//assign ASout=(enable)?acalc:op1;
//FMUL
wire [19:0]valmul;
wire [5:0]expmul;
wire [15:0]mcalc;
assign valmul=val1*val2;
assign expmul=exp1+exp2-6'd15;
assign mcalc=(enable)?{sign1^sign2,expmul[4:0],valmul[19:10]}:op1;


//integer to float
wire [15:0]itfcalc;
reg [3:0]exp_get;
wire [4:0]itf_exp;
wire [15:0]itf_shift;
assign itf_exp=(op1!=0)?exp_get+4'hf:4'h0;
always@(op1[14:0])
    casex(op1[14:0]) 
        15'b1xx_xxxx_xxxx_xxxx:exp_get=4'hf;
        15'b01x_xxxx_xxxx_xxxx:exp_get=4'he;
        15'b001_xxxx_xxxx_xxxx:exp_get=4'hd;
        15'b000_1xxx_xxxx_xxxx:exp_get=4'hc;
        15'b000_01xx_xxxx_xxxx:exp_get=4'hb;
        15'b000_001x_xxxx_xxxx:exp_get=4'ha;
        15'b000_0001_xxxx_xxxx:exp_get=4'h9;
        15'b000_0000_1xxx_xxxx:exp_get=4'h8;
        15'b000_0000_01xx_xxxx:exp_get=4'h7;
        15'b000_0000_001x_xxxx:exp_get=4'h6;
        15'b000_0000_0001_xxxx:exp_get=4'h5;
        15'b000_0000_0000_1xxx:exp_get=4'h4;
        15'b000_0000_0000_01xx:exp_get=4'h3;
        15'b000_0000_0000_001x:exp_get=4'h2;
        15'b000_0000_0000_0001:exp_get=4'h1;
        15'b000_0000_0000_0000:exp_get=4'h0;
        default:exp_get=15'hx;
    endcase
bshifter16 itfshifter1
(
    .datain({op1[14:0],1'b0}),
    .shiftnum(exp_get+1),
    .typ(2'b00),//Left shift
    .dataout(itf_shift)
);

assign itfcalc={op1[15],itf_exp,itf_shift[15:5]};
//float to integer
wire [15:0]fticalc;
wire [15:0]ftival;
wire ftishiftdir,belowzero;
wire [15:0]ftishift;
wire [3:0]ftiexp;//exponential adjust
assign ftival=(sign1)?((~{6'h01,op1[9:0]})+1):{6'h01,op1[9:0]};//补码
assign ftishiftdir=(exp1>=5'h1a)?1'b0:1'b1;
assign ftiexp=(ftishiftdir)?(4'd10-exp1[4:0]):(exp1[4:0]-4'd10);
assign belowzero=(exp1<5'h10);

bshifter16 ftishifter1
(
    .datain(ftival),
    .shiftnum(ftiexp),
    .typ({ftishiftdir,1'b1}),//
    .dataout(ftishift)
);
assign fticalc=(belowzero)?16'b0:{op1[15],ftishift[14:0]};
wire [15:0]maxout,minout,ftlout;
wire [7:0] ftlexpgen,ltfexpgen;
assign maxout=(gt)?op1:op2;
assign minout=(gt)?op2:op1;
assign ftlexpgen=fullin[30:22]-8'd112;
assign ltfexpgen=exp1+8'd112;
assign ftlout={fullin[31],ftlexpgen[4:0],fullin[22:13]};
assign fullout={op1[15],ltfexpgen,val1,13'b0};
//OUTPUT STAGE    
assign opout=   (!enable 		? op1		: 16'b0)|//ds1直通,lane unchanged
			    ((addsel|subsel)? acalc 	: 16'b0)|//加
                (mulsel 		? mcalc 	: 16'b0)|
				(itfsel 		? itfcalc 	: 16'b0)|//short to half
                (ftisel 		? fticalc  	: 16'b0)|//half to short
                (maxsel 		? maxout 	: 16'b0)|//lane max
                (minsel 		? minout  	: 16'b0)|//lane max
                (ftlsel 		? ftlout  	: 16'b0); //float to half lane


endmodule
