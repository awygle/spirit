`default_nettype none

module character_recovery
#(
	parameter OVERSAMPLING = 16,
	parameter DATA_BITS = 8,
	parameter PARITY = 0
)
(
	input rst_i,
	input clk_i,
	input rx_i,
	output reg [DATA_BITS-1:0] char_o,
	output reg valid_o,
	output reg frame_error_o,
	output reg parity_error_o
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
wire start_bit_edge;
assign start_bit_edge = (past_rx) && (~rx_i);

// parity calculation
wire parity_error;
wire data_finished;
reg parity_bit;
generate if (PARITY > 0) begin
	reg parity;
	always @(posedge clk_i) begin
		if (rst_i) begin
			parity <= 1'b0;
			parity_bit <= 1'b0;
		end
		else begin
			case (state)
				IDLE: begin
					parity <= 1'b0;
					parity_bit <= 1'b0;
				end
				STARTED: begin
					if (counter_empty) begin
						parity <= parity ^ rx_i;
						if (index == DATA_BITS-1) begin
							parity_bit <= 1'b1;
						end
					end
				end
				default: begin
					;
				end
			endcase
		end
	end
	assign parity_error = parity != PARITY[0];
	assign data_finished = parity_bit;
end
endgenerate

generate if (PARITY == 0) begin
	assign parity_error = 1'b0;
	assign data_finished = (index == DATA_BITS-1);
	always @(*) begin
		parity_bit = 1'b0;
	end
end
endgenerate

always @(posedge clk_i) begin
	if (rst_i) begin
		valid_o <= 1'b0;
		frame_error_o <= 1'b0;
		state <= IDLE;
		past_rx <= 1'b1;
		counter <= {COUNTSIZE{1'b0}};
		parity_error_o <= 1'b0;
		// No need to reset char_o
	end
	else begin
		past_rx <= rx_i;
		case (state)
			IDLE: begin
				valid_o <= 1'b0;
				frame_error_o <= 1'b0;
				parity_error_o <= 1'b0;
				if (counter_empty && start_bit_edge) begin
					state <= STARTING;
					index <= {DATASIZE{1'b0}};
					counter <= (OVERSAMPLING >> 1) - 1'b1;
				end
			end
			STARTING: begin
				counter <= counter - 1'b1;
				if (counter_empty) begin
					state <= (~rx_i) ? STARTED : IDLE;
					counter <= OVERSAMPLING-1;
				end
			end
			STARTED: begin
				counter <= counter - 1'b1;
				if (counter_empty) begin
					if (~parity_bit) begin
						char_o[index] <= rx_i;
						index <= index + 1'b1;
					end
					if (data_finished) state <= CAPTURED;
					counter <= OVERSAMPLING-1;
				end
			end
			CAPTURED: begin
				counter <= counter - 1'b1;
				if (counter_empty) begin
					// stop bit must be opposite of start bit
					// can't assert valid if there's a parity error
					valid_o <= (rx_i & ~parity_error);
					frame_error_o <= (~rx_i);
					parity_error_o <= parity_error;
					state <= IDLE;
					// wait out the rest of the bit period before restart
					counter <= (OVERSAMPLING >> 1) - 1'b1 + (OVERSAMPLING & 1'b1);
				end
			end
		endcase
	end
end

endmodule
