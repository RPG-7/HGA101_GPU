
module MulCyc_Div
	(
	input clk,
	input rst_n,
	input [31:0]DIVIDEND,
	input [31:0]DIVIDSOR,
	input start,
	output reg[31:0]DIV,
	output reg[31:0]MOD,
	output reg ready //Calculate done
	);
	parameter IDLE = 2'd0;
	parameter CALC = 2'd1;
	parameter DONE = 2'd3;
	reg [63:0]mid;
	reg [1:0]state;
	reg [5:0]SCNT;
	reg [1:0]next_state;
	always @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)state<=0;
		else state=next_state;
	end
	always @(*)
	begin
		case(state)
		default:
		begin
			if(start)
				next_state=CALC;
			else next_state=IDLE;
		end
		CALC:
		begin
			if(SCNT==5'h1F)next_state=DONE;
			else next_state=CALC;
		end
		DONE:
		begin
			next_state=IDLE;
		end
		endcase
		
	end
	wire [63:0]DVS;//divisor
	wire [63:0]mid_s;
	wire [63:0]mid_o;
	assign DVS={DIVIDSOR,32'h00000000};
	assign mid_s={mid[63:0],1'b0};
	assign mid_o=(mid_s[63:32]>=DIVIDSOR)?(mid_s-DVS+1):mid_s;
	
	always @(posedge clk or negedge rst_n)
	begin
		if(!rst_n)
		begin
			DIV<=0;
			MOD<=0;
			SCNT<=0;
			ready<=1;
			DIV<=0;
			MOD<=0;
			mid<=0;
		end
		else
			case(next_state)
			default://IDLE
			begin
				mid<={32'h00000000,DIVIDEND};
				SCNT<=0;
				ready<=1;
			end
			CALC:
			begin
				ready<=0;
				SCNT<=SCNT+1;
				mid<=mid_o;
			end
			DONE:
			begin
				DIV=mid[31:0];
				MOD=mid[63:32];
				ready<=1;
			end
			endcase
		
	end
endmodule
