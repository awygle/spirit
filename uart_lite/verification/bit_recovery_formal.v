`default_nettype none

module bit_recovery_formal ();

wire rx_bit;
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

// Property: valid only asserted if last 16 values the same
reg [15:0] f_hold;
initial f_hold = 16'h0f0f;
always @(posedge clk) begin
	f_hold[15] <= rx;
	f_hold[0:14] <= f_hold[1:15];
	if (f_reset_in_past) begin
		if (!rst) begin
			if (valid && rx_bit) assert(&(f_hold));
			if (valid && !rx_bit) assert(~|(f_hold));
		end
	end
end

// Property: assertions of valid are at least 16 cycles apart
reg [3:0] f_counter;
initial f_counter = 4'hF;
always @(posedge clk) begin
	if (f_counter < 4'hF) f_counter <= f_counter + 1'b1;
	if (f_reset_in_past) begin
		if (valid) begin
			assert(f_counter == 4'hf);
			f_counter <= 4'h0;
		end
	end
end

// Property: reset clears valid
always @(posedge clk) begin
	if (f_reset_in_past) begin
		if ($past(rst)) assert(!valid);
	end
end
	
// Property: valid is eventually set
always @(posedge clk) begin
	if (f_reset_in_past) begin
		cover(valid);
	end
end

// Property: both high and low bits are detected
always @(posedge clk) begin
	if (f_reset_in_past) begin
		cover(valid && rx_bit);
		cover(valid && !rx_bit);
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
	.valid_o(valid)
);

endmodule
