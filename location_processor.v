
module locationProcessorPaddle (
		input clock,
		input reset_n,
		input [2:0] in_color,
		input [8:0] box_init_x,

		/* Keyboard inputs */
		input up,
		input down,

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
				// X update
				next_box_x = current_box_x;

				// Y update
				if (down == INCREASE) begin
					if (current_box_y + BOX_HEIGHT == SCREEN_HEIGHT) begin
						next_box_y = current_box_y;
					end
					else begin
						next_box_y = current_box_y + 9'd4;
					end
				end
				else if (up == INCREASE) begin
					if (current_box_y == 9'd0) begin
						next_box_y = current_box_y;
					end
					else begin
						next_box_y = current_box_y - 9'd4;
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
			current_box_x <= box_init_x;
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


module locationProcessorBall (
		input clock,
		input reset_n,
		input [2:0] in_color,

		/*Interface tp the screen drawer*/
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
	parameter BALL_WIDTH = 9'd4;
	parameter BALL_HEIGHT = 9'd4;
	parameter SCREEN_WIDTH = 9'd320;
	parameter SCREEN_HEIGHT = 9'd240;
	parameter LEFT_COLLISION = 9'd10;
	parameter RIGHT_COLLISION = 9'd310;
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

	// Direction of movement for the box
	reg current_box_vx; // Should be synthesized into an FF.
	reg current_box_vy; // Should be synthesized into an FF.
	reg next_box_vx; // Should be synthesized into an FF.
	reg next_box_vy; // Should be synthesized into an FF.

	reg [31:0] current_frame_rate_counter; //FF
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
		next_box_vx = current_box_vx;
		next_box_vy = current_box_vy;
		m_valid = 1'b0;
		next_frame_rate_counter = (current_frame_rate_counter==FRAME_RATE_COUNT) ? current_frame_rate_counter : current_frame_rate_counter + 32'd1;
		case (current_state)
			S_UPDATE_POSITION: begin
				// X update
				if (current_box_vx == INCREASE) begin
					if (current_box_x + BALL_WIDTH == RIGHT_COLLISION) begin
						next_box_x = current_box_x - 9'd1;
						next_box_vx = DECREASE;
					end
					else begin
						next_box_x = current_box_x + 9'd1;
					end
				end
				else begin
					if (current_box_x == 9'd0) begin
						next_box_x = current_box_x + 9'd1;
						next_box_vx = INCREASE;
					end
					else begin
						next_box_x = current_box_x - 9'd1;
					end
				end

				// Y update
				if (current_box_vy == INCREASE) begin
					if (current_box_y + BALL_WIDTH == LEFT_COLLISION) begin
						next_box_y = current_box_y - 9'd1;
						next_box_vy = DECREASE;
					end
					else begin
						next_box_y = current_box_y + 9'd1;
					end
				end
				else begin
					if (current_box_y == 9'd0) begin
						next_box_y = current_box_y + 9'd1;
						next_box_vy = INCREASE;
					end
					else begin
						next_box_y = current_box_y - 9'd1;
					end
				end
			end
			S_WAIT_TRANSACTION: begin
				m_valid = 1'b1;
				next_frame_rate_counter = 32'd0;
			end
			default: begin
				// Nothing fits here
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
			current_box_x <= 9'd160;  // Starts in the middle of the screen
			current_box_y <= 9'd120;
			current_box_vy <= INCREASE;
			current_box_vx <= INCREASE;
		end
		else begin
			current_frame_rate_counter <= next_frame_rate_counter;
			current_state <= next_state;
			current_box_x <= next_box_x;
			current_box_y <= next_box_y;
			current_box_vy <= next_box_vy;
			current_box_vx <= next_box_vx;
		end
	end
endmodule // location processor
