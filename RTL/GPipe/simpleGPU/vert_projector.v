`timescale 1ns / 1ps

module vert_projector(
        input i_clk,
        input in_start,
        input [(N*16)-1:0] mvp_in,
        input [(N*4)-1:0] vertex_in,
        output out_done,
        output [(N*3)-1:0] out_vector
    );
    
       parameter Q = 8;
       parameter N = 16;
    
       wire [(N*4)-1:0] result;
       reg in_start_1;
       
       wire x_division_done;
       wire y_division_done;
       wire z_division_done;

       reg inProgress = 0;
       reg [8:0] counter = 0;
       reg divide_start = 0;
       wire [N-1:0] xResult;
       wire [N-1:0] yResult;
       wire[N-1:0] zResult;
       
       reg out_done_reg = 0;
       reg [(N*3)-1:0] out_vector_reg = 0;
       reg internal_done = 0;
       
       wire  [N-1:0] xcomp  = vertex_in[(N*4)-1:(N*3)];
       wire  [N-1:0] ycomp = vertex_in[(N*3)-1:(N*2)];
       wire  [N-1:0] zcomp= vertex_in[(N*2)-1:(N*1)];
       wire  [N-1:0] wcomp = vertex_in[(N*1)-1:(N*0)];
        
        assign out_done = out_done_reg;
        assign out_vector = out_vector_reg;
       
       localparam WAIT = 33;
       
            
     matrix4x4x1#(
           .Q(Q),
           .N(N)
           ) vertexMultipler 
               (    
                .mvp_in( mvp_in),
               .vertex_in(vertex_in),
               .result( result)
               );
               
               
       // we should instantiate 3 dividers - 
       // one for each vector component.
       // we somehow need to wait to start dividing until the 
       // result is valid...
                            
     qdiv#(
           .Q(Q),
           .N(N))
               xDivider(
               .i_dividend(result[(N*4)-1:(N*3)]),
               .i_divisor(result[N-1:0]),
               .i_start(divide_start),
               .i_clk(i_clk),
               .o_quotient_out(xResult),
               .o_complete(x_division_done)
               );
               
        qdiv#(
            .Q(Q),
            .N(N))
                yDivider(
                .i_dividend(result[(N*3)-1:(N*2)]),
                .i_divisor(result[N-1:0]),
                .i_start(divide_start),
                .i_clk(i_clk),
                .o_quotient_out(yResult),
                .o_complete(y_division_done)
                );
                
    qdiv#(
           .Q(Q),
           .N(N))
               zDivider(
               .i_dividend(result[(N*2)-1:(N*1)]),
               .i_divisor(result[N-1:0]),
               .i_start(divide_start),
               .i_clk(i_clk),
               .o_quotient_out(zResult),
               .o_complete(z_division_done)
               );
               
             
             always@(posedge i_clk) begin
              
              if (inProgress == 1) begin
              //if we're in progress, we are not done.
              internal_done <= 0;
                //lets wait x count before starting division.
                counter <= counter + 1;
                    if (counter > WAIT) begin
                   // start dividing - then wait another 17 clocks to be safe.
                   // or wait until the complete signal is raised.
                        divide_start <= 1;
                            if(z_division_done == 1 && counter > WAIT * 2) begin
                                // we're done dividing
                                internal_done <= 1;
                                counter <= 0;
                                divide_start <= 0;
                                out_vector_reg <= {xResult,yResult,zResult}; 
                                #1 $display("x %b ,y %b ,z %b" , xResult,yResult,zResult);
                                #1 $display("x %d,%f",xResult[N-2:Q],$itor(xResult[Q:0])*2.0**-16.0);
                                 #1 $display("y %d,%f",yResult[N-2:Q],$itor(yResult[Q:0])*2.0**-16.0);
                                  #1 $display("z %d,%f",zResult[N-2:Q],$itor(zResult[Q:0])*2.0**-16.0);
                        end // if
                    end // if
                end //start if
             end //end always
             
//we need N clocks before the division result is ready.
               always @(posedge i_clk) begin
                    in_start_1 <= in_start;
                   //only do anything if we detect a start pulse.
                   if(in_start && ~in_start_1) begin
                           #1 $display("The original vertex");
                           #1 $display("x %b ,y %b ,z %b , w%b" , xcomp,ycomp,zcomp,wcomp);
                           #1 $display("x %d,%f",xcomp[N-2:Q],$itor(xcomp[Q:0])*2.0**-16.0);
                           #1 $display("y %d,%f",ycomp[N-2:Q],$itor(ycomp[Q:0])*2.0**-16.0);
                           #1 $display("z %d,%f",zcomp[N-2:Q],$itor(zcomp[Q:0])*2.0**-16.0);
                           #1 $display("w %d,%f",wcomp[N-2:Q],$itor(wcomp[Q:0])*2.0**-16.0);

                       //we saw the pulse so we're now doing our work:
                       inProgress <= 1;
                       //reset the done flag.
                       out_done_reg <= 0;
                     end
                   if(internal_done == 1) begin
                         inProgress <= 0;
                         out_done_reg =1;
                   end
               end // always
               
endmodule
