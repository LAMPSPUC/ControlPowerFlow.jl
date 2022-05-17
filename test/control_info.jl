@testset "Control from control_info" begin

    file = joinpath(@__DIR__, "data/3busfrank_continuous_shunt.pwf")
    data = PWF.parse_pwf_to_powermodels(file; add_control_data = true)

    control_info = Dict(
        "control_info" => Dict{Any, Any}(
            :controllable_bus => false,
            :control_variables => Dict{Any, Any}(
                "generic_variable" => Dict{Any, Any}(
                    "name" => "generic_variable",
                    "variable" => "generic_variable",
                    "element" => :bus, # key where the final value of the variable will be placed in the result dictionary
                    "indexes" => [1,2,3], # exact keys of the variables
                    "start" => [0.0, 0.0, 0.0]
                ),
                "shunt" => Dict{Any, Any}(
                    "name" => "shunt",
                    "variable" => "bs",
                    "element" => :shunt,
                    "indexes" => [1],
                    "start" => [0.0]
                ),
                "shift" => Dict{Any, Any}(
                    "name" => "shift",
                    "variable" => "shift",
                    "element" => :branch,
                    "indexes" => [1, 3],
                    "start" => [0.0, 0.0]
                ),
                "tap" => Dict{Any, Any}(
                    "name" => "tap",
                    "variable" => "tap",
                    "element" => :branch,
                    "indexes" => [1],
                    "start" => [0.0]
                )
            ),
            :control_constraints => Dict{Any, Any}(
                "constraint_voltage_magnitude_bounds" => Dict{Any, Any}(
                    "name" => "constraint_voltage_magnitude_bounds",
                    "element" => :bus,
                    "indexes" => [3],
                )
            ),
            :control_slacks => Dict{Any, Any}(
                "constraint_voltage_magnitude_bounds" => Dict{Any, Any}(
                    "name" => "constraint_voltage_magnitude_bounds",
                    "variable" => "con_vol_mag_bou",
                    "weight" => 1.0,
                    "element" => :bus,
                    "indexes" => [3],
                    "type" => :bound
                )
            )
        )
    )

    ControlPowerFlow.set_control_info!(data, control_info)

    pm = PowerModels.instantiate_model(data, ControlPowerFlow.ControlACPPowerModel, ControlPowerFlow.build_pf)

    # New Control Variables
    @test length(var(pm, :generic_variable)) == 3
    @test length(var(pm, :bs)) == 1
    @test length(var(pm, :tap)) == 1
    @test length(var(pm, :shift)) == 2
    
    # Slack Variables 
    @test length(var(pm, :sl_con_vol_mag_bou_low)) == 1
    @test length(var(pm, :sl_con_vol_mag_bou_upp)) == 1

    set_optimizer(pm.model, ipopt)
    result = optimize_model!(pm)

    @test termination_status(pm.model) == MOI.LOCALLY_SOLVED

    @test haskey(result["solution"]["bus"]["1"], "generic_variable")
    @test haskey(result["solution"]["bus"]["2"], "generic_variable")
    @test haskey(result["solution"]["bus"]["3"], "generic_variable")
    @test haskey(result["solution"]["bus"]["3"], "sl_con_vol_mag_bou_low")
    @test haskey(result["solution"]["bus"]["3"], "sl_con_vol_mag_bou_upp")

    @test haskey(result["solution"]["branch"]["1"], "tap")
    @test haskey(result["solution"]["branch"]["1"], "shift")
    @test haskey(result["solution"]["branch"]["3"], "shift")

    @test haskey(result["solution"]["shunt"]["1"], "bs")
end