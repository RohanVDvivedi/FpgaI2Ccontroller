
// The follong i2c_master controller is built such that, it will not expect anyother i2c master on the i2c bus

module i2c_controller(
		input reset,					// reset signal for the module
		input clk,						// clk of the device
		
		// set appropriate addr and R/Wbar value, and send_start to start communication
		input [6:0] addr_in,
		input R_Wbar,
		input send_start,
		
		// to write data to device
		input [7:0] data_in,
		input write_enable,
		
		// to read the received data
		output [7:0] data_out,
		input read_enable,
		
		// set the corresponding bits to specify whether to send ack or send nack
		input send_ack,
		input send_nack, // sending a nack will also send stop bit, when in receiver mode
		
		// connect the following i2c lines to the slave device
		inout i2c_sda,
		inout i2c_sck,
		
		// data_in, write_enable and the data_out, read_enable can be probed only when the byte_io_complete is set
		output reg byte_io_complete,
		
		// once the  byte_io_complete is set, 
		// in transmitter mode, if slave ack is received this bit will be also set
		// while in receiver mode you can set send_ack or send_nack 
		output reg slave_ack_received,
		
		output reg bus_busy
    );
	 
	reg [7:0] data_tx_buff;
	reg [7:0] data_rx_buff;

	reg sda_en;
	reg scl_en;
	
	assign i2c_sda = sda_en ? 0 : 1'bz;
	assign i2c_scl = scl_en ? 0 : 1'bz;
	
	parameter sys_clk = 50000000;
	parameter i2c_frequency = 400 * 1000;
	parameter i2c_clock_divider_clocks = (sys_clk / i2c_frequency);
	parameter i2c_clock_divider_max_count = i2c_clock_divider_clocks - 1;
	parameter i2c_high_time = (i2c_clock_divider_clocks * 9) / 25;
	parameter i2c_half_low_time = (i2c_clock_divider_clocks - i2c_high_time)/2;
	
	parameter i2c_clock_first_half_low_reached = i2c_half_low_time - 1;
	parameter i2c_clock_high_end_reached = i2c_clock_first_half_low_reached + i2c_high_time;
	parameter i2c_clock_completion_reached = i2c_clock_divider_max_count;
	
	reg i2c_state;
	
	parameter IDLE						= 3'b000;
	parameter START					= 3'b001;
	parameter SEND_BYTE				= 3'b010;
	parameter RECEIVE_BYTE			= 3'b011;
	parameter SEND_ACK				= 3'b100;
	parameter SEND_NACK				= 3'b101;
	parameter RECEIVE_ACK_NACK		= 3'b110;
	parameter SEND_STOP				= 3'b111;
	
	integer i2c_clock_counter;
	
	always@(posedge clk) begin
		if(reset) begin
			i2c_state <= IDLE;
			sda_en <= 1;
			scl_en <= 1;
			i2c_clock_counter = 0;
		end
		else begin
			case(i2c_state)
			
				IDLE : 
					begin
					end

				START	:
					begin
					end

				SEND_BYTE :
					begin
					end

				RECEIVE_BYTE :
					begin
					end
					
				SEND_ACK :
					begin
					end
					
				SEND_NACK :
					begin
					end
					
				RECEIVE_ACK_NACK :
					begin
					end
					
				SEND_STOP :
					begin
					end
					
			endcase
		end
	end
	

endmodule
