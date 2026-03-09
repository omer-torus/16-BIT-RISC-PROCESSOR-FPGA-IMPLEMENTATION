/*
 * HDMI Top Module (DVI-D)
 * 
 * Generates 640x480@60Hz video output using DVI-D protocol over HDMI connector.
 * Uses Tang Nano 9K PLL and OSER10 primitives for TMDS serialization.
 * 
 * Clock requirements:
 * - clk_27m: 27 MHz input from board oscillator
 * - PLL generates: 25.2 MHz pixel clock, 126 MHz serial clock (5x)
 */

module hdmi_top (
    input  wire       clk_27m,
    input  wire       rst_n,

    // Pixel data input (from HUD)
    input  wire [7:0] red_in,
    input  wire [7:0] green_in,
    input  wire [7:0] blue_in,

    // Timing outputs (for HUD)
    output wire [9:0] x_out,
    output wire [9:0] y_out,
    output wire       active_out,
    output wire       clk_pix_out,

    // TMDS differential outputs (to HDMI connector)
    output wire [2:0] tmds_d_p,
    output wire       tmds_clk_p
);

    // PLL-generated clocks
    wire clk_ser;   // 126 MHz (5x pixel clock for serialization)
    wire pll_lock;

    // Instantiate rPLL IP (Gowin rPLL - only generates 126 MHz)
    pll_hdmi u_pll (
        .clkout  (clk_ser),    // 126 MHz output (was clkout0 in old PLL)
        .lock    (pll_lock),   // Lock signal
        .clkin   (clk_27m)     // 27 MHz input
    );

    // Clock divider: 126 MHz / 5 = 25.2 MHz pixel clock
    reg [2:0] clk_div;
    reg clk_pix;
    
    always @(posedge clk_ser or posedge (~pll_lock)) begin
        if (~pll_lock) begin
            clk_div <= 3'd0;
            clk_pix <= 1'b0;
        end else begin
            if (clk_div == 3'd4) begin
                clk_div <= 3'd0;
                clk_pix <= ~clk_pix;  // Toggle every 5 cycles = /10 frequency
            end else begin
                clk_div <= clk_div + 1'd1;
            end
        end
    end

    assign clk_pix_out = clk_pix;
    wire rst_hdmi = (~rst_n) | (~pll_lock);

    // Video timing signals
    wire hsync, vsync, de;

    video_timing_640x480 u_timing (
        .pclk  (clk_pix),
        .rst   (rst_hdmi),
        .x     (x_out),
        .y     (y_out),
        .hsync (hsync),
        .vsync (vsync),
        .de    (de)
    );
    
    assign active_out = de;

    // TMDS encoded data
    wire [9:0] tmds_b, tmds_g, tmds_r;
    
    // TMDS encoders for RGB channels
    tmds_encoder u_enc_b(
        .clk  (clk_pix),
        .rst  (rst_hdmi),
        .vd   (blue_in),
        .cd   ({vsync,hsync}),  // Sync signals embedded in blue channel
        .vde  (de),
        .tmds (tmds_b)
    );
    
    tmds_encoder u_enc_g(
        .clk  (clk_pix),
        .rst  (rst_hdmi),
        .vd   (green_in),
        .cd   (2'b00),
        .vde  (de),
        .tmds (tmds_g)
    );
    
    tmds_encoder u_enc_r(
        .clk  (clk_pix),
        .rst  (rst_hdmi),
        .vd   (red_in),
        .cd   (2'b00),
        .vde  (de),
        .tmds (tmds_r)
    );

    // TMDS clock pattern (alternating 0/1)
    wire [9:0] tmds_clk = 10'b1111100000;

    // TMDS serializers (Gowin OSER10 primitives)
    OSER10 u_oser_b(
        .RESET (rst_hdmi),
        .PCLK  (clk_pix),
        .FCLK  (clk_ser),
        .D0(tmds_b[0]), .D1(tmds_b[1]), .D2(tmds_b[2]), .D3(tmds_b[3]), .D4(tmds_b[4]),
        .D5(tmds_b[5]), .D6(tmds_b[6]), .D7(tmds_b[7]), .D8(tmds_b[8]), .D9(tmds_b[9]),
        .Q(tmds_d_p[0])
    );

    OSER10 u_oser_g(
        .RESET (rst_hdmi),
        .PCLK  (clk_pix),
        .FCLK  (clk_ser),
        .D0(tmds_g[0]), .D1(tmds_g[1]), .D2(tmds_g[2]), .D3(tmds_g[3]), .D4(tmds_g[4]),
        .D5(tmds_g[5]), .D6(tmds_g[6]), .D7(tmds_g[7]), .D8(tmds_g[8]), .D9(tmds_g[9]),
        .Q(tmds_d_p[1])
    );

    OSER10 u_oser_r(
        .RESET (rst_hdmi),
        .PCLK  (clk_pix),
        .FCLK  (clk_ser),
        .D0(tmds_r[0]), .D1(tmds_r[1]), .D2(tmds_r[2]), .D3(tmds_r[3]), .D4(tmds_r[4]),
        .D5(tmds_r[5]), .D6(tmds_r[6]), .D7(tmds_r[7]), .D8(tmds_r[8]), .D9(tmds_r[9]),
        .Q(tmds_d_p[2])
    );

    OSER10 u_oser_c(
        .RESET (rst_hdmi),
        .PCLK  (clk_pix),
        .FCLK  (clk_ser),
        .D0(tmds_clk[0]), .D1(tmds_clk[1]), .D2(tmds_clk[2]), .D3(tmds_clk[3]), .D4(tmds_clk[4]),
        .D5(tmds_clk[5]), .D6(tmds_clk[6]), .D7(tmds_clk[7]), .D8(tmds_clk[8]), .D9(tmds_clk[9]),
        .Q(tmds_clk_p)
    );

endmodule


/*
 * Video Timing Generator for 640x480@60Hz
 * Pixel clock: 25.175 MHz
 */
module video_timing_640x480(
    input  wire       pclk,
    input  wire       rst,
    output reg [9:0]  x,
    output reg [9:0]  y,
    output reg        hsync,
    output reg        vsync,
    output reg        de
);
    // 640x480 @ 60Hz timing parameters
    localparam H_ACTIVE = 10'd640;
    localparam H_FP     = 10'd16;
    localparam H_SYNC   = 10'd96;
    localparam H_BP     = 10'd48;
    localparam H_TOTAL  = H_ACTIVE + H_FP + H_SYNC + H_BP; // 800

    localparam V_ACTIVE = 10'd480;
    localparam V_FP     = 10'd10;
    localparam V_SYNC   = 10'd2;
    localparam V_BP     = 10'd33;
    localparam V_TOTAL  = V_ACTIVE + V_FP + V_SYNC + V_BP; // 525

    reg [9:0] hcnt, vcnt;

    always @(posedge pclk or posedge rst) begin
        if (rst) begin
            hcnt <= 0;
            vcnt <= 0;
            x <= 0;
            y <= 0;
            hsync <= 1;
            vsync <= 1;
            de <= 0;
        end else begin
            // Horizontal counter
            if (hcnt == H_TOTAL-1) begin
                hcnt <= 0;
                // Vertical counter
                if (vcnt == V_TOTAL-1)
                    vcnt <= 0;
                else
                    vcnt <= vcnt + 1;
            end else begin
                hcnt <= hcnt + 1;
            end

            // Output coordinates
            x <= hcnt;
            y <= vcnt;

            // Display enable (active video region)
            de <= (hcnt < H_ACTIVE) && (vcnt < V_ACTIVE);

            // Sync pulses (active low)
            hsync <= ~((hcnt >= (H_ACTIVE + H_FP)) && (hcnt < (H_ACTIVE + H_FP + H_SYNC)));
            vsync <= ~((vcnt >= (V_ACTIVE + V_FP)) && (vcnt < (V_ACTIVE + V_FP + V_SYNC)));
        end
    end
endmodule


/*
 * TMDS Encoder
 * Implements DVI 8b/10b encoding with DC balance
 */
module tmds_encoder(
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] vd,    // Video data (8-bit pixel component)
    input  wire [1:0] cd,    // Control data (for sync signals)
    input  wire       vde,   // Video data enable
    output reg  [9:0] tmds
);
    // Count ones in video data
    wire [3:0] n1d = vd[0]+vd[1]+vd[2]+vd[3]+vd[4]+vd[5]+vd[6]+vd[7];
    
    // Encoding decision: use XNOR if more 1s, or if equal and bit0 is 0
    wire use_xnor = (n1d > 4) || ((n1d==4) && (vd[0]==1'b0));

    // Stage 1: 8b -> 9b minimized transitions
    reg [8:0] q_m;
    integer i;
    always @* begin
        q_m[0] = vd[0];
        for (i=1; i<8; i=i+1)
            q_m[i] = use_xnor ? ~(q_m[i-1]^vd[i]) : (q_m[i-1]^vd[i]);
        q_m[8] = use_xnor ? 1'b0 : 1'b1;
    end

    // Count ones in q_m
    wire [3:0] n1qm = q_m[0]+q_m[1]+q_m[2]+q_m[3]+q_m[4]+q_m[5]+q_m[6]+q_m[7];
    wire signed [5:0] balance = $signed({1'b0,n1qm,1'b0}) - 6'sd8;

    // DC disparity tracker
    reg signed [6:0] disparity;

    // Control period symbols (for hsync/vsync embedding)
    function [9:0] tmds_control;
        input [1:0] c;
        begin
            case(c)
                2'b00: tmds_control = 10'b1101010100;
                2'b01: tmds_control = 10'b0010101011;
                2'b10: tmds_control = 10'b0101010100;
                default: tmds_control = 10'b1010101011;
            endcase
        end
    endfunction

    // Encoding decision for DC balance
    wire inv_data = ((disparity==0)||(balance==0)) ? (~q_m[8]) :
                    (((disparity>0)&&(balance>0))||((disparity<0)&&(balance<0))) ? 1'b1 : 1'b0;

    wire bit9 = ((disparity==0)||(balance==0)) ? (~q_m[8]) :
                (((disparity>0)&&(balance>0))||((disparity<0)&&(balance<0))) ? 1'b1 : 1'b0;

    wire [4:0] ones_total = (inv_data ? (5'd8 - {1'b0,n1qm}) : {1'b0,n1qm}) + {4'd0,q_m[8]} + {4'd0,bit9};
    wire signed [6:0] delta = $signed({1'b0,ones_total,1'b0}) - 7'sd10;

    // Stage 2: DC balancing and output
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tmds <= 10'h000;
            disparity <= 0;
        end else if (!vde) begin
            // Control period: output sync symbols
            tmds <= tmds_control(cd);
            disparity <= 0;
        end else begin
            // Data period: output encoded pixel
            tmds[9]   <= bit9;
            tmds[8]   <= q_m[8];
            tmds[7:0] <= inv_data ? ~q_m[7:0] : q_m[7:0];
            disparity <= disparity + delta;
        end
    end
endmodule
