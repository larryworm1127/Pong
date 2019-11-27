module tb_locationProcessor ();
	reg clock;
	reg reset_n;
    reg up;
    reg down;
	wire valid;

	wire [8:0] box_x;
	wire [8:0] box_y;
    wire [2:0] out_color;

    //Instantiate the dut
    locationProcessor # (
    	.BOX_WIDTH              (9'd4),
    	.BOX_HEIGHT              (9'd4),
    	.SCREEN_WIDTH              (9'd7),
    	.SCREEN_HEIGHT (9'd7),
    	.FRAME_RATE_COUNT       (32'd10)
    	)
    	dut (
    		.clock (clock),
    		.reset_n (reset_n),
    		.in_color (3'd2),
            .up(up),
            .down(down),
    		.m_ready(1'b1),
    		.m_valid  (valid),
    		.box_x (box_x),
    		.box_y    (box_y),
    		.out_color(out_color)
    		);

    always #5 clock = !clock;

    initial #0 begin
    	clock = 0;
    	reset_n = 1'b0;
    	#7 reset_n = !reset_n;

        up = 1'b1;
        #50 up = !up;

        down = 1'b1;
        #50 down = !down;
    	#500 $stop;
    end
endmodule