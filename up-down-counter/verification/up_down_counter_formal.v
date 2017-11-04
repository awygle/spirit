module up_down_counter_tb ();

wire [7:0] counter_output;
reg rst;
reg clk;
reg ce;
reg up;

initial begin
	rst <= 1'b1;
	ce <= 1'b1;
	up_i <= 1'b1;
	#1000 rst<= 1'b0;
end

up_down_counter 
#(
	.WIDTH(8)
) up_down_counter
(
	.rst_i(rst),
	.clk_i(clk),
	.ce_i(ce),
	.up_i(up),
	.count_o(counter_output)
);

endmodule
