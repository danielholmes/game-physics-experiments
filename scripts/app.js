// Generated by CoffeeScript 1.6.2
var AccumulatorFixedStepSimulationRun, AccumulatorFixedStepWithApproxSimulationRun, ApproxState, FixedStepSimulationRun, SemiFixedStepSimulationRun, SimSpec, SimulationRun, VariableStepSimulationRun, addSim, createSimFromSpec, render, renderSimList, simSpecs, sims, start, _ref, _ref1,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

SimulationRun = (function() {
  SimulationRun.prototype.state = null;

  SimulationRun.prototype.highestX = 0;

  SimulationRun.prototype.t = 0;

  SimulationRun.prototype.integration = null;

  SimulationRun.prototype.accelerant = null;

  SimulationRun.prototype.started = false;

  SimulationRun.prototype.running = false;

  function SimulationRun(state, integration, accelerant) {
    this.state = state;
    this.integration = integration;
    this.accelerant = accelerant;
    this.t = 0;
  }

  SimulationRun.prototype.calculateDt = function() {
    throw new Error("No dt method");
  };

  SimulationRun.prototype.progress = function() {
    var dt, previousState, previousT;

    previousT = this.t;
    previousState = this.state;
    dt = this.calculateDt();
    this.performStep(dt);
    if (this.state.x >= 0) {
      this.scheduleStep();
      return this.performDisruption();
    } else {
      return this.running = false;
    }
  };

  SimulationRun.prototype.performDisruption = function() {
    var disruption, endDisruption, maxSecsDisruption, minSecsDisruption, range, sleep, _results;

    minSecsDisruption = parseFloat($("#minSecsDisruption").val());
    maxSecsDisruption = parseFloat($("#maxSecsDisruption").val());
    range = maxSecsDisruption - minSecsDisruption;
    if (minSecsDisruption > 0 || range > 0) {
      disruption = minSecsDisruption + (Math.random() * range);
      endDisruption = (new Date()).getTime() + (disruption * 1000);
      _results = [];
      while ((new Date()).getTime() < endDisruption) {
        _results.push(sleep = true);
      }
      return _results;
    }
  };

  SimulationRun.prototype.performStep = function(dt) {
    this.state = this.integration(this.state, this.t, dt, this.accelerant);
    this.t += dt;
    return this.highestX = Math.max(this.highestX, this.state.x);
  };

  SimulationRun.prototype.scheduleStep = function() {
    var _this = this;

    return setTimeout(function() {
      return _this.progress();
    }, this.dt * 1000);
  };

  SimulationRun.prototype.run = function() {
    this.started = true;
    this.running = true;
    this.highestX = 0;
    return this.scheduleStep();
  };

  return SimulationRun;

})();

FixedStepSimulationRun = (function(_super) {
  __extends(FixedStepSimulationRun, _super);

  function FixedStepSimulationRun(state, integration, accelerant, dt) {
    this.dt = dt;
    FixedStepSimulationRun.__super__.constructor.call(this, state, integration, accelerant);
  }

  FixedStepSimulationRun.prototype.calculateDt = function() {
    return this.dt;
  };

  return FixedStepSimulationRun;

})(SimulationRun);

VariableStepSimulationRun = (function(_super) {
  __extends(VariableStepSimulationRun, _super);

  function VariableStepSimulationRun() {
    _ref = VariableStepSimulationRun.__super__.constructor.apply(this, arguments);
    return _ref;
  }

  VariableStepSimulationRun.prototype.calculateDt = function() {
    var dt, newTime;

    newTime = (new Date()).getTime();
    dt = newTime - this.lastTime;
    this.lastTime = newTime;
    return dt / 1000;
  };

  VariableStepSimulationRun.prototype.run = function() {
    this.lastTime = (new Date()).getTime();
    return VariableStepSimulationRun.__super__.run.apply(this, arguments);
  };

  return VariableStepSimulationRun;

})(SimulationRun);

SemiFixedStepSimulationRun = (function(_super) {
  __extends(SemiFixedStepSimulationRun, _super);

  SemiFixedStepSimulationRun.prototype.maxDt = null;

  function SemiFixedStepSimulationRun(state, integration, accelerant, maxDt) {
    this.maxDt = maxDt;
    SemiFixedStepSimulationRun.__super__.constructor.call(this, state, integration, accelerant);
  }

  SemiFixedStepSimulationRun.prototype.performStep = function(dt) {
    var currentDt, stepDt, _results;

    currentDt = 0;
    _results = [];
    while (currentDt < dt) {
      stepDt = Math.min(this.maxDt, dt - currentDt);
      currentDt += stepDt;
      _results.push(SemiFixedStepSimulationRun.__super__.performStep.call(this, stepDt));
    }
    return _results;
  };

  return SemiFixedStepSimulationRun;

})(VariableStepSimulationRun);

AccumulatorFixedStepSimulationRun = (function(_super) {
  __extends(AccumulatorFixedStepSimulationRun, _super);

  AccumulatorFixedStepSimulationRun.prototype.fixedDt = null;

  AccumulatorFixedStepSimulationRun.prototype.accumulator = 0;

  function AccumulatorFixedStepSimulationRun(state, integration, accelerant, fixedDt) {
    this.fixedDt = fixedDt;
    AccumulatorFixedStepSimulationRun.__super__.constructor.call(this, state, integration, accelerant);
  }

  AccumulatorFixedStepSimulationRun.prototype.performStep = function(dt) {
    var _results;

    this.accumulator += dt;
    _results = [];
    while (this.accumulator >= this.fixedDt) {
      AccumulatorFixedStepSimulationRun.__super__.performStep.call(this, this.fixedDt);
      _results.push(this.accumulator -= this.fixedDt);
    }
    return _results;
  };

  AccumulatorFixedStepSimulationRun.prototype.run = function() {
    this.accumulator = 0;
    return AccumulatorFixedStepSimulationRun.__super__.run.apply(this, arguments);
  };

  return AccumulatorFixedStepSimulationRun;

})(VariableStepSimulationRun);

ApproxState = (function(_super) {
  __extends(ApproxState, _super);

  function ApproxState(tempState, dt, fixedState) {
    this.dt = dt;
    this.fixedState = fixedState;
    ApproxState.__super__.constructor.call(this, tempState.x, tempState.v);
  }

  return ApproxState;

})(State);

AccumulatorFixedStepWithApproxSimulationRun = (function(_super) {
  __extends(AccumulatorFixedStepWithApproxSimulationRun, _super);

  function AccumulatorFixedStepWithApproxSimulationRun() {
    _ref1 = AccumulatorFixedStepWithApproxSimulationRun.__super__.constructor.apply(this, arguments);
    return _ref1;
  }

  AccumulatorFixedStepWithApproxSimulationRun.prototype.progress = function() {
    if (this.state instanceof ApproxState) {
      this.accumulator += this.state.dt;
      this.t -= this.state.dt;
      this.state = this.state.fixedState;
    }
    return AccumulatorFixedStepWithApproxSimulationRun.__super__.progress.call(this);
  };

  AccumulatorFixedStepWithApproxSimulationRun.prototype.performStep = function(dt) {
    var remainingDt, tempState;

    AccumulatorFixedStepWithApproxSimulationRun.__super__.performStep.call(this, dt);
    if (this.accumulator > 0) {
      remainingDt = this.accumulator;
      this.accumulator = 0;
      tempState = this.integration(this.state, this.t, remainingDt, this.accelerant);
      this.state = new ApproxState(tempState, remainingDt, this.state);
      return this.t += remainingDt;
    }
  };

  return AccumulatorFixedStepWithApproxSimulationRun;

})(AccumulatorFixedStepSimulationRun);

SimSpec = (function() {
  function SimSpec() {}

  SimSpec.prototype.initialPosition = 0;

  SimSpec.prototype.initialVelocity = 0;

  SimSpec.prototype.integrationName = null;

  SimSpec.prototype.integrationFixedStep = null;

  SimSpec.prototype.accelerationName = null;

  SimSpec.prototype.stepName = null;

  SimSpec.prototype.accelerationStepAmount = null;

  return SimSpec;

})();

simSpecs = [];

sims = [];

addSim = function() {
  var spec;

  spec = new SimSpec();
  spec.initialPosition = parseFloat($("#initialPosition").val());
  spec.initialVelocity = parseFloat($("#initialVelocity").val());
  spec.integrationName = $('input[name="integrationType"]:radio:checked').val();
  spec.integrationFixedStep = parseFloat($("#integrationTypeFixedStep").val());
  spec.accelerationName = $('input[name="acceleration"]:radio:checked').val();
  spec.stepName = $('input[name="stepType"]:radio:checked').val();
  if (spec.accelerationName === 'constant') {
    spec.accelerationStepAmount = parseFloat($("#accelerationConstantAmount").val());
  }
  simSpecs.push(spec);
  renderSimList();
  sims.push(createSimFromSpec(spec));
  render();
  return renderSimList();
};

start = function() {
  var sim, spec, _i, _len;

  sims = (function() {
    var _i, _len, _results;

    _results = [];
    for (_i = 0, _len = simSpecs.length; _i < _len; _i++) {
      spec = simSpecs[_i];
      _results.push(createSimFromSpec(spec));
    }
    return _results;
  })();
  for (_i = 0, _len = sims.length; _i < _len; _i++) {
    sim = sims[_i];
    sim.run();
  }
  render();
  return requestAnimationFrame(render);
};

createSimFromSpec = function(spec) {
  var accelerant, initialState, integrationType;

  initialState = new State(spec.initialPosition, spec.initialVelocity);
  integrationType = null;
  switch (spec.integrationName) {
    case "euler":
      integrationType = eulerIntegration;
      break;
    case "rk4":
      integrationType = rk4Integration;
  }
  accelerant = null;
  switch (spec.accelerationName) {
    case "constant":
      accelerant = constantAccelerant(spec.accelerationStepAmount);
      break;
    case "humanOnEarthWithoutAir":
      accelerant = constantAccelerant(-9.80665);
      break;
    case "humanOnEarth":
      accelerant = personFallingThroughAirAcceleration;
  }
  switch (spec.stepName) {
    case "fixed":
      return new FixedStepSimulationRun(initialState, integrationType, accelerant, spec.integrationFixedStep);
    case "variable":
      return new VariableStepSimulationRun(initialState, integrationType, accelerant);
    case "semiFixed":
      return new SemiFixedStepSimulationRun(initialState, integrationType, accelerant, spec.integrationFixedStep);
    case "accumulatorFixed":
      return new AccumulatorFixedStepSimulationRun(initialState, integrationType, accelerant, spec.integrationFixedStep);
    case "accumulatorFixedWithApprox":
      return new AccumulatorFixedStepWithApproxSimulationRun(initialState, integrationType, accelerant, spec.integrationFixedStep);
  }
};

renderSimList = function() {
  var acceleration, index, row, sim, simTableBody, spec, _i, _len, _results;

  simTableBody = $("#sim-table tbody");
  simTableBody.empty();
  _results = [];
  for (index = _i = 0, _len = simSpecs.length; _i < _len; index = ++_i) {
    spec = simSpecs[index];
    acceleration = spec.accelerationName;
    if (spec.accelerationStepAmount != null) {
      acceleration += " (" + spec.accelerationStepAmount + ")";
    }
    row = $("<tr></tr>").append($("<td>" + spec.initialPosition + "</td>")).append($("<td>" + spec.initialVelocity + "</td>")).append($("<td>" + spec.integrationName + "</td>")).append($("<td>" + acceleration + "</td>")).append($("<td>" + spec.stepName + "  " + spec.integrationFixedStep + "</td>")).append($('<td><a href="#" class="remove">Remove</a></td>')).data("specIndex", index).appendTo(simTableBody);
    sim = sims[index];
    if ((sim != null) && sim.started && !sim.running) {
      _results.push(row.append($("<td>t:" + sim.t + " max:" + sim.highestX + " v:" + sim.state.v + "</td>")));
    } else {
      _results.push(row.append($("<td> </td>")));
    }
  }
  return _results;
};

render = function() {
  var canvas, context, groundPixels, height, highestPostionY, index, pixelHeight, pixelWidth, pixelsPerMetre, sim, someRunning, width, x, y, _i, _len;

  pixelsPerMetre = document.getElementById("pixelsPerMetre").value;
  canvas = document.getElementById("display");
  context = canvas.getContext("2d");
  context.clearRect(0, 0, canvas.width, canvas.height);
  groundPixels = 20;
  context.fillStyle = "#000000";
  context.fillRect(0, canvas.height - groundPixels, canvas.width, 1);
  someRunning = false;
  for (index = _i = 0, _len = sims.length; _i < _len; index = ++_i) {
    sim = sims[index];
    if (sim.running) {
      someRunning = true;
    } else {
      renderSimList();
    }
    context.fillStyle = "hsl(" + (Math.round(index * 300 / sims.length)) + ",100%,25%)";
    height = 2;
    width = 1;
    pixelWidth = width * pixelsPerMetre;
    pixelHeight = height * pixelsPerMetre;
    x = ((index + 1) * 50) - (pixelWidth / 2);
    y = canvas.height - (sim.state.x * pixelsPerMetre) - pixelHeight - groundPixels;
    context.fillRect(x, y, pixelWidth, pixelHeight);
    highestPostionY = canvas.height - (sim.highestX * pixelsPerMetre) - pixelHeight - groundPixels;
    context.fillRect(x, highestPostionY, pixelWidth, 1);
  }
  if (someRunning) {
    return requestAnimationFrame(function() {
      return render(sim);
    });
  }
};

$(document).ready(function() {
  if (window.requestAnimationFrame == null) {
    window.requestAnimationFrame = window.webkitRequestAnimationFrame || window.mozRequestAnimationFrame || window.oRequestAnimationFrame || window.msRequestAnimationFrame || function(callback, element) {
      return setTimeout(callback, 1000 / 60);
    };
  }
  $("#run-params").submit(function() {
    start();
    return false;
  });
  $("#sim-params").submit(function() {
    addSim();
    return false;
  });
  return $("#sim-table").on("click", "a.remove", function(event) {
    var specIndex;

    specIndex = $(event.target).parents("tr").data("specIndex");
    simSpecs.splice(specIndex, 1);
    sims.splice(specIndex, 1);
    renderSimList();
    render();
    return false;
  });
});
