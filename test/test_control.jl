@testset "Slack Variables" begin
    ε = 1e-5
    file = joinpath(@__DIR__, "test/data/3busfrank.pwf")
    # file = joinpath(@__DIR__, "data/3busfrank.pwf")
    network = BrazilianPowerModels.ParserPWF.parse_pwf_to_powermodels(file)
    network["shunt"]["1"]

    control = Dict(
        "control"=> Dict{String, Any}(
            # "shunt" => true,
            # "tap" => true,
            # "shift" => [4],
            # "voltage" => true,
            # "gen_active" => true,
            # "gen_reactive" => true
        )
    )

    update_data!(network, control)
    pm = BrazilianPowerModels._PM.instantiate_model(network, ACPPowerModel, BrazilianPowerModels.build_br_pf);
    solver = optimizer_with_attributes(Ipopt.Optimizer, "print_level" => 0)
    set_optimizer(pm.model, solver)
    result = BrazilianPowerModels._PM.optimize_model!(pm)

    # no new control variables created
    @test !any(occursin.("bs", String.(keys(var(pm)))))
    @test !any(occursin.("tap", String.(keys(var(pm)))))
    @test !any(occursin.("shift", String.(keys(var(pm)))))

    # verify optimality
    @test result["termination_status"] == MOI.LOCALLY_SOLVED
    # zero objective value 
    @test result["objective"] == 0.0
    
    solution = result["solution"]

    # verfy pf results
    @test solution["bus"]["1"]["va"] ≈ 0.0         atol = ε
    @test solution["bus"]["1"]["vm"] ≈ 1.029       atol = ε
    @test solution["bus"]["2"]["va"] ≈ -0.169542   atol = ε
    @test solution["bus"]["2"]["vm"] ≈ 1.15567     atol = ε
    @test solution["bus"]["3"]["va"] ≈ -0.105733   atol = ε
    @test solution["bus"]["3"]["vm"] ≈ 1.03        atol = ε


    file = joinpath(@__DIR__, "test/data/3busfrank_var_shunt.pwf")
    # file = joinpath(@__DIR__, "data/3busfrank_var_shunt.pwf")
    network = BrazilianPowerModels.ParserPWF.parse_pwf_to_powermodels(file)
    network["shunt"]
    control = Dict(
        "control"=> Dict{String, Any}(
            "shunt" => true,
        )
    )

    update_data!(network, control)
    pm = BrazilianPowerModels._PM.instantiate_model(network, ACPPowerModel, BrazilianPowerModels.build_br_pf);
    solver = optimizer_with_attributes(Ipopt.Optimizer, "print_level" => 0)
    set_optimizer(pm.model, solver)
    result = BrazilianPowerModels._PM.optimize_model!(pm)

    # shunt control variables created
    @test any(occursin.("bs", String.(keys(var(pm)))))
    @test length(var(pm, :bs)) == 2
    @test !any(occursin.("tap", String.(keys(var(pm)))))
    @test !any(occursin.("shift", String.(keys(var(pm)))))

    # verify optimality
    @test result["termination_status"] == MOI.LOCALLY_SOLVED
    # zero objective value 
    @test result["objective"] == 0.0
    
    # verify shunt control variables
    @test value(var(pm, :bs)[1]) ≈ network["shunt"]["1"]["bs"]     # fixed
    @test value(var(pm, :bs)[2]) >= network["shunt"]["2"]["bsmin"] # variable
    @test value(var(pm, :bs)[2]) <= network["shunt"]["2"]["bsmax"] # variable

    solution = result["solution"]

    # verfy pf results
    @test solution["bus"]["1"]["va"] ≈ 0.0         atol = ε
    @test solution["bus"]["1"]["vm"] ≈ 1.029       atol = ε
    @test solution["bus"]["2"]["vm"] ≈ 1.03        atol = ε

    
    file = joinpath(@__DIR__, "test/data/3busfrank_var_shunt.pwf")
    # file = joinpath(@__DIR__, "data/3busfrank_var_shunt.pwf")
    network = BrazilianPowerModels.ParserPWF.parse_pwf_to_powermodels(file)
    network["shunt"]
    control = Dict(
        "control"=> Dict{String, Any}(
            "shunt" => [2],
            # "tap" => [2],
            # "shift" => [2, 3],
            # "voltage" => [3],
            # "gen_active" => true,
            # "gen_reactive" => true
        )
    )


    update_data!(network, control)
    pm = BrazilianPowerModels._PM.instantiate_model(network, ACPPowerModel, BrazilianPowerModels.build_br_pf);
    solver = optimizer_with_attributes(Ipopt.Optimizer, "print_level" => 0)
    set_optimizer(pm.model, solver)
    result = BrazilianPowerModels._PM.optimize_model!(pm)

    # shunt control variables created
    @test any(occursin.("bs", String.(keys(var(pm)))))
    @test length(var(pm, :bs)) == 2
    @test !any(occursin.("tap", String.(keys(var(pm)))))
    @test !any(occursin.("shift", String.(keys(var(pm)))))

    # verify optimality
    @test result["termination_status"] == MOI.LOCALLY_SOLVED
    # zero objective value 
    @test result["objective"] == 0.0
    
    # verify decision control variables
    @test value(var(pm, :bs)[1])  ≈ network["shunt"]["1"]["bs"]    # fixed
    @test value(var(pm, :bs)[2]) >= network["shunt"]["2"]["bsmin"] 
    @test value(var(pm, :bs)[2]) <= network["shunt"]["2"]["bsmax"] 

    @test value(var(pm, :tap)[2]) >= network["branch"]["2"]["tapmin"]
    @test value(var(pm, :tap)[2]) <= network["branch"]["2"]["tapmax"] 
    
    @test value(var(pm, :shift)[2]) >= -0.5 # todo - bounds currently fixed
    @test value(var(pm, :shift)[2]) <=  0.5 # todo - bounds currently fixed

    @test value.(var(pm, :qg))

    file = joinpath(@__DIR__, "test/data/3busfrank_var_shunt.pwf")
    # file = joinpath(@__DIR__, "data/3busfrank_var_shunt.pwf")
    network = BrazilianPowerModels.ParserPWF.parse_pwf_to_powermodels(file)

    control = Dict(
        "control"=> Dict{String, Any}(
            "shunt" => true,
            "tap" => [2, 3],
            "shift" => true,
            "voltage" => true,
            # "gen_active" => true,
            "gen_reactive" => true
        )
    )

    update_data!(network, control)
    pm = BrazilianPowerModels._PM.instantiate_model(network, ACPPowerModel, BrazilianPowerModels.build_br_pf);
    solver = optimizer_with_attributes(Ipopt.Optimizer, "print_level" => 0)
    set_optimizer(pm.model, solver)
    result = BrazilianPowerModels._PM.optimize_model!(pm)

    # verify decision control variables

    @test value.(var(pm, :vm)[3]) >= 0.9
    @test value.(var(pm, :vm)[3]) <= 1.1

    @test value.(var(pm, :qg)[1]) >= network["gen"]["1"]["qmin"] - ε
    @test value.(var(pm, :qg)[1]) <= network["gen"]["1"]["qmax"] + ε
    @test value.(var(pm, :qg)[2]) >= network["gen"]["2"]["qmin"] - ε
    @test value.(var(pm, :qg)[2]) <= network["gen"]["2"]["qmax"] + ε

    @test length(var(pm, :tap)) == 2
    @test value.(var(pm, :tap)[2]) >= network["branch"]["2"]["tapmin"] - ε
    @test value.(var(pm, :tap)[2]) <= network["branch"]["2"]["tapmax"] + ε
    @test value.(var(pm, :tap)[3]) >= network["branch"]["3"]["tapmin"] - ε
    @test value.(var(pm, :tap)[3]) <= network["branch"]["3"]["tapmax"] + ε

    @test length(var(pm, :shift)) == 3
    @test value.(var(pm, :shift)[1]) >= network["branch"]["1"]["angmin"] - ε
    @test value.(var(pm, :shift)[1]) <= network["branch"]["1"]["angmax"] + ε
    @test value.(var(pm, :shift)[2]) >= network["branch"]["2"]["angmin"] - ε
    @test value.(var(pm, :shift)[2]) <= network["branch"]["2"]["angmax"] + ε
    @test value.(var(pm, :shift)[3]) >= network["branch"]["3"]["angmin"] - ε
    @test value.(var(pm, :shift)[3]) <= network["branch"]["3"]["angmax"] + ε
end