module vga(
  input hwclk,
  output led1,
  output led2,
  output led3,
  output led4,
  output led5,
  output led6,
  output led7,
  output led8,
  output x,
  output y,
  output r,
  output g,
  output b,
  output frame_clk
);

  // Modeline "320x200@71" 12.02 320 352 368 400 200 204 207 211 doublescan (12.01MHZ)
  // Modeline "320x200@71" 12.00 320 336 380 396 200 204 207 211
  // -----------------------------------------------------------
  // Modeline "640x400@80" 27.00 640 672 768 800 400 407 413 421
  // Modeline "640x400@60" 19.88 640 672 744 776 400 408 412 421

  // 640x480  60  25.175  640 16  96  48  480 10  2 33  n n
  // 640x400  70  25.175  640 16  96  48  400 12  2 35  n p
  // Modeline "640x400@75" 25.18 640 672 760 792 400 408 413 421
  //
  //   ---------------------------640----672   768----800
  //   |                           |      |     |      |
  //   |                           |       -----       |
  //   |                           |                   |
  //   |                           |                   |
  //   |                           |                   |
  //   |                           |                   |
  //   |                           |                   |
  //   |                           |                   |
  //  400--------------------------                    |
  //   |                                               |
  //  407--                                            |
  //       |                                           |
  //  413--                                            |
  //   |                                               |
  //  421-----------------------------------------------
  //
  //  horizontal 30.04 kHz / 30.3 kHz
  //  vertical 71.19 Hz / 71.97 Hz
  //

  // 416x304 (512x312)
  parameter x_visible = 416-1;
  parameter x_front = 12;
  parameter x_pulse = 36;
  parameter x_back = 48;

  parameter y_visible = 304-1;
  parameter y_front = 4;
  parameter y_pulse = 2;
  parameter y_back = 2;

/*
  // 640x400
  parameter x_visible = 640-1;
  parameter x_front = 32;
  parameter x_pulse = 88;
  parameter x_back = 32;

  parameter y_visible = 400-1;
  parameter y_front = 8;
  parameter y_pulse = 5;
  parameter y_back = 8;
*/

/*
  parameter x_visible = 640-1;
  parameter x_front = 16;
  parameter x_pulse = 96;
  parameter x_back = 48;

  // 720x400 or 640x350(v polarity)
  parameter y_visible = 400-1;
  parameter y_front = 12;
  parameter y_pulse = 2;
  parameter y_back = 35;

  // 640x480
  parameter y_visible = 480-1;
  parameter y_front = 10;
  parameter y_pulse = 2;
  parameter y_back = 33;
*/

///*
  wire       sysclk;
  wire       locked;
  pll myPLL (.clock_in(hwclk), .global_clock(sysclk), .locked(locked));

  // 8 MHz clock generation (from 48 MHz)
  reg clk_2 = 0;
  reg [31:0] cntr_2 = 32'b0;
  parameter period_2 = 2; // 3 - 1

  always @(posedge sysclk) begin
    cntr_2 <= cntr_2 + 1;
    if (cntr_2 == period_2) begin
      clk_2 <= ~clk_2;
      cntr_2 <= 32'b0;
    end
  end

  wire clk = clk_2;
//*/

/*
  // 1 Hz clock generation (from 12 MHz)
  reg clk_1 = 0;
  reg [31:0] cntr_1 = 32'b0;
  parameter period_1 = 59; // 6000000;

  always @(posedge hwclk) begin
    cntr_1 <= cntr_1 + 1;
    if (cntr_1 == period_1) begin
      clk_1 <= ~clk_1;
      cntr_1 <= 32'b0;
    end
  end

  wire clk = clk_1; // test with leds
*/

//  wire clk = hwclk; // test with verilator

//  wire clk = sysclk; // test with oscilloscope

  reg[9:0] reg_x = 0;
  reg[9:0] reg_y = 0;
  wire[9:0] reg_x_adjusted = reg_x - delta_left;
  wire[9:0] reg_y_adjusted = reg_y - delta_top;
  wire[9:0] reg_x_1 = reg_x_adjusted + 1;
//  wire[9:0] reg_x_1 = reg_x + 1;
//  wire[5:0] ind_x = reg_x_1[9:4];
  wire[5:0] ind_x = reg_x_1[8:3];
//  wire[8:0] ind_y = reg_y[9:1];
  wire[8:0] ind_y = reg_y_adjusted[8:0];

  reg [7:0] frame = 0;
  wire [13:0] offset = (ind_y * 40) + {8'b0, ind_x};
//  wire [13:0] addr_bus = frame[0] ? offset : 8000+offset;
  wire [13:0] addr_bus = offset;
  wire [7:0] data_out;
  bitmap myBITMAP(
    .CLK(clk),
    .WE(1'b0),
    .Address(addr_bus),
    .DataIn(8'h00),
    .DataOut(data_out)
  );

  // 416x304 (512x312)
  // actually visible: 388x268
  // safe area: 230 lines
  parameter delta_left = 46; // 29;
  parameter delta_right = 50; // 39;
  parameter delta_top = 62; // 57;
  parameter delta_bottom = 42; // 11;
  // 388 - 320 = 68, 12*68/(12 + 16)=29, 16*68/(12+16)=39, 12: left, 16: right
  // 268 - 200 = 68, 30*68/(30 + 6)=57, 6*68/(30+6)=11, 30: top, 6: bottom

//  wire pixel = data_out[7-reg_x[3:1]]; // vga 640
  wire pixel = data_out[7-reg_x_adjusted[2:0]]; // pal 320
  always @(posedge clk) begin
    if (
      reg_x >= delta_left && reg_x <= x_visible-delta_right &&
      reg_y >= delta_top && reg_y <= y_visible-delta_bottom
    ) begin
      r <= pixel; // 1'b1; // pixel;
      g <= 1'b1; // pixel;
      b <= 1'b1; // pixel;
    end
    else begin
      r <= 0'b0;
      g <= 0'b0;
      b <= 0'b0;
    end
  end

  reg next_line = 0;
  always @(posedge clk) begin
    case (reg_x)
      x_visible: begin
        reg_x <= reg_x + 1;
        next_line <= 1'b0;
      end
      x_visible + x_front: begin
        reg_x <= reg_x + 1;
//        x <= 1'b1;
        x <= 1'b0;
      end
      x_visible + x_front + x_pulse: begin
        reg_x <= reg_x + 1;
//        x <= 1'b0;
        x <= 1'b1;
      end
      x_visible + x_front + x_pulse + x_back: begin
        reg_x <= 0;
        next_line <= 1'b1;
      end
      default:
        reg_x <= reg_x + 1;
    endcase
  end

  reg next_frame = 0;
  reg correction = 0;
  always @(posedge next_line) begin
    case (reg_y)
      y_visible: begin
        reg_y <= reg_y + 1;
        next_frame <= 1'b0;
      end
      y_visible + y_front: begin
        reg_y <= reg_y + 1;
//        y <= 1'b1;
        y <= 1'b0;
      end
      y_visible + y_front + y_pulse: begin
        reg_y <= reg_y + 1;
//        y <= 1'b0;
        y <= 1'b1;
      end
      y_visible + y_front + y_pulse + y_back + correction: begin
        reg_y <= 0;
        next_frame <= 1'b1;
        // correction <= ~correction;
      end
      default:
        reg_y <= reg_y + 1;
    endcase
  end

  reg main_clk = 0;
  reg[31:0] main_clk_cntr = 32'b0;
  parameter main_clk_period = 23999999;

  always @(posedge sysclk) begin
    main_clk_cntr <= main_clk_cntr + 1;
    if (main_clk_cntr == main_clk_period) begin
      main_clk <= ~main_clk;
      main_clk_cntr <= 32'b0;
    end
  end

  reg line_clk = 0;
  reg[31:0] line_number = 0;
  parameter line_period = 7812;

  always @(posedge next_line) begin
    line_number <= line_number + 1;
    if (line_number == line_period) begin
      line_clk <= ~line_clk;
      line_number <= 32'b0;
    end
  end

  // 1 Hz clock generation (from 50 Hz)
  reg frame_clk = 0;
  parameter frame_period = 24;

  always @(posedge next_frame) begin
    frame <= frame + 1;
    if (frame == frame_period) begin
      frame_clk <= ~frame_clk;
      frame <= 8'b0;
    end
  end

  // assign {led1, led2, led3, led4, led5, led6, led7, led8} = frame;
  assign led1 = main_clk;
//  assign led2 = line_clk;
  assign led3 = frame_clk;

//  assign {led4, led5, led6, led7, led8} = frame[4:0];


endmodule
