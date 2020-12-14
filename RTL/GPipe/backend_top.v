module backend_top
(

    
);

//2D Sprite GPU 
//TODO 改到480p 
parameter
    H_RES   = 640,      // horizontal resolution (pixels)
    V_RES   = 360,      // vertical resolution (lines)
    H_FP    = 24,       // horizontal front porch
    H_SYNC  = 32,       // horizontal sync
    H_BP    = 46,       // horizontal back porch
    V_FP    = 3,        // vertical front porch
    V_SYNC  = 5,        // vertical sync
    V_BP    = 14,       // vertical back porch
    H_POL   = 0,        // horizontal sync polarity (0:neg, 1:pos)
    V_POL   = 0;        // vertical sync polarity

    
// Horizontal: sync, active, and pixels
localparam HS_STA = H_FP - 1;           // sync start (first pixel is 0)
localparam HS_END = HS_STA + H_SYNC;    // sync end
localparam HA_STA = HS_END + H_BP;      // active start
localparam HA_END = HA_STA + H_RES;     // active end 
localparam LINE   = HA_END;             // line pixels 

// Vertical: sync, active, and pixels
localparam VS_STA = V_FP - 1;           // sync start (first line is 0)
localparam VS_END = VS_STA + V_SYNC;    // sync end
localparam VA_STA = VS_END + V_BP;      // active start
localparam VA_END = VA_STA + V_RES;     // active end 
localparam FRAME  = VA_END;             // frame lines 





wire [2:0] BGW_r;
wire [2:0] BGW_g;
wire [1:0] BGW_b;


BGWrenderer #(
    .H_RES(H_RES),      // horizontal resolution (pixels)
    .V_RES(V_RES),      // vertical resolution (lines)
    .H_FP(H_FP),        // horizontal front porch
    .H_SYNC(H_SYNC),       // horizontal sync
    .H_BP(H_BP),        // horizontal back porch
    .V_FP(V_FP),        // vertical front porch
    .V_SYNC(V_SYNC),       // vertical sync
    .V_BP(V_BP),        // vertical back porch
    .H_POL(H_POL),        // horizontal sync polarity (0:neg, 1:pos)
    .V_POL(V_POL)         // vertical sync polarity (0:neg, 1:pos)
) bgwrenderer(
    //VGA I/O
    .vga_clk(vga_clk),            //9MHz
    .vga_hs(o_hs),
    .vga_vs(o_vs),
    
    .vga_r(BGW_r),
    .vga_g(BGW_g),
    .vga_b(BGW_b),

    .h_count(h_count),  // line position in pixels including blanking 
    .v_count(v_count),  // frame position in lines including blanking 

    .o_hs(o_hs), 
    .o_vs(o_vs), 
    .o_de(o_de), 
    .o_h(o_h), 
    .o_v(o_v), 
    .o_frame(o_frame),

    //VRAM32
    .vram32_addr(vram32_addr),
    .vram32_q(vram32_q), 

    //VRAM8
    .vram8_addr(vram8_addr),
    .vram8_q(vram8_q)
);


wire [2:0] SPR_r;
wire [2:0] SPR_g;
wire [1:0] SPR_b;

wire       draw_sprite;
wire       draw_behind_bg;

Spriterenderer #(
    .H_RES(H_RES),      // horizontal resolution (pixels)
    .V_RES(V_RES),      // vertical resolution (lines)
    .H_FP(H_FP),        // horizontal front porch
    .H_SYNC(H_SYNC),       // horizontal sync
    .H_BP(H_BP),        // horizontal back porch
    .V_FP(V_FP),        // vertical front porch
    .V_SYNC(V_SYNC),       // vertical sync
    .V_BP(V_BP),        // vertical back porch
    .H_POL(H_POL),        // horizontal sync polarity (0:neg, 1:pos)
    .V_POL(V_POL)         // vertical sync polarity (0:neg, 1:pos)
) spriterenderer(
    //VGA I/O
    .vga_clk(vga_clk),            //9MHz
    .vga_hs(o_hs),
    .vga_vs(o_vs),
    
    .vga_r(SPR_r),
    .vga_g(SPR_g),
    .vga_b(SPR_b),

    .h_count(h_count),  // line position in pixels including blanking 
    .v_count(v_count),  // frame position in lines including blanking 

    .o_hs(o_hs), 
    .o_vs(o_vs), 
    .o_de(o_de), 
    .o_h(o_h), 
    .o_v(o_v), 
    .o_frame(o_frame),

    //VRAM32
    .vram32_addr(vram322_addr), //use copy of vram32 here
    .vram32_q(vram322_q), //use copy of vram32 here

    //VRAMSPR
    .vramSPR_addr(vramSPR_addr),
    .vramSPR_q(vramSPR_q),
    
    //Drawing signals
    .draw_sprite(draw_sprite),
    .draw_behind_bg(draw_behind_bg)
);

vgaSignalGenerator vgaPart (
                         .i_clk(i_clk),
                         .i_pix_stb(pix_stb),
                         .o_hs(hs),
                         .o_vs(vs),
                         .o_x(xvga),
                         .o_y(yvga)
                     );

//temporary for testing. Should implement some kind of pixelvalid in spriterenderer
wire sprite_drawn;
assign sprite_drawn = (SPR_r != 3'd0 || SPR_g != 3'd0 || SPR_b != 2'd0) ? 1'b1:
                    1'b0;

assign crt_r =  (sprite_drawn) ?  SPR_r: BGW_r;
assign crt_g =  (sprite_drawn) ?  SPR_g: BGW_g;
assign crt_b =  (sprite_drawn) ?  SPR_b: BGW_b;

assign vga_r = crt_r;
assign vga_g = crt_g;
assign vga_b = crt_b;

endmodule