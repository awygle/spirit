# Spirit IP: Up-Down Counter

A synchronous binary up-down counter with parameterized width and optional unidirectional modes.

## Module Parameters

* WIDTH     - The width of the counter, in bits, as a positive integer. Defaults to 8 bits.
* INIT      - The initial value of the counter as a positive integer. Defaults to 0.

## Module Ports

* input rst_i                   - The synchronous, active-high reset input to the counter module.
* input clk_i                   - The clock input to the counter module.
* input ce_i                    - The clock enable input to the counter module.
* input up_i                    - The direction input to the counter module. If 1'b1, the counter will count up. If 1'b0, the counter will count down. 
* output [WIDTH-1:0] count_o    - The current value of the counter.

## Input Restrictions

None

## Output Restrictions

Consecutive values of count_o must differ by at most 1, except when reset is asserted.

## Dependencies

None

