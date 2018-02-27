`default_nettype none

module character_recovery_formal ();

wire [7:0] char;
wire valid;
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
reg [151:0] f_hold;
integer f_i;
always @(posedge clk) begin
	f_hold[151] <= rx;
	f_hold[0:150] <= f_hold[1:151];
	if (f_reset_in_past) begin
		if (!rst && valid) begin
			assert(f_hold[7]);
			assert(~f_hold[151]);
			for (f_i = 16; f_i < 136; f_i = f_i + 16)
				assert(f_hold[f_i+7] == char[(f_i/16)-1]);
		end
	end
end

// Property: assertions of valid are at least 160 cycles apart
reg [7:0] f_counter;
initial f_counter = 8'd159;
always @(posedge clk) begin
	if (f_counter < 8'd159) f_counter <= f_counter + 1'b1;
	if (f_reset_in_past) begin
		assume(f_counter <= 8'd159);
		if (valid) begin
			assert(f_counter == 8'd159);
			f_counter <= 8'd0;
		end
	end
	// This is below the check because if the core asserts valid on the same
	// cycle that the controller asserts reset, we still consider the property
	// to hold.
	if (rst) begin
		f_counter <= 8'd159;
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
reg [8:0] i;
always @(posedge clk) begin
	if (f_reset_in_past) begin
		for (i = 0; i < 9'd256; i = i + 1) begin
			cover(valid && char == i[7:0]);
		end
	end
end

character_recovery
#(
	.OVERSAMPLING(16),
	.DATA_BITS(8)
) character_recovery
(
	.rst_i(rst),
	.clk_i(clk),
	.rx_i(rx),
	.char_o(char),
	.valid_o(valid)
);

endmodule
