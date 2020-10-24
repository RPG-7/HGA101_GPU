(* DONT_TOUCH = "yes" *)
        //-----------------------------------------------------
        module staticRamDiscretePorts (
            address     , // Address Input
            data        , // Data input
            we_,
            clock,
            Q               //output
            );
            parameter ROMFILE = "noFile";
            parameter DATA_WIDTH = 8 ;
            parameter ADDR_WIDTH = 8 ;
            parameter RAM_DEPTH = 1 << ADDR_WIDTH;
            
        
            //--------------Input Ports----------------------- 
            input [ADDR_WIDTH-1:0] address ;
            input [DATA_WIDTH-1:0]  data;
            input we_;
            input clock;
        
            //--------------Output Ports----------------------- 
            output reg [DATA_WIDTH-1:0] Q;
            integer i;
            //--------------Internal variables----------------
            reg [DATA_WIDTH-1:0] mem [RAM_DEPTH-1:0];
            
            //--------------Code Starts Here------------------ 
            initial begin
             $readmemb(ROMFILE, mem);
              for (i = 0; i < RAM_DEPTH; i = i + 1) begin
              //#1 $display("%d",mem[i]);
              end
            end
            
            always @(posedge clock)
            begin
              if (!we_) begin
                mem[address] <= data;
                end
                else begin
               Q <= mem[address];
               end
            end
            
            endmodule
    