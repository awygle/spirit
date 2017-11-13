module gray_code_counter_formal ();

wire [7:0] binary_output;
wire [7:0] gray_output;
reg rst;
reg clk;
reg ce;

initial begin
	rst = 1'b1;
	ce = 1'b1;
	#1000 rst = 1'b0;
end

`ifdef FORMAL
	reg f_last_clk;
	always @($global_clock) begin
		assume(clk == !f_last_clk);
		f_last_clk <= clk;
		clk <= (clk === 1'b0);
	end
`else
	always #100 clk = (clk === 1'b0);
`endif

gray_code_counter 
#(
	.WIDTH(8)
) gray_code_counter
(
	.rst_i(rst),
	.clk_i(clk),
	.ce_i(ce),
	.binary_o(binary_output),
	.gray_o(gray_output)
);

endmodule
