
// The given main module, queries accelerometer data and gyroscope data, over i2c
module main(
	input reset_bar,
	input clk,
	input start_bar,
	inout i2c_sda,
	inout i2c_scl,
	output indicate_ack_received_bar,
	output indicate_nack_received_bar,
	output reg [7:0] display
    );
	 
	 wire reset;
	 assign reset = ~reset_bar;
	 
	 wire start;
	 assign start = ~start_bar;
	 
	 reg indicate_ack_received;
	 assign indicate_ack_received_bar = ~indicate_ack_received;
	 
	 reg indicate_nack_received;
	 assign indicate_nack_received_bar = ~indicate_nack_received;
	 
	 reg dev_state;
	 
	 reg [6:0]device_addr;
	 reg R_Wbar;
	 
	 reg send_start;
	 reg send_ack;
	 reg send_nack;
	 reg send_stop;
	 
	 wire ack_received;
	 wire nack_received;
	 
	 wire communication_ongoing;
	 wire controller_idle;
	 
	 reg data_in;
	 reg write_enable;
	 
	 wire data_out;
	 reg read_enable;
	 
	 localparam I2C_CONT_RESET 		= 0;
	 localparam DETECT_DEVICE 			= 1;
	 localparam SEND_POWER_REG_ADDR 	= 2;
	 localparam WRITE_POWER_REGISTER = 3;
	 localparam SEND_DATA_REG_ADDR 	= 4;
	 localparam READ_DATA_REGISTERS 	= 5;
	 
	 localparam HALT = 6;
	 
	 reg [7:0] SETUP_ADDR;
	 reg [7:0] mpu_data_addr;
	 // gyrox, gyroy, gyroz, acclx, accly, acclz
	 reg [15:0] mpu_data [0:5];
	 reg [7:0] bytes_read;
	 
	integer step_counter;

	always@(posedge clk) begin
		if(reset) begin
			dev_state <= I2C_CONT_RESET;
			
			device_addr <= 8'h00;
			R_Wbar <= 0;
	 
			send_start <= 0;
			send_ack <= 0;
			send_nack <= 0;
			send_stop <= 0;
			
			data_in <= 0;
			write_enable <= 0;
	 
			read_enable <= 0;
			
			step_counter <= 0;
			
			indicate_ack_received <= 0;
			indicate_nack_received <= 0;
			
			display <= 0;
		end
		else begin
			case (dev_state)
			
				I2C_CONT_RESET : begin
					if(start) begin
						step_counter <= 0;
						dev_state <= DETECT_DEVICE;
					end
				end
				
				DETECT_DEVICE : begin
					if(controller_idle) begin
						if(step_counter == 0) begin
							R_Wbar <= 0;
							send_start <= 1;
							display <= device_addr;
							step_counter <= step_counter + 1;
						end
						else if(step_counter == 1) begin
							if(ack_received) begin
								indicate_ack_received <= 1;
							end
							else if(nack_received) begin
								indicate_nack_received <= 1;
							end
							send_stop <= 1;
							step_counter <= step_counter + 1;
						end
						else if(step_counter == 2) begin
							if(ack_received || device_addr == 7'h7f) begin
								dev_state <= HALT;
							end
							else begin
								device_addr <= device_addr + 1;
							end
							step_counter <= 0;
						end
					end
					else begin
						send_start <= 0;
						send_stop <= 0;
					end
				end
				
				SEND_POWER_REG_ADDR : begin
				end
				
				WRITE_POWER_REGISTER : begin
				end
				
				SEND_DATA_REG_ADDR : begin
				end
				
				READ_DATA_REGISTERS : begin
				end
				
				HALT : begin
				end
				
			endcase
		end
	end
	
	
	i2c_controller i2c_controller (
						reset, clk, 
						i2c_sda, i2c_scl, 
						device_addr, R_Wbar, send_start,
						data_in, write_enable,
						data_out, read_enable,
						send_ack, send_nack, send_stop,
						ack_received, nack_received,
						communication_ongoing, controller_idle);

endmodule
