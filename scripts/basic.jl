# using Packages
using PowerModels, Ipopt, JuMP
using PWF

# Include ControlPowerFlow module
include("../src/ControlPowerFlow.jl")
ipopt = optimizer_with_attributes(Ipopt.Optimizer, "tol"=>0.001, "max_iter"=>100) 
# PWF system file
file = "scripts\\data\\pwf\\EMS\\EMS_base_fora_ponta.PWF"

# Reading PWF and converting to PowerModels network data dictionary
software = ControlPowerFlow.ParserPWF.Organon
add_control_data = true
m = Model()
result = ControlPowerFlow.run_pf(file, ControlPowerFlow.ControlACPPowerModel, ipopt, ControlPowerFlow.build_pf; software = software, add_control_data = add_control_data, jump_model = m)

print(m)

result["solution"]["shunt"]