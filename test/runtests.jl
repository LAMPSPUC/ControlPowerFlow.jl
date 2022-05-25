using ControlPowerFlow
using PowerModels
using JuMP
using Test
using Ipopt
using PWF

# test parameters
ipopt = optimizer_with_attributes(Ipopt.Optimizer, "tol" => 0.0001, "print_level" => 0)
tol = 1e-3
anarede = PWF.ANAREDE
organon = PWF.Organon

@testset begin
    # control structure verifications
    include("actions.jl")
    # create control from control_info
    include("control_info.jl")
    # create control from generic_info
    include("generic_info.jl")
    # create control from anarede defaults
    @testset "Anarede Controls" begin
        include("anarede_acp.jl")
        include("anarede_acr.jl")
        include("anarede_ivr.jl")
    end
    # create control from custom defaults
    include("custom.jl")
end