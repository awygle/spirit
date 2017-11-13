# Spirit IP: Gray Code Counter

A synchronous Gray code counter with parameterized width.

## Module Parameters

* WIDTH     - The width of the counter, in bits, as a positive integer. Defaults to 8 bits.

## Module Ports

* input rst_i                   - The synchronous, active-high reset input to the counter module.
* input clk_i                   - The clock input to the counter module.
* input ce_i                    - The clock enable input to the counter module.
* output [WIDTH-1:0] binary_o   - The current value of the counter in binary.
* output [WIDTH-1:0] gray_o     - The current Gray coded value of the counter. Not registered.

## Input Restrictions

None

## Output Restrictions

Consecutive values of gray_o must differ by at most 1 _bit_, except when reset is asserted.

## Dependencies

None

