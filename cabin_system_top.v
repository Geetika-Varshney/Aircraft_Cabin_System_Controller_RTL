`timescale 1ns / 1ps
// cabin_system_top.v
// Top-level integrated cabin controller system

module cabin_system_top (
    input  wire       clk,
    input  wire       reset_n,

    input  wire [2:0] flight_phase,
    input  wire       seatbelt_cmd,
    input  wire       lighting_cmd,
    input  wire       maintenance_mode,
    input  wire       fault_detected,

    output wire       seatbelt_on,
    output wire [1:0] lighting_mode,
    output wire       system_locked,
    output wire       fault_alert,
    output wire       phase_stable,
    output wire [3:0] state_debug
);

    // Global enable (freeze everything in maintenance)
    wire sys_en = ~maintenance_mode;

    // Phase stabilization
    phase_stabilizer #(.STABLE_CYCLES(6)) u_phase_stable (
        .clk(clk),
        .reset_n(reset_n),
        .en(sys_en),
        .flight_phase(flight_phase),
        .phase_stable(phase_stable)
    );

    // FSM control outputs
    wire fsm_locked;
    wire seatbelt_force_on;
    wire lighting_force_en;
    wire [1:0] lighting_forced_mode;

    cabin_moore_fsm u_fsm (
        .clk(clk),
        .reset_n(reset_n),
        .en(sys_en),
        .flight_phase(flight_phase),
        .phase_stable(phase_stable),
        .fault_detected(fault_detected),
        .maintenance_mode(maintenance_mode),
        .system_locked(fsm_locked),
        .seatbelt_force_on(seatbelt_force_on),
        .lighting_force_en(lighting_force_en),
        .lighting_forced_mode(lighting_forced_mode),
        .fault_alert(fault_alert),
        .state_debug(state_debug)
    );

    assign system_locked = fsm_locked;

    // Allow commands only when:
    // - not locked
    // - phase stable
    // - not in maintenance
    // - not in fault-safe (locked anyway)
    wire allow_cmds = sys_en && phase_stable && !fsm_locked;

    // Command pulses
    wire seatbelt_pulse;
    wire lighting_pulse;

    command_latch u_cmds (
        .clk(clk),
        .reset_n(reset_n),
        .allow_cmds(allow_cmds),
        .seatbelt_cmd(seatbelt_cmd),
        .lighting_cmd(lighting_cmd),
        .seatbelt_pulse(seatbelt_pulse),
        .lighting_pulse(lighting_pulse)
    );

    // Seatbelt state register (toggle behavior in cruise/ground when allowed)
    reg seatbelt_state;

    always @(posedge clk) begin
        if (!reset_n) begin
            seatbelt_state <= 1'b1; // default ON at reset
        end else if (!sys_en) begin
            seatbelt_state <= seatbelt_state; // freeze in maintenance
        end else begin
            if (seatbelt_force_on)
                seatbelt_state <= 1'b1;
            else if (seatbelt_pulse)
                seatbelt_state <= ~seatbelt_state; // toggle when allowed
        end
    end

    assign seatbelt_on = seatbelt_state;

    // Lighting mode register
    // Option B: OFF -> DIM -> BRIGHT -> OFF (only when allowed + after delay)
    reg [1:0] lighting_state;

    // Start a transition timer when a lighting command pulse arrives
    wire lighting_delay_done;

    lighting_transition_timer #(.DELAY_CYCLES(5)) u_light_delay (
        .clk(clk),
        .reset_n(reset_n),
        .en(sys_en),
        .start(lighting_pulse),
        .done(lighting_delay_done)
    );

    // Apply forced lighting mode (from FSM) OR cycle mode after delay completes
    always @(posedge clk) begin
        if (!reset_n) begin
            lighting_state <= 2'b01; // DIM default
        end else if (!sys_en) begin
            lighting_state <= lighting_state; // freeze in maintenance
        end else begin
            if (lighting_force_en) begin
                lighting_state <= lighting_forced_mode;
            end else begin
                // If not forced, we cycle ONLY when the delayed "done" hits
                if (lighting_delay_done) begin
                    case (lighting_state)
                        2'b00: lighting_state <= 2'b01; // OFF -> DIM
                        2'b01: lighting_state <= 2'b10; // DIM -> BRIGHT
                        2'b10: lighting_state <= 2'b00; // BRIGHT -> OFF
                        default: lighting_state <= 2'b00;
                    endcase
                end
            end
        end
    end

    assign lighting_mode = lighting_state;

endmodule
