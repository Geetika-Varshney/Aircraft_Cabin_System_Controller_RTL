// dff_resetn.v
// D flip-flop with active-low synchronous reset (Lab 3 concept)

module dff_resetn (
    input  wire clk,
    input  wire reset_n,
    input  wire d,
    output reg  q
);
    always @(posedge clk) begin
        if (!reset_n)
            q <= 1'b0;
        else
            q <= d;
    end
endmodule
