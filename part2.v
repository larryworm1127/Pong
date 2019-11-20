// Part 2 skeleton

module part2
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
	wire [8:0] x;
	wire [7:0] y;
	wire writeEn;

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
	defparam VGA.RESOLUTION = "320x240";
	defparam VGA.MONOCHROME = "FALSE";
	defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
	defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
    
	wire go;
//	assign go = ~KEY[3];
	reg count;
	always @(negedge) begin
		if (!resetn) begin
			count <= 0;
		end 
		// On LOAD_Y
		else if (count == 1) begin
			
		end
		// On LOAD_C
		else if (count == 2) begin
			
		end
		else begin
			count <= count + 1;
		end
	end

	wire ld_x, ld_y, ld_c, plot, enable;
	
    // Instansiate datapath
	datapath d0(
		.data_in(SW[8:0]),
		.colour_in({SW[9], ~KEY[1], ~KEY[2]}),
		.resetn(resetn),
		.enable(writeEn),
		.clk(CLOCK_50),
		.ld_c(ld_c),
		.ld_x(ld_x),
		.ld_y(ld_y),
		.x_out(x),
		.y_out(y),
		.colour_out(colour)
	);

    // Instansiate FSM control
    control c0(
    	.clk(CLOCK_50),
    	.resetn(resetn),
    	.go(~CLOCK_50),
    	.ld_x(ld_x),
    	.ld_y(ld_y),
    	.ld_c(ld_c),
    	.plot(plot),
    	.enable(writeEn)
    );
    
endmodule


module datapath(
	input [8:0] data_in,
	input [2:0] colour_in,
	input resetn,
	input enable,
	input clk,
	input ld_c,
	input ld_x, 
	input ld_y,
	output [8:0] x_out,
	output [7:0] y_out,
	output [2:0] colour_out);

	// Initialize values of x and y
	reg [8:0] input_x;
	reg [7:0] input_y;
	reg [2:0] input_c;
	always @(posedge clk) 
	begin
		if (!resetn) begin
			input_x <= 9'd0;
			input_y <= 8'd0;
			input_c <= 3'd0;
		end
		else begin
			if (ld_x)
				input_x <= 0;
			if (ld_y)
				input_y <= data_in[7:0];
			if (ld_c)
				input_c <= colour_in;
		end
	end

	// Keep track of x and y count
	reg [5:0] yCount;         // Count 0 -> 47
	reg [3:0] xCount;         // Count 0 -> 9

	always @(posedge clk) 
	begin
		if (!resetn) begin
			yCount <= 6'd0;
			xCount <= 4'd0;
		end
		else if (enable) begin
			// x reach end reset
			if (xCount == 4'b1001 && yCount != 6'b101111) begin
				// Reset x count to 0
				xCount <= 4'd0;
				// Add one to yCount
				yCount <= yCount + 1;
			end
			// xy reach end reset
			else if (xCount == 4'b1001 && yCount == 6'b101111) begin
				xCount <= 4'd0;
				yCount <= 6'd0;
			end
			//+ 1 to x
			else begin
				xCount <= xCount + 1;
			end	
		end
	end
	
	assign x_out = input_x + xCount;
	assign y_out = input_y + yCount;
	assign colour_out = input_c;

endmodule


module control(
	input clk,
	input resetn,
	input go,
	output reg ld_x, ld_y, ld_c, plot, enable
	);

	reg [3:0] current_state, next_state; 

	localparam LOAD_X      = 3'd0,
	           LOAD_Y      = 3'd1,
	           LOAD_C      = 3'd2,
	           PLOT        = 3'd3,
	           LOAD_ERASE  = 3'd4,
	           ERASE       = 3'd5;

	// State table for loading x and y into register
	always @(*)
  	begin: state_table
	    case (current_state)
	    	LOAD_X: next_state =  go ? LOAD_Y: LOAD_X;
	        LOAD_Y: next_state = go ? LOAD_C: LOAD_Y;
	        LOAD_C: next_state = go ? PLOT: LOAD_C;
	        PLOT: next_state = go ? LOAD_ERASE: PLOT;
	        LOAD_ERASE: next_state = go ? ERASE: LOAD_ERASE;
	        ERASE: next_state = go ? LOAD_X: ERASE;
	      	default: next_state = LOAD_X;
	    endcase
	end

	// Output logic
	always @(*) 
	begin
		ld_x = 1'b0;
		ld_y = 1'b0;
		plot = 1'b0;
		ld_c = 1'b0;
		enable = 1'b0;

		case (current_state)
			LOAD_X: begin
				plot = 1'b0;
                ld_x = 1'b1;
				ld_y = 1'b0;
				ld_c = 1'b0;
            end
            LOAD_Y: begin
				ld_x = 1'b0;
				ld_y = 1'b1;
				ld_c = 1'b0;
            end
            LOAD_C: begin
				ld_x = 1'b0;
				ld_y = 1'b0;
                ld_c = 1'b1;
            end
			PLOT: begin 
				ld_x = 1'b0;
				ld_y = 1'b0;
                ld_c = 1'b0;
				enable = 1'b1;
				plot = 1'b1;
			end
			LOAD_ERASE: begin 
				ld_x = 1'b0;
				ld_y = 1'b0;
                ld_c = 1'b1;
			end
			ERASE: begin 
				ld_x = 1'b0;
				ld_y = 1'b0;
                ld_c = 1'b0;
				enable = 1'b1;
				plot = 1'b1;
			end
		endcase
	end

	// current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= LOAD_X;
        else
            current_state <= next_state;
    end

endmodule

