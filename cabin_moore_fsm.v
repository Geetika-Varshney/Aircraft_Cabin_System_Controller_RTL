// cabin_moore_fsm.v
// Moore FSM controlling cabin rules by flight phase, with fault-safe + maintenance mode.

module cabin_moore_fsm (
    input  wire       clk,
    input  wire       reset_n,
    input  wire       en,            // when 0, freeze state (maintenance freeze)
    input  wire [2:0] flight_phase,
    input  wire       phase_stable,
    input  wire       fault_detected,
    input  wire       maintenance_mode,

    output reg        system_locked,
    output reg        seatbelt_force_on,
    output reg        lighting_force_en,
    output reg  [1:0] lighting_forced_mode,
    output reg        fault_alert,
    output reg  [3:0] state_debug
);
    // State encoding
    localparam [3:0]
        S_GROUND          = 4'd0,
        S_TAXI            = 4'd1,
        S_TAKEOFF_LOCKED  = 4'd2,
        S_CLIMB           = 4'd3,
        S_CRUISE          = 4'd4,
        S_DESCENT         = 4'd5,
        S_LANDING_LOCKED  = 4'd6,
        S_FAULT_SAFE      = 4'd7,
        S_MAINTENANCE     = 4'd8;

    reg [3:0] state, next_state;

    // State register
    always @(posedge clk) begin
        if (!reset_n)
            state <= S_GROUND;
        else if (!en)
            state <= state; // freeze
        else
            state <= next_state;
    end

    // Next-state logic
    always @(*) begin
        next_state = state;

        // Highest priority: maintenance mode state
        if (maintenance_mode)
            next_state = S_MAINTENANCE;
        // Next priority: fault-safe
        else if (fault_detected)
            next_state = S_FAULT_SAFE;
        else if (!phase_stable) begin
            // If phase not stable, hold current state (prevents glitches)
            next_state = state;
        end else begin
            // phase-based transitions (only when stable)
            case (flight_phase)
                3'b000: next_state = S_GROUND;
                3'b001: next_state = S_TAXI;
                3'b010: next_state = S_TAKEOFF_LOCKED;
                3'b011: next_state = S_CLIMB;
                3'b100: next_state = S_CRUISE;
                3'b101: next_state = S_DESCENT;
                3'b110: next_state = S_LANDING_LOCKED;
                default: next_state = S_FAULT_SAFE; // invalid phase treated as fault-safe
            endcase
        end
    end

    // Output logic (Moore: depends on state only)
    always @(*) begin
        // defaults
        system_locked        = 1'b0;
        seatbelt_force_on    = 1'b0;
        lighting_force_en    = 1'b0;
        lighting_forced_mode = 2'b01; // DIM default
        fault_alert          = 1'b0;

        case (state)
            S_GROUND: begin
                system_locked     = 1'b0;
                seatbelt_force_on = 1'b0;
                lighting_force_en = 1'b0; // allow user lighting cycle
            end

            S_TAXI: begin
                system_locked     = 1'b0; // allow lighting but seatbelt forced on
                seatbelt_force_on = 1'b1;
                lighting_force_en = 1'b1;
                lighting_forced_mode = 2'b01; // DIM
            end

            S_TAKEOFF_LOCKED: begin
                system_locked     = 1'b1;
                seatbelt_force_on = 1'b1;
                lighting_force_en = 1'b1;
                lighting_forced_mode = 2'b01; // DIM
            end

            S_CLIMB: begin
                system_locked     = 1'b1; // still locked for climb (safety)
                seatbelt_force_on = 1'b1;
                lighting_force_en = 1'b1;
                lighting_forced_mode = 2'b01; // DIM
            end

            S_CRUISE: begin
                system_locked     = 1'b0;
                seatbelt_force_on = 1'b0;   // allow toggle in cruise
                lighting_force_en = 1'b0;   // allow user lighting cycle
            end

            S_DESCENT: begin
                system_locked     = 1'b0; // allow limited commands, but seatbelt forced on
                seatbelt_force_on = 1'b1;
                lighting_force_en = 1'b1;
                lighting_forced_mode = 2'b01; // DIM
            end

            S_LANDING_LOCKED: begin
                system_locked     = 1'b1;
                seatbelt_force_on = 1'b1;
                lighting_force_en = 1'b1;
                lighting_forced_mode = 2'b01; // DIM
            end

            S_FAULT_SAFE: begin
                system_locked     = 1'b1;
                seatbelt_force_on = 1'b1;
                lighting_force_en = 1'b1;
                lighting_forced_mode = 2'b11; // EMERGENCY
                fault_alert       = 1'b1;
            end

            S_MAINTENANCE: begin
                // Freeze mode: we still expose safe-ish outputs; top-level freeze keeps outputs steady anyway
                system_locked     = 1'b1;
                seatbelt_force_on = 1'b1;
                lighting_force_en = 1'b1;
                lighting_forced_mode = 2'b10; // BRIGHT for maintenance
                fault_alert       = 1'b0;
            end

            default: begin
                system_locked     = 1'b1;
                seatbelt_force_on = 1'b1;
                lighting_force_en = 1'b1;
                lighting_forced_mode = 2'b11;
                fault_alert       = 1'b1;
            end
        endcase
    end

    always @(*) begin
        state_debug = state;
    end

endmodule
