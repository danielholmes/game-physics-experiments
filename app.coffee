class SimulationRun
    state: null
    highestX: 0
    t: 0
    integration: null
    accelerant: null
    started: false
    running: false

    constructor: (@state, @integration, @accelerant) ->
        @t = 0

    calculateDt: ->
        throw new Error("No dt method")

    progress: ->
        dt = @calculateDt()
        @performStep(dt)
        if @state.x >= 0
            @scheduleStep()
        else
            @running = false

        # Disruption
        minSecsDisruption = parseFloat($("#minSecsDisruption").val())
        maxSecsDisruption = parseFloat($("#maxSecsDisruption").val())
        range = maxSecsDisruption - minSecsDisruption
        if minSecsDisruption > 0 or range > 0
            disruption = minSecsDisruption + (Math.random() * range)
            endDisruption = (new Date()).getTime() + (disruption * 1000)
            while (new Date()).getTime() < endDisruption
                sleep = true

    performStep: (dt) ->
        @state = @integration(@state, @t, dt, @accelerant)
        @t += dt
        @highestX = Math.max(@highestX, @state.x)

    scheduleStep: ->
        setTimeout( =>
            @progress()
        , @dt * 1000)

    run: -> 
        @started = true
        @running = true
        @highestX = 0
        @scheduleStep()

class FixedStepSimulationRun extends SimulationRun
    constructor: (state, integration, accelerant, @dt) ->
        super(state, integration, accelerant)

    calculateDt: -> @dt

class VariableStepSimulationRun extends SimulationRun
    calculateDt: ->
        newTime = (new Date()).getTime()
        dt = newTime - @lastTime
        @lastTime = newTime
        dt / 1000

    run: ->
        @lastTime = (new Date()).getTime()
        super

class SemiFixedStepSimulationRun extends VariableStepSimulationRun
    maxDt: null

    constructor: (state, integration, accelerant, @maxDt) ->
        super(state, integration, accelerant)

    performStep: (dt) ->
        currentDt = 0
        while currentDt < dt
            stepDt = Math.min(@maxDt, dt - currentDt)
            currentDt += stepDt
            super(stepDt)

# Problem - can be jittery - will go under on some frames
class AccumulatorFixedStepSimulationRun extends VariableStepSimulationRun
    fixedDt: null
    accumulator: 0

    constructor: (state, integration, accelerant, @fixedDt) ->
        super(state, integration, accelerant)

    performStep: (dt) ->
        @accumulator += dt
        while @accumulator >= @fixedDt
            super(@fixedDt)
            @accumulator -= @fixedDt

    run: ->
        @accumulator = 0
        super

class SimSpec
    initialPosition: 0
    initialVelocity: 0
    integrationName: null
    accelerationName: null
    stepName: null
    accelerationStepAmount: null

simSpecs = []
sims = []

addSim = ->
    spec = new SimSpec()
    spec.initialPosition = parseFloat($("#initialPosition").val())
    spec.initialVelocity = parseFloat($("#initialVelocity").val())
    spec.integrationName = $('input[name="integrationType"]:radio:checked').val()
    spec.accelerationName = $('input[name="acceleration"]:radio:checked').val()
    spec.stepName = $('input[name="stepType"]:radio:checked').val()
    if spec.accelerationName is 'constant'
        spec.accelerationStepAmount = $("#accelerationConstantAmount").val()

    console.log(spec.initialPosition)
    simSpecs.push(spec)
    renderSimList()
    sims.push(createSimFromSpec(spec))
    render()
    renderSimList()

start = ->
    sims = (createSimFromSpec(spec) for spec in simSpecs)
    (sim.run() for sim in sims)
    render()
    requestAnimationFrame(render)

createSimFromSpec = (spec) ->
    initialState = new State(spec.initialPosition, spec.initialVelocity)

    integrationType = null
    switch spec.integrationName
        when "euler" then integrationType = eulerIntegration
        when "rk4" then integrationType = rk4Integration

    accelerant = null
    switch spec.accelerationName
        when "constant" then accelerant = constantAccelerant(spec.accelerationStepAmount)
        when "humanOnEarthWithoutAir" then accelerant = constantAccelerant(-9.80665)
        when "humanOnEarth" then accelerant = personFallingThroughAirAcceleration

    switch spec.stepName
        when "fixed" then new FixedStepSimulationRun(initialState, integrationType, accelerant, 0.02)
        when "variable" then new VariableStepSimulationRun(initialState, integrationType, accelerant)
        when "semiFixed" then new SemiFixedStepSimulationRun(initialState, integrationType, accelerant, 0.02)
        when "accumulatorFixed" then new AccumulatorFixedStepSimulationRun(initialState, integrationType, accelerant, 0.02)

renderSimList = ->
    simTableBody = $("#sim-table tbody")
    simTableBody.empty()
    for spec, index in simSpecs
        acceleration = spec.accelerationName
        if spec.accelerationStepAmount?
            acceleration += " (#{spec.accelerationStepAmount})"
        row = $("<tr></tr>")
            .append($("<td>#{spec.initialPosition}</td>"))
            .append($("<td>#{spec.initialVelocity}</td>"))
            .append($("<td>#{spec.integrationName}</td>"))
            .append($("<td>#{acceleration}</td>"))
            .append($("<td>#{spec.stepName}</td>"))
            .append($('<td><a href="#" class="remove">Remove</a></td>'))
            .data("specIndex", index)
            .appendTo(simTableBody)
        sim = sims[index]
        if sim? and sim.started and not sim.running
            row.append($("<td>t:#{sim.t} max:#{sim.highestX} v:#{sim.state.v}</td>"))
        else
            row.append($("<td> </td>"))

render = ->
    pixelsPerMetre = document.getElementById("pixelsPerMetre").value
    canvas = document.getElementById("display")
    context = canvas.getContext("2d")
    context.clearRect 0, 0, canvas.width, canvas.height

    someRunning = false
    for sim, index in sims
        if sim.running
            someRunning = true
        else
            renderSimList()

        context.fillStyle = "hsl(#{Math.round(index * 300 / sims.length)},100%,25%)"
        height = 2
        width = 1
        pixelWidth = width * pixelsPerMetre
        pixelHeight = height * pixelsPerMetre
        x = ((index + 1) * 50) - (pixelWidth / 2)
        y = canvas.height - (sim.state.x * pixelsPerMetre) - pixelHeight
        context.fillRect(x, y, pixelWidth, pixelHeight)

        highestPostionY = canvas.height - (sim.highestX * pixelsPerMetre) - pixelHeight
        context.fillRect(x, highestPostionY, pixelWidth, 1)
        

    if someRunning
        requestAnimationFrame(-> render(sim))


$(document).ready -> 
    $("#run-params").submit ->
        start()
        false

    $("#sim-params").submit ->
        addSim()
        false

    $("#sim-table").on("click", "a.remove", (event) ->
        specIndex = $(event.target).parents("tr").data("specIndex")
        simSpecs.splice(specIndex, 1)
        sims.splice(specIndex, 1)
        renderSimList()
        render()
        false
    )