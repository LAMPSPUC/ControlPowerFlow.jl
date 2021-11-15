@testset "Control from generic_info" begin

    file = joinpath(@__DIR__, "data/3busfrank_continuous_shunt.pwf")
    data = ControlPowerFlow.ParserPWF.parse_pwf_to_powermodels(file)

    generic_info = Dict{Any, Any}(
        :control_variables => Dict{Any, Any}(
            "1" => Dict(
                "name" => "shunt",
                "variable" => "bs",
                "element" => :shunt,
                "start" => 0.0,
                "filters" => [
                    (shunt, nw_ref) -> ControlPowerFlow._control_data(shunt)["shunt_type"] == 2
                ],
            )
        ),
        :control_constraints => Dict(
            "1" => Dict(
                "name" => "constraint_shunt_bounds",
                "element" => :shunt,
                "filters" => [
                    (shunt, nw_ref) -> ControlPowerFlow._control_data(shunt)["shunt_type"] == 2
                ]
            ),
            "2" => Dict(
                "name" => "constraint_voltage_magnitude_bounds",
                "element" => :bus,
                "filters" => [
                    (bus, nw_ref) -> ControlPowerFlow._controlled_by_shunt(nw_ref, bus; shunt_control_type = 2), #discrete
                    (bus, nw_ref) -> bus["bus_type"] == 1 # PQ
                ]
            ),
            "3" => Dict(
                "name" => "constraint_voltage_magnitude_setpoint",
                "element" => :bus,
                "filters" => [
                    (bus, nw_ref) -> ControlPowerFlow._controlled_by_shunt(nw_ref, bus; shunt_control_type = 3), #continuous
                    (bus, nw_ref) -> bus["bus_type"] == 1 # PQ
                ]
            ),
        ),
        :control_slacks => Dict(
            "1" => Dict(
                "name" => "constraint_voltage_magnitude_bounds",
                "element" => :bus,
                "variable" => "con_vol_mag_bou",
                "filters" => [
                    (bus, nw_ref) -> ControlPowerFlow._controlled_by_shunt(nw_ref, bus; shunt_control_type = 2), #discrete
                    (bus, nw_ref) -> bus["bus_type"] == 1 # PQ
                ],
                "type" => :bound,
            ),
            "2" => Dict(
                "name" => "constraint_voltage_magnitude_setpoint",
                "element" => :bus,
                "variable" => "con_vol_mag_set",
                "filters" => [
                    (bus, nw_ref) -> ControlPowerFlow._controlled_by_shunt(nw_ref, bus; shunt_control_type = 3), #continuous
                    (bus, nw_ref) -> bus["bus_type"] == 1 # PQ
                ],
                "type" => :equalto,
            )
        )
    )

    data["info"] = Dict(
        "generic_info" => generic_info,
    )

    pm = instantiate_model(data, ControlPowerFlow.ControlACPPowerModel, ControlPowerFlow.build_pf);

    

    # New Control Variables
    @test length(var(pm, :bs)) == 1
    @test !haskey(var(pm), :tap)
    @test !haskey(var(pm), :shift)
    
    # Slack Variables 
    @test !haskey(var(pm), :sl_con_vol_mag_bou_upp)
    @test !haskey(var(pm), :sl_con_vol_mag_bou_low)
    @test length(var(pm, :sl_con_vol_mag_set)) == 1

    set_optimizer(pm.model, ipopt)
    result = optimize_model!(pm)

    @test termination_status(pm.model) == MOI.LOCALLY_SOLVED

    @test haskey(result["solution"]["bus"]["3"], "sl_con_vol_mag_set")
    @test haskey(result["solution"]["shunt"]["1"], "bs")

    ## Testing Repeated Control - This should be equivalent of adding only one
    data["info"] = Dict(
        "generic_info" => generic_info,
        "generic_info" => generic_info,
    )

    pm = instantiate_model(data, ControlPowerFlow.ControlACPPowerModel, ControlPowerFlow.build_pf);

    

    # New Control Variables
    @test length(var(pm, :bs)) == 1
    @test !haskey(var(pm), :tap)
    @test !haskey(var(pm), :shift)
    
    # Slack Variables 
    @test !haskey(var(pm), :sl_con_vol_mag_bou_upp)
    @test !haskey(var(pm), :sl_con_vol_mag_bou_low)
    @test length(var(pm, :sl_con_vol_mag_set)) == 1

    set_optimizer(pm.model, ipopt)
    result = optimize_model!(pm)

    @test termination_status(pm.model) == MOI.LOCALLY_SOLVED

    @test haskey(result["solution"]["bus"]["3"], "sl_con_vol_mag_set")
    @test haskey(result["solution"]["shunt"]["1"], "bs")

  ## Testing Repeated Control - This should be equivalent of adding only one
    data["info"] = Dict(
        "generic_info" => generic_info,
        "generic_info" => generic_info,
    )

    pm = instantiate_model(data, ControlPowerFlow.ControlACPPowerModel, ControlPowerFlow.build_pf);

    

    # New Control Variables
    @test length(var(pm, :bs)) == 1
    @test !haskey(var(pm), :tap)
    @test !haskey(var(pm), :shift)
    
    # Slack Variables 
    @test !haskey(var(pm), :sl_con_vol_mag_bou_upp)
    @test !haskey(var(pm), :sl_con_vol_mag_bou_low)
    @test length(var(pm, :sl_con_vol_mag_set)) == 1

    set_optimizer(pm.model, ipopt)
    result = optimize_model!(pm)

    @test termination_status(pm.model) == MOI.LOCALLY_SOLVED

    @test haskey(result["solution"]["bus"]["3"], "sl_con_vol_mag_set")
    @test haskey(result["solution"]["shunt"]["1"], "bs")


    ## Testing Generic combined with default
    data["info"] = Dict(
        "generic_info" => generic_info,
        "qlim" => true
    )

    pm = instantiate_model(data, ControlPowerFlow.ControlACPPowerModel, ControlPowerFlow.build_pf);

    

    # New Control Variables
    @test length(var(pm, :bs)) == 1
    @test !haskey(var(pm), :tap)
    @test !haskey(var(pm), :shift)
    
    # Slack Variables 
    @test !haskey(var(pm), :sl_con_vol_mag_bou_upp)
    @test !haskey(var(pm), :sl_con_vol_mag_bou_low)
    @test length(var(pm, :sl_con_vol_mag_set)) == 3

    set_optimizer(pm.model, ipopt)
    result = optimize_model!(pm)

    @test termination_status(pm.model) == MOI.LOCALLY_SOLVED

    @test haskey(result["solution"]["bus"]["1"], "sl_con_vol_mag_set")
    @test haskey(result["solution"]["bus"]["2"], "sl_con_vol_mag_set")
    @test haskey(result["solution"]["bus"]["3"], "sl_con_vol_mag_set")
    @test haskey(result["solution"]["shunt"]["1"], "bs")
    
end