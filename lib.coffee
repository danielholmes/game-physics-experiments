class State
    constructor: (@x = 0, @v = 0) ->
    toString: -> "{x: #{@x.toPrecision(6)}, v: #{@v.toPrecision(6)}}"

class Derivative
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
    gravity = -9.80665
    mass = 75

    weightForce = mass * gravity
    currentDirection = 0
    if state.v isnt 0
        currentDirection = state.v / Math.abs(state.v)

    dragForceDirection = -1 * currentDirection
    dragCoefficient = 0.5
    airDensity = 1.2
    frontalArea = 0.7
    dragForce = dragForceDirection * (1 / 2) * dragCoefficient * airDensity * frontalArea * Math.pow(state.v, 2)

    (dragForce + weightForce) / mass

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

# See http://www.calctool.org/CALC/eng/aerospace/terminal
# Density of air at different temperatures: http://en.wikipedia.org/wiki/Density_of_air
# Mass in kg
# area in m^3
# downwardsAcceleration in m.s^2
terminalVelocity = (mass, area, downwardsAcceleration) -> 
    dragCoefficient = 0.5
    mediumDensity = 1.2 # kg / m^3

    cda = area * dragCoefficient

    Math.sqrt(2 * mass * downwardsAcceleration / (mediumDensity * cda))