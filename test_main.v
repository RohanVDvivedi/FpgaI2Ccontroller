`timescale 1ns / 1ps

module test_main;

	// Inputs
	reg reset_bar;
	reg clk;
	reg start_bar;

	// Outputs
	wire indicate_ack_received_bar;
	wire indicate_nack_received_bar;
	wire [7:0] display;

	// Bidirs
	wire i2c_sda;
	wire i2c_scl;
	
	defparam uut.i2c_controller.i2c_low_time = 2;
	defparam uut.i2c_controller.i2c_high_time = 2;

	// Instantiate the Unit Under Test (UUT)
	main uut (
		.reset_bar(reset_bar), 
		.clk(clk), 
		.start_bar(start_bar), 
		.i2c_sda(i2c_sda), 
		.i2c_scl(i2c_scl), 
		.indicate_ack_received_bar(indicate_ack_received_bar), 
		.indicate_nack_received_bar(indicate_nack_received_bar), 
		.display(display)
	);

	initial begin
		// Initialize Inputs
		reset_bar = 1;
		clk = 0;
		start_bar = 1;
		#10;
		reset_bar = 0;
		#10;
		reset_bar = 1;
		#10;
		start_bar = 0;
		#10;
		start_bar = 1;
		
		while(1) begin
			#1;
		end

	end
	
	always begin
		clk = ~clk;
		#1;
	end
      
endmodule

