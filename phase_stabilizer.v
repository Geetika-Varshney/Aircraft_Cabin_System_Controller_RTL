// phase_stabilizer.v
// Debounces/stabilizes flight_phase changes using a small timer (counter enable/hold concept)

module phase_stabilizer #(
    parameter integer STABLE_CYCLES = 6  // how many cycles to wait after a phase change
)(
    input  wire       clk,
    input  wire       reset_n,
    input  wire       en,                 // freeze when en=0 (maintenance)
    input  wire [2:0] flight_phase,
    output reg        phase_stable
);
    reg [2:0] last_phase;
    reg [3:0] count;       // small counter (enough for STABLE_CYCLES up to 15)
    reg       counting;

    always @(posedge clk) begin
        if (!reset_n) begin
            last_phase   <= 3'b000;
            count        <= 4'b0000;
            counting     <= 1'b0;
            phase_stable <= 1'b1;  // stable at reset baseline
        end else if (!en) begin
            // maintenance freeze: hold everything
            last_phase   <= last_phase;
            count        <= count;
            counting     <= counting;
            phase_stable <= phase_stable;
        end else begin
            if (flight_phase != last_phase) begin
                // detected new phase -> start stabilization timer
                last_phase   <= flight_phase;
                count        <= 4'b0000;
                counting     <= 1'b1;
                phase_stable <= 1'b0;
            end else if (counting) begin
                if (count == (STABLE_CYCLES-1)) begin
                    counting     <= 1'b0;
                    phase_stable <= 1'b1;
                end else begin
                    count        <= count + 4'b0001;
                    phase_stable <= 1'b0;
                end
            end else begin
                phase_stable <= 1'b1;
            end
        end
    end

endmodule
