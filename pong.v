`include "PS2MouseKeyboard/PS2_Keyboard_Controller.v"
`include "vga_adaptor/vga_adaptor.v"

module pong
	(
		CLOCK_50,						//	On Board 50 MHz
	);

endmodule


module keyboard();

	keyboard_tracker #(.PULSE_OR_HOLD(1)) k1();

endmodule
