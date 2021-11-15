using ControlPowerFlow
using PowerModels
using JuMP
using Test
using Ipopt

# test parameters
ipopt = optimizer_with_attributes(Ipopt.Optimizer, "tol" => 0.0001, "print_level" => 0)
tol = 1e-3

@testset begin
    include("actions.jl")
    include("control_info.jl")
    include("generic_info.jl")
    include("anarede.jl")
    include("custom.jl")
end