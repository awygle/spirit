`default_nettype none

module character_recovery_formal ();

wire rx_bit;
wire bit_valid;
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
reg [9:0] f_hold;
always @(posedge clk) begin
	if (bit_valid) begin
		f_hold[9] <= rx_bit;
		f_hold[0:8] <= f_hold[1:9];
	end
	if (f_reset_in_past) begin
		if (!rst && valid) begin
			assert(f_hold[0] == 1'b1);
			assert(f_hold[9] == 1'b0);
			assert(f_hold[1:8] == char);
		end
	end
end

// Property: assertions of valid are at least 160 cycles apart
reg [7:0] f_counter;
initial f_counter = 8'd159;
always @(posedge clk) begin
	if (f_counter < 8'd159) f_counter <= f_counter + 1'b1;
	if (rst) begin
		f_counter <= 8'd159;
	end
	if (f_reset_in_past) begin
		assume(f_counter <= 8'd159);
		if (valid) begin
			assert(f_counter == 8'd159);
			f_counter <= 8'd0;
		end
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

bit_recovery 
#(
	.OVERSAMPLING(16)
) bit_recovery
(
	.rst_i(rst),
	.clk_i(clk),
	.rx_i(rx),
	.rx_bit_o(rx_bit),
	.valid_o(bit_valid)
);

character_recovery
#(
	.OVERSAMPLING(16),
	.DATA_BITS(8)
) character_recovery
(
	.rst_i(rst),
	.clk_i(clk),
	.rx_i(rx_bit),
	.valid_i(bit_valid),
	.char_o(char),
	.valid_o(valid)
);

endmodule
