# Include BrazilianPowerModels module
include("src/BrazilianPowerModels.jl")

# using Packages
using PowerModels, Ipopt, JuMP
using ParserPWF

# PWF system file
file = "scripts\\data\\pwf\\EMS_fase1.pwf"

# Reading PWF and converting to PowerModels network data dictionary
network_pwf = BrazilianPowerModels.ParserPWF.parse_pwf_to_powermodels(file)

result = BrazilianPowerModels.run_br_pf(network_pwf, ACPPowerModel, Ipopt.Optimizer)
result["solution"]["shunt"]




pm = BrazilianPowerModels._PM.instantiate_model(network_pwf, ACPPowerModel, BrazilianPowerModels.build_br_pf);
print(pm.model)
solver = optimizer_with_attributes(Ipopt.Optimizer)
set_optimizer(pm.model, solver)
result = optimize_model!(pm)
result["solution"]["bus"][""]

using JSON

js = JSON.json(result);

open("foo.json","w") do f 
    write(f, js) 
end




function value_slacks(pm)
    slacks = Dict()
    for (k,v) in var(pm, 0)
        if occursin("sl", string(k))
            slacks[k] = value.(v)
        end
    end
    return slacks
end
function violated_slacks(slacks)
    violated_slacks = Dict()
    for (k, v) in slacks
        if !all(v .== 0)
            violated_slacks[k] = Dict()
            for (i, sl) in enumerate(v)
                if abs(sl) > 1e-4
                    for (j, sl_v) in enumerate(var(pm, 0)[k])
                        if j == i
                            violated_slacks[k][sl_v] = sl
                        end
                    end
                end
            end
        end
    end

    return violated_slacks
end

slacks = value_slacks(pm)
viol_slacks = violated_slacks(slacks)

viol_slacks[:sl_const_balance_p_pos]


slacks[:sl_bus_p_pos]

all_variables(pm.model)


bus = ref(pm, 0, :bus, 3)
i = 1

bus_sl_pos = var(pm, nw, :sl_pos, i)
bus_sl_neg = var(pm, nw, :sl_neg, i)

s = run_pf(network, _BRPM._PM.SOCWRPowerModel, Ipopt.Optimizer)

result = BrazilianPowerModels.run_brazilian_pf(network, _BRPM._PM.ACPPowerModel, Ipopt.Optimizer)


_pm_global_keys = Set(["time_series", "per_unit"])
pm_it_name = "pm"
pm_it_sym = Symbol(pm_it_name)

imo = BrazilianPowerModels._IM.InitializeInfrastructureModel(ACPPowerModel, network, _pm_global_keys, pm_it_sym);

var(imo, 0)[:p]

all_constraints(imo.model)


BrazilianPowerModels._PM.ref_add_core!(imo.ref)

BrazilianPowerModels._PM.variable_bus_voltage(imo, bounded = false)
BrazilianPowerModels._PM.variable_gen_power(imo, bounded = false)
BrazilianPowerModels._PM.variable_dcline_power(imo, bounded = false)
BrazilianPowerModels.variable_shunt(imo)

for i in BrazilianPowerModels.ids(imo, :branch)
    BrazilianPowerModels._PM.expression_branch_power_ohms_yt_from(imo, i)
    BrazilianPowerModels._PM.expression_branch_power_ohms_yt_to(imo, i)
end

BrazilianPowerModels._PM.constraint_model_voltage(imo)

for (i,bus) in BrazilianPowerModels.ref(imo, :ref_buses)
    @assert bus["bus_type"] == 3
    BrazilianPowerModels._PM.constraint_theta_ref(imo, i)
    BrazilianPowerModels._PM.constraint_voltage_magnitude_setpoint(imo, i)

    # if multiple generators, fix power generation degeneracies
    if length(BrazilianPowerModels.ref(imo, :bus_gens, i)) > 1
        for j in collect(BrazilianPowerModels.ref(pm, :bus_gens, i))[2:end]
            BrazilianPowerModels._PM.constraint_gen_setpoint_active(imo, j)
            BrazilianPowerModels._PM.constraint_gen_setpoint_reactive(imo, j)
        end
    end
end

for (i,bus) in BrazilianPowerModels.ref(imo, :bus)
    BrazilianPowerModels.constraint_power_balance(imo, i)
    
    BrazilianPowerModels.constraint_shunt(imo, i)

    # PV Bus Constraints
    if length(BrazilianPowerModels.ref(imo, :bus_gens, i)) > 0 && !(i in BrazilianPowerModels.ids(imo,:ref_buses))
        # this assumes inactive generators are filtered out of bus_gens
        @assert bus["bus_type"] == 2

        BrazilianPowerModels._PM.constraint_voltage_magnitude_setpoint(imo, controled_bus(imo, i)) # lamps
        for j in BrazilianPowerModels.ref(imo, :bus_gens, i)
            BrazilianPowerModels._PM.constraint_gen_setpoint_active(imo, j)
        end
    end
end


for (i,dcline) in BrazilianPowerModels.ref(imo, :dcline)
    #constraint_dcline_power_losses(pm, i) not needed, active power flow fully defined by dc line setpoints
    BrazilianPowerModels._PM.constraint_dcline_setpoint_active(imo, i)

    f_bus = ref(imo, :bus)[dcline["f_bus"]]
    if f_bus["bus_type"] == 1
        BrazilianPowerModels._PM.constraint_voltage_magnitude_setpoint(imo, f_bus["index"])
    end

    t_bus = ref(imo, :bus)[dcline["t_bus"]]
    if t_bus["bus_type"] == 1
        BrazilianPowerModels._PM.constraint_voltage_magnitude_setpoint(imo, t_bus["index"])
    end
end

set_optimizer(imo.model, Ipopt.Optimizer)
@time optimize!(imo.model);
values(all_variables(imo.model))
value.(all_variables(imo.model))

print(imo.model)

element_from_bus(pm, :shunt, 6982, filters = [shunt->shunt["shunt_type"] == 2])

