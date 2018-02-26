`default_nettype none

module character_recovery
#(
	parameter OVERSAMPLING = 16,
	parameter DATA_BITS = 8
)
(
	input rst_i,
	input clk_i,
	input rx_i,
	input valid_i,
	output reg [DATA_BITS-1:0] char_o,
	output reg valid_o
);

localparam COUNTSIZE = $clog2(OVERSAMPLING);
reg [COUNTSIZE-1:0] counter;

localparam DATASIZE = $clog2(DATA_BITS);
reg [DATASIZE-1:0] index;

reg [1:0] state;

localparam IDLE = 2'b00;
localparam STARTED = 2'b01;
localparam CAPTURED = 2'b10;

wire counter_full;
assign counter_full = counter == {COUNTSIZE{1'b1}};

always @(posedge clk_i) begin
	if (rst_i) begin
		valid_o <= 1'b0;
		state <= IDLE;
		// No need to reset char_o, counter
	end
	else begin
		case (state)
			IDLE: begin
				valid_o <= 1'b0;
				if (valid_i && rx_i) begin
					state <= STARTED;
					index <= {DATASIZE{1'b0}};
					counter <= {COUNTSIZE{1'b0}};
				end
			end
			STARTED: begin
				counter <= counter + 1'b1;
				case ({counter_full, valid_i}) 
					2'b11: begin // counter full + valid - advance
						char_o[index] <= rx_i;
						index <= index + 1'b1;
						if (index == DATA_BITS-1) state <= CAPTURED;
					end
					2'b10, 2'b01: begin // not full but valid or not valid but full - error
						state <= IDLE;
					end
					2'b00: begin // not full or valid - continue
						;
					end
				endcase
			end
			CAPTURED: begin
				counter <= counter + 1'b1;
				case ({counter_full, valid_i})
					2'b11: begin 
						valid_o <= ~rx_i; // stop bit must be low
						state <= IDLE;
					end
					2'b10, 2'b01: begin // error
						state <= IDLE;
					end
					2'b00: begin // continue
						;
					end
				endcase
			end
			default: begin
				// impossible
				state <= IDLE;
			end
		endcase
	end
end

endmodule
