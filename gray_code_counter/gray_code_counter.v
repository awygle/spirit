`default_nettype none

module gray_code_counter
#(
	parameter WIDTH = 8
)
(
	input wire rst_i,
	input wire clk_i,
	input wire ce_i,
	output reg [WIDTH-1:0] binary_o,
	output wire [WIDTH-1:0] gray_o
);

`ifdef FORMAL
reg f_past_valid;
initial f_past_valid = 1'b0;
always @(posedge clk_i) begin
	f_past_valid <= 1'b1;
end

integer f_bitcount;
integer f_idx;

always @(posedge clk_i) begin
	if (f_past_valid) begin
		if ($past(ce_i) && !$past(rst_i)) begin
			assert(binary_o == $past(binary_o) + 1'b1);
			f_bitcount = 0;
			for (f_idx = 0; f_idx < WIDTH; f_idx = f_idx + 1) begin
				f_bitcount = f_bitcount + ($past(gray_o[f_idx]) ^ gray_o[f_idx]);
			end
			assert(f_bitcount == 1);
		end
		if (!$past(ce_i) && !$past(rst_i)) begin
			assert(binary_o == $past(binary_o));
			restrict(gray_o == $past(gray_o));
		end
		if ($past(rst_i)) begin
			assert(binary_o == {WIDTH{1'b0}});
			restrict(gray_o == {WIDTH{1'b0}});
		end
	end
end
`endif

always @(posedge clk_i) begin
	if (rst_i) begin
		binary_o <= {WIDTH{1'b0}};
	end
	else if (ce_i) begin
		binary_o <= binary_o + 1'b1;
	end
end

assign gray_o = (binary_o >> 1) ^ binary_o;

endmodule
