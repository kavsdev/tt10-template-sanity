`default_nettype none

module tt_um_vga_box_v1(
  input  wire [7:0] ui_in,    // Dedicated inputs
  output wire [7:0] uo_out,   // Dedicated outputs
  input  wire [7:0] uio_in,   // IOs: Input path
  output wire [7:0] uio_out,  // IOs: Output path
  output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
  input  wire       ena,      // always 1 when the design is powered, so you can ignore it
  input  wire       clk,      // clock
  input  wire       rst_n     // reset_n - low to reset
);

  //localparams
  localparam  VGA_WIDTH  = 640;
  localparam  VGA_HEIGHT = 480;

  // VGA signals
  wire hsync;
  wire vsync;
  wire [1:0] R;
  wire [1:0] G;
  wire [1:0] B;
  wire video_active;
  wire [9:0] pix_x;
  wire [9:0] pix_y;
  wire reset = ~rst_n;
  // TinyVGA PMOD
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  // Unused outputs assigned to 0.
  assign uio_out = 0;
  assign uio_oe  = 0;

  // Suppress unused signals warning
  wire _unused_ok = &{ena, ui_in, uio_in};

    hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(pix_x),
    .vpos(pix_y)
  );

  // localparam FN =0 ;
  // reg [4:0]frameCount;

  // always @ (posedge vsync) begin
  //   if(reset || frameCount==FN) frameCount <= 0;
  //   else frameCount <= frameCount +1; 
  // end

  localparam sq_size = 200;
  reg [9:0] sq_xpos, sq_ypos;
  reg sq_dx,sq_dy; //right = 0, down =0
  wire [9:0]sq_speed =5;


  always @ (posedge vsync or posedge reset) begin
    if(reset) begin
      sq_xpos <= 0;
      sq_ypos <= 0;
      sq_dx <= 0;
      sq_dy <= 0;
    end


    case (sq_dx)
        0: begin
            if(sq_xpos+sq_size+sq_speed >=VGA_WIDTH-1) begin
                sq_dx <= 1; //change horizontal direction
                sq_xpos <= VGA_WIDTH-1 -sq_size; //move as right as possible
            end else sq_xpos <= sq_xpos + sq_speed;
        end 
        1: begin
            if(sq_xpos < sq_speed) begin
                sq_dx <=0;
                sq_xpos <= 0;
            end else sq_xpos <= sq_xpos - sq_speed;
        end
    endcase

    case (sq_dy)
        0: begin
            if(sq_ypos+sq_size+sq_speed >=VGA_HEIGHT-1) begin
                sq_dy <= 1; //change vertical direction
                sq_ypos <= VGA_HEIGHT-1 -sq_size; //move as down as possible
            end else sq_ypos <= sq_ypos +sq_speed;
        end
        1: begin
            if(sq_ypos < sq_speed) begin
                sq_dy <=0;
                sq_ypos <= 0;
            end else sq_ypos <= sq_ypos -sq_speed;
        end 
    endcase
  end

wire square = (pix_x>=sq_xpos) && (pix_x < sq_xpos+sq_size) && (pix_y>=sq_ypos) && (pix_y < sq_ypos+sq_size);


  assign R = video_active ? (square ? 2'b11 : 2'b00) : 2'b00;
  assign G = video_active ? (square ? 2'b11 : 2'b00) : 2'b00;
  assign B = video_active ? (square ? 2'b11 : (pix_x <2 || (pix_x > VGA_WIDTH -1 -2) || pix_y <2 || (pix_y > VGA_HEIGHT -1 -2)? 2'b11 :2'b00 ) ): 2'b00;
    
endmodule
