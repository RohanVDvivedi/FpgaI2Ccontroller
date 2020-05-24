
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
	 
	 reg [3:0]dev_state;
	 
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
	 
	 reg [7:0] data_in;
	 reg write_enable;
	 
	 wire [7:0] data_out;
	 reg read_enable;
	 
	 localparam I2C_CONT_RESET 		= 0;
	 localparam DETECT_DEVICE 			= 1;
	 localparam SETUP_DEVICE			= 2;
	 localparam READ_SENSOR_DATA 		= 3;
	 localparam WAIT_1_SEC 				= 4;
	 localparam HALT						= 5;
	 
	 reg [7:0] SETUP_ADDR;
	 reg [7:0] mpu_data_addr;
	 // acclx, accly, acclz, temp, gyrox, gyroy, gyroz
	 reg [7:0] mpu_data [0:13];
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
							if(ack_received) begin
								dev_state <= SETUP_DEVICE;
								display <= device_addr;
							end
							else if(device_addr == 7'h7f) begin
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
				
				SETUP_DEVICE : begin
					if(controller_idle) begin
						if(step_counter == 0) begin
							R_Wbar <= 0;
							send_start <= 1;
							step_counter <= step_counter + 1;
						end
						else if(step_counter == 1) begin
							if(ack_received) begin
								indicate_ack_received <= 1;
								data_in <= 8'h6b;
								write_enable <= 1;
								step_counter <= step_counter + 1;
							end
							else if(nack_received) begin
								dev_state <= HALT;
								display <= 8'h94;
								indicate_nack_received <= 1;
							end
						end
						else if(step_counter == 2) begin
							if(ack_received) begin
								indicate_ack_received <= 1;
								data_in <= 8'h00;
								write_enable <= 1;
								step_counter <= step_counter + 1;
							end
							else if(nack_received) begin
								dev_state <= HALT;
								display <= 8'h85;
								indicate_nack_received <= 1;
							end
						end
						else if(step_counter == 3) begin
							if(ack_received) begin
								indicate_ack_received <= 1;
								send_stop <= 1;
								step_counter <= step_counter + 1;
							end
							else if(nack_received) begin
								dev_state <= HALT;
								display <= 8'h95;
								indicate_nack_received <= 1;
							end
						end
						else if(step_counter == 3) begin
							step_counter <= 0;
							dev_state <= HALT;
							display <= 8'h95;
							//dev_state <= READ_SENSOR_DATA;
						end
						else begin
							step_counter <= 0;
						end
					end
					else begin
						send_start <= 0;
						write_enable <= 0;
						send_stop <= 0;
					end
				end
				
				READ_SENSOR_DATA : begin
					if(controller_idle) begin
						if(step_counter == 0) begin
							R_Wbar <= 0;
							send_start <= 1;
							step_counter <= step_counter + 1;
						end
						else if(step_counter == 1) begin
							if(ack_received) begin
								indicate_ack_received <= 1;
								data_in <= 8'h3b;
								write_enable <= 1;
								step_counter <= step_counter + 1;
							end
							else if(nack_received) begin
								dev_state <= HALT;
								indicate_nack_received <= 1;
							end
						end
						else if(step_counter == 2) begin
							if(ack_received) begin
								indicate_ack_received <= 1;
								R_Wbar <= 1;
								send_start <= 1;
								bytes_read <= 0;
								step_counter <= step_counter + 1;
							end
							else if(nack_received) begin
								dev_state <= HALT;
								indicate_nack_received <= 1;
							end
						end
						else if(step_counter == 3) begin
							if(bytes_read == 0 && nack_received) begin
								dev_state <= HALT;
								indicate_nack_received <= 1;
							end
							else begin
								if(bytes_read == 0) begin
									indicate_ack_received <= 1;
								end
								read_enable <= 1;
								step_counter <= step_counter + 1;
							end
						end
						else if(step_counter == 4) begin
							mpu_data[bytes_read] <= data_out;
							bytes_read <= bytes_read + 1;
							if(bytes_read == 13) begin
								send_nack <= 1;
								step_counter <= step_counter + 1;
							end
							else begin
								send_ack <= 1;
								step_counter <= 3;		
							end
						end
						else if(step_counter == 5) begin
							send_stop <= 1;
							step_counter <= step_counter + 1;
						end
						else if(step_counter == 6) begin
							step_counter <= 0;
							dev_state <= WAIT_1_SEC;
						end
						else begin
							step_counter <= 0;
						end
					end
					else begin
						send_start <= 0;
						write_enable <= 0;
						read_enable <= 0;
						send_ack <= 0;
						send_nack <= 0;
						send_stop <= 0;
					end
				end
				
				WAIT_1_SEC : begin
					if(step_counter == 50000000) begin
						dev_state <= READ_SENSOR_DATA;
						step_counter <= 0;
					end
					else begin
						step_counter <= step_counter + 1;
					end
				end
				
				HALT : begin
				end
				
			endcase
		end
	end
	
	wire[15:0] acclz;
	assign acclz = {mpu_data[4],mpu_data[5]};
	
	wire[15:0] pos_acclz;
	assign pos_acclz = (acclz < 0) ? -acclz : acclz;
	
	wire[7:0] pos_acclz_8;
	assign pos_acclz_8 = pos_acclz[14:7];
	
	/*always@(posedge clk) begin
		if(reset) begin
			display <= 0;
		end
		else if(send_stop) begin
			display <= mpu_data[5];
		end
	end*/
	
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
