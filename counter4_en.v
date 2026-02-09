// counter4_en.v
// 4-bit synchronous counter with active-low reset and enable/hold behavior (Lab 4 concept)

module counter4_en (
    input  wire       clk,
    input  wire       reset_n,
    input  wire       en,
    output reg  [3:0] q
);
    always @(posedge clk) begin
        if (!reset_n)
            q <= 4'b0000;
        else if (en)
            q <= q + 4'b0001;
        else
            q <= q; // hold
    end
endmodule
