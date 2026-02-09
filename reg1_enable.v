
// reg1_enable.v
// 1-bit register with enable and active-low synchronous reset (Lab 3 concept)

module reg1_enable (
    input  wire clk,
    input  wire reset_n,
    input  wire en,
    input  wire d,
    output reg  q
);
    always @(posedge clk) begin
        if (!reset_n)
            q <= 1'b0;
        else if (en)
            q <= d;
        else
            q <= q; // hold
    end
endmodule

