;// Data path to draw paddles
module datapath(
	input [8:0] x_in,
	input [7:0] y_in,
	input resetn,
	input enable,
	input clk,
	input down, up, left, right,
	output [8:0] x_out,
	output [7:0] y_out,
	output do_erase
	);

	// Count frames
	rateDividerFPS r0(
		.clock   (clk),
		.enable  (enable),
		.resetn  (resetn),
		.do_erase(do_erase)
	);

	// Initialize values of x and y
	reg [8:0] input_x;
	reg [7:0] input_y;

	always @(posedge clk) 
	begin : y_counter
		if (!resetn)
			input_y <= y_in;
		else if (enable) begin
			if (down == 1'b1)
				input_y <= input_y + 1'b1;
			else if (up == 1'b1)
				input_y <= input_y - 1'b1;
			else
				input_y <= input_y;
		end
	end

	always @(posedge clk) 
	begin : x_counter
		if (!resetn)
			input_x <= x_in;
		else if (enable) begin
			if (right == 1'b1)
				input_x <= input_x + 1'b1;
			else if (left == 1'b1)
				input_x <= input_x - 1'b1;
			else
				input_x <= input_x;
		end
	end

	// Keep track of position x and y which are being drawn
	reg [5:0] yCount;         // Count 0 -> 47
	reg [3:0] xCount;         // Count 0 -> 9

	always @(posedge clk) 
	begin : paddle_drawer
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

	// Assign
	assign x_out =  input_x + xCount;
	assign y_out = input_y + yCount;

endmodule


// Control FSM
module control(
	input clk,		    // 50Mhz Clock
	input resetn,	    // reset
	input go,		    // Manual trigger, DRAW -> ERASE
	output reg plot,    // Plot for VGA
	output reg enable,  // Enable for vga
	output reg load_en,  // Load enable for xy & colour
	output reg [2:0] colourOut
	);

	reg [1:0] current_state, next_state; 

	localparam LOAD  = 2'd0,
	           DRAW  = 2'd1,
	           ERASE = 2'd2;

	// State table
	always @(*)
  	begin: state_table
	    case (current_state)
	    	LOAD: next_state = DRAW;
	    	DRAW: next_state = go ? ERASE: DRAW; // Manual trigger to erase
	    	ERASE: next_state = LOAD;
	      	default: next_state = LOAD;
	    endcase
	end

	// Output logic
	always @(*) 
	begin: enable_signals
		// Set all to 0
		plot = 1'b0;
		enable = 1'b0;
		load_en = 1'b0;
		colourOut = 3'b000;

		case (current_state)
			LOAD: begin
				plot = 1'b0;
				enable = 1'b0;
				load_en = 1'b1;
				colourOut = 3'b000;
            end
            DRAW: begin
            	plot = 1'b1;
				enable = 1'b1;
				load_en = 1'b0;
				colourOut = 3'b111;
            end
			ERASE: begin 
				plot = 1'b1;
				enable = 1'b1;
				load_en = 1'b0;
				colourOut = 3'b000;
			end
		endcase
	end

	// current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= LOAD;
        else
            current_state <= next_state;
    end
endmodule