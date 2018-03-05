`default_nettype none

module wrapping_fifo_sync
#(
	parameter WIDTH = 8,
	parameter DEPTH = 4
)
(
	input rst_i,
	input clk_i,
	input wr_i,
	input rd_i,
	input [WIDTH-1:0] data_i,
	output [WIDTH-1:0] data_o,
	output reg empty_o,
	output reg full_o,
	output [$clog2(DEPTH):0] count_o,
	`ifdef FORMAL
	output [$clog2(DEPTH):0] write_ptr_f,
	output [$clog2(DEPTH):0] read_ptr_f,
	`endif
);

generate
	if (DEPTH != 1 && (DEPTH  & (DEPTH-1))) begin
		DEPTH_NOT_POWER_OF_TWO dummy ();
	end
endgenerate

reg [WIDTH-1:0] memory [DEPTH-1:0];

localparam ADDR_SIZE = $clog2(DEPTH);
reg [ADDR_SIZE:0] read_ptr;
reg [ADDR_SIZE:0] write_ptr;

`ifdef FORMAL
	assign write_ptr_f = write_ptr;
	assign read_ptr_f = read_ptr;
`endif

assign data_o = memory[read_ptr[ADDR_SIZE-1:0]];

wire [ADDR_SIZE:0] next_write_ptr;
wire [ADDR_SIZE:0] next_read_ptr;
assign next_write_ptr = write_ptr + 1'b1;
assign next_read_ptr = read_ptr + 1'b1;


// Flags section
always @(posedge clk_i) begin
	if (rst_i) begin
		empty_o <= 1'b1;
		full_o <= 1'b0;
		read_ptr <= {(ADDR_SIZE+1){1'b0}};
		write_ptr <= {(ADDR_SIZE+1){1'b0}};
		count_o <= {(ADDR_SIZE+1){1'b0}};
	end
	else begin
		casez ({wr_i, rd_i, full_o, empty_o})
			4'b11?0: begin
				memory[write_ptr[ADDR_SIZE-1:0]] <= data_i;
				write_ptr <= write_ptr + 1'b1;
				read_ptr <= read_ptr + 1'b1;
			end
			4'b1010: begin
				memory[write_ptr[ADDR_SIZE-1:0]] <= data_i;
				write_ptr <= write_ptr + 1'b1;
				read_ptr <= read_ptr + 1'b1; // dropping last value
			end
			4'b1101: begin
				memory[write_ptr[ADDR_SIZE-1:0]] <= data_i;
				write_ptr <= write_ptr + 1'b1;
				// no previous value - don't increment read, do increment
				// count
				count_o <= count_o + 1'b1;
				empty_o <= 1'b0;
			end
			4'b100?: begin
				full_o <= (next_write_ptr[ADDR_SIZE-1:0] == read_ptr[ADDR_SIZE-1:0]) && (next_write_ptr[ADDR_SIZE] != read_ptr[ADDR_SIZE]);
				empty_o <= 1'b0;
				write_ptr <= write_ptr + 1'b1;
				count_o <= count_o + 1'b1;
			end
			4'b01?0: begin
				empty_o <= (write_ptr == next_read_ptr);
				full_o <= 1'b0;
				read_ptr <= read_ptr + 1'b1;
				count_o <= count_o - 1'b1;
			end
			default: begin
			end
		endcase
	end
end

endmodule
