
module rateDivider(out, enable, freqControl, clock, parload, rReset, dReset);
	
	input enable, clock, parload, enable, rReset, dReset;
	input [1:0] freqControl;

	output [3:0] out;

	wire [27:0] backCounterOut;
	wire counterPulse;

	reg [27:0] loadValue;

	always @(*) 
	begin
		case (freqControl)
			// Counts 60Hz Normally
			2'b00: loadValue = 0;
			// Paddle frequency
			// Counts 15, 0 -> 14
			2'b01: loadValue = 4'b1110;
			// Add different frequencies for the ball later
			2'b10: loadValue = 28'b0101111101011110000011111110;
			2'b11: loadValue = 28'b1011111010111100000111111100;
			default: loadValue = 0;
		endcase
	end

	backCounter count(
		.clock(clock),
		.reset_n(rReset),
		.d(loadValue),
		.parload(parload),
		.enable(enable),
		.q(backCounterOut)
		);

	assign counterPulse = (backCounterOut == 28'b0000000000000000000000000000) ? 1 : 0;

	displayControl display(
		.clock(clock),
		.reset_n(dReset),
		.enable(counterPulse),
		.q(out)
		);

endmodule


module displayControl(clock, reset_n, enable, q);

	input enable, clock, reset_n;
  	output [3:0] q;
  	reg [3:0] q;

    always @(posedge clock or negedge reset_n)
    begin
    	if (reset_n == 1'b0)
      		q <= 4'b0000;
    	else if (enable == 1'b1)
      		q <= q + 1;
    end

endmodule


module backCounter(clock, reset_n, d, parload, enable, q);

	input [27:0] d;                  // Declare d
	input clock;                     // Declare clock
	input reset_n;                   // Declare reset_n
	input parload, enable;           // Declare parload and enable

	output [27:0] q;
	reg [27:0] q;                    // Declare q

	always @(posedge clock)          // Triggered every time clock rises
	begin
		if (reset_n == 1'b0)         // When reset_n is 0 
			q <= 0;                  // Set q to 0
		else if (parload == 1'b1)    // Check if parallel load
			q <= d;                  // Load d
		else if (enable == 1'b1)     // Decrement q only when enable is 1
			begin 
				if (q == 0)          // When q is 0
					q <= d;          // Reset q into to be the maximum value
				else                 // When q is not 0
					q <= q - 1'b1;   // Decrement q
			end
	end

endmodule
