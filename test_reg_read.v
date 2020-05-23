`timescale 1ns / 1ps

module test_reg_read;

	// Inputs
	reg reset;
	reg clk;
	reg [6:0] addr_in;
	reg R_Wbar;
	reg send_start;
	reg [7:0] data_in;
	reg write_enable;
	reg read_enable;
	reg send_ack;
	reg send_nack;
	reg send_stop;

	// Outputs
	wire [7:0] data_out;
	wire byte_io_complete;
	wire slave_ack_received;
	wire slave_nack_received;
	wire communication_ongoing;
	wire controller_idle;
	wire [2:0] i2c_state;
	
	wire [31:0] i2c_clock_counter;

	// Bidirs
	wire i2c_sda;
	wire i2c_scl;
	
	defparam uut.i2c_high_time = 4;
	defparam uut.i2c_low_time = 4;

	// Instantiate the Unit Under Test (UUT)
	i2c_controller uut (
		.reset(reset), 
		.clk(clk), 
		.addr_in(addr_in), 
		.R_Wbar(R_Wbar), 
		.send_start(send_start), 
		.data_in(data_in), 
		.write_enable(write_enable), 
		.data_out(data_out), 
		.read_enable(read_enable), 
		.send_ack(send_ack), 
		.send_nack(send_nack), 
		.send_stop(send_stop), 
		.i2c_sda(i2c_sda), 
		.i2c_scl(i2c_scl), 
		.byte_io_complete(byte_io_complete), 
		.slave_ack_received(slave_ack_received), 
		.slave_nack_received(slave_nack_received), 
		.communication_ongoing(communication_ongoing), 
		.controller_idle(controller_idle),
		.i2c_clock_counter(i2c_clock_counter),
		.i2c_state(i2c_state)
	);
	
	integer r_bytes;

	initial begin
		// Initialize Inputs
		reset = 0;
		clk = 0;
		addr_in = 0;
		R_Wbar = 0;
		send_start = 0;
		data_in = 0;
		write_enable = 0;
		read_enable = 0;
		send_ack = 0;
		send_nack = 0;
		send_stop = 0;
		
		#1;
		
		reset = 1;
		
		#10;
		
		reset = 0;
		
		#20;

		addr_in = 8'h68;
		R_Wbar = 0;
		
		send_start = 1;
		#1;
		while(controller_idle == 1) begin
			#1;
		end
		
		send_start = 0;
		#1;
		while(controller_idle == 0) begin
			#1;
		end
		
		data_in = 8'h27;
		write_enable = 1;
		#1;
		while(controller_idle == 1) begin
			#1;
		end
		
		write_enable = 0;
		#1;
		while(controller_idle == 0) begin
			#1;
		end
		
		addr_in = 8'h68;
		R_Wbar = 1;
		send_start = 1;
		#1;
		while(controller_idle == 1) begin
			#1;
		end
		
		send_start = 0;
		#1;
		while(controller_idle == 0) begin
			#1;
		end
		
		for(r_bytes = 0; r_bytes < 2; r_bytes = r_bytes + 1)begin
			if(r_bytes == 1)
				send_nack = 1;
			else
				send_ack = 1;
			#1;
			while(controller_idle == 1) begin
				#1;
			end
			
			send_ack = 0;
			send_nack = 0;
			#1;
			while(controller_idle == 0) begin
				#1;
			end
		end
		
		send_stop = 1;
		#1;
		while(controller_idle == 1) begin
			#1;
		end
		
		send_stop = 0;
		#1;
		while(controller_idle == 0) begin
			#1;
		end
		
		#120;

	end
	
	always begin
		clk = ~clk;
		#1;
	end
      
endmodule

