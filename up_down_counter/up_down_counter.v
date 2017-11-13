`default_nettype none

module up_down_counter
#(
	parameter WIDTH = 8,
	parameter INIT = 8'h00
)
(
	input wire rst_i,
	input wire clk_i,
	input wire ce_i,
	input wire up_i,
	output reg [WIDTH-1:0] count_o
);

generate
	if ($clog2(INIT) > WIDTH) begin
		INIT_TOO_LARGE dummy ();
	end
endgenerate

`ifdef FORMAL
reg f_past_valid;
initial f_past_valid = 1'b0;
always @(posedge clk_i) begin
	f_past_valid <= 1'b1;
end

always @(posedge clk_i) begin
	if (f_past_valid) begin
		if ($past(ce_i) && $past(up_i) && !$past(rst_i)) begin
			assert(count_o == $past(count_o) + 1'b1);
		end
		if ($past(ce_i) && !$past(up_i) && !$past(rst_i)) begin
			assert(count_o == $past(count_o) - 1'b1);
		end
		if (!$past(ce_i) && !$past(rst_i)) begin
			assert(count_o == $past(count_o));
		end
		if ($past(rst_i)) begin
			assert(count_o == INIT);
		end
	end
end
`endif

always @(posedge clk_i) begin
	if (rst_i) begin
		count_o <= INIT;
	end
	else if (ce_i) begin
		if (up_i) begin
			count_o <= count_o + 1'b1;
		end
		else begin
			count_o <= count_o - 1'b1;
		end
	end
end

endmodule
