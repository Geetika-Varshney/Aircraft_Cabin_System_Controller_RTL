// command_latch.v
// Latches + edge-detects commands into clean one-cycle pulses (avionics-style sampling)

module command_latch (
    input  wire clk,
    input  wire reset_n,
    input  wire allow_cmds,        // 1 = commands accepted
    input  wire seatbelt_cmd,      // raw command input
    input  wire lighting_cmd,      // raw command input
    output wire seatbelt_pulse,    // 1-cycle rising-edge pulse
    output wire lighting_pulse     // 1-cycle rising-edge pulse
);
    reg seatbelt_prev;
    reg lighting_prev;

    always @(posedge clk) begin
        if (!reset_n) begin
            seatbelt_prev <= 1'b0;
            lighting_prev <= 1'b0;
        end else if (allow_cmds) begin
            seatbelt_prev <= seatbelt_cmd;
            lighting_prev <= lighting_cmd;
        end
        // If allow_cmds=0, we freeze prev values (no edge detection)
    end

    assign seatbelt_pulse = allow_cmds && seatbelt_cmd && !seatbelt_prev;
    assign lighting_pulse = allow_cmds && lighting_cmd && !lighting_prev;

endmodule
