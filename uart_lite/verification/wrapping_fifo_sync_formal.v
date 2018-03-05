`default_nettype none

module wrapping_fifo_sync_formal ();

parameter DEPTH = 16;
parameter WIDTH = 8;

localparam ADDR_SIZE = $clog2(DEPTH);

wire valid;
wire frame_error;
wire parity_error;
reg rst;
reg clk;
reg wr;
reg rd;
reg [WIDTH-1:0] data_i;
wire [WIDTH-1:0] data_o;
wire empty;
wire full;
wire [$clog2(DEPTH):0] count;
wire [$clog2(DEPTH):0] f_read_ptr;
wire [$clog2(DEPTH):0] f_write_ptr;

// Properties are only valid if the core has been reset in the past
reg f_reset_in_past;
initial f_reset_in_past = 1'b0;
always @(posedge clk) begin
	if (rst) f_reset_in_past <= 1'b1;
end

// Property: write_ptr == (# written)
// Property: read_ptr == (# read - # dropped)
// Property: count == (# written - # read)
reg [31:0] f_written;
reg [31:0] f_read;
reg [31:0] f_dropped;
wire [31:0] f_difference;
assign f_difference = (f_written - f_read - f_dropped);
always @(posedge clk) begin
	if (rst) begin
		f_written <= 0;
		f_read <= 0;
		f_dropped <= 0;
	end
	else if (f_reset_in_past) begin
		assert(count <= DEPTH);
		if (wr) begin
			f_written <= f_written + 1;
		end
		if (rd && ~empty) begin
			f_read <= f_read + 1;
		end
		if (wr && (full & ~rd)) begin
			f_dropped <= f_dropped + 1;
		end
		assert(f_read_ptr == (f_read[ADDR_SIZE:0] + f_dropped[ADDR_SIZE:0]));
		assert(f_write_ptr == f_written[ADDR_SIZE:0]);
		assert(count == f_difference[ADDR_SIZE:0]);
	end
end

// Property: "empty", "full", and "count" are in sync
always @(posedge clk) begin
	if (rst) begin
		assume(count == {DEPTH+1{1'b0}});
	end
	if (f_reset_in_past && !rst) begin
		if (full) begin
			assert(count == DEPTH);
		end
		if (count == DEPTH) begin
			assert(full);
		end
		if (empty) begin
			assert(count == {DEPTH+1{1'b0}});
		end
		if (count == {DEPTH+1{1'b0}}) begin
			assert(empty);
		end
		assert(!(empty & full));
	end
end

wrapping_fifo_sync
#(
	.DEPTH(DEPTH),
	.WIDTH(WIDTH)
) character_recovery
(
	.rst_i(rst),
	.clk_i(clk),
	.wr_i(wr),
	.rd_i(rd),
	.data_i(data_i),
	.data_o(data_o),
	.empty_o(empty),
	.full_o(full),
	.count_o(count),
	.read_ptr_f(f_read_ptr),
	.write_ptr_f(f_write_ptr)
);

endmodule
