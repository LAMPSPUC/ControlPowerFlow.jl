# using Packages
using PowerModels, Ipopt, JuMP
using ParserPWF

# Include ControlPowerFlow module
include("src/ControlPowerFlow.jl")

# PWF system file
file = "scripts\\data\\pwf\\3busfrank.pwf"

# Reading PWF and converting to PowerModels network data dictionary
network = ControlPowerFlow.ParserPWF.parse_pwf_to_powermodels(file)


network_pwf = deepcopy(network)

slack = Dict(
    "slack" => Dict(
        # "constraint_voltage_bounds"                => true,
        # "constraint_theta_ref"                     => true,
        # "constraint_voltage_magnitude_setpoint"    => true,
        # "constraint_gen_setpoint_active"           => true,
        # "constraint_gen_setpoint_reactive"         => true,
        # "constraint_gen_reactive_bounds"           => true,
        # "constraint_power_balance_active"          => true,
        # "constraint_power_balance_reactive"        => true,
        # "constraint_shunt"                         => true,
        # "constraint_dcline_setpoint_active_fr"     => true,
        # "constraint_dcline_setpoint_active_to"     => true,
    )
)

ControlPowerFlow._PM.update_data!(network_pwf, slack)
network_pwf["slack"]

solver = optimizer_with_attributes(Ipopt.Optimizer, "tol" => 1e-8)
include("src/ControlPowerFlow.jl")
pm = ControlPowerFlow._PM.instantiate_model(network_pwf, ACPPowerModel, ControlPowerFlow.build_br_pf);
print(pm.model)

result = ControlPowerFlow.run_br_pf(network_pwf, solver);

result["solution"]["bus"]["1"]

control = Dict(
    "control" => Dict(
        # "voltage"      => true,
        # "gen_active"   => true,
        # "gen_reactive" => true,
        # "shunt"        => true,
        # "tap"          => true,
    )
)

control_functions = Dict(
    "voltage"       => (control_voltage_bounds),
    "gen_active"    => (control_gen_active_bounds),
    "gen_reactive"  => (control_gen_reactive_bounds),
    "shunt"         => (control_shunt_bounds),
    "tap"           => (control_tap_bounds),
)

