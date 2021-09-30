using BrazilianPowerModels
using PowerModels
using JuMP

using Test

using Ipopt

@testset begin
    include("test_slacks.jl")
end