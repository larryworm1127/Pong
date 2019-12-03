
module boxDrawer (
		input clock,
		input reset_n,

		/* Interface tp the screen drawer processor */
		output reg s_ready,
		input s_valid,
		input [8:0] in_box_x,
		input [8:0] in_box_y,
		input [8:0] in_box_w,
		input [8:0] in_box_h,
		input [2:0] in_box_color,

		/* Interface to VGA adapter. Assuming 160x120 resolution, 8 colour */
		output [8:0] vga_x,
		output [7:0] vga_y,
		output reg plot,
		output [2:0] colour
	);


	/*
		State encodings
	*/
	parameter S_WAIT_FOR_INPUT = 2'd0,
			  S_DRAW_BOX = 2'd1;
	/*
		Internal signals
	*/
	reg [1:0] current_state; // Should be synthesized into an FF.
	reg [1:0] next_state;


	// Position of the box
	reg [8:0] box_x; // Should be synthesized into an FF
	reg [8:0] box_y; // Should be synthesized into an FF
	reg [8:0] box_w; // Should be synthesized into an FF
	reg [8:0] box_h; // Should be synthesized into an FF
	reg [2:0] box_color; // Should be synthesized into an FF
	reg [8:0] iter_box_w; // Should be synthesized into an FF
	reg [8:0] iter_box_h; // Should be synthesized into an FF

	assign colour = box_color;
	assign vga_x = box_x + iter_box_w; // Width won't match, so rely on the compiler to truncate
	assign vga_y = box_y + iter_box_h; // Width won't match, so rely on the compiler to truncate


	/*
		Next state logic update
		Interface signals control
	*/
	always @ (*) begin
		s_ready = 1'b0;
		plot = 1'b0;
		next_state = current_state;
		case (current_state)
			S_WAIT_FOR_INPUT: begin
				s_ready = 1'b1;
				if (s_valid == 1'b1) begin
					next_state = S_DRAW_BOX;
				end
			end
			S_DRAW_BOX: begin
				plot = 1'b1;
				if ((iter_box_w + 9'd1 == box_w) && (iter_box_h + 9'd1 == box_h)) begin
					next_state = S_WAIT_FOR_INPUT;
				end
			end
			default: begin
			end
		endcase
	end

	/*
		Sequential logic
	*/
	always @ (posedge clock) begin
		if (reset_n == 1'b0) begin
			box_x <= 9'd0;
			box_y <= 9'd0;
			box_w <= 9'd0;
			box_h <= 9'd0;
			box_color <= 3'd0;
			iter_box_w <= 9'd0;
			iter_box_h <= 9'd0;
			current_state <= S_WAIT_FOR_INPUT;
		end
		else begin
			current_state <= next_state;

			if ((current_state == S_WAIT_FOR_INPUT) && (s_valid == 1'b1)) begin
				box_x <= in_box_x;
				box_y <= in_box_y;
				box_w <= in_box_w;
				box_h <= in_box_h;
				box_color <= in_box_color;
			end

			if ((current_state == S_WAIT_FOR_INPUT) && (s_valid == 1'b1)) begin
				iter_box_h <= 9'd0;
				iter_box_w <= 9'd0;
			end
			else if (current_state == S_DRAW_BOX) begin
				if (iter_box_w + 9'd1 == box_w) begin
					iter_box_w <= 9'd0;
					iter_box_h <= iter_box_h + 9'd1;
				end
				else begin
					iter_box_w <= iter_box_w + 9'd1;
				end
			end
			
		end
	end
endmodule // box drawer
