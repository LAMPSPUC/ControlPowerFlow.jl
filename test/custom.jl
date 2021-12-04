@testset "Custom Defaults" begin
    tol = 1e-3
    @testset "cslv" begin
        file = joinpath(@__DIR__, "data/5busfrank.pwf")
        data = ControlPowerFlow.ParserPWF.parse_pwf_to_powermodels(file; add_control_data = true)

        data["info"] = Dict(
            "actions" => Dict(
                "cslv" => true
            )
        )
        pm = instantiate_model(data, ControlPowerFlow.ControlACPPowerModel, ControlPowerFlow.build_pf);
    
        @test haskey(var(pm), :sl_con_vol_mag_set)
        @test length(var(pm, :sl_con_vol_mag_set)) == 2

        @test haskey(var(pm), :sl_con_gen_set_act)
        @test length(var(pm, :sl_con_gen_set_act)) == 1

        @test haskey(var(pm), :sl_con_pow_bal_act)
        @test length(var(pm, :sl_con_pow_bal_act)) == 5

        @test haskey(var(pm), :sl_con_pow_bal_rea)
        @test length(var(pm, :sl_con_pow_bal_rea)) == 5

        @test haskey(var(pm), :sl_con_gen_set_act)
        @test length(var(pm, :sl_con_gen_set_act)) == 1
    
        set_optimizer(pm.model, ipopt)
        result = optimize_model!(pm)

        @test isapprox(result["objective"], 0.0; atol = tol^2)
    end
end

