(* DONT_TOUCH = "yes" *)
    //-----------------------------------------------------
    module dualPortStaticRam (
        address_1     , // Address Input
        address_2     , // Address Input
        data        , // Data input
        we_,
        clock,
        clock2,
        Q_1,               //output
        Q_2               //output
        );
        parameter ROMFILE = "noFile";
        parameter DATA_WIDTH = 8 ;
        parameter ADDR_WIDTH = 8 ;
        parameter RAM_DEPTH = 1 << ADDR_WIDTH;
        
    
        //--------------Input Ports----------------------- 
        input [ADDR_WIDTH-1:0] address_1 ;
        input [ADDR_WIDTH-1:0] address_2 ;
        input [DATA_WIDTH-1:0]  data;
        input we_;
        input clock;
        input clock2;
    
        //--------------Output Ports----------------------- 
        output reg [DATA_WIDTH-1:0] Q_1;
        output reg [DATA_WIDTH-1:0] Q_2;
        integer i;
        //--------------Internal variables----------------
        reg [DATA_WIDTH-1:0] mem [RAM_DEPTH-1:0];
        
        //--------------Code Starts Here------------------ 
        initial begin
          $readmemb(ROMFILE, mem);
          for (i = 0; i < RAM_DEPTH; i = i + 1) begin
          //#1 $display("%d: %d ",i,mem[i]);
          end
        end
        
        always @(posedge clock)
        begin
          if (!we_) begin
            mem[address_1] = data;
          end
          else begin
           Q_1 <=  mem[address_1];
          end
        end
        
        always@(posedge clock2) begin
            Q_2 = mem[address_2];
        end
        
        endmodule