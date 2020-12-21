/*
This part is the shell scripts which will be extracted by autosim 
act as preprocessor and execute before running the testbench itself.
Convenient for tasks such as generate random instruction flow 
for processor verification.
---------THE FORMAT SHOWS AS FOLLOWING-----------------------
#PREPROCESS_START 

if ! test -s ./sim/obj/fop_a.hex ; then
    echo test case generated 
    ./sim/c_tools/calctestgen_half -all 32 ./sim/obj/fop
fi

#PREPROCESS_END 
*/
`timescale 1ns/100ps
module fpu16_tb ();
reg clk,asel,ssel,msel,dsel;
reg [15:0]op1[31:0];
reg [15:0]op2[31:0];
reg [6:0]opcnt;
wire [15:0]DOUT;
always #5 clk=~clk;
initial 
begin
    $dumpfile("./sim/obj/fpu16_tb.vcd"); // 指定用作dumpfile的文件
    $dumpvars; // dump all vars
    $readmemh("./sim/obj/fop_a.hex",op1);
    $readmemh("./sim/obj/fop_b.hex",op2);
    #0 clk=0;opcnt=0;{asel,ssel,msel,dsel}<=4'b1000;
end
always @(posedge clk)
begin
    opcnt<=opcnt+1;
    if(opcnt==7'h7f)$finish;
    case(opcnt[6:5])
        2'b00:{asel,ssel,msel,dsel}<=4'b1000;
        2'b01:{asel,ssel,msel,dsel}<=4'b0100;
        2'b10:{asel,ssel,msel,dsel}<=4'b0010;
        2'b11:{asel,ssel,msel,dsel}<=4'b0001;
    endcase
end

FALU16 DUT
(
    .enable(1'b1),
    .op1(op1[opcnt[4:0]]),
    .op2(op2[opcnt[4:0]]),
    .vec_en(1'b0),//enable VECTOR (replace op2 with fullin)
    .addsel(asel),//Add/subtract control 0=add,1=subtract
    .subsel(ssel),//add/sub select
    .mulsel(msel), //multiply select
    .itfsel(1'b0), //integer to float
    .ftisel(1'b0), //float to integer
    .maxsel(1'b0),
    .minsel(1'b0),
    .fullin(32'b0),//Full range float in 
    .ftlsel(1'b0),
    .fullout(),//float out to float reg
    .opout(DOUT),
    .gt(),
    .eq()
);

endmodule