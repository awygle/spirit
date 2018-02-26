`default_nettype none

module bit_recovery
#(
	parameter OVERSAMPLING = 16
)
(
	input rst_i,
	input clk_i,
	input rx_i,
	output reg rx_bit_o,
	output reg valid_o
);

reg hold;

localparam COUNTSIZE = $clog2(OVERSAMPLING);
localparam UGLYTMP = OVERSAMPLING-'b1;
localparam [COUNTSIZE-1:0] MAXCOUNT = UGLYTMP[COUNTSIZE-1:0];
reg [COUNTSIZE-1:0] counter;

always @(posedge clk_i) begin
	if (rst_i) begin
		valid_o <= 1'b0;
		counter <= {COUNTSIZE{1'b0}};
		// No need to reset rx_bit_o 
	end
	else begin
		hold <= rx_i;
		valid_o <= 1'b0;
		counter <= counter + 1'b1;
		
		if (counter != {COUNTSIZE{1'b0}} && hold != rx_i) begin
			counter <= {COUNTSIZE{1'b0}};
		end
		if (counter == MAXCOUNT && hold == rx_i) begin
			valid_o <= 1'b1;
			rx_bit_o <= hold;
			counter <= {COUNTSIZE{1'b0}};
		end
	end
end

endmodule
