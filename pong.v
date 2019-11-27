
module pong
	(
		CLOCK_50,						//	On Board 50 MHz
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,					//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B,   						//	VGA Blue[9:0]
		// The ports below are for the PS/2 serial port.
		PS2_CLK,
		PS2_DAT
	);

	input CLOCK_50;
	input PS2_CLK;
	input PS2_DAT;
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;			//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]

	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [8:0] x;
	wire [7:0] y; 
	wire writeEn;
	wire load_en;

	// Create keys detectors
	wire key_w, key_s, key_up, key_down, key_space, key_enter;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter # (
		.RESOLUTION             ("320x240"),
		.MONOCHROME             ("FALSE"),
		.BITS_PER_COLOUR_CHANNEL(1),
		.BACKGROUND_IMAGE       ("background.mif");
		)
		VGA(
			.resetn   (resetn),
			.clock    (CLOCK_50),
			.colour   (colour),
			.x        (x),
			.y        (y),
			.plot     (writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R    (VGA_R),
			.VGA_G    (VGA_G),
			.VGA_B    (VGA_B),
			.VGA_HS   (VGA_HS),
			.VGA_VS   (VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC (VGA_SYNC_N),
			.VGA_CLK  (VGA_CLK));
		defparam VGA.RESOLUTION = "320x240";
		defparam VGA.MONOCHROME = "TRUE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";

	// Instantiate keyboard controller
	keyboard k0(
		.clock    (CLOCK_50),
		.resetn   (resetn),
		.PS2_CLK  (PS2_CLK),
		.PS2_DAT  (PS2_DAT),
		.key_w    (key_w),
		.key_s    (key_s),
		.key_up   (key_up),
		.key_down (key_down),
		.key_space(key_space),
		.key_enter(key_enter)
	);

	// Instantiate datapath
	// wire paddle1_erase; 
	
	// datapath paddle1(
	// 	.x_in      (0),
	// 	.y_in      (0),
	// 	.resetn    (resetn),
	// 	.enable    (writeEn),
	// 	.clk       (CLOCK_50),
	// 	.down      (key_down),
	// 	.up        (key_up),
	// 	.left      (key_left),
	// 	.right     (key_right),
	// 	.x_out     (x),
	// 	.y_out     (y),
	// 	.do_erase  (paddle1_erase)
	// );

	// Instantiate FSM control
	// control paddleControl1(
	// 	.clk      (CLOCK_50),
	// 	.resetn   (resetn),
	// 	.go       (paddle1_erase),
	// 	.plot     (plot),
	// 	.enable   (writeEn),
	// 	.load_en  (load_en),
	// 	.colourOut(colour)
	// );
	
	locationProcessor # (
      .BOX_WIDTH              (9'd4),
      .BOX_HEIGHT              (9'd4),
      .SCREEN_WIDTH              (9'd160),
      .SCREEN_HEIGHT                (9'd120),
      .FRAME_RATE_COUNT       (32'd9999999) //5 Hz
      )
      processor (
            .clock (clock),
            .reset_n (reset_n),
            .in_color (color_in),
            .m_ready(screen_drawer_ready),
            .m_valid  (processor_data_valid),
            .box_x (box_x),
            .box_y    (box_y),
            .out_color(box_color)
            );

    screenDrawer # (
      .BOX_WIDTH              (9'd4),
      .BOX_HEIGHT              (9'd4),
      .SCREEN_WIDTH              (9'd160),
      .SCREEN_HEIGHT                  (9'd120),
      .REFRESH_RATE_COUNT       (32'd833332) //60Hz
      )
      screen_drawer_0 (
            .clock (clock),
            .reset_n (reset_n),
            .s_ready (screen_drawer_ready),
             .s_valid      (processor_data_valid),
             .in_box_x     (box_x),
             .in_box_y     (box_y),
             .in_box_color (box_color),

             .m_ready (box_drawer_ready),
             .m_valid (screen_drawer_data_valid),
             .out_box_x    (draw_box_x),
             .out_box_y    (draw_box_y),
             .out_box_w    (draw_box_w),
             .out_box_h    (draw_box_h),
             .out_box_color (draw_box_color)
            );

    boxDrawer box_drawer_0 (
            .clock       (clock),
            .reset_n    (reset_n),

            .s_ready     (box_drawer_ready),
            .s_valid     (screen_drawer_data_valid),
            .in_box_x    (draw_box_x),
            .in_box_y    (draw_box_y),
            .in_box_w    (draw_box_w),
            .in_box_h    (draw_box_h),
            .in_box_color(draw_box_color),
            .vga_x       (vga_x),
            .vga_y       (vga_y),
            .plot            (vga_plot),
            .colour      (vga_color)
      );

	
endmodule


// Handles keyboard input
module keyboard(
	input clock,
	input resetn,
	input PS2_CLK,
	input PS2_DAT,
	output key_w, key_s, key_up, key_down, 
	output key_space, key_enter
	);

	keyboard_tracker #(.PULSE_OR_HOLD(0)) k1(
		.clock  (clock),
		.reset  (resetn),
		.PS2_CLK(PS2_CLK),
		.PS2_DAT(PS2_DAT),
		.w      (key_w),
		.s      (key_s),
		.up     (key_up),
		.down   (key_down),
		.space  (key_space),
		.enter  (key_enter)
	);

endmodule