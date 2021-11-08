@testset "Slack Variables" begin
    tolerance = 1e-5

    file = joinpath(@__DIR__, "data/3busfrank.pwf")
    network = ControlPowerFlow.ParserPWF.parse_pwf_to_powermodels(file)

    slack_constraints = Dict(
        "slack" => Dict(
        )
    )

    update_data!(network, slack_constraints)
    pm = ControlPowerFlow._PM.instantiate_model(network, ACPPowerModel, ControlPowerFlow.build_br_pf);
    solver = optimizer_with_attributes(Ipopt.Optimizer, "print_level" => 0)
    set_optimizer(pm.model, solver)
    result = ControlPowerFlow._PM.optimize_model!(pm)

    
    # no slack variables created
    @test !any(occursin.("sl_", String.(keys(var(pm)))))
    # verify optimality
    @test result["termination_status"] == MOI.LOCALLY_SOLVED
    # zero objective value 
    @test result["objective"] == 0.0
    
    solution = result["solution"]

    # verfy pf results
    @test solution["bus"]["1"]["va"] ≈ 0.0         atol = tolerance
    @test solution["bus"]["1"]["vm"] ≈ 1.029       atol = tolerance
    @test solution["bus"]["2"]["va"] ≈ -0.169542   atol = tolerance
    @test solution["bus"]["2"]["vm"] ≈ 1.15567     atol = tolerance
    @test solution["bus"]["3"]["va"] ≈ -0.105733   atol = tolerance
    @test solution["bus"]["3"]["vm"] ≈ 1.03        atol = tolerance

    network["slack"] = Dict{String, Any}()

    slack_constraints = Dict(
        "slack" => Dict(
            "constraint_voltage_bounds"                => true,
            "constraint_power_balance_active"          => true,
            "constraint_power_balance_reactive"        => true,
            "constraint_shunt"                         => true,
        )
    )

    ControlPowerFlow._PM.update_data!(network, slack_constraints)

    pm = ControlPowerFlow._PM.instantiate_model(network, ACPPowerModel, ControlPowerFlow.build_br_pf);
    solver = optimizer_with_attributes(Ipopt.Optimizer, "print_level" => 0)
    set_optimizer(pm.model, solver)
    result = ControlPowerFlow._PM.optimize_model!(pm)

    # check slack variables creation
    @test any(occursin.("sl_", String.(keys(var(pm)))))
    @test any(occursin.("sl_pow_bal_act_pos", String.(keys(var(pm)))))
    @test any(occursin.("sl_pow_bal_act_neg", String.(keys(var(pm)))))
    @test any(occursin.("sl_pow_bal_rea_pos", String.(keys(var(pm)))))
    @test any(occursin.("sl_pow_bal_rea_neg", String.(keys(var(pm)))))
    @test any(occursin.("sl_volt_bou_pos", String.(keys(var(pm)))))
    @test any(occursin.("sl_volt_bou_neg", String.(keys(var(pm)))))
    @test any(occursin.("sl_shunt_pos", String.(keys(var(pm)))))
    @test any(occursin.("sl_shunt_neg", String.(keys(var(pm)))))

    @test length(var(pm, :sl_pow_bal_act_pos)) == 3
    @test length(var(pm, :sl_pow_bal_act_neg)) == 3
    @test length(var(pm, :sl_pow_bal_rea_pos)) == 3
    @test length(var(pm, :sl_pow_bal_rea_neg)) == 3
    @test length(var(pm, :sl_volt_bou_pos))    == 3
    @test length(var(pm, :sl_volt_bou_neg))    == 3
    @test length(var(pm, :sl_shunt_pos))       == 1
    @test length(var(pm, :sl_shunt_neg))       == 1

    # verify optimality
    @test result["termination_status"] == MOI.LOCALLY_SOLVED
    # zero objective value 
    @test result["objective"] ≈ 0.0 atol = tolerance
    
    solution = result["solution"]

    # verfy pf results
    @test solution["bus"]["1"]["va"] ≈ 0.0         atol = tolerance
    @test solution["bus"]["1"]["vm"] ≈ 1.029       atol = tolerance
    @test solution["bus"]["2"]["va"] ≈ -0.169542   atol = tolerance
    @test solution["bus"]["2"]["vm"] ≈ 1.15567     atol = tolerance
    @test solution["bus"]["3"]["va"] ≈ -0.105733   atol = tolerance
    @test solution["bus"]["3"]["vm"] ≈ 1.03        atol = tolerance

    network["slack"] = Dict{String, Any}()

    slack_constraints = Dict(
        "slack" => Dict(
            "constraint_voltage_bounds"                => [1],
            "constraint_power_balance_active"          => [1,2],
            "constraint_power_balance_reactive"        => [1,2,3],
            "constraint_shunt"                         => [2], # only one shunt with number 1. This won't create any slack variables
        )
    )

    ControlPowerFlow._PM.update_data!(network, slack_constraints)

    pm = ControlPowerFlow._PM.instantiate_model(network, ACPPowerModel, ControlPowerFlow.build_br_pf);
    solver = optimizer_with_attributes(Ipopt.Optimizer, "print_level" => 0)
    set_optimizer(pm.model, solver)
    result = ControlPowerFlow._PM.optimize_model!(pm)

    # check slack variables creation
    @test any(occursin.("sl_", String.(keys(var(pm)))))
    @test any(occursin.("sl_pow_bal_act_pos", String.(keys(var(pm)))))
    @test any(occursin.("sl_pow_bal_act_neg", String.(keys(var(pm)))))
    @test any(occursin.("sl_pow_bal_rea_pos", String.(keys(var(pm)))))
    @test any(occursin.("sl_pow_bal_rea_neg", String.(keys(var(pm)))))
    @test any(occursin.("sl_volt_bou_pos", String.(keys(var(pm)))))
    @test any(occursin.("sl_volt_bou_neg", String.(keys(var(pm)))))
    @test any(occursin.("sl_shunt_pos", String.(keys(var(pm)))))
    @test any(occursin.("sl_shunt_neg", String.(keys(var(pm)))))

    @test length(var(pm, :sl_pow_bal_act_pos)) == 2
    @test length(var(pm, :sl_pow_bal_act_neg)) == 2
    @test length(var(pm, :sl_pow_bal_rea_pos)) == 3
    @test length(var(pm, :sl_pow_bal_rea_neg)) == 3
    @test length(var(pm, :sl_volt_bou_pos))    == 1
    @test length(var(pm, :sl_volt_bou_neg))    == 1
    @test length(var(pm, :sl_shunt_pos))       == 0 #there's only one shunt
    @test length(var(pm, :sl_shunt_neg))       == 0 #there's only one shunt

    # verify optimality
    @test result["termination_status"] == MOI.LOCALLY_SOLVED
    # zero objective value 
    @test result["objective"] ≈ 0.0 atol = tolerance
    
    solution = result["solution"]

    # verfy pf results
    @test solution["bus"]["1"]["va"] ≈ 0.0         atol = tolerance
    @test solution["bus"]["1"]["vm"] ≈ 1.029       atol = tolerance
    @test solution["bus"]["2"]["va"] ≈ -0.169542   atol = tolerance
    @test solution["bus"]["2"]["vm"] ≈ 1.15567     atol = tolerance
    @test solution["bus"]["3"]["va"] ≈ -0.105733   atol = tolerance
    @test solution["bus"]["3"]["vm"] ≈ 1.03        atol = tolerance
end