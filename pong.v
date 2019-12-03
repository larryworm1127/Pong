
module pong(

		///////// ADC /////////
		output             ADC_CONVST,
		output             ADC_DIN,
		input              ADC_DOUT,
		output             ADC_SCLK,

		///////// AUD /////////
		input              AUD_ADCDAT,
		inout              AUD_ADCLRCK,
		inout              AUD_BCLK,
		output             AUD_DACDAT,
		inout              AUD_DACLRCK,
		output             AUD_XCK,

		///////// CLOCK2 /////////
		input              CLOCK2_50,

		///////// CLOCK3 /////////
		input              CLOCK3_50,

		///////// CLOCK4 /////////
		input              CLOCK4_50,

		///////// CLOCK /////////
		input              CLOCK_50,

		///////// DRAM /////////
		output      [12:0] DRAM_ADDR,
		output      [1:0]  DRAM_BA,
		output             DRAM_CAS_N,
		output             DRAM_CKE,
		output             DRAM_CLK,
		output             DRAM_CS_N,
		inout       [15:0] DRAM_DQ,
		output             DRAM_LDQM,
		output             DRAM_RAS_N,
		output             DRAM_UDQM,
		output             DRAM_WE_N,

		///////// FAN /////////
		output             FAN_CTRL,

		///////// FPGA /////////
		output             FPGA_I2C_SCLK,
		inout              FPGA_I2C_SDAT,

		///////// GPIO /////////
		inout     [35:0]         GPIO_0,
		inout     [35:0]         GPIO_1,


		///////// HEX0 /////////
		output      [6:0]  HEX0,

		///////// HEX1 /////////
		output      [6:0]  HEX1,

		///////// HEX2 /////////
		output      [6:0]  HEX2,

		///////// HEX3 /////////
		output      [6:0]  HEX3,

		///////// HEX4 /////////
		output      [6:0]  HEX4,

		///////// HEX5 /////////
		output      [6:0]  HEX5,

		///////// IRDA /////////
		input              IRDA_RXD,
		output             IRDA_TXD,

		///////// KEY /////////
		input       [3:0]  KEY,

		///////// LEDR /////////
		output      [9:0]  LEDR,

		///////// PS2 /////////
		inout              PS2_CLK,
		inout              PS2_CLK2,
		inout              PS2_DAT,
		inout              PS2_DAT2,

		///////// SW /////////
		input       [9:0]  SW,

		///////// TD /////////
		input              TD_CLK27,
		input      [7:0]  TD_DATA,
		input             TD_HS,
		output             TD_RESET_N,
		input             TD_VS,

		///////// VGA /////////
		output      [7:0]  VGA_B,
		output             VGA_BLANK_N,
		output             VGA_CLK,
		output      [7:0]  VGA_G,
		output             VGA_HS,
		output      [7:0]  VGA_R,
		output             VGA_SYNC_N,
		output             VGA_VS
	);

	//=======================================================
	//  REG/WIRE declarations
	//=======================================================
	wire clock;
	wire reset_n;
	wire up;
	wire down;

	wire [2:0] color_in;

	wire [8:0] box_x;
	wire [8:0] box_y;
	wire [2:0] box_color;

	wire processor_data_valid;
	wire screen_drawer_ready;

	wire screen_drawer_data_valid;
	wire box_drawer_ready;

	wire [8:0] draw_box_x;
	wire [8:0] draw_box_y;
	wire [8:0] draw_box_h;
	wire [8:0] draw_box_w;
	wire [2:0] draw_box_color;

	wire [8:0] vga_x;
	wire [7:0] vga_y;
	wire [2:0] vga_color;
	wire vga_plot;


	//=======================================================
	//  Structural coding
	//=======================================================
	assign clock = CLOCK_50;
	assign reset_n = KEY[0];
	assign color_in = SW[9:7];
	assign up = ~KEY[1];
	assign down = ~KEY[2];
	
	vga_adapter #(
		.RESOLUTION             ("320x240"),
        .MONOCHROME             ("FALSE"),
        .BITS_PER_COLOUR_CHANNEL(1),
        .BACKGROUND_IMAGE       ("background.mif"))
        VGA(
            .resetn(reset_n),
            .clock(clock),
            .colour(vga_color),
            .x(vga_x),
            .y(vga_y),
            .plot(vga_plot),
            /* Signals for the DAC to drive the monitor. */
            .VGA_R(VGA_R),
            .VGA_G(VGA_G),
            .VGA_B(VGA_B),
            .VGA_HS(VGA_HS),
            .VGA_VS(VGA_VS),
            .VGA_BLANK(VGA_BLANK_N),
            .VGA_SYNC(VGA_SYNC_N),
            .VGA_CLK(VGA_CLK)
       );

	// Instantiate keyboard controller
	keyboard k0(
		.clock    (clock),
		.resetn   (reset_n),
		.PS2_CLK  (PS2_CLK),
		.PS2_DAT  (PS2_DAT),
		.key_w    (key_w),
		.key_s    (key_s),
		.key_up   (key_up),
		.key_down (key_down),
		.key_space(key_space),
		.key_enter(key_enter)
	);
	
	locationProcessor # (
        .BOX_WIDTH       (9'd10),
        .BOX_HEIGHT      (9'd48),
        .SCREEN_WIDTH    (9'd320),
        .SCREEN_HEIGHT   (9'd240),
        .FRAME_RATE_COUNT(32'd9999999) //5 Hz
        )
        processor (
            .clock (clock),
            .reset_n (reset_n),
            .in_color (color_in),
			.box_init_x(0),
			.up(up),
			.down(down),
            .m_ready(screen_drawer_ready),
            .m_valid  (processor_data_valid),
            .box_x (box_x),
            .box_y    (box_y),
            .out_color(box_color)
            );

    screenDrawer # (
		.BOX_WIDTH         (9'd10),
		.BOX_HEIGHT        (9'd48),
		.SCREEN_WIDTH      (9'd320),
		.SCREEN_HEIGHT     (9'd240),
		.REFRESH_RATE_COUNT(32'd833332) //60Hz
		)
		screen_drawer_0 (
            .clock        (clock),
            .reset_n      (reset_n),
            .s_ready      (screen_drawer_ready),
			.s_valid      (processor_data_valid),
			.in_box_x     (box_x),
			.in_box_y     (box_y),
			.in_box_color (box_color),

			.m_ready      (box_drawer_ready),
			.m_valid      (screen_drawer_data_valid),
			.out_box_x    (draw_box_x),
			.out_box_y    (draw_box_y),
			.out_box_w    (draw_box_w),
			.out_box_h    (draw_box_h),
			.out_box_color(draw_box_color)
            );

    boxDrawer box_drawer_0 (
        .clock       (clock),
        .reset_n     (reset_n),

        .s_ready     (box_drawer_ready),
        .s_valid     (screen_drawer_data_valid),
        .in_box_x    (draw_box_x),
        .in_box_y    (draw_box_y),
        .in_box_w    (draw_box_w),
        .in_box_h    (draw_box_h),
        .in_box_color(draw_box_color),
        .vga_x       (vga_x),
        .vga_y       (vga_y),
        .plot        (vga_plot),
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