@testset "ACR Model" begin
    tol = 1e-3
    @testset "qlim" begin
        file = joinpath(@__DIR__, "data/anarede/3busfrank_qlim.pwf")
        data = PWF.parse_pwf_to_powermodels(file; add_control_data = true)
        data["info"]

        pm = instantiate_model(data, ControlPowerFlow.ControlACRPowerModel, ControlPowerFlow.build_pf);

        @test haskey(var(pm), :sl_con_vol_mag_set)
        @test length(var(pm, :sl_con_vol_mag_set)) == 1 # only in PV buses
 
        set_optimizer(pm.model, ipopt)
        result = optimize_model!(pm)
        @test termination_status(pm.model) == MOI.LOCALLY_SOLVED

        # fixed values values
        va = angle(result["solution"]["bus"]["1"]["vr"] + im*result["solution"]["bus"]["1"]["vi"])
        @test isapprox(va, data["bus"]["1"]["va"], atol = tol)
        vm = abs(result["solution"]["bus"]["2"]["vr"] + im*result["solution"]["bus"]["2"]["vi"])
        @test isapprox(vm^2 - result["solution"]["bus"]["2"]["sl_con_vol_mag_set"], data["bus"]["2"]["vm"]^2, atol = tol)

        @test result["solution"]["gen"]["1"]["qg"] >= data["gen"]["1"]["qmin"] - tol
        @test result["solution"]["gen"]["1"]["qg"] <= data["gen"]["1"]["qmax"] + tol
        @test result["solution"]["gen"]["2"]["qg"] >= data["gen"]["2"]["qmin"] - tol
        @test result["solution"]["gen"]["2"]["qg"] <= data["gen"]["2"]["qmax"] + tol

        @test isapprox(result["solution"]["gen"]["2"]["pg"], data["gen"]["2"]["pg"], atol = tol)   
    end
    @testset "vlim" begin
        file = joinpath(@__DIR__, "data/anarede/4busfrank_vlim.pwf")
        data = PWF.parse_pwf_to_powermodels(file; add_control_data = true)
        data["info"]

        pm = instantiate_model(data, ControlPowerFlow.ControlACRPowerModel, ControlPowerFlow.build_pf);
        
        @test haskey(var(pm), :qd)
        @test length(var(pm, :qd)) == 2
        @test haskey(var(pm), :sl_con_load_set_rea)
        @test length(var(pm, :sl_con_load_set_rea)) == 2
 
        set_optimizer(pm.model, ipopt)
        result = optimize_model!(pm)
        @test termination_status(pm.model) == MOI.LOCALLY_SOLVED
        
        # fixed values values
        va = angle(result["solution"]["bus"]["1"]["vr"] + im*result["solution"]["bus"]["1"]["vi"])
        @test isapprox(va, data["bus"]["1"]["va"], atol = tol)
        
        vm = abs(result["solution"]["bus"]["3"]["vr"] + im*result["solution"]["bus"]["3"]["vi"])
        @test vm >= data["bus"]["3"]["control_data"]["vmmin"] - tol
        @test vm <= data["bus"]["3"]["control_data"]["vmmax"] + tol
        
        vm = abs(result["solution"]["bus"]["4"]["vr"] + im*result["solution"]["bus"]["4"]["vi"])
        @test vm >= data["bus"]["4"]["control_data"]["vmmin"] - tol
        @test vm <= data["bus"]["4"]["control_data"]["vmmax"] + tol

        @test isapprox(result["solution"]["load"]["1"]["sl_con_load_set_rea"], -0.96987; atol = tol)
        @test isapprox(result["solution"]["load"]["2"]["sl_con_load_set_rea"], -0.35143; atol = tol)
    end
    @testset "csca" begin
        file = joinpath(@__DIR__, "data/anarede/5busfrank_csca.pwf")
        data = PWF.parse_pwf_to_powermodels(file; add_control_data = true)

        pm = instantiate_model(data, ControlPowerFlow.ControlACRPowerModel, ControlPowerFlow.build_pf);
    
        @test haskey(var(pm), :bs)
        @test length(var(pm, :bs)) == 3
        @test haskey(var(pm), :sl_con_vol_mag_set)
        @test length(var(pm, :sl_con_vol_mag_set)) == 2
        @test haskey(var(pm), :sl_con_vol_mag_bou_low)
        @test haskey(var(pm), :sl_con_vol_mag_bou_upp)
        @test length(var(pm, :sl_con_vol_mag_bou_low)) == 1
        @test length(var(pm, :sl_con_vol_mag_bou_upp)) == 1
 
        set_optimizer(pm.model, ipopt)
        result = optimize_model!(pm)
        @test termination_status(pm.model) == MOI.LOCALLY_SOLVED
        
        @test result["solution"]["shunt"]["2"]["bs"] >= data["shunt"]["2"]["control_data"]["bsmin"] - tol
        @test result["solution"]["shunt"]["2"]["bs"] <= data["shunt"]["2"]["control_data"]["bsmax"] - tol
        @test result["solution"]["shunt"]["3"]["bs"] >= data["shunt"]["3"]["control_data"]["bsmin"] - tol
        @test result["solution"]["shunt"]["3"]["bs"] <= data["shunt"]["3"]["control_data"]["bsmax"] - tol
        @test result["solution"]["shunt"]["4"]["bs"] >= data["shunt"]["4"]["control_data"]["bsmin"] - tol
        @test result["solution"]["shunt"]["4"]["bs"] <= data["shunt"]["4"]["control_data"]["bsmax"] - tol

        vm = abs(result["solution"]["bus"]["3"]["vr"] + im*result["solution"]["bus"]["3"]["vi"])
        @test isapprox(
            vm^2 - result["solution"]["bus"]["3"]["sl_con_vol_mag_set"], 
            data["bus"]["3"]["vm"]^2;
            atol = tol
        )

        vm = abs(result["solution"]["bus"]["5"]["vr"] + im*result["solution"]["bus"]["5"]["vi"])
        @test isapprox(
            vm^2 - result["solution"]["bus"]["5"]["sl_con_vol_mag_set"], 
            data["bus"]["5"]["vm"]^2;
            atol = tol
        )

        vm = abs(result["solution"]["bus"]["4"]["vr"] + im*result["solution"]["bus"]["4"]["vi"])
        @test vm^2 + result["solution"]["bus"]["4"]["sl_con_vol_mag_bou_low"] >= data["bus"]["4"]["control_data"]["vmmin"]^2  - tol
        @test vm^2 - result["solution"]["bus"]["4"]["sl_con_vol_mag_bou_upp"] <= data["bus"]["4"]["control_data"]["vmmax"]^2  + tol
    end
    @testset "ctap" begin
        file = joinpath(@__DIR__, "data/anarede/5busfrank_ctap.pwf")
        data = PWF.parse_pwf_to_powermodels(file; add_control_data = true)

        pm = instantiate_model(data, ControlPowerFlow.ControlACRPowerModel, ControlPowerFlow.build_pf);
    
        @test haskey(var(pm), :tap)
        @test length(var(pm, :tap)) == 2
        @test haskey(var(pm), :sl_con_vol_mag_set)
        @test length(var(pm, :sl_con_vol_mag_set)) == 2
 
        set_optimizer(pm.model, ipopt)
        result = optimize_model!(pm)
        @test termination_status(pm.model) == MOI.LOCALLY_SOLVED

        @test result["solution"]["branch"]["4"]["tap"] >= data["branch"]["4"]["control_data"]["tapmin"] - tol
        @test result["solution"]["branch"]["4"]["tap"] <= data["branch"]["4"]["control_data"]["tapmax"] + tol
        @test result["solution"]["branch"]["5"]["tap"] >= data["branch"]["5"]["control_data"]["tapmin"] - tol
        @test result["solution"]["branch"]["5"]["tap"] <= data["branch"]["5"]["control_data"]["tapmax"] + tol

        vm = abs(result["solution"]["bus"]["3"]["vr"] + im*result["solution"]["bus"]["3"]["vi"])
        @test isapprox(
            vm^2 - result["solution"]["bus"]["3"]["sl_con_vol_mag_set"], 
            data["bus"]["3"]["vm"]^2;
            atol = tol
        )

        vm = abs(result["solution"]["bus"]["5"]["vr"] + im*result["solution"]["bus"]["5"]["vi"])
        @test isapprox(
            vm^2 - result["solution"]["bus"]["5"]["sl_con_vol_mag_set"], 
            data["bus"]["5"]["vm"]^2;
            atol = tol
        )
    end
    @testset "ctaf" begin
        file = joinpath(@__DIR__, "data/anarede/5busfrank_ctaf.pwf")
        data = PWF.parse_pwf_to_powermodels(file; add_control_data = true)

        pm = instantiate_model(data, ControlPowerFlow.ControlACRPowerModel, ControlPowerFlow.build_pf);

        @test haskey(var(pm), :tap)
        @test length(var(pm, :tap)) == 2
        @test haskey(var(pm), :sl_con_vol_mag_bou_upp)
        @test length(var(pm, :sl_con_vol_mag_bou_upp)) == 2
 
        @test haskey(var(pm), :sl_con_vol_mag_bou_low)
        @test length(var(pm, :sl_con_vol_mag_bou_low)) == 2
 
        set_optimizer(pm.model, ipopt)
        result = optimize_model!(pm)
        @test termination_status(pm.model) == MOI.LOCALLY_SOLVED

        @test result["solution"]["branch"]["4"]["tap"] >= data["branch"]["4"]["control_data"]["tapmin"] - tol
        @test result["solution"]["branch"]["4"]["tap"] <= data["branch"]["4"]["control_data"]["tapmax"] + tol
        @test result["solution"]["branch"]["5"]["tap"] >= data["branch"]["5"]["control_data"]["tapmin"] - tol
        @test result["solution"]["branch"]["5"]["tap"] <= data["branch"]["5"]["control_data"]["tapmax"] + tol

        vm = abs(result["solution"]["bus"]["3"]["vr"] + im*result["solution"]["bus"]["3"]["vi"])
        @test vm^2 + result["solution"]["bus"]["3"]["sl_con_vol_mag_bou_low"] >= data["bus"]["3"]["control_data"]["vmmin"]^2  - tol
        @test vm^2 - result["solution"]["bus"]["3"]["sl_con_vol_mag_bou_upp"] <= data["bus"]["3"]["control_data"]["vmmax"]^2  + tol

        vm = abs(result["solution"]["bus"]["5"]["vr"] + im*result["solution"]["bus"]["5"]["vi"])
        @test vm^2 + result["solution"]["bus"]["5"]["sl_con_vol_mag_bou_low"] >= data["bus"]["5"]["control_data"]["vmmin"]^2  - tol
        @test vm^2 - result["solution"]["bus"]["5"]["sl_con_vol_mag_bou_upp"] <= data["bus"]["5"]["control_data"]["vmmax"]^2  + tol
    end

    @testset "cphs" begin
        file = joinpath(@__DIR__, "data/anarede/5busfrank_cphs.pwf")
        data = PWF.parse_pwf_to_powermodels(file; add_control_data = true)

        pm = instantiate_model(data, ControlPowerFlow.ControlACRPowerModel, ControlPowerFlow.build_pf);
        
        @test haskey(var(pm), :shift)
        @test length(var(pm, :shift)) == 1
        @test haskey(var(pm), :sl_con_act_pow_set)
        @test length(var(pm, :sl_con_act_pow_set)) == 1
 
        set_optimizer(pm.model, ipopt)
        result = optimize_model!(pm)
        @test termination_status(pm.model) == MOI.LOCALLY_SOLVED

        @test result["solution"]["branch"]["5"]["shift"] >= data["branch"]["5"]["control_data"]["shiftmin"] - tol
        @test result["solution"]["branch"]["5"]["shift"] <= data["branch"]["5"]["control_data"]["shiftmax"] + tol

        @test isapprox(
            value(var(pm, :p)[(5, 2, 3)]) - result["solution"]["branch"]["5"]["sl_con_act_pow_set"], 
            data["branch"]["5"]["control_data"]["valsp"];
            atol = tol
        ) # todo figure out how to put active power result into dictionary
    end
end