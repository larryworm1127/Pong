
module screenDrawer (
		input clock,
		input reset_n,

		/* Interface tp the location processor */
		output reg s_ready,
		input s_valid,
		input [8:0] in_paddle_left_x,
		input [8:0] in_paddle_left_y,
		input [8:0] in_paddle_right_x;
		input [8:0] in_paddle_right_y;
		input [8:0] in_ball_x;
		input [8:0] in_ball_y;
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
	parameter BOX_WIDTH = 9'd10;
	parameter BOX_HEIGHT = 9'd48;
	parameter BALL_WIDTH = 9'd4;
	parameter BALL_HEIGHT = 9'd4;
	parameter SCREEN_WIDTH = 9'd320;
	parameter SCREEN_HEIGHT = 9'd240;
	parameter REFRESH_RATE_COUNT = 32'd833332;

	/*
		State encodings
	*/
	parameter S_WAIT_FOR_INPUT = 2'd0,
			  S_WAIT_TO_DRAW_BACKGROUND = 2'd1,
			  S_WAIT_TO_DRAW_PADDLE_LEFT = 2'd2,
			  S_WAIT_TO_DRAW_PADDLE_RIGHT = 2'd3,
			  S_WAIT_TO_DRAW_BALL = 2'd4,
			  S_WAIT_FOR_REFRESH_COUNT = 2'd5;

	/*
		Internal signals
	*/
	reg [1:0] current_state; // Should be synthesized into an FF.
	reg [1:0] next_state;


	// Position of the box
	reg [8:0] paddle_left_x; // Should be synthesized into an FF
	reg [8:0] paddle_left_y; // Should be synthesized into an FF
	reg [8:0] paddle_right_x; // Should be synthesized into an FF
	reg [8:0] paddle_right_y; // Should be synthesized into an FF
	reg [8:0] ball_x; // Should be synthesized into an FF
	reg [8:0] ball_y; // Should be synthesized into an FF
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
					next_state = S_WAIT_TO_DRAW_PADDLE_LEFT;
				end
			end
			S_WAIT_TO_DRAW_PADDLE_LEFT: begin
				m_valid = 1'b1;
				out_box_x = paddle_left_x;
				out_box_y = paddle_left_y;
				out_box_w = BOX_WIDTH;
				out_box_h = BOX_HEIGHT;
				out_box_color = box_color;
				if (m_ready == 1'b1) begin
					next_state = S_WAIT_TO_DRAW_PADDLE_RIGHT;
				end
			end
			S_WAIT_TO_DRAW_PADDLE_RIGHT: begin
				m_valid = 1'b1;
				out_box_x = paddle_right_x;
				out_box_y = paddle_right_y;
				out_box_w = BOX_WIDTH;
				out_box_h = BOX_HEIGHT;
				out_box_color = box_color;
				if (m_ready == 1'b1) begin
					next_state = S_WAIT_TO_DRAW_BALL;
				end
			end
			S_WAIT_TO_DRAW_BALL: begin
				m_valid = 1'b1;
				out_box_x = ball_x;
				out_box_y = ball_y;
				out_box_w = BALL_WIDTH;
				out_box_h = BALL_HEIGHT;
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
			paddle_left_x <= 9'd0;
			paddle_left_y <= 9'd0;
			paddle_right_x <= 9'd310;
			paddle_right_y <= 9'd0;
			ball_x <= 9'd160;
			ball_y <= 9'd120;
			box_color <= 3'd0;
			current_state <= S_WAIT_FOR_INPUT;
		end
		else begin
			current_state <= next_state;
			
			if (current_state == S_WAIT_FOR_INPUT && s_valid == 1'b1) begin
				paddle_left_x <= in_paddle_left_x;
				paddle_left_y <= in_paddle_left_y;
				paddle_right_x <= in_paddle_right_x;
				paddle_right_y <= in_paddle_right_y;
				ball_x <= in_ball_x;
				ball_y <= in_ball_y;
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
