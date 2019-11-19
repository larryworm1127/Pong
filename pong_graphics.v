module datapath(
	input [7:0] data_in,
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
				input_x <= {1'b0, data_in};
			if (ld_y)
				input_y <= data_in;
			if (ld_c)
				input_c <= colour_in;
		end
	end

	// Keep track of x and y count
	reg [5:0] yCount;         // Count 0 -> 47
	reg [3:0] xCount;         // Count 0 -> 9
	
	always @(posedge clock) 
	begin
		if (!resetn) begin
			yCount <= 6'd0;
			xCount <= 4'd0;
		end
		else if (enable) begin
			// x reach end reset
			if (xCount == 4'b1001 && yCount != 6'b101111) begin
				// Reset x count to 0
				xCount <= 2'd0;
				// Add one to yCount
				yCount <= yCount + 1;
			end
			// xy reach end reset
			else if (xCount == 4'b1001 && yCount == 6'b101111) begin
				xCount <= 2'd0;
				yCount <= 2'd0;
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
			   LOAD_X_WAIT = 3'd1,
	           LOAD_Y      = 3'd2,
	           LOAD_Y_WAIT = 3'd3,
	           LOAD_C      = 3'd4,
	           LOAD_C_WAIT = 3'd5,
	           PLOT        = 3'd6;

	// State table for loading x and y into register
	always @(*)
  	begin: state_table
	    case (current_state)
	    	LOAD_X: next_state = go ? LOAD_X_WAIT: LOAD_X;
	        LOAD_X_WAIT: next_state = go ? LOAD_X_WAIT: LOAD_Y;
	        LOAD_Y: next_state = go ? LOAD_Y_WAIT: LOAD_Y;
	        LOAD_Y_WAIT: next_state = go ? LOAD_Y_WAIT: LOAD_C;
	        LOAD_C: next_state = go ? LOAD_C_WAIT: LOAD_C;
	        LOAD_C_WAIT: next_state = go ? LOAD_C_WAIT: PLOT;
	        PLOT: next_state = go ? LOAD_X: PLOT;
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
			DRAW: begin 
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