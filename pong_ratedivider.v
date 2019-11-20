// Converts 50Mhz to 60Hz
module rateDividerFPS(
	input clock,     // clock
	intput enable,   // enable the rate div
	intput resetn,   // reset
	output do_erase,
	);

	// 50 million div 60
	// Binary 1100_1011_0111_0011_0101 20 bits
	reg [19:0] countdown; 
	
	always @(posedge clock)
	begin : delay_counter
		// Start at 833 333
		if (!resetn)
			countdown <= 20'd833_333;

		// Subtract 1
		else if (enable) begin
			countdown <= countdown - 1'b1;

			// If reach end, reset
			if (countdown == 20'd0) begin
				countdown <= 20'd833_333;
			end
		end
	end 

	// If countdown reaches 0, enable frame counter 1
	assign frame_enable = (countdown == 0) ? 1 : 0;

	// Counter to count up to 15 frames
	reg [3:0] num_frames; 
	
	always @(posedge clock)
	begin : frame_counter
		if (!resetn)
			num_frames <= 0;
		else if (frame_enable == 1'b1) begin
			if (num_frames == 4'd14)
				num_frames <= 4'd0;
			else
				num_frames <= num_frames + 1'b1;
		end else
			num_frames <= num_frames;
	end

	// If num_frames reaches 14, signal erase
	assign do_erase = (num_frames == 4'd14) ? 1 : 0;

endmodule
