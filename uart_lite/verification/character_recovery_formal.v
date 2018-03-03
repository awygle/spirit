`default_nettype none

module character_recovery_formal ();

parameter OVERSAMPLING = 16;
parameter DATA_BITS = 8;
parameter PARITY = 2;

localparam PARITY_BITS = (PARITY > 0) ? 1 : 0;

wire [DATA_BITS-1:0] char;
wire valid;
wire frame_error;
wire parity_error;
reg rst;
reg clk;
reg rx;

// Properties are only valid if the core has been reset in the past
reg f_reset_in_past;
initial f_reset_in_past = 1'b0;
always @(posedge clk) begin
	if (rst) f_reset_in_past <= 1'b1;
end

// Property: all accepted inputs well-formed, no invalid inputs accepted
localparam OFFSET = (OVERSAMPLING / 2);
localparam HOLD_LENGTH = ((OVERSAMPLING) * (DATA_BITS + PARITY_BITS + 1)) + OFFSET;
reg [HOLD_LENGTH-1:0] f_hold;
integer f_i;
wire parity_bit = f_hold[HOLD_LENGTH-OVERSAMPLING-1];
always @(posedge clk) begin
	f_hold[HOLD_LENGTH-1] <= rx;
	f_hold[0:HOLD_LENGTH-2] <= f_hold[1:HOLD_LENGTH-1];
	if (f_reset_in_past && ~rst) begin
		if (valid) begin
			assert(~f_hold[OFFSET-1]);
			assert(f_hold[HOLD_LENGTH-1]);
			assert(!frame_error);
			assert(!parity_error);
			for (f_i = 1; f_i < DATA_BITS+1; f_i = f_i + 1)
				assert(f_hold[(f_i*OVERSAMPLING)+(OFFSET-1)] == char[f_i-1]);
		end
		if (frame_error) begin
			assert(~f_hold[OFFSET-1]);
			assert(~f_hold[HOLD_LENGTH-1]);
			assert(~valid);
		end
		if (parity_error) begin
			assert(^{char[DATA_BITS-1:0], parity_bit} != PARITY[0]);
			assert(~valid);
		end
	end
end

// Property: assertions of valid are at least 160 cycles apart
localparam TOTAL_BITS = OVERSAMPLING * (DATA_BITS + PARITY_BITS + 2);
reg [$clog2(TOTAL_BITS)-1:0] f_counter;
initial f_counter = TOTAL_BITS - 1;
always @(posedge clk) begin
	if (f_counter < TOTAL_BITS - 1) f_counter <= f_counter + 1'b1;
	if (f_reset_in_past) begin
		assume(f_counter <= TOTAL_BITS - 1);
		if (valid) begin
			assert(f_counter == TOTAL_BITS - 1);
			f_counter <= 8'd0;
		end
	end
	// This is below the check because if the core asserts valid on the same
	// cycle that the controller asserts reset, we still consider the property
	// to hold.
	if (rst) begin
		f_counter <= TOTAL_BITS - 1;
	end
end

// Property: reset clears valid
always @(posedge clk) begin
	if (f_reset_in_past) begin
		if ($past(rst)) assert(!valid);
	end
end
	
always @(posedge clk) begin
	if (f_reset_in_past) begin
		cover(valid);
	end
end

// Property: all valid inputs accepted
reg [DATA_BITS:0] i;
always @(posedge clk) begin
	if (f_reset_in_past) begin
		for (i = 0; i < 2**DATA_BITS; i = i + 1) begin
			cover(valid && char == i[DATA_BITS-1:0]);
		end
	end
end

character_recovery
#(
	.OVERSAMPLING(OVERSAMPLING),
	.DATA_BITS(DATA_BITS),
	.PARITY(PARITY)
) character_recovery
(
	.rst_i(rst),
	.clk_i(clk),
	.rx_i(rx),
	.char_o(char),
	.valid_o(valid),
	.frame_error_o(frame_error),
	.parity_error_o(parity_error)
);

endmodule
