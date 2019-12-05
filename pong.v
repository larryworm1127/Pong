
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
		//output      [6:0]  HEX2,

		///////// HEX3 /////////
		//output      [6:0]  HEX3,

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
	wire score_reset_n;
	wire up_left;
	wire down_left;
	wire up_right;
	wire down_right;

	wire [2:0] color_in;

	wire [8:0] paddle_left_x;
	wire [8:0] paddle_left_y;
	wire [8:0] paddle_right_x;
	wire [8:0] paddle_right_y;
	wire [8:0] ball_x;
	wire [8:0] ball_y;
	wire [2:0] box_color;
	wire [2:0] paddle_right_color;
	wire [2:0] paddle_left_color;
	//assign box_color = 3'b111;

	wire processor_data_valid_pl;
	wire processor_data_valid_pr;
	wire processor_data_valid_ball;
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

	wire left_enable;
	wire right_enable;
	wire [7:0] left_score;
	wire [7:0] right_score;


	//=======================================================
	//  Structural coding
	//=======================================================
	assign clock = CLOCK_50;
	assign reset_n = SW[0];
	assign score_reset_n = SW[1];
	assign color_in = SW[9:7];
	assign up_left = ~KEY[2];
	assign down_left = ~KEY[3];
	assign up_right = ~KEY[0];
	assign down_right = ~KEY[1];
	
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

	// Location processors
	locationProcessorPaddle # (
        .BOX_WIDTH       (9'd10),
        .BOX_HEIGHT      (9'd48),
        .SCREEN_WIDTH    (9'd320),
        .SCREEN_HEIGHT   (9'd240),
        .FRAME_RATE_COUNT(32'd9999999) //5 Hz
        )
        processor_paddle_left (
            .clock     (clock),
            .reset_n   (reset_n),
            .in_color  (color_in),
			.box_init_x(0),
			.up        (up_left),
			.down      (down_left),
            .m_ready   (screen_drawer_ready),
            .m_valid   (processor_data_valid_pl),
            .box_x     (paddle_left_x),
            .box_y     (paddle_left_y),
            .out_color (paddle_left_box_color)
            );

    locationProcessorPaddle # (
        .BOX_WIDTH       (9'd10),
        .BOX_HEIGHT      (9'd48),
        .SCREEN_WIDTH    (9'd320),
        .SCREEN_HEIGHT   (9'd240),
        .FRAME_RATE_COUNT(32'd9999999) //5 Hz
        )
        processor_paddle_right (
            .clock     (clock),
            .reset_n   (reset_n),
            .in_color  (color_in),
			.box_init_x(310),
			.up        (up_right),
			.down      (down_right),
            .m_ready   (screen_drawer_ready),
            .m_valid   (processor_data_valid_pr),
            .box_x     (paddle_right_x),
            .box_y     (paddle_right_y),
            .out_color (paddle_left_box_color)
            );

    locationProcessorBall # (
        .BALL_WIDTH      (9'd10),
        .BALL_HEIGHT     (9'd10),
        .SCREEN_WIDTH    (9'd320),
        .SCREEN_HEIGHT   (9'd240),
        .LEFT_COLLISION  (9'd10),
	     .RIGHT_COLLISION (9'd310),
        .FRAME_RATE_COUNT(32'd9999999) //5 Hz
        )
        processor_ball (
            .clock         (clock),
            .reset_n       (reset_n),
            .in_color      (color_in),
            .paddle_left_y (paddle_left_y),
            .paddle_right_y(paddle_right_y),
            .m_ready       (screen_drawer_ready),
            .m_valid       (processor_data_valid_ball),
            .box_x         (ball_x),
            .box_y         (ball_y),
            .out_color     (box_color),
			.left_point    (left_enable),
			.right_point   (right_enable)
            );

    screenDrawer # (
		.BOX_WIDTH         (9'd10),
		.BOX_HEIGHT        (9'd48),
		.BALL_WIDTH        (9'd10),
		.BALL_HEIGHT       (9'd10),
		.SCREEN_WIDTH      (9'd320),
		.SCREEN_HEIGHT     (9'd240),
		.REFRESH_RATE_COUNT(32'd833332) //60Hz
		)
		screen_drawer_0 (
            .clock            (clock),
            .reset_n          (reset_n),
            .s_ready          (screen_drawer_ready),
			.s_valid_pl       (processor_data_valid_pl),
			.s_valid_pr       (processor_data_valid_pr),
			.s_valid_ball     (processor_data_valid_ball),
			.in_paddle_left_x (paddle_left_x),
			.in_paddle_left_y (paddle_left_y),
			.in_paddle_right_x(paddle_right_x),
			.in_paddle_right_y(paddle_right_y),
			.in_ball_x        (ball_x),
			.in_ball_y        (ball_y),
			.in_box_color     (box_color),

			.m_ready          (box_drawer_ready),
			.m_valid          (screen_drawer_data_valid),
			.out_box_x        (draw_box_x),
			.out_box_y        (draw_box_y),
			.out_box_w        (draw_box_w),
			.out_box_h        (draw_box_h),
			.out_box_color    (draw_box_color)
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

	score score_0 (
		.clock           (clock),
		.reset_n         (score_reset_n),
		.left_enable     (left_enable),
		.right_enable    (right_enable),
		.left_out        (left_score),
		.right_out       (right_score)
		);
		
	hex_decoder H0(
	    .hex_digit(right_score[3:0]),
	    .segments(HEX0)
	    );
		 
	hex_decoder H1(
	    .hex_digit(right_score[7:4]),
	    .segments(HEX1)
	    );

	hex_decoder H4(
	    .hex_digit(left_score[3:0]),
	    .segments(HEX4)
	    );	
		 	
	hex_decoder H5(
	    .hex_digit(left_score[7:4]),
	    .segments(HEX5)
	    );	

endmodule


module score(
		input clock,
		input reset_n,
		input left_enable,	         // Add one to left reg
		input right_enable,  		 // Add one to right reg
		output reg [7:0] left_out,   // Output score left paddle
		output reg [7:0] right_out	 // Output score right paddle
	);
		
	// Only have one enable at a time or nothing happens
	always @ (*) begin
		// Reset both scores to 0
		if (!reset_n) begin
			left_out = 0;
			right_out = 0;
		end 
		else if (left_enable == 1) begin
			left_out = left_out + 1;

		end
		else if (right_enable == 1) begin
			right_out = right_out + 1;
		end
		else begin
		end
	end
endmodule

