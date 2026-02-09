`timescale 1ns/1ps

module tb_cabin_system;

  // -----------------------------
  // Clock + Reset
  // -----------------------------
  logic clk;
  logic reset_n;

  // -----------------------------
  // Inputs to DUT
  // -----------------------------
  logic [2:0] flight_phase;        // 000=GROUND, 001=TAXI, 010=TAKEOFF, 011=CLIMB, 100=CRUISE, 101=DESCENT, 110=LANDING
  logic       lighting_cmd;        // pulses to cycle lighting mode in CRUISE
  logic       fault_detected;      // emergency/fault trigger
  logic       maintenance_mode;    // freezes updates when asserted

  // -----------------------------
  // Outputs from DUT
  // -----------------------------
  logic       system_locked;
  logic       seatbelt_on;
  logic [1:0] lighting_mode;       // 00=OFF, 01=DIM, 10=BRIGHT, 11=EMERGENCY
  logic       fault_alert;
  logic [3:0] state_debug;

  // -----------------------------
  // DUT Instance
  // -----------------------------
  cabin_system_top dut (
    .clk(clk),
    .reset_n(reset_n),
    .flight_phase(flight_phase),
    .lighting_cmd(lighting_cmd),
    .fault_detected(fault_detected),
    .maintenance_mode(maintenance_mode),
    .system_locked(system_locked),
    .seatbelt_on(seatbelt_on),
    .lighting_mode(lighting_mode),
    .fault_alert(fault_alert),
    .state_debug(state_debug)
  );

  // -----------------------------
  // Clock generation: 100 MHz
  // -----------------------------
  initial clk = 0;
  always #5 clk = ~clk;  // 10ns period

  // -----------------------------
  // Helper tasks
  // -----------------------------
  task automatic pulse_lighting_cmd();
    begin
      lighting_cmd = 1;
      @(posedge clk);
      lighting_cmd = 0;
    end
  endtask

  task automatic go_phase(input logic [2:0] ph, input string label);
    begin
      $display("[%0t] PHASE -> %s (%0d)", $time, label, ph);
      flight_phase = ph;
      // give time for phase_stabilizer + FSM to react
      repeat (25) @(posedge clk);
    end
  endtask

  // -----------------------------
  // Test sequence
  // -----------------------------
  initial begin
    // Init inputs
    reset_n          = 0;
    flight_phase     = 3'b000; // GROUND
    lighting_cmd     = 0;
    fault_detected   = 0;
    maintenance_mode = 0;

    // Reset
    $display("[%0t] Applying reset...", $time);
    repeat (5) @(posedge clk);
    reset_n = 1;
    $display("[%0t] Release reset.", $time);

    // Let system settle
    repeat (20) @(posedge clk);

    // -----------------------------
    // Normal flight sequence
    // -----------------------------
    go_phase(3'b000, "GROUND");
    go_phase(3'b001, "TAXI");
    go_phase(3'b010, "TAKEOFF");  // expect locked + seatbelt ON
    go_phase(3'b011, "CLIMB");
    go_phase(3'b100, "CRUISE");   // expect unlocked; allow lighting cycling

    // Lighting cycling in CRUISE (OFF->DIM->BRIGHT->OFF...)
    $display("[%0t] Cycling lighting in CRUISE...", $time);
    pulse_lighting_cmd();
    repeat (60) @(posedge clk);  // timer delay
    pulse_lighting_cmd();
    repeat (60) @(posedge clk);
    pulse_lighting_cmd();
    repeat (60) @(posedge clk);

    go_phase(3'b101, "DESCENT");
    go_phase(3'b110, "LANDING"); // expect locked + seatbelt ON again

    // -----------------------------
    // Fault injection (emergency lighting)
    // -----------------------------
    $display("[%0t] Injecting fault...", $time);
    fault_detected = 1;
    repeat (10) @(posedge clk);
    fault_detected = 0;
    repeat (30) @(posedge clk);

    // -----------------------------
    // Maintenance mode freeze test
    // -----------------------------
    $display("[%0t] Entering maintenance mode...", $time);
    maintenance_mode = 1;
    // Try to change phase + lighting during maintenance; design should freeze
    flight_phase = 3'b100;
    pulse_lighting_cmd();
    repeat (50) @(posedge clk);

    $display("[%0t] Exiting maintenance mode...", $time);
    maintenance_mode = 0;
    repeat (30) @(posedge clk);

    // End sim
    $display("[%0t] Simulation complete.", $time);
    $finish;
  end

endmodule
