// Part 3 skeleton

module part3
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;
	wire ld_x, ld_y, draw;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
    
    combined c1 (
		.clock(CLOCK_50),
		.resetn(resetn),
		
		.colour(SW[9:7]),
		.go(~KEY[1]),
		
		.out_x(x),
		.out_y(y),
		.out_colour(colour),
		.plot(writeEn)
	);

    
endmodule

module combined (clock, resetn, colour, go, out_x, out_y, out_colour, plot);
	input clock, resetn, go;

	input [2:0] colour;
	output [7:0] out_x;
	output [6:0] out_y;
	output [2:0] out_colour;
	output plot;
	
	wire  en, en_d, down, right, select_colour, draw, change, finish_draw;
	
	// Instansiate datapath
	datapath d0(
		.resetn(resetn),
		.clock(clock),
		
		.colour(colour),
		
		.en(en),
		.en_d(en_d),
		.down(down),
		.right(right),
		.select_colour(select_colour),
		.draw(draw),
		
		.out_x(out_x),
		.out_y(out_y),
		.out_colour(out_colour),
		.change(change),
		.finish_draw(finish_draw)
	);

    // Instansiate FSM control
   control c0(
		.clock(clock),
		.resetn(resetn),
		.go(go),
		
		.change(change),
		.finish_draw(finish_draw),
		.out_x(out_x),
		.out_y(out_y),
		
		.en(en),
		.en_d(en_d),
		.down(down),
		.right(right),
		.select_colour(select_colour),
		.draw(draw),
		.plot(plot)
		);
	
endmodule

module datapath(colour, resetn, clock, draw, en, en_d, down, right, select_colour, out_x, out_y, out_colour, change, finish_draw);
	input [2:0] colour;
	input resetn, clock;
	input en, en_d, down, right, select_colour, draw;
	
	output reg finish_draw;
	output  [7:0] out_x;
	output  [6:0] out_y;
	output reg [2:0] out_colour;
	output change;
	
	reg [7:0] x;
	reg [6:0] y;
	reg [3:0] q, frame;
	reg [19:0] delay;
	wire frame_en;
	
	always @(posedge clock)
	begin: load
		if (!resetn) begin
			out_colour = 3'b111;
			end
		else 
			begin
				if (select_colour)
					out_colour = 3'b111;
				else
					out_colour = colour;
			end
	end
	
	always @(posedge clock)
	begin: delay_counter
		if (!resetn)
			delay <= 20'd833_333;
		else if (en_d == 1'b1)
			begin
				if (delay == 0)
					delay <= 20'd833_333;
				else
					delay <= delay - 1'b1;
			end
		else
			delay <= delay;
	end
	
	assign frame_en = (delay == 20'd0) ? 1 : 0;
	
	always @(posedge clock)
	begin: frame_counter
		if (!resetn)
			frame <= 4'b0000;
		else if (frame_en == 1'b1)
			begin
				if (frame == 4'd14)
					frame <= 4'd0;
				else
					frame <= frame + 1'b1;
			end
		else
			frame <= frame;
	end
	
	assign change = (frame == 4'd14) ? 1 : 0;
	
	always @(posedge clock)
	begin: x_counter
		if (!resetn)
			x <= 8'd0;
		else if (en == 1'b1)
			begin
				if (right == 1'b1)
					x <= x + 1'b1;
				else
					x <= x - 1'b1;
			end
		else
			x <= x;
	end
	
	always @(posedge clock)
	begin: y_counter
		if (!resetn)
			y <= 7'd60;
		else if (en == 1'b1)
			begin
				if (down == 1'b1)
					y <= y + 1'b1;
				else
					y <= y - 1'b1;
			end
		else
			y <= y;
	end

	always @(posedge clock)
	begin: counter
		if (! resetn) begin
			q <= 4'b0000;
			finish_draw <= 1'b0;
			end
		else if (draw)
			begin
				if (q == 4'b1111) begin
					q <= 0;
					finish_draw <= 1'b1;
					end
				else begin
					q <= q + 1'b1;
					finish_draw <= 1'b0;
					end
			end
	end
	
	assign out_x = x + q[1:0];
	assign out_y = y + q[3:2];
	
endmodule

module control(clock, resetn, go, change, finish_draw, out_x, out_y, en, en_d, down, right, select_colour, draw, plot);
	input resetn, clock, go, change, finish_draw, out_x, out_y;
	output reg en, en_d, down, right, select_colour, draw, plot;

	reg [2:0] current_state, next_state;
	
	localparam Start = 3'd0,
					Draw = 3'd1,
					Erase= 3'd2,
					New_x_y = 3'd3;
					

	always @(*)
	begin: state_table
		case (current_state)
			Start: next_state = go ? Draw : Start;
			Draw: next_state = change ?  Erase: Draw;
			Erase: next_state = finish_draw ? New_x_y : Erase;
			New_x_y: next_state = Draw;
			default: next_state = Start;
		endcase
	end
	
	always @(*)
	begin: signals
		en = 1'b0; 
		en_d = 1'b0;
		down = 1'b0;
		right= 1'b1; 
		select_colour = 1'b0;
		draw = 1'b0;
		plot = 1'b0;
		
		case (current_state)
		Start: begin
			en_d = 1'b1;
			end
		Draw: begin 
			select_colour = 1'b0;
			draw = 1'b1;
			plot = 1'b1;
			end
		Erase: begin
			select_colour = 1'b1;
			draw = 1'b1;
			plot = 1'b1;
			end
		New_x_y : begin
			en = 1'b1;
			begin
				if (out_x == 0)
					right = 1'b1;
				else if (out_x == 8'd159)
					right = 1'b0;
				else if (out_y == 0)
					down = 1'b1;
				else if (out_y == 7'd119)
					down = 1'b0;
				end	
			end
		endcase
	end
	
always@(posedge clock)
    begin: state_FFs
        if(!resetn)
            current_state <= Start;
        else
            current_state <= next_state;
    end // state_FFS
endmodule

