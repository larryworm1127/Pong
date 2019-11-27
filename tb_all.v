`timescale 1ns/1ps

module tb_all();
	reg clock;
	reg reset_n;

	wire [8:0] box_x;
	wire [8:0] box_y;
    wire [2:0] box_color;

    wire processor_data_valid;
    wire screen_drawer_ready;

    wire screen_drawer_data_valid;
    wire box_drawer_ready;

    wire [8:0] draw_box_x;
    wire [8:0] draw_box_y;
    wire [8:0] draw_box_h;
    wire [8:0] draw_box_w;
    wire [2:0] draw_box_color;

    wire [7:0] vga_x;
    wire [6:0] vga_y;
    wire [2:0] vga_color;
    wire vga_plot;

	locationProcessor # (
    	.BOX_WIDTH              (9'd2),
    	.BOX_HEIGHT              (9'd2),
    	.SCREEN_WIDTH              (9'd6),
    	.SCREEN_HEIGHT 			(9'd6),
    	.FRAME_RATE_COUNT       (32'd99)
    	)
    	processor (
    		.clock (clock),
    		.reset_n (reset_n),
    		.in_color (3'd2),
    		.m_ready(screen_drawer_ready),
    		.m_valid  (processor_data_valid),
    		.box_x (box_x),
    		.box_y    (box_y),
    		.out_color(box_color)
    		);

    screenDrawer # (
    	.BOX_WIDTH              (9'd2),
    	.BOX_HEIGHT              (9'd2),
    	.SCREEN_WIDTH              (9'd6),
    	.SCREEN_HEIGHT 			  (9'd6),
    	.REFRESH_RATE_COUNT       (32'd40)
    	)
    	screen_drawer_0 (
    		.clock (clock),
    		.reset_n (reset_n),
    		.s_ready (screen_drawer_ready),
    		 .s_valid      (processor_data_valid),
    		 .in_box_x     (box_x),
    		 .in_box_y     (box_y),
    		 .in_box_color (box_color),

    		 .m_ready (box_drawer_ready),
    		 .m_valid (screen_drawer_data_valid),
    		 .out_box_x    (draw_box_x),
    		 .out_box_y    (draw_box_y),
    		 .out_box_w    (draw_box_w),
    		 .out_box_h    (draw_box_h),
    		 .out_box_color (draw_box_color)
    		);

    boxDrawer box_drawer_0 (
    		.clock       (clock),
    		.reset_n    (reset_n),

    		.s_ready     (box_drawer_ready),
    		.s_valid     (screen_drawer_data_valid),
    		.in_box_x    (draw_box_x),
    		.in_box_y    (draw_box_y),
    		.in_box_w    (draw_box_w),
    		.in_box_h    (draw_box_h),
    		.in_box_color(draw_box_color),
    		.vga_x       (vga_x),
    		.vga_y       (vga_y),
    		.plot 	     (vga_plot),
    		.colour      (vga_color)
    	);

    always #5 clock = !clock;

    initial #0 begin
    	clock = 0;
    	reset_n = 1'b0;
    	#7 reset_n = !reset_n;
    	#8000 $stop;
    end


endmodule