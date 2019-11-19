
module datapath(
	input [6:0] data_in,
	input resetn,
	input enable,
	input clk,
	input ld_x, 
	input ld_y,
	output [7:0] x_out,
	output [6:0] y_out);

	// Initialize values of x and y
	reg [7:0] input_x;
	reg [6:0] input_y;
	always @(posedge clk) 
	begin
		if (!resetn) begin
			input_x <= 8'd0;
			input_y <= 7'd0;
		end
		else begin
			if (ld_x)
				input_x <= {1'b0, data_in};
			if (ld_y)
				input_y <= data_in;
		end
	end

	// 4-bit counter that helps sequencially creates 4x4 square
	reg [3:0] count;
	always @(posedge clk) 
	begin
		if (!resetn) begin
			count <= 4'b0000;			
		end
		else if (enable) begin
			if (count == 4'b1111)
				count <= 4'b0000;
			else
				count <= count + 1;
		end
	end

	assign x_out = input_x + count[1:0];
	assign y_out = input_y + count[3:2];

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
	           PLOT        = 3'd4;

	// State table for loading x and y into register
	always @(*)
  	begin: state_table
	    case (current_state)
	    	LOAD_X: next_state = go ? LOAD_X_WAIT: LOAD_X;
	        LOAD_X_WAIT: next_state = go ? LOAD_X_WAIT: LOAD_Y;
	        LOAD_Y: next_state = go ? LOAD_Y_WAIT: LOAD_Y;
	        LOAD_Y_WAIT: next_state = go ? LOAD_Y_WAIT: PLOT;
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
		enable = 1'b0;

		case (current_state)
			LOAD_X: begin
				plot = 1'b0;
                ld_x = 1'b1;
				ld_y = 1'b0;
            end
            LOAD_Y: begin
				ld_x = 1'b0;
				ld_y = 1'b1;
            end
   			DRAW: begin 
				ld_x = 1'b0;
				ld_y = 1'b0;
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
