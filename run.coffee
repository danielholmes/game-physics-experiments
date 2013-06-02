class State
    x: null
    v: null
    constructor: (@x, @v) ->

class Derivative
    dx: null
    dv: null
    constructor: (@dx = 0, @dv = 0) ->

eulerIntegration = (state, t, dt, accelerant) ->
    ###
    force = 10
    mass = 1
    accel = force / mass
    ###
    acceleration = accelerant(state, t)
    new State(
        state.x + state.v * dt,
        state.v + (acceleration * dt)
    )

constantAccelerant = (amount) ->
    (state, t) -> amount

pendulumAcceleration = (state, t) ->
    k = 10
    b = 1
    (-k * state.x) - (b * state.v)

personFallingThroughAirAcceleration = (state, t) ->
    gravity = 9.80665
    mass = 75

    weightForce = mass * gravity

    dragCoefficient = 0.5
    airDensity = 1.2
    frontalArea = 0.7
    dragForce = (1 / 2) * dragCoefficient * airDensity * frontalArea * Math.pow(state.v, 2)

    (weightForce - dragForce) / mass

rk4Evaluate = (initial, t, dt, derivative, accelerant) ->
    state = new State(initial.x + (derivative.dx * dt), initial.v + (derivative.dv * dt))
    new Derivative(state.v, accelerant(state, t + dt))

rk4Integration = (state, t, dt, accelerant) ->
    a = rk4Evaluate(state, t, 0.0, new Derivative(), accelerant);
    b = rk4Evaluate(state, t, dt * 0.5, a, accelerant)
    c = rk4Evaluate(state, t, dt * 0.5, b, accelerant)
    d = rk4Evaluate(state, t, dt, c, accelerant)

    dxdt = 1.0 / 6.0 * (a.dx + 2.0 * (b.dx + c.dx) + d.dx)
    dvdt = 1.0 / 6.0 * (a.dv + 2.0 * (b.dv + c.dv) + d.dv)

    new State(
        state.x + (dxdt * dt),
        state.v + (dvdt * dt)
    )

run = (integration, endTime, timeStep, accelerant, stepLogger = ->) ->
    time = 0

    state = new State(0, 0)

    while time < endTime
        useTimeStep = Math.min(endTime - time, timeStep)
        state = integration(state, time, useTimeStep, accelerant)
        stepLogger("Step[#{time}] x:#{state.x} v:#{state.v}")
        time += useTimeStep

    state

# See http://www.calctool.org/CALC/eng/aerospace/terminal
# Density of air at different temperatures: http://en.wikipedia.org/wiki/Density_of_air
# Mass in kg
# area in m^3
# downwardsAcceleration in m.s^2
terminalVelocity = (mass, area, downwardsAcceleration) -> 
    dragCoefficient = 0.5
    mediumDensity = 1.2 # kg / m^3

    cda = area * dragCoefficient

    return Math.sqrt(2 * mass * downwardsAcceleration / (mediumDensity * cda))

# NOTE: These don't account for wind resistance and terminal velocity
# T.V for a human is approx 55 m/s (200 km/h), higher for aerodynamic poses
# It's when the force from wind resistance = gravity, therefore total acceleration becoming zero
console.log "Euler Constant a: ", run(eulerIntegration, 10, 0.1, constantAccelerant(10))
console.log "RK4 Constant a:   ", run(rk4Integration, 10, 0.1, constantAccelerant(10))

# Empire state refers to the fact that falling from it (381m) takes 8.81 seconds if there's no air resistance
console.log "Empire State (no air resistance) Euler:", run(eulerIntegration, 8.81, 0.1, constantAccelerant(9.80665))
console.log "Empire State (no air resistance) RK4:  ", run(rk4Integration, 8.81, 0.1, constantAccelerant(9.80665))
console.log "Empire State (with air resistance) Euler:", run(eulerIntegration, 8.81, 0.1, personFallingThroughAirAcceleration)
console.log "Empire State (with air resistance) RK4:  ", run(rk4Integration, 8.81, 0.1, personFallingThroughAirAcceleration)
console.log "TV of skydiver (should be approx 59m/s):", terminalVelocity(75, 0.7, 9.80665)
console.log "Skydiver falling to TV:", run(rk4Integration, 20, 1, personFallingThroughAirAcceleration, console.log)