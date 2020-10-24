`timescale 1ns / 1ps

module FIFO(clk_i, data_i, reset_i, r_en_i, w_en_i, data_o, empty_o, full_o, count_o );
input clk_i;
input reset_i;
input [DATA_WIDTH-1:0]data_i;
input r_en_i;
input w_en_i;

output reg [DATA_WIDTH-1:0]data_o;
output empty_o;
output full_o;
output count_o; 

parameter DATA_WIDTH = 8;
parameter RAM_DEPTH = 8;
  
reg [RAM_DEPTH:0]count;
reg [DATA_WIDTH-1:0]memory[RAM_DEPTH-1:0];
reg [2:0]wr_pointer, rd_pointer;
reg full, empty;
reg [DATA_WIDTH-1:0]dataout;

// reading data out from the FIFO
always @( posedge clk_i or posedge reset_i)
begin
   if( reset_i )
   begin
      dataout <= 0;
      //memory <= {RAM_DEPTH{DATA_WIDTH{1'b0}}};
   end
   else
   begin
      if( r_en_i && !empty_o )
         dataout <= memory[rd_pointer];

      else
         dataout <= dataout;

   end
end

//writing data in the FIFO
always @(posedge clk_i)
begin
   if( w_en_i && !full_o )
      memory[wr_pointer] <= data_i;

   else
      memory[wr_pointer] <= memory[wr_pointer];
end



//pointer increment system
always @ (posedge clk_i or posedge reset_i)
begin 
	if(reset_i)
	begin
	//reset pointers
		wr_pointer <= 0;
		rd_pointer <= 0;
	end
	else
	begin
	//write data increment pointer
		if(!full_o && w_en_i)
		wr_pointer <= wr_pointer+1;
	//do nothing
		else
		wr_pointer <= wr_pointer;
	//read data, increment pointer
		if(!empty_o && r_en_i)
		rd_pointer <= rd_pointer+1;
	//do nothing
		else
		rd_pointer <= rd_pointer;
	end
end

//set states of full,empty flags
always @(posedge clk_i or posedge reset_i)
begin
   if( reset_i )
       count <= 0;

   // trying to both read and write while fifo is in good state
   // count stays the same. - This is valid because there is only
   // one clock for this fifo.
   else if( (!full_o && w_en_i) && ( !empty_o && r_en_i ) )
       count <= count;
    // writing not full, increment
   else if( !full_o && w_en_i )
       count <= count + 1;
    //reading and not empty, decrement
   else if( !empty_o && r_en_i )
       count <= count - 1;
   else
      count <= count;
end

//for full and empty
//use blocking assigns for combinatoral logic
always @(count)
begin
if(count==0)
  empty = 1 ;
  else
  empty = 0;

  if(count==RAM_DEPTH)
   full = 1;
   else
   full = 0;
end

endmodule
