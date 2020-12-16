module GPR(
    input wire clk,
    input wire rst,
    input wire [4:0]read_rs1_addr,
    input wire [4:0]read_rs2_addr,
    input wire write_en,
    input wire read_hold,               //output data hold
    input wire [4:0]write_rd_addr,
    input wire [63:0]rd_data,
    output wire [63:0]rs1_data_out,
    output wire [63:0]rs2_data_out
);
//Register Unit
reg [63:0]memcell1[31:0];
reg [63:0]memcell2[31:0];
//------------------------------
//registers for hold data
reg [63:0]rs1_data_hold;
reg [63:0]rs2_data_hold;
//memory block output
reg [63:0]rs1_data;
reg [53:0]rs2_data;

reg state_hold;

always@(posedge clk)begin
    rs1_data    <=  memcell1[read_rs1_addr];
    rs2_data    <=  memcell2[read_rs2_addr];
    if(write_en)begin
        memcell1[write_rd_addr] <=  rd_data;
        memcell2[write_rd_addr] <=  rd_data;
    end
end

always@(posedge clk)begin
    if(rst)begin
        state_hold <= 1'b0;
    end
    else begin
        case(state_hold)
            1'b0:   state_hold <= read_hold;
            1'b1:   state_hold <= read_hold;
    end
end

always@(posedge clk)begin
    if(rst)begin
        rs1_data_hold   <=  64'b0;
        rs2_data_hold   <=  64'b0;
    end
    else if(read_hold & !state_hold)begin
        rs1_data_hold   <=  rs1_data;
        rs2_data_hold   <=  rs2_data;
    end
end 
assign rs1_data_out =   hold ? rs1_data_hold : rs1_data;
assign rs2_data_out =   hold ? rs2_data_hold : rs2_data;

endmodule
