# using Packages
using PowerModels, Ipopt, JuMP
using PWF

# Include ControlPowerFlow module
include("../src/ControlPowerFlow.jl")
include("auxiliar.jl")
ipopt = optimizer_with_attributes(Ipopt.Optimizer,"max_iter"=>300, "tol"=>0.001) 
# PWF system file
file = "scripts\\data\\pwf\\franks\\6busfrank.PWF"

# Reading PWF and converting to PowerModels network data dictionary
data = PWF.parse_file(file, pm = true, add_control_data = true)
network = deepcopy(data)
