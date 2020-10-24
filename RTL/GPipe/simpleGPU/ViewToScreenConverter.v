`timescale 1ns / 1ps
module ViewToScreenConverter(
        
       
        input  [11:0] width_in,
        input  [11:0] height_in,
        //vector format(x,y,z) each component is [1signbit,N-1databits,Qbits]
        input [(N*3)-1:0] vector_in,
        
        //the final pixels - these should be unsigned integers I think...?
        output  [11:0] xpix_out,
        output  [11:0] ypix_out,
        output on_screen_out

    );
    
     parameter Q = 8;
     parameter N = 16;
    
    wire [N-1:0] xResult1;
    wire [N-1:0] yResult1;
    wire [N-1:0] xResult2;
    wire [N-1:0] yResult2;
    
    wire  [N-1:0]  xInteger;
    wire  [N-1:0]  yInteger;
    
    wire  [11:0] halfWidth = width_in >> 1;
    wire  [11:0] halfHeight = height_in >> 1;
    
    // drop upper Q bits (max width is 2048... 2^11) not a problem for 640x480 vga output
    //TODO do we need to concat extra 0's in front here?
    wire [N-1:0] fixedPointHalfWidth = {{4{1'b0}},halfWidth, {Q{1'b0}}};
    wire [N-1:0] fixedPointHalfHeight = {{4{1'b0}},halfHeight, {Q{1'b0}}};
    
    
     qadd #(
             .Q(Q),
            .N(N)) addXandWidth(xInteger,fixedPointHalfWidth,xResult2);
    
     qadd #(
             .Q(Q),
            .N(N)) addYandHeight(yInteger,fixedPointHalfHeight,yResult2);
    
    // multiply x cord
     qmult #(
        .Q(Q),
       .N(N)) mult1x(fixedPointHalfWidth,vector_in[(N*3)-1:(N*2)],xResult1);
       //multiply by neg y coord to get correct scaling. (non mirrored)
     qmult #(
         .Q(Q),
        .N(N)) mult1y({1'b1,fixedPointHalfHeight[N-2:0]},vector_in[(N*2)-1:(N*1)],yResult1);
        

     //this converts the resulting normalized value to the screen integer as a Q number.
     assign xInteger = {xResult1[N-1:Q],{Q{1'b0}}};
     assign yInteger = {yResult1[N-1:Q],{Q{1'b0}}};
     // this converts the resulting Q addition to an unsigned integer, shifting down by Q bits
     assign xpix_out = xResult2[N-1:Q];
     assign ypix_out = yResult2[N-1:Q];
        
     //on_screen is high only when x and y values are between 0 and width/height.
     assign on_screen_out = (xpix_out < width_in) && (xpix_out >=0) && (ypix_out < height_in) && (ypix_out >= 0);
     
    
endmodule
