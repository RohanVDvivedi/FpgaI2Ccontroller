
// The follong i2c_master controller is built such that, it will not expect anyother i2c master on the i2c bus

module i2c_controller(
		input reset,					// reset signal for the module
		input clk,						// clk of the device
		
		// connect the following i2c lines to the slave device
		inout i2c_sda,
		inout i2c_scl,
		
		// set appropriate addr and R/Wbar value, and send_start to start communication
		input [6:0] addr_in,
		input R_Wbar,
		input send_start,
		
		// to write data to device
		input [7:0] data_in,
		input write_enable,
		
		// to read the received data
		output reg [7:0] data_out,
		input read_enable,
		
		// set the corresponding bits to specify whether to send ack or send nack
		input send_ack,
		input send_nack,
		input send_stop,
		
		// once the  byte_io_complete is set, 
		// in transmitter mode, if slave ack is received this bit will be also set
		// while in receiver mode you can set send_ack or send_nack 
		output reg slave_ack_received,
		output reg slave_nack_received,
		
		// if the module has an on going connection with an i2c slave device
		output reg communication_ongoing,
		
		output controller_idle
    );
	
	reg [6:0] slave_addr;
	reg slave_R_Wbar;
	
	reg [7:0] data_tx_buff;
	reg [7:0] data_rx_buff;
	
	reg [2:0] bit_addr;

	reg sda_en;
	reg scl_en;
	
	assign i2c_sda = sda_en ? 1'bz : 0;
	assign i2c_scl = scl_en ? 1'bz : 0;
	
	parameter sys_clk = 50000000;
	parameter i2c_frequency = 400 * 1000;
	parameter i2c_clock_divider_clocks = (sys_clk / i2c_frequency);
	parameter i2c_high_time = (i2c_clock_divider_clocks * 9) / 25;
	parameter i2c_half_high_time = i2c_high_time / 2;
	parameter i2c_low_time = (i2c_clock_divider_clocks - i2c_high_time);
	parameter i2c_half_low_time = i2c_low_time/2;
	
	parameter i2c_half_high_time_count = i2c_half_high_time - 1;
	parameter i2c_high_time_count = i2c_high_time - 1;
	parameter i2c_high_and_half_low_time_count =  i2c_high_time + i2c_half_low_time - 1;
	
	parameter i2c_low_time_count = i2c_low_time - 1;
	
	parameter i2c_half_low_time_count = i2c_half_low_time - 1;
	parameter i2c_half_low_and_half_high_time_count =  i2c_half_low_time + i2c_half_high_time - 1;
	parameter i2c_half_low_and_high_time_count =  i2c_half_low_time + i2c_high_time - 1;
	parameter i2c_half_low_and_high_and_half_low_time_count = i2c_low_time + i2c_high_time - 1;
	
	reg [2:0] i2c_state;
	localparam IDLE					= 3'b000;
	localparam START					= 3'b001;
	localparam SEND_BYTE				= 3'b010;
	localparam RECEIVE_BYTE			= 3'b011;
	localparam SEND_ACK				= 3'b100;
	localparam SEND_NACK				= 3'b101;
	localparam RECEIVE_ACK_NACK	= 3'b110;
	localparam SEND_STOP				= 3'b111;
	assign controller_idle = ((reset == 0) && (i2c_state == IDLE)) ? 1 : 0;
	
	integer i2c_clock_counter;
	
	always@(posedge clk) begin
		if(reset) begin
			i2c_state <= IDLE;
			sda_en <= 1;
			scl_en <= 1;
			i2c_clock_counter <= 0;
			communication_ongoing <= 0;
			slave_ack_received <= 0;
			slave_nack_received <= 0;
		end
		else begin
			case(i2c_state)
			
				IDLE : 
					begin
						if(send_start) begin
							// for a start condition to bigin, sda and scl must both be high
							sda_en <= 1;
							scl_en <= 1;
								
							// reset ack and nack for the next cycle
							slave_ack_received <= 0;
							slave_nack_received <= 0;
								
							// reset the i2c clock counter
							i2c_clock_counter <= 0;
								
							// set the next state as START
							i2c_state <= START;
								
							// mark the communication as ongoing
							communication_ongoing <= 1;
								
							// setup slave address and the Read/Write bar for future reference
							// until the current ongoing communication ends
							slave_addr <= addr_in;
							slave_R_Wbar <= R_Wbar;
						end
						else if(communication_ongoing) begin
							if(send_stop && !send_ack && !send_nack) begin
								// reset counter
								i2c_clock_counter <= 0;
								
								// set state to send stop bit
								i2c_state <= SEND_STOP;
								
								// a stop bit can be sent only after sda and scl are already low, hold by master
								sda_en <= 0;
								scl_en <= 0;
							end
							// you may send ack or nack only if you are receiving from the i2c slave device
							else if(!send_stop && send_ack && !send_nack && slave_R_Wbar) begin
								// reset counter
								i2c_clock_counter <= 0;
								
								// set state to send an ack
								i2c_state <= SEND_ACK;
								
								sda_en <= 0;
							end
							else if(!send_stop && !send_ack && send_nack && slave_R_Wbar) begin
								// reset counter
								i2c_clock_counter <= 0;
								
								// set state to send a nack
								i2c_state <= SEND_NACK;
								
								sda_en <= 1;
							end
							else if(write_enable && !slave_R_Wbar) begin
								// reset the i2c clock counter
								i2c_clock_counter <= 0;
								
								data_tx_buff <= data_in;
								
								i2c_state <= SEND_BYTE;
								
								bit_addr <= 7;
								
								sda_en <= data_in[7];
								scl_en <= 0;
							end
							else if(read_enable && slave_R_Wbar) begin
								// reset the i2c clock counter
								i2c_clock_counter <= 0;
								
								// reset ack and nack for the next cycle
								slave_ack_received <= 0;
								slave_nack_received <= 0;
							end
						end
					end

				START	:
					begin
						if(i2c_clock_counter == i2c_half_high_time_count) begin
							// bring sda low after half high time
							sda_en <= 0;
							
							i2c_clock_counter <= i2c_clock_counter + 1;
						end
						else if(i2c_clock_counter == i2c_high_time_count) begin
							// bring scl low after high time
							scl_en <= 0;
							
							i2c_clock_counter <= i2c_clock_counter + 1;
						end
						else if(i2c_clock_counter == i2c_high_and_half_low_time_count) begin
							// reset the clock counter
							i2c_clock_counter <= 0;
							
							// start bit has completed, send addr and read/write bar bit
							data_tx_buff <= {slave_addr, slave_R_Wbar};
							
							// start with sending the 7th bit
							bit_addr <= 7;
							sda_en <= slave_addr[6];
							
							// set state to send a byte
							i2c_state <= SEND_BYTE;
						end
						else begin
							i2c_clock_counter <= i2c_clock_counter + 1;
						end
					end

				SEND_BYTE :
					begin
						if(i2c_clock_counter == i2c_half_low_time_count) begin
							// bring clock high
							scl_en <= 1;
							
							i2c_clock_counter <= i2c_clock_counter + 1;
						end
						else if(i2c_clock_counter == i2c_half_low_and_high_time_count) begin
							// then bring clock low
							scl_en <= 0;
							
							i2c_clock_counter <= i2c_clock_counter + 1;
						end
						else if(i2c_clock_counter == i2c_half_low_and_high_and_half_low_time_count) begin
							// the last bit was send perfectly fine
							
							// reset clock counter
							i2c_clock_counter <= 0;
							
							// if the bit that was send is the 0th bit, we need to get ready to receive a ack or nack from the slave device
							if(bit_addr == 0) begin
								// change state to receive a ack or nack
								i2c_state <= RECEIVE_ACK_NACK;
								
								// leave sda line alone, so the i2c slave can wiggle it to send ack/nack
								sda_en <= 1;
							end
							else begin
								// update the bit address
								bit_addr <= bit_addr - 1;
								
								// set the sda line to send the corresponding bit
								sda_en <= data_tx_buff[bit_addr - 1];
							end
						end
						else
							i2c_clock_counter <= i2c_clock_counter + 1;
					end

				RECEIVE_BYTE :
					begin
						if(i2c_clock_counter == i2c_half_low_time_count) begin
							// bring clock high, now bit on sda has been latched,
							// but we will read it only in the middle of the high pulse of the scl
							scl_en <= 1;
							
							i2c_clock_counter <= i2c_clock_counter + 1;
						end
						else if(i2c_clock_counter == i2c_half_low_and_half_high_time_count) begin
							// middle of scl high pulse, is reached, read the bit
							data_rx_buff[bit_addr] <= i2c_sda;
							bit_addr <= bit_addr - 1;
							
							i2c_clock_counter <= i2c_clock_counter + 1;
						end
						else if(i2c_clock_counter == i2c_half_low_and_high_time_count) begin
							// clock high pulse is complete
							scl_en <= 0;
							
							i2c_clock_counter <= i2c_clock_counter + 1;
						end
						else if(i2c_clock_counter == i2c_half_low_and_high_and_half_low_time_count) begin
							// bit has been read
							
							// reset the counter
							i2c_clock_counter <= 0;
							
							if(bit_addr == 7) begin
								data_out <= data_rx_buff;

								// go to idle state, wait until, we receive ack/nack to send, or to send a stop bit
								i2c_state <= IDLE;
							end
						end
						else
							i2c_clock_counter <= i2c_clock_counter + 1;
					end
					
				SEND_ACK :
					begin
						if(i2c_clock_counter == i2c_half_low_time_count) begin
							// bring clock high
							scl_en <= 1;
							
							i2c_clock_counter <= i2c_clock_counter + 1;
						end
						else if(i2c_clock_counter == i2c_half_low_and_high_time_count) begin
							// then bring clock low
							scl_en <= 0;
							
							i2c_clock_counter <= i2c_clock_counter + 1;
						end
						else if(i2c_clock_counter == i2c_half_low_and_high_and_half_low_time_count) begin
							// the ack/nack bit was send perfectly fine
							
							// reset clock counter
							i2c_clock_counter <= 0;
							
							// sending ack-nack directly transitions to 
							if(i2c_state == SEND_ACK) begin
								// if acked, we get another byte from the device
								bit_addr <= 7;
								
								i2c_state <= RECEIVE_BYTE;
								
								sda_en <= 1;
							end
							else begin
								// else we send stop bit on the line
								i2c_state <= SEND_STOP;
								
								sda_en <= 0;
								scl_en <= 0;
							end
						end
						else begin
							i2c_clock_counter <= i2c_clock_counter + 1;
						end
					end
				
				SEND_NACK :
					begin
						if(i2c_clock_counter == i2c_half_low_time_count) begin
							// bring clock high
							scl_en <= 1;
							
							i2c_clock_counter <= i2c_clock_counter + 1;
						end
						else if(i2c_clock_counter == i2c_half_low_and_high_time_count) begin
							// then bring clock low
							scl_en <= 0;
							
							i2c_clock_counter <= i2c_clock_counter + 1;
						end
						else if(i2c_clock_counter == i2c_half_low_and_high_and_half_low_time_count) begin
							// the ack/nack bit was send perfectly fine
							
							// reset clock counter
							i2c_clock_counter <= 0;
							
							// sending ack-nack directly transitions to 
							if(i2c_state == SEND_ACK) begin
								// if acked, we get another byte from the device
								bit_addr <= 7;
								
								i2c_state <= RECEIVE_BYTE;
								
								sda_en <= 1;
							end
							else begin
								// else we send stop bit on the line
								i2c_state <= SEND_STOP;
								
								sda_en <= 0;
								scl_en <= 0;
							end
						end
						else begin
							i2c_clock_counter <= i2c_clock_counter + 1;
						end
					end
					
				RECEIVE_ACK_NACK :
					begin
						if(i2c_clock_counter == i2c_half_low_time_count) begin
							// bring clock high, now ack or nack bit on sda has been latched,
							// but we will read it only in the middle of the high pulse of the scl
							scl_en <= 1;
							
							i2c_clock_counter <= i2c_clock_counter + 1;
						end
						else if(i2c_clock_counter == i2c_half_low_and_half_high_time_count) begin
							// middle of scl high pulse, is reached, read the bit
							if(i2c_sda) begin
								// if sda is high, it is a nack, else it is an ack
								slave_nack_received <= 1;
								slave_ack_received <= 0;
							end
							else begin
								slave_nack_received <= 0;
								slave_ack_received <= 1;
							end
							
							i2c_clock_counter <= i2c_clock_counter + 1;
						end
						else if(i2c_clock_counter == i2c_half_low_and_high_time_count) begin
							// clock high pulse is complete
							scl_en <= 0;
							
							i2c_clock_counter <= i2c_clock_counter + 1;
						end
						else if(i2c_clock_counter == i2c_half_low_and_high_and_half_low_time_count) begin
							// ack nack bit has been read
							
							// reset the counter
							i2c_clock_counter <= 0;
							
							if(slave_R_Wbar && slave_ack_received) begin
								// go to idle state, wait until, we receive a byte from slave device
								// if acked, we get another byte from the device
								bit_addr <= 7;
								
								i2c_state <= RECEIVE_BYTE;
							end
							else begin
								// or we receive another byte to send, or to send a stop bit
								i2c_state <= IDLE;
							end
						end
						else
							i2c_clock_counter <= i2c_clock_counter + 1;
					end
					
				SEND_STOP :
					begin
						if(i2c_clock_counter == i2c_half_low_time_count) begin
							// set scl high
							scl_en <= 1;
							
							i2c_clock_counter <= i2c_clock_counter + 1;
						end
						else if(i2c_clock_counter == i2c_half_low_and_half_high_time_count) begin
							// then set sda high
							sda_en <= 1;
							
							i2c_clock_counter <= i2c_clock_counter + 1;
						end
						else if(i2c_clock_counter == i2c_half_low_and_high_time_count) begin
							// stop byte has been sent, the communication is now not ongoing
							communication_ongoing <= 0;
							
							// reset the clock counter
							i2c_clock_counter <= 0;
							
							// state set to idle, since communication is not ongoing, the next command must be a start condition
							i2c_state <= IDLE;
						end
						else
							i2c_clock_counter <= i2c_clock_counter + 1;
					end
					
			endcase
		end
	end
	

endmodule
