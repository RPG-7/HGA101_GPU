/*
* Renders Background and Window plane
*/
module Spriterenderer
#(
    parameter H_RES   = 320,      // horizontal resolution (pixels)
    parameter V_RES   = 240,      // vertical resolution (lines)
    parameter H_FP    = 24,       // horizontal front porch
    parameter H_SYNC  = 32,       // horizontal sync
    parameter H_BP    = 46,       // horizontal back porch
    parameter V_FP    = 3,        // vertical front porch
    parameter V_SYNC  = 5,        // vertical sync
    parameter V_BP    = 14,       // vertical back porch
    parameter H_POL   = 0,        // horizontal sync polarity (0:neg, 1:pos)
    parameter V_POL   = 0         // vertical sync polarity
) 
(
    //VGA I/O
    input               vga_clk,            //9MHz
    input               vga_hs,
    input               vga_vs,
    output wire [2:0]   vga_r,
    output wire [2:0]   vga_g,
    output wire [1:0]   vga_b,

    input [9:0]         h_count,  // line position in pixels including blanking 
    input [8:0]         v_count,  // frame position in lines including blanking 

    input               o_hs, 
    input               o_vs, 
    input               o_de, 
    input               o_h, 
    input               o_v, 
    input               o_frame,

    //VRAM32
    output [13:0]       vram32_addr,
    input  [31:0]       vram32_q, 

    //VRAMSPR
    output [13:0]       vramSPR_addr,
    input  [8:0]        vramSPR_q, 

    //Draw pixel signal
    output wire         draw_sprite,
    output wire         draw_behind_bg
);

//x:        9b
//y:        8b
//tile:     8b
//palette:  5b
//hflip:    1b
//vflip:    1b
//priority: 1b
//disable : 1b
//------------ +
//         34b


parameter MAX_SPRITES = 16;
//currently two sprites
reg [33:0] sprites [0:MAX_SPRITES-1];
reg [33:0] sprites_next [0:MAX_SPRITES-1];
reg [5:0] spriteIdx = 0;




reg [9:0] h_count_delay;
reg [9:0] h_count_visible_delay;
reg [8:0] v_count_delay;
reg [8:0] v_count_visible_delay;

always @(negedge vga_clk)
begin
    h_count_delay <= h_count;
    v_count_delay <= v_count;
    h_count_visible_delay <= h_count_visible;
    v_count_visible_delay <= v_count_visible;
end

reg [5:0] spriteSelectionList [0:MAX_SPRITES-1];
reg [5:0] spriteSelectionCount;

//select for next line during h_count_visible (delay)

integer x=0;
always @(posedge vga_clk)
begin
    if (h_count_visible_delay == 319) //do somewhere at end of hline
    begin
        spriteSelectionCount <= 6'd0;
        for (x=0; x<MAX_SPRITES; x=x+1)
        begin
            spriteSelectionList[x] <= 6'd0;
        end
    end
    else 
    begin
        if (v_count_visible_delay < 240 || v_count_visible_delay == 511)
        begin
            if (spriteSelectionCount < MAX_SPRITES)
            begin
                if (h_count_visible_delay < 64)
                begin
                    if ((v_count_visible_delay + 1) >= vramSPR_q && (v_count_visible_delay + 1) < vramSPR_q + 8)
                    begin
                        spriteSelectionList[spriteSelectionCount] <= h_count_visible_delay;
                        spriteSelectionCount <= spriteSelectionCount + 1'b1;
                    end
                end
            end
        end
    end
end

assign vramSPR_addr =   (v_count_visible != 511 && v_count_visible > 239) ? 15'd0:
                        (h_count_visible >= 0 && h_count_visible < 128) ? (h_count_visible * 4) + 1'b1:
                        (spriteSelectionList[(h_count_visible-128)>>2]<<2) + h_count_visible[1:0];


integer v=0;
always @(posedge vga_clk)
begin
    if (h_count_visible_delay == 127) //right before writing the sprites
    begin
        for (v=0; v<MAX_SPRITES; v=v+1)
        begin
            sprites_next[v] <= 34'd0;
        end
    end
    else 
    begin
        if (h_count_visible_delay >= 128 && h_count_visible_delay < 192)
        begin
            case (h_count_visible_delay[1:0])
                2'd0 : sprites_next[(h_count_visible_delay-128)/4][33:25]   <= vramSPR_q[8:0];
                2'd1 : sprites_next[(h_count_visible_delay-128)/4][24:17]   <= vramSPR_q[7:0];
                2'd2 : sprites_next[(h_count_visible_delay-128)/4][16:9]    <= vramSPR_q[7:0];
                2'd3 : sprites_next[(h_count_visible_delay-128)/4][8:0]     <= vramSPR_q[8:0];
            endcase
            
        end
    end
end

integer b=0;
always @(posedge vga_clk)
begin
    if (h_count_visible_delay == 319)
    begin
        for (b=0; b<MAX_SPRITES; b=b+1)
        begin
            sprites[b] <= sprites_next[b];
        end
    end
end

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


// counters for tile and position
wire [8:0] v_count_visible;
assign v_count_visible = v_count - V_FP - V_SYNC - V_BP;

wire [9:0] h_count_visible;
assign h_count_visible = h_count - H_FP - H_SYNC - H_BP;

wire [5:0] h_tile;
assign h_tile = (h_count_visible / 8);

wire [5:0] v_tile;
assign v_tile = v_count_visible / 8;

wire [2:0] h_tile_pixel;
assign h_tile_pixel = h_count_visible[2:0];

wire [2:0] v_tile_pixel;
assign v_tile_pixel = v_count_visible[2:0];

wire [10:0] tile;
assign tile = (v_tile * (H_RES/8)) + h_tile;

wire [5:0] h_tile_next;
assign h_tile_next = ((h_count - H_FP - H_SYNC - H_BP + 8) / 8);

wire [10:0] tile_next;
assign tile_next = (v_tile * (H_RES/8)) + h_tile_next;

wire [3:0] spriteVpixel [0:MAX_SPRITES-1];
wire [3:0] spriteHpixel [0:MAX_SPRITES-1];
genvar l;
generate
for (l=0; l<MAX_SPRITES; l=l+1) begin:o
    assign spriteVpixel[l] = (v_count_visible - sprites[l][24:17]);
    assign spriteHpixel[l] = (h_count_visible - sprites[l][33:25]);
    end
endgenerate

wire [9:0] h_count_div2;
assign h_count_div2 = h_count >> 1;

reg [9:0] h_count_div2_offset;
always @(negedge vga_clk)
begin
    h_count_div2_offset <= h_count_div2;
end

wire [5:0] spritephase;
reg [5:0] spritephaseOffset;

always @(negedge vga_clk)
begin
    spritephaseOffset <= spritephase;
end

assign spritephase =    (v_count_visible >= 240) ? 0:
                        (h_count >= MAX_SPRITES*2) ? 0:
                        (h_count[0] == 0) ? 1:
                        (h_count[0] == 1) ? 2:
                        0;

wire spriteVisible [0:MAX_SPRITES-1];
genvar m;
generate
for (m=0; m<MAX_SPRITES; m=m+1) begin:p
    assign spriteVisible[m] =  ( h_count_visible >= sprites[m][33:25] && h_count_visible < sprites[m][33:25] + 8 && v_count_visible >= sprites[m][24:17] && v_count_visible < sprites[m][24:17] + 8);
    end
endgenerate

//For reversing the tile data
wire [31:0] vram32_q_reverse;
genvar i;
generate
for (i=0; i<=31; i=i+1) begin:y
    assign vram32_q_reverse[31-i] = vram32_q[i];
    end
endgenerate


reg [63:0] rendered_sprite [0:MAX_SPRITES-1];

reg [15:0] pattern;
reg [31:0] palette;

always @(posedge vga_clk)
begin
    if (spritephaseOffset == 1)
    begin
        //get pattern
        if (spriteVpixel[h_count_div2_offset][0] == 1)
            pattern <= vram32_q_reverse[31:16];
        else
            pattern <= vram32_q_reverse[15:0];
    end
    if (spritephaseOffset == 2)
    begin
        //get color
        palette <= vram32_q;
        case (pattern[1:0])
            2'b00: rendered_sprite[h_count_div2_offset][7:0] <= vram32_q[31:24];
            2'b01: rendered_sprite[h_count_div2_offset][7:0] <= vram32_q[23:16];
            2'b10: rendered_sprite[h_count_div2_offset][7:0] <= vram32_q[15:8];
            2'b11: rendered_sprite[h_count_div2_offset][7:0] <= vram32_q[7:0];
        endcase
        case (pattern[3:2])
            2'b00: rendered_sprite[h_count_div2_offset][15:8] <= vram32_q[31:24];
            2'b01: rendered_sprite[h_count_div2_offset][15:8] <= vram32_q[23:16];
            2'b10: rendered_sprite[h_count_div2_offset][15:8] <= vram32_q[15:8];
            2'b11: rendered_sprite[h_count_div2_offset][15:8] <= vram32_q[7:0];
        endcase
        case (pattern[5:4])
            2'b00: rendered_sprite[h_count_div2_offset][23:16] <= vram32_q[31:24];
            2'b01: rendered_sprite[h_count_div2_offset][23:16] <= vram32_q[23:16];
            2'b10: rendered_sprite[h_count_div2_offset][23:16] <= vram32_q[15:8];
            2'b11: rendered_sprite[h_count_div2_offset][23:16] <= vram32_q[7:0];
        endcase
        case (pattern[7:6])
            2'b00: rendered_sprite[h_count_div2_offset][31:24] <= vram32_q[31:24];
            2'b01: rendered_sprite[h_count_div2_offset][31:24] <= vram32_q[23:16];
            2'b10: rendered_sprite[h_count_div2_offset][31:24] <= vram32_q[15:8];
            2'b11: rendered_sprite[h_count_div2_offset][31:24] <= vram32_q[7:0];
        endcase
        case (pattern[9:8])
            2'b00: rendered_sprite[h_count_div2_offset][39:32] <= vram32_q[31:24];
            2'b01: rendered_sprite[h_count_div2_offset][39:32] <= vram32_q[23:16];
            2'b10: rendered_sprite[h_count_div2_offset][39:32] <= vram32_q[15:8];
            2'b11: rendered_sprite[h_count_div2_offset][39:32] <= vram32_q[7:0];
        endcase
        case (pattern[11:10])
            2'b00: rendered_sprite[h_count_div2_offset][47:40] <= vram32_q[31:24];
            2'b01: rendered_sprite[h_count_div2_offset][47:40] <= vram32_q[23:16];
            2'b10: rendered_sprite[h_count_div2_offset][47:40] <= vram32_q[15:8];
            2'b11: rendered_sprite[h_count_div2_offset][47:40] <= vram32_q[7:0];
        endcase
        case (pattern[13:12])
            2'b00: rendered_sprite[h_count_div2_offset][55:48] <= vram32_q[31:24];
            2'b01: rendered_sprite[h_count_div2_offset][55:48] <= vram32_q[23:16];
            2'b10: rendered_sprite[h_count_div2_offset][55:48] <= vram32_q[15:8];
            2'b11: rendered_sprite[h_count_div2_offset][55:48] <= vram32_q[7:0];
        endcase
        case (pattern[15:14])
            2'b00: rendered_sprite[h_count_div2_offset][63:56] <= vram32_q[31:24];
            2'b01: rendered_sprite[h_count_div2_offset][63:56] <= vram32_q[23:16];
            2'b10: rendered_sprite[h_count_div2_offset][63:56] <= vram32_q[15:8];
            2'b11: rendered_sprite[h_count_div2_offset][63:56] <= vram32_q[7:0];
        endcase
    end
end


assign vram32_addr =    (spritephase == 1) ? (sprites[h_count_div2][16:9] * 4) + (spriteVpixel[h_count_div2])/2 : 
                        (spritephase == 2) ? 1024 + sprites[h_count_div2][8:4]:
                        14'd0;

//RENDERING
assign draw_sprite = 1'b0;
assign draw_behind_bg = 1'b0;

//Render all sprites

wire [3:0] sprite_r [0:MAX_SPRITES-1];
wire [3:0] sprite_g [0:MAX_SPRITES-1];
wire [2:0] sprite_b [0:MAX_SPRITES-1];

//For generating sprite rgb assignments
genvar j;
generate
for (j=0; j<MAX_SPRITES; j=j+1) 
begin:n
    
    assign sprite_r[j] =  (!spriteVisible[j]) ? 3'd0:
                    (spriteHpixel[j] == 0) ? rendered_sprite[j][0*8 +7: 0*8 +5]:
                    (spriteHpixel[j] == 1) ? rendered_sprite[j][1*8 +7: 1*8 +5]:
                    (spriteHpixel[j] == 2) ? rendered_sprite[j][2*8 +7: 2*8 +5]:
                    (spriteHpixel[j] == 3) ? rendered_sprite[j][3*8 +7: 3*8 +5]:
                    (spriteHpixel[j] == 4) ? rendered_sprite[j][4*8 +7: 4*8 +5]:
                    (spriteHpixel[j] == 5) ? rendered_sprite[j][5*8 +7: 5*8 +5]:
                    (spriteHpixel[j] == 6) ? rendered_sprite[j][6*8 +7: 6*8 +5]:
                    (spriteHpixel[j] == 7) ? rendered_sprite[j][7*8 +7: 7*8 +5]:
                3'd0;

    assign sprite_g[j] =  (!spriteVisible[j]) ? 3'd0:
                    (spriteHpixel[j] == 0) ? rendered_sprite[j][0*8 +4: 0*8 +2]:
                    (spriteHpixel[j] == 1) ? rendered_sprite[j][1*8 +4: 1*8 +2]:
                    (spriteHpixel[j] == 2) ? rendered_sprite[j][2*8 +4: 2*8 +2]:
                    (spriteHpixel[j] == 3) ? rendered_sprite[j][3*8 +4: 3*8 +2]:
                    (spriteHpixel[j] == 4) ? rendered_sprite[j][4*8 +4: 4*8 +2]:
                    (spriteHpixel[j] == 5) ? rendered_sprite[j][5*8 +4: 5*8 +2]:
                    (spriteHpixel[j] == 6) ? rendered_sprite[j][6*8 +4: 6*8 +2]:
                    (spriteHpixel[j] == 7) ? rendered_sprite[j][7*8 +4: 7*8 +2]:
                3'd0;

    assign sprite_b[j] =  (!spriteVisible[j]) ? 3'd0:
                    (spriteHpixel[j] == 0) ? rendered_sprite[j][0*8 +1: 0*8 +0]:
                    (spriteHpixel[j] == 1) ? rendered_sprite[j][1*8 +1: 1*8 +0]:
                    (spriteHpixel[j] == 2) ? rendered_sprite[j][2*8 +1: 2*8 +0]:
                    (spriteHpixel[j] == 3) ? rendered_sprite[j][3*8 +1: 3*8 +0]:
                    (spriteHpixel[j] == 4) ? rendered_sprite[j][4*8 +1: 4*8 +0]:
                    (spriteHpixel[j] == 5) ? rendered_sprite[j][5*8 +1: 5*8 +0]:
                    (spriteHpixel[j] == 6) ? rendered_sprite[j][6*8 +1: 6*8 +0]:
                    (spriteHpixel[j] == 7) ? rendered_sprite[j][7*8 +1: 7*8 +0]:
                2'd0;    

end
endgenerate



//Select which pixel to render

wire sprite_drawn [0:MAX_SPRITES-1];
genvar k;
generate
for (k=0; k<MAX_SPRITES; k=k+1) 
begin:z
    
    assign sprite_drawn[k] = (sprite_r[k] != 3'd0 || sprite_g[k] != 3'd0 || sprite_b[k] != 2'd0) ? 1'b1:
                        1'b0;
end
endgenerate

assign vga_r =  (sprite_drawn[0]) ? sprite_r[0]: 
                (sprite_drawn[1]) ? sprite_r[1]: 
                (sprite_drawn[2]) ? sprite_r[2]: 
                (sprite_drawn[3]) ? sprite_r[3]: 
                (sprite_drawn[4]) ? sprite_r[4]: 
                (sprite_drawn[5]) ? sprite_r[5]: 
                (sprite_drawn[6]) ? sprite_r[6]: 
                (sprite_drawn[7]) ? sprite_r[7]: 
                (sprite_drawn[8]) ? sprite_r[8]: 
                (sprite_drawn[9]) ? sprite_r[9]: 
                (sprite_drawn[10]) ? sprite_r[10]: 
                (sprite_drawn[11]) ? sprite_r[11]: 
                (sprite_drawn[12]) ? sprite_r[12]: 
                (sprite_drawn[13]) ? sprite_r[13]: 
                (sprite_drawn[14]) ? sprite_r[14]: 
                (sprite_drawn[15]) ? sprite_r[15]: 
                3'd0;

assign vga_g =  (sprite_drawn[0]) ? sprite_g[0]: 
                (sprite_drawn[1]) ? sprite_g[1]: 
                (sprite_drawn[2]) ? sprite_g[2]: 
                (sprite_drawn[3]) ? sprite_g[3]: 
                (sprite_drawn[4]) ? sprite_g[4]: 
                (sprite_drawn[5]) ? sprite_g[5]: 
                (sprite_drawn[6]) ? sprite_g[6]: 
                (sprite_drawn[7]) ? sprite_g[7]: 
                (sprite_drawn[8]) ? sprite_g[8]: 
                (sprite_drawn[9]) ? sprite_g[9]: 
                (sprite_drawn[10]) ? sprite_g[10]: 
                (sprite_drawn[11]) ? sprite_g[11]: 
                (sprite_drawn[12]) ? sprite_g[12]: 
                (sprite_drawn[13]) ? sprite_g[13]: 
                (sprite_drawn[14]) ? sprite_g[14]: 
                (sprite_drawn[15]) ? sprite_g[15]:
                3'd0;

assign vga_b =  (sprite_drawn[0]) ? sprite_b[0]: 
                (sprite_drawn[1]) ? sprite_b[1]: 
                (sprite_drawn[2]) ? sprite_b[2]: 
                (sprite_drawn[3]) ? sprite_b[3]: 
                (sprite_drawn[4]) ? sprite_b[4]: 
                (sprite_drawn[5]) ? sprite_b[5]: 
                (sprite_drawn[6]) ? sprite_b[6]: 
                (sprite_drawn[7]) ? sprite_b[7]: 
                (sprite_drawn[8]) ? sprite_b[8]: 
                (sprite_drawn[9]) ? sprite_b[9]: 
                (sprite_drawn[10]) ? sprite_b[10]: 
                (sprite_drawn[11]) ? sprite_b[11]: 
                (sprite_drawn[12]) ? sprite_b[12]: 
                (sprite_drawn[13]) ? sprite_b[13]: 
                (sprite_drawn[14]) ? sprite_b[14]: 
                (sprite_drawn[15]) ? sprite_b[15]:
                2'd0;

endmodule