/*
* Graphical processor (Frame Synthesizer)
* Generates video from VRAM
*/
module FSX(
    //VGA I/O
    input               vga_clk,
    
    output wire [2:0]   vga_r,
    output wire [2:0]   vga_g,
    output wire [1:0]   vga_b,
    output wire         vga_hs,
    output wire         vga_vs,

    //CRT Video
    output          crt_sync,
    output [2:0]    crt_r,
    output [2:0]    crt_g,
    output [1:0]    crt_b,

    //VRAM32
    output [13:0]       vram32_addr,
    input  [31:0]       vram32_q, 

    //VRAM322
    output [13:0]       vram322_addr,
    input  [31:0]       vram322_q, 

    //VRAM8
    output [13:0]       vram8_addr,
    input  [7:0]        vram8_q,

    //VRAMSPR
    output [13:0]       vramSPR_addr,
    input  [8:0]        vramSPR_q,

    //Interrupt signal
    output reg         frameDrawn
);
//assign vga_blk = 1'b1;
//assign frameDrawn = o_frame;

//DISPLAY SIGNAL GENERATION
/* 480x272 TFT screen
parameter
    H_RES=480,      // horizontal resolution (pixels)
    V_RES=272,      // vertical resolution (lines)
    H_FP=2,        // horizontal front porch
    H_SYNC=41,      // horizontal sync
    H_BP=2,        // horizontal back porch
    V_FP=2,        // vertical front porch
    V_SYNC=10,       // vertical sync
    V_BP=2,        // vertical back porch
    H_POL=0,        // horizontal sync polarity (0:neg, 1:pos)
    V_POL=0;        // vertical sync polarity (0:neg, 1:pos)
*/

//CRT 360p
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

reg [9:0] h_count;  // line position in pixels including blanking 
reg [8:0] v_count;  // frame position in lines including blanking 

wire o_hs, o_vs, o_de, o_h, o_v, o_frame;
assign crt_sync = !(o_hs^o_vs);
assign vga_hs = o_hs;
assign vga_vs = o_vs;

// generate sync signals with correct polarity
assign o_hs = H_POL ? (h_count > HS_STA & h_count <= HS_END)
    : ~(h_count > HS_STA & h_count <= HS_END);
assign vga_hs = o_hs;
assign o_vs = V_POL ? (v_count > VS_STA & v_count <= VS_END)
    : ~(v_count > VS_STA & v_count <= VS_END);
assign vga_vs = o_vs;
    
// display enable: high during active period
assign o_de = h_count > HA_STA & h_count <= HA_END
    & v_count > VA_STA & v_count <= VA_END; 

// keep o_h and o_v bound within active pixels
assign o_h = (o_de & h_count > HA_STA & h_count <= HA_END) ? 
                h_count - (HA_STA + 1): 0;
assign o_v = (o_de & v_count > VA_STA & v_count <= VA_END) ? 
                v_count - (VA_STA + 1): 0;

// o_frame: high for some ticks when last frame is drawn
assign o_frame = (v_count == 0 & h_count < 8);
 
always @ (posedge vga_clk)
begin
    if (h_count == LINE)  // end of line
    begin
         h_count <= 0;
         if (v_count == FRAME) // end of frame
         begin      
              v_count <= 0;
         end
         else
              v_count <= v_count + 1;
    end
    else 
         h_count <= h_count + 1;

    if (v_count == 0 && h_count < 8)
        frameDrawn <= 1'b1;
    else
        frameDrawn <= 1'b0;
end

initial begin
    h_count = 12'd0;
    v_count = 12'd0;
end

/*
reg [2:0] BGW_r = 0;
reg [2:0] BGW_g = 0;
reg [1:0] BGW_b = 0;
*/


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

/*
reg [2:0] SPR_r = 0;
reg [2:0] SPR_g = 0;
reg [1:0] SPR_b = 0;
*/

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

//FRAME TO PICTURE IN SIMULATION

integer file;
integer framecounter = "0";
always @(negedge vga_vs)
begin
    file = $fopen({"/home/bart/Documents/FPGA/FPGC4/Verilog/output/frame",framecounter,".ppm"}, "w");
    $fwrite(file, "P3\n");
    $fwrite(file, "320 240\n");
    $fwrite(file, "7\n");
    framecounter = framecounter + 1;
end

always @(posedge vga_clk)
begin
    if (o_de)
    begin
        $fwrite(file, "%d  %d  %d\n", crt_r, crt_g, {1'b1, crt_b});
    end
end

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