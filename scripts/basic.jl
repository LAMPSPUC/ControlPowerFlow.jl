# using Packages
using PowerModels, Ipopt, JuMP
using ParserPWF

# Include ControlPowerFlow module
include("../src/ControlPowerFlow.jl")
ipopt = optimizer_with_attributes(Ipopt.Optimizer, "tol"=>0.001) 
# PWF system file
file = "scripts\\data\\pwf\\3busfrank.pwf"

# Reading PWF and converting to PowerModels network data dictionary
software = ControlPowerFlow.ParserPWF.Organon
add_control_data = true
m = Model()
result = ControlPowerFlow.run_pf(file, ControlPowerFlow.ControlACPPowerModel, ipopt, ControlPowerFlow.build_pf; software = software, add_control_data = add_control_data, jump_model = m)

print(m)

result["solution"]["shunt"]