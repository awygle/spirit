`default_nettype none

module character_recovery
#(
	parameter OVERSAMPLING = 16,
	parameter GLITCH_LENGTH = 1,
	parameter DATA_BITS = 8
)
(
	input rst_i,
	input clk_i,
	input rx_i,
	output reg [DATA_BITS-1:0] char_o,
	output reg valid_o
);

localparam COUNTSIZE = $clog2(OVERSAMPLING);
reg [COUNTSIZE-1:0] counter;

localparam DATASIZE = $clog2(DATA_BITS);
reg [DATASIZE-1:0] index;

reg [1:0] state;

localparam IDLE = 2'b00;
localparam STARTING = 2'b01;
localparam STARTED = 2'b10;
localparam CAPTURED = 2'b11;

wire counter_empty;
assign counter_empty = counter == {COUNTSIZE{1'b0}};

reg past_rx;

always @(posedge clk_i) begin
	if (rst_i) begin
		valid_o <= 1'b0;
		state <= IDLE;
		past_rx <= 1'b0;
		counter <= {COUNTSIZE{1'b0}};
		// No need to reset char_o
	end
	else begin
		past_rx <= rx_i;
		case (state)
			IDLE: begin
				valid_o <= 1'b0;
				if (counter_empty && !past_rx && rx_i) begin
					state <= STARTING;
					index <= {DATASIZE{1'b0}};
					counter <= (OVERSAMPLING >> 1) - 1'b1;
				end
			end
			STARTING: begin
				counter <= counter - 1'b1;
				if (counter_empty) begin
					state <= rx_i ? STARTED : IDLE;
					counter <= OVERSAMPLING-1;
				end
			end
			STARTED: begin
				counter <= counter - 1'b1;
				if (counter_empty) begin
					char_o[index] <= rx_i;
					index <= index + 1'b1;
					if (index == DATA_BITS-1) state <= CAPTURED;
					counter <= OVERSAMPLING-1;
				end
			end
			CAPTURED: begin
				counter <= counter - 1'b1;
				if (counter_empty) begin
					valid_o <= ~rx_i; // stop bit must be low
					state <= IDLE;
					// wait out the rest of the bit period before restart
					counter <= (OVERSAMPLING >> 1) - 1'b1 + (OVERSAMPLING & 1'b1);
				end
			end
		endcase
	end
end

endmodule
