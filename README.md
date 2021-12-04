# ControlPowerFlow.jl

A package for performing AC power flow with control actions using ANAREDE file.

In large-scale power systems, controllable elements are included in the system to improve voltage profiles in stress situations.

The default control options were inspired in ANAREDE software and they are:

- Reactive Generation Limits (QLIM)
- Voltage Magnitude Limits (VLIM)
- Automatic Reactor Control (CSCA)
- Automatic OLTC transformer control (CTAP/CTAF)
- Automatic Phase-Shifting control (CPHS)

Additionally the package allow user to create its own control action.

The control actions are achieved through modification in the original power flow formulations, provided by PowerModels.jl. The resultant model is a OPF which is solved through NLP Solvers.

Fore more information visit ADD REFS

Powered by PowerModels.jl, JuMP.jl and PWF.jl

PACKAGE IN CONSTRUCTION
