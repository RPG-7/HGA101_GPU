//16b x 8lane VPU Regfile
module VGPR
(
    input [4:0]rs1,
    input [4:0]rs2,
    output [127:0]rs1o,
    output [127:0]rs2o,
    input [127:0]rdi,
    input [4:0]rd,
    input rdw,
    input clk
);
reg [127:0]vregs[31:0];
assign rs1o=vregs[rs1];
assign rs2o=vregs[rs2];
always @(posedge clk)
begin
    if(rdw)
        vregs[rd]<=rdi;
end

endmodule
