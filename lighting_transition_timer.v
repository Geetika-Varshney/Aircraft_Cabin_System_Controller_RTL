// lighting_transition_timer.v
// Delays lighting updates (timed transitions) using enable/hold behavior

module lighting_transition_timer #(
    parameter integer DELAY_CYCLES = 5
)(
    input  wire clk,
    input  wire reset_n,
    input  wire en,          // freeze when en=0 (maintenance)
    input  wire start,       // pulse to start a transition delay
    output reg  done         // 1-cycle pulse when delay completes
);
    reg [3:0] count;
    reg       running;

    always @(posedge clk) begin
        if (!reset_n) begin
            count   <= 4'b0000;
            running <= 1'b0;
            done    <= 1'b0;
        end else if (!en) begin
            // freeze in maintenance
            count   <= count;
            running <= running;
            done    <= 1'b0;
        end else begin
            done <= 1'b0;

            if (start && !running) begin
                running <= 1'b1;
                count   <= 4'b0000;
            end else if (running) begin
                if (count == (DELAY_CYCLES-1)) begin
                    running <= 1'b0;
                    done    <= 1'b1;
                end else begin
                    count <= count + 4'b0001;
                end
            end
        end
    end

endmodule
