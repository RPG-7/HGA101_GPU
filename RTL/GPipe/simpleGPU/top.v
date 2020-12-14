`timescale 1ns / 1ps

module top(
        
        input [2:0] MODE_I, //(000) = vertexWriteMode
        input CLK100MHZ,
        input WRITE_IN,
        input MOSI,SERIALCLOCK,ENABLE,
        
        output VGA_HS_O,
        output VGA_VS_O,
        output VGA_R,
        output VGA_G,
        output VGA_B,
        output led,
        output VALIDWORD,
        output READVERTEX,
        output WRITEVERTEX,
        output CLOCK25,
        output FULL,
        output [4:0] COUNTER
    );
    
    wire i_clk = CLK100MHZ;
    reg we_ = 1;

    reg [13:0] romAddressLines = 0;
      
    reg [Nbit-1:0] romDataLines = 0;
    
    wire [Nbit-1:0] vertDataOut;
    //single buffer xyz
    reg [(Nbit*3)-1:0] vertexBuffer = 0;
    reg[(Nbit*4)-1:0] vertex = 0;
    
    //TODO - maybe remove after vert data comes from external source
    reg [32:0] iterationCounter = 0;
    reg [15:0] vertCounter = 0;
    reg [8:0] stateCounter = 0;
    
    reg vertexReady = 0;
    //TODO this will be ready when matrix buffer is full.
    reg matrixReady = 1;
     
     //projection regs
    reg startProjection = 0;
    //16 x 16 matrix
    reg [(Nbit*16)-1:0] mvp_in = 512'b00000000000000001011010100000100000000000000000000000000000000001000000000000000101101010000010000000000000000000000000000000000100000000000000010001011010110010000000000000001000101101011001010000000000000001000101101011001000000000000000000000000000000001000000000000000101110001100000010000000000000001011100011000000100000000000000010111000110000000000000000001000010100110100100010000000000000001001001111001101100000000000000010010011110011011000000000000000100100111100110100000000000010001010100100000110;
    wire [(Nbit*3)-1:0] projected_vector;
    wire projection_done;
    
    //viewToScreen regs
    localparam SCREEN_WIDTH = 640;
    localparam Qbit = 16;
    localparam Nbit = 32;
    reg  [11:0 ]width = 640;
    reg  [11:0 ]height = 480;
    
    wire  [11:0] xpixel;
    wire  [11:0] ypixel;
    wire pixelOnScreen;
    
    //framebuffer regs
    reg [18:0] frameBufferAddressLines1 = 0;
    reg [18:0] frameBufferAddressLines2 = 0;
    reg  frameBufferData = 1; 
    reg frameBuffer_we_ = 1;
    wire frameBufferDataOut1;
    wire frameBufferDataOut2;
    
    //memory address regs
    reg [19:0] memoryAddress = 0;
    
    //vga data
    wire hs;
    wire vs;
    wire [9:0] xvga;
    wire [8:0] yvga;
    reg [15:0] cnt = 0;
    reg pix_stb = 0;
    assign CLOCK25 = cnt[15];
    
    reg outputColorReg = 0;
    
    //fifo data
    wire reset_fifos;
    reg readVertexFromFifo = 0;
    reg writeVertexToFifo = 0;
    wire empty;
    wire full;

    assign reset_fifos = 0;
    
    
   //spi data
   wire [Nbit-1:0] serialData;
   wire validSerialData;
   assign led = validSerialData;
   assign VALIDWORD = validSerialData;
   
   
   
    //DEBUG
    
    assign READVERTEX = readVertexFromFifo;
    assign WRITEVERTEX = writeVertexToFifo;
    assign FULL = full;
    
    
  
   
   always@(posedge CLK100MHZ) begin
    if(pix_stb) begin
        if(MODE_I == 3'b000 && validSerialData) begin
            writeVertexToFifo <= 1;
        end
        else begin
         writeVertexToFifo <= 0;
        end
     end
   end
   
   
   wire [7:0] debugCounter;

   SPI_slave#(.n(Nbit)) 
   serialInput (.i_base_clock(cnt[15]),
                .i_SCK(SERIALCLOCK),
                .i_MOSI(MOSI),
                .i_EN(ENABLE),
                .o_WORDVALID(validSerialData),
                .o_DATA(serialData),
                .o_COUNTER(debugCounter)
                ); 
                
     assign COUNTER = debugCounter[4:0];
   
    //FIFO for reading vertex data from external source
    FIFO#(.DATA_WIDTH(Nbit),.RAM_DEPTH(3))
   
    vertexFifo (.clk_i(cnt[15]),
                .reset_i(reset_fifos),
                .data_i(serialData),
                .r_en_i(readVertexFromFifo),
                .w_en_i(writeVertexToFifo),
                .data_o(vertDataOut),
                .empty_o(empty),
                .full_o(full));

   dualPortStaticRam #(.ROMFILE("framebuffer.mem"),.DATA_WIDTH(1),.ADDR_WIDTH(19)) frameBuffer (
                       .address_1(frameBufferAddressLines1),
                       .address_2(frameBufferAddressLines2),
                        .data(frameBufferData), 
                         .we_(frameBuffer_we_),
                         .clock(i_clk),
                         .clock2(i_clk),
                         .Q_1(frameBufferDataOut1),
                         .Q_2(frameBufferDataOut2));


                       
        vert_projector #(.Q(Qbit),.N(Nbit)) 
               projector(.i_clk(i_clk),
                    .in_start(startProjection),
                    .mvp_in( mvp_in),
                   .vertex_in(vertex),
                   .out_vector( projected_vector),
                   .out_done(projection_done)
                   );
                   
     ViewToScreenConverter#(.Q(Qbit),.N(Nbit))
                viewToScreen(.width_in(width),
                             .height_in(height),
                             .vector_in(projected_vector),
                             .xpix_out(xpixel),
                             .ypix_out(ypixel),
                             .on_screen_out(pixelOnScreen));
                             
   vgaSignalGenerator vgaPart (
                         .i_clk(i_clk),
                         .i_pix_stb(pix_stb),
                         .o_hs(hs),
                         .o_vs(vs),
                         .o_x(xvga),
                         .o_y(yvga)
                     );
                                         
                           assign VGA_HS_O = hs;
                           assign VGA_VS_O = vs;
                           assign VGA_R = outputColorReg;
                           assign VGA_G = outputColorReg;
                           assign VGA_B = outputColorReg;
 
      
   //on each clock - increment the counter and grab more data from ram.
   //TODO a state machine would work well for this...
   always@(posedge i_clk) begin
       
       {pix_stb, cnt} <= cnt + 16'h4000;  // divide by 4: (2^16)/4 = 0x4000
       iterationCounter <= iterationCounter + 1;
       frameBufferAddressLines2 <= (yvga * SCREEN_WIDTH) + xvga;
       outputColorReg <= frameBufferDataOut2;
        
      
       //~3mhz
           if(pix_stb) begin
           
           // Based on MODE - jump to various states...
            //mode control
             /// 000_ vertex write
             /// 001
             /// 010
             /// 011_blank frame buffer
             
              // if mode is set to write vertex, and we're outside of write vertex states
              // then start write vertex flow over from 0.
              if(MODE_I == 3'b000 && stateCounter >= 200 ) begin
                stateCounter <= 0;
              end
              
              if(MODE_I == 3'b011) begin
              // jump to state 200 - where we will blank the framebuffer
              // by incrementing address and writing over and over.
              // until we leave this mode.
               stateCounter <= 200;
              end
           
           
           // wait until the FIFO is full, (3) numbers- 
           // then grab all three, do the projection
           // then return to a waiting state.
                    
                    //wait for FIFO state
                    if(stateCounter == 0) begin
                        //reset some values for writing pixels
                         frameBufferData <= 1;
                         frameBuffer_we_ <= 1;
                         
                        if(full == 1) begin
                            stateCounter <= 1;
                        end
                    
                    end
                    
                    // start read from FIFO state
                    if(stateCounter == 1) begin
                         readVertexFromFifo <= 1;
                          stateCounter <= 2;
                    end
                    //build up the vertex buffer
                    //GET X
                    if(stateCounter == 2) begin
                        //save data from FIFO shifted into the buffer.
                         vertexBuffer <= {vertexBuffer[(Nbit*2)-1:0],vertDataOut};
                        stateCounter <= stateCounter + 1;
                    end
                    
                   //GET Y
                      if(stateCounter == 3) begin
                          //save data from ram shifted into the buffer.
                           vertexBuffer <= {vertexBuffer[(Nbit*2)-1:0],vertDataOut};
                          stateCounter <= stateCounter + 1;
                     end
                   
                      //GET Z                                 
                     if(stateCounter == 4) begin
                      //save data from ram shifted into the buffer.
                       vertexBuffer <= {vertexBuffer[(Nbit*2)-1:0],vertDataOut};
                      readVertexFromFifo <= 0;
                      stateCounter <= stateCounter + 1;
                 end
                 
                  if(stateCounter == 5) begin                
                    stateCounter <= stateCounter + 1;       
                 end       
                    
                    // append W - and set the states.
                    if (stateCounter == 6) begin
                        vertCounter <= vertCounter + 1;
                        vertex <= {vertexBuffer,{Qbit-1{1'b0}},1'b1,{Qbit{1'b0}}};
                        vertexReady <= 1;
                        stateCounter <= 7;
                    end
                    
                    // in state 4 - we are done buffering and are starting to project.
                    if(stateCounter ==7 && vertexReady ==1 && matrixReady == 1) begin
                        startProjection <= 1;
                         stateCounter <= 8;
                      end
                    
                    // projection just finished, reset some state and 
                    // draw the vertex.
                    if(stateCounter >7 && stateCounter <100 && projection_done == 1) begin
                        //lets wait here for another 15 cycles
                        //TODO make this more easily adjustable.
                        stateCounter <= stateCounter+1;
                    end
                    
                    //TODO lets assume pixel calculations are done
                    //so now map to memory and write to the framebuffer.
                    //
                    if(stateCounter == 100) begin
                        #5 $display("vertexcount %d, should display at coord x %d, y %d ",vertCounter,xpixel,ypixel );
                        memoryAddress <= xpixel + (ypixel * SCREEN_WIDTH);
                        frameBufferAddressLines1 <= memoryAddress;
                        stateCounter <= 101;
                    end
                    
                    // actually write a one into memory if the pixel is
                    // visible - else give do nothing.
                     if(stateCounter == 101) begin
                     //assert the write bit for a clock.
                     if(pixelOnScreen ==1) begin
                        frameBuffer_we_ <= 0;
                        end
                       stateCounter <= 102;

                    end
                    
                    //we're done - reset all state
                    if(stateCounter == 102) begin
                        frameBuffer_we_ <= 1;
                        stateCounter <= 0;
                        vertexReady <= 0;
                        startProjection <= 0;

                    end
                    
                     if(stateCounter == 200) begin
                     //should not be projecting during screen blank.
                     vertexReady <= 0;
                     startProjection <= 0;
                     
                     //we want to write black pixels
                      frameBufferData <= 0;
                     // this will overflow and loop.
                       memoryAddress <= memoryAddress +1;
                       frameBufferAddressLines1 <= memoryAddress;
                       //write 0 to framebuffer
                       frameBuffer_we_ <= 0;
                       
                   end
                    
           end            
    end

endmodule
