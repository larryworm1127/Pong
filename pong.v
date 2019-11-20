`include "PS2MouseKeyboard/PS2_Keyboard_Controller.v"
`include "vga_adaptor/vga_adaptor.v"

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

	// erase

	// Create keys detectors
	wire key_w, key_s, key_up, key_down, key_space, key_enter;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
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
	wire paddle1_erase; 
	
	datapath paddle1(
		.x_in      (0),
		.y_in      (0),
		.colour_in (colour_in),
		.resetn    (resetn),
		.enable    (enable),
		.clk       (CLOCK_50),
		.down      (key_down),
		.up        (key_up),
		.left      (key_left),
		.right     (key_right),
		.x_out     (x),
		.y_out     (y),
		.colour_out(colour_out),
		.do_erase  (paddle1_erase)
	);

	// Instantiate FSM control
	control paddleControl1(
		.clk   (clk),
		.resetn(resetn),
		.go    (paddle1_erase),
		.plot  (plot),
		.enable(enable)
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
