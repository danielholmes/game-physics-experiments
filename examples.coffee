runSim = (integration, endTime, timeStep, accelerant) ->
    time = 0
    state = new State(0, 0)

    while time < endTime
        useTimeStep = Math.min(endTime - time, timeStep)
        state = integration(state, time, useTimeStep, accelerant)
        time += useTimeStep

    state

$(document).ready ->
    # NOTE: These don't account for wind resistance and terminal velocity
    # T.V for a human is approx 55 m/s (200 km/h), higher for aerodynamic poses
    # It's when the force from wind resistance = gravity, therefore total acceleration becoming zero
    examples = {
        "Euler Constant a": runSim(eulerIntegration, 10, 0.1, constantAccelerant(-10)),
        "RK4 Constant a":   runSim(rk4Integration, 10, 0.1, constantAccelerant(-10)),

        # Empire state refers to the fact that falling from it (381m) takes 8.81 seconds if there's no air resistance
        "Empire State (no air resistance) Euler: ": runSim(eulerIntegration, 8.81, 0.1, constantAccelerant(-9.80665)),
        "Empire State (no air resistance) RK4:   ": runSim(rk4Integration, 8.81, 0.1, constantAccelerant(-9.80665)),
        "Empire State (with air resistance) Euler: ": runSim(eulerIntegration, 8.81, 0.1, personFallingThroughAirAcceleration),
        "Empire State (with air resistance) RK4:   ": runSim(rk4Integration, 8.81, 0.1, personFallingThroughAirAcceleration),
        "TV of skydiver (should be approx 59m/s): ": terminalVelocity(75, 0.7, 9.80665),
        "Skydiver falling to TV: ": runSim(rk4Integration, 20, 1, personFallingThroughAirAcceleration)
    }
    table = $("<table></table>")
    for label, value of examples
        $("<tr></tr>").append($("<td></td>").html(label))
            .append($("<td></td>").html("#{value}"))
            .appendTo(table)
    $("#result").append(table)