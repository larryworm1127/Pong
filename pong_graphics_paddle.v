
module locationProcessor (
		input clock,
		input reset_n,
		input [2:0] in_color,

		/* Keyboard inputs */
		input up;
		input down;
 
		/* Interface tp the screen drawer */
		input m_ready,
		output reg m_valid,
		output [8:0] box_x,
		output [8:0] box_y,
		output [2:0] out_color
	);

	/*
		Parameters that should be configured properly at the instantiation of the module.
		The values here are just defaults.
		In simulation testbenches, these values can be replaced with smallar values
	*/
	parameter BOX_WIDTH = 9'd10;
	parameter BOX_HEIGHT = 9'd48;
	parameter SCREEN_WIDTH = 9'd320;
	parameter SCREEN_HEIGHT = 9'd240;
	parameter FRAME_RATE_COUNT = 32'd3333332;

	/*
		State encodings
	*/
	parameter S_UPDATE_POSITION = 2'd0,
			  S_WAIT_TRANSACTION = 2'd1,
			  S_WAIT_FRAME_RATE_COUNT = 2'd2;

	/*
		Internal signals
	*/
	reg [1:0] current_state; // Should be synthesized into an FF.
	reg [1:0] next_state;


	// Position of the box
	reg [8:0] current_box_x; // Should be synthesized into an FF
	reg [8:0] current_box_y; // Should be synthesized into an FF
	reg [8:0] next_box_x;
	reg [8:0] next_box_y;

	parameter INCREASE = 1'b1, DECREASE = 1'b0;

	reg [31:0] current_frame_rate_counter; // FF
	reg [31:0] next_frame_rate_counter;

	assign box_x = current_box_x;
	assign box_y = current_box_y;

	assign out_color = in_color;

	/*
		Next state logic.
	*/
	always @ (*) begin
		next_state = current_state;
		case (current_state)
			S_UPDATE_POSITION: begin
				if (current_frame_rate_counter == FRAME_RATE_COUNT) begin
						next_state = S_WAIT_TRANSACTION;
				end
				else begin
					next_state = S_WAIT_FRAME_RATE_COUNT;
				end
			end
			S_WAIT_TRANSACTION: begin
				if (m_ready == 1'b1) begin
					next_state = S_UPDATE_POSITION;
				end
			end
			S_WAIT_FRAME_RATE_COUNT: begin
				if (current_frame_rate_counter == FRAME_RATE_COUNT) begin
					next_state = S_WAIT_TRANSACTION;
				end
			end
			default:
				next_state = current_state;
		endcase
	end

	/*
		Other COMB logics
		- Box position update. 
		- Interface signal
		- next frame rate counter
	*/
	always @ (*) begin
		next_box_x = current_box_x;
		next_box_y = current_box_y;
		m_valid = 1'b0;
		next_frame_rate_counter = (current_frame_rate_counter==FRAME_RATE_COUNT) ? current_frame_rate_counter : current_frame_rate_counter + 32'd1;
		case (current_state)
			S_UPDATE_POSITION: begin
				// X position doesn't change
				next_box_x = current_box_x;

				// Y update
				if (up == INCREASE) begin
					if (current_box_y + BOX_WIDTH == SCREEN_HEIGHT) begin
						next_box_y = current_box_y - 9'd1;
					end
					else begin
						next_box_y = current_box_y + 9'd1;
					end
				end
				else if (down == INCREASE) begin
					if (current_box_y == 9'd0) begin
						next_box_y = current_box_y + 9'd1;
					end
					else begin
						next_box_y = current_box_y - 9'd1;
					end
				end
				else begin
					next_box_y = current_box_y;
				end
			end
			S_WAIT_TRANSACTION: begin
				m_valid = 1'b1;
				next_frame_rate_counter = 32'd0;
			end
			default: begin
				//Nothing fits here
			end
		endcase
	end

	/*
		Sequential logic
	*/
	always @ (posedge clock) begin
		if (reset_n == 1'b0) begin
			current_frame_rate_counter <= 32'd0;
			current_state <= S_WAIT_TRANSACTION;
			current_box_x <= 9'd0;
			current_box_y <= 9'd0;
		end
		else begin
			current_frame_rate_counter <= next_frame_rate_counter;
			current_state <= next_state;
			current_box_x <= next_box_x;
			current_box_y <= next_box_y;
		end
	end
endmodule // location processor


module screenDrawer (
		input clock,
		input reset_n,

		/* Interface tp the location processor */
		output reg s_ready,
		input s_valid,
		input [8:0] in_box_x,
		input [8:0] in_box_y,
		input [2:0] in_box_color,

		/* Interface to the box drawer */
		input m_ready,
		output reg m_valid,
		output reg [8:0] out_box_x,
		output reg [8:0] out_box_y,
		output reg [8:0] out_box_h,
		output reg [8:0] out_box_w,
		output reg [2:0] out_box_color
	);

	/*
		Parameters that should be configured properly at the instantiation of the module.
		The values here are just defaults.
		In simulation testbenches, these values can be replaced with smallar values
	*/
	parameter BOX_WIDTH = 9'd48;
	parameter BOX_HEIGHT = 9'd10;
	parameter SCREEN_WIDTH = 9'd320;
	parameter SCREEN_HEIGHT = 9'd240;
	parameter REFRESH_RATE_COUNT = 32'd833332;

	/*
		State encodings
	*/
	parameter S_WAIT_FOR_INPUT = 2'd0,
			  S_WAIT_TO_DRAW_BACKGROUND = 2'd1,
			  S_WAIT_TO_DRAW_BOX = 2'd2,
			  S_WAIT_FOR_REFRESH_COUNT = 2'd3;

	/*
		Internal signals
	*/
	reg [1:0] current_state; // Should be synthesized into an FF.
	reg [1:0] next_state;


	// Position of the box
	reg [8:0] box_x; // Should be synthesized into an FF
	reg [8:0] box_y; // Should be synthesized into an FF
	reg [2:0] box_color; // Should be synthesized into an FF

	reg [31:0] refresh_count;

	/*
		Next state logic update
		Interface signals control
	*/
	always @ (*) begin
		next_state = current_state;
		s_ready = 1'b0;
		m_valid = 1'b0;
		out_box_x = 9'd0;
		out_box_y = 9'd0;
		out_box_w = 9'd1;
		out_box_h = 9'd1;
		out_box_color = 3'd0;

		case (current_state)
			S_WAIT_FOR_INPUT: begin
				s_ready = 1'b1;
				if (s_valid == 1'b1) begin
					next_state = S_WAIT_TO_DRAW_BACKGROUND;
				end
			end
			S_WAIT_TO_DRAW_BACKGROUND: begin
				m_valid = 1'b1;
				out_box_x = 9'd0;
				out_box_y = 9'd0;
				out_box_w = SCREEN_WIDTH;
				out_box_h = SCREEN_HEIGHT;
				out_box_color = 3'd0;
				if (m_ready == 1'b1) begin
					next_state = S_WAIT_TO_DRAW_BOX;
				end
			end
			S_WAIT_TO_DRAW_BOX: begin
				m_valid = 1'b1;
				out_box_x = box_x;
				out_box_y = box_y;
				out_box_w = BOX_WIDTH;
				out_box_h = BOX_HEIGHT;
				out_box_color = box_color;
				if (m_ready == 1'b1) begin
					next_state = S_WAIT_FOR_REFRESH_COUNT;
				end
			end
			S_WAIT_FOR_REFRESH_COUNT: begin
				if (refresh_count == REFRESH_RATE_COUNT) begin
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
			refresh_count <= 32'd0;
			box_x <= 9'd0;
			box_y <= 9'd0;
			box_color <= 3'd0;
			current_state <= S_WAIT_FOR_INPUT;
		end
		else begin
			current_state <= next_state;
			
			if (current_state == S_WAIT_FOR_INPUT && s_valid == 1'b1) begin
				box_x <= in_box_x;
				box_y <= in_box_y;
				box_color <= in_box_color;
			end

			if (current_state == S_WAIT_TO_DRAW_BACKGROUND) begin
				refresh_count <= 32'd0;
			end
			else begin
				refresh_count <= (refresh_count == REFRESH_RATE_COUNT) ? refresh_count : refresh_count + 32'd1;
			end
			
		end
	end
endmodule // screen drawer


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
		output [7:0] vga_x,
		output [6:0] vga_y,
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