# using Packages
using PowerModels, Ipopt, JuMP
using ParserPWF 

# Include ControlPF module
include("src/ControlPowerFlow.jl")

ipopt = optimizer_with_attributes(Ipopt.Optimizer, "tol"=>0.00001)

# PWF system file
file = "scripts\\data\\pwf\\3busfrank.pwf"
# Reading PWF and converting to PowerModels network data dictionary
data = ControlPowerFlow.ParserPWF.parse_pwf_to_powermodels(file; software = ControlPowerFlow.ParserPWF.Organon)
network = deepcopy(data)

network["shunt"]["1"]["control_data"] = network["shunt"]["1"]["control_info"]
network["shunt"]["2"]["control_data"] = network["shunt"]["2"]["control_info"]
network["shunt"]["3"]["control_data"] = network["shunt"]["3"]["control_info"]

network["bus"]["3"]["vmin"] = 0.91
network["bus"]["3"]["vmax"] = 0.95

network["branch"]["3"]["control_data"] = Dict()
network["branch"]["3"]["control_data"]["control_type"] = "shift_control"
network["branch"]["3"]["control_data"]["constraint_type"] = "setpoint"
network["branch"]["3"]["control_data"]["controlled_bus"] = 3
network["branch"]["3"]["control_data"]["shiftmin"] = -0.5
network["branch"]["3"]["control_data"]["shiftmax"] = 0.5
network["branch"]["3"]["control_data"]["p"] = -0.5

network["branch"]["4"]["control_data"] = Dict()
network["branch"]["4"]["control_data"]["control_type"] = "fix"
network["branch"]["4"]["control_data"]["constraint_type"] = "fix"
network["branch"]["4"]["control_data"]["controlled_bus"] = 1


network["branch"]["2"]["control_data"] = Dict()
network["branch"]["2"]["control_data"]["control_type"] = "fix"
network["branch"]["2"]["control_data"]["constraint_type"] = "fix"
network["branch"]["2"]["control_data"]["controlled_bus"] = 1

network["branch"]["1"]["control_data"] = Dict()
network["branch"]["1"]["control_data"]["control_type"] = "fix"
network["branch"]["1"]["control_data"]["constraint_type"] = "fix"
network["branch"]["1"]["control_data"]["controlled_bus"] = 1

control_info = Dict{String, Any}(
    "control_info" => Dict{Any, Any}(
        :controlled_bus => true,
        :control_variables => Dict{Any, Any}(
            "shunt" => Dict{Any, Any}(
                "name"     => "shunt",
                "variable" => "bs",
                "element"  => :shunt,
                "start"    => 0.0,
                "indexes"  => parse.(Int, findall(shunt->shunt["shunt_type"] in [1,2] && shunt["status"] == 1, network["shunt"]))
            )
        ),
        :control_constraints => Dict{Any, Any}(
            # "constraint_voltage_magnitude_setpoint" => Dict{Any, Any}(
            #     "name"    => "constraint_voltage_magnitude_setpoint",
            #     "element" => :bus,
            #     "indexes" => parse.(Int, findall(bus->bus["bus_type"] == 1, network["bus"]))
            # ),
            # "constraint_voltage_angle_setpoint" => Dict{Any, Any}(
            #     "name"    => "constraint_voltage_angle_setpoint",
            #     "element" => :bus,
            #     "indexes" => parse.(Int, findall(bus->bus["bus_type"] in [1,2], network["bus"]))
            # ),
            # "constraint_voltage_magnitude_bounds" => Dict{Any, Any}(
            #     "name"    => "constraint_voltage_magnitude_bounds",
            #     "element" => :bus,
            #     "indexes" => parse.(Int, findall(bus->bus["bus_type"] == 1, network["bus"]))
            # ),
            "constraint_voltage_angle_bounds" => Dict{Any, Any}(
                "name"    => "constraint_voltage_angle_bounds",
                "element" => :bus,
                "indexes" => parse.(Int, findall(bus->bus["bus_type"] in [2], network["bus"]))
            ),
            # "constraint_shunt" => Dict{Any, Any}(
            #     "name"    => "constraint_shunt",
            #     "element" => :shunt,
            #     "indexes"  => parse.(Int, findall(shunt->shunt["shunt_type"] == 2 && shunt["status"] == 1, network["shunt"]))
            # ),
        ),
        :slack_variables => Dict{Any, Any}(
            # "constraint_voltage_magnitude_setpoint" => Dict{Any, Any}(
            #     "name"    => "constraint_voltage_magnitude_setpoint",
            #     "variable"=> "con_vol_mag_set",
            #     "weight" => 1.0,
            #     "element" => :bus,
            #     "indexes" => [parse(Int,i) for (i, bus) in network["bus"] if bus["bus_type"] != 4],
            #     "type" => :equalto
            # ),
            # "constraint_voltage_angle_setpoint" => Dict{Any, Any}(
            #     "name"    => "constraint_voltage_angle_setpoint",
            #     "variable"=> "con_vol_ang_set",
            #     "weight" => 1.0,
            #     "element" => :bus,
            #     "indexes" => [parse(Int,i) for (i, bus) in network["bus"] if bus["bus_type"] != 4],
            #     "type" => :equalto
            # ),
            "constraint_power_balance_active" => Dict{Any, Any}(
                "name"    => "constraint_power_balance_active",
                "variable"=> "con_pow_bal_act",
                "weight" => 1.0,
                "element" => :bus,
                "indexes" => [parse(Int,i) for (i, bus) in network["bus"] if bus["bus_type"] != 4],
                "type" => :equalto
            ),
            "constraint_power_balance_reactive" => Dict{Any, Any}(
                "name"    => "constraint_power_balance_reactive",
                "variable"=> "con_pow_bal_rea",
                "weight" => 1.0,
                "element" => :bus,
                "indexes" => [parse(Int,i) for (i, bus) in network["bus"] if bus["bus_type"] != 4],
                "type" => :equalto
            ),
        )
    )
)

# ControlPF.set_control_info!(network, control_info)
network["info"] = Dict()
network["info"]["cphs"] = true
network["info"]["csca"] = true
set_ac_pf_start_values!(network)
@time pm = instantiate_model(network, ACPPowerModel, ControlPowerFlow.build_br_pf);

print(pm.model)

set_optimizer(pm.model, ipopt)
result = optimize_model!(pm)
result["solution"]["bus"]
result["solution"]["branch"]
result["solution"]["shunt"]
update_data!(network, result["solution"])
ControlPowerFlow.print_bus(network)
update_data!(network, PowerModels.calc_branch_flow_ac(network))
ControlPF.print_bus(network)
ControlPF.print_gen(network)

bus = network["bus"]["3"]
status = "br_status"
control_type = "tap_voltage_control"
tap_voltage_control = "setpoint"
!isempty(
        findall(
            branch -> branch[status] == 1 &&
                      ControlPowerFlow._control_type(branch; control_type = control_type) &&
                      ControlPowerFlow._tap_voltage_control(branch; tap_voltage_control  = tap_voltage_control) &&
                      ControlPowerFlow._controlled_bus(branch, bus["bus_i"]), 
            nw_ref[:branch])
        )

branch = ref(pm, :branch, 1)




control_info = Dict{String, Any}(
    "control_info" => Dict{Any, Any}(
        :controlled_bus => true,
        :control_variables => Dict{Any, Any}(
            "shunt" => Dict{Any, Any}(
                "name"     => "shunt",
                "variable" => "bs",
                "element"  => :shunt,
                "start"    => 0.0,
                "indexes"  => parse.(Int, findall(shunt->shunt["shunt_type"] in [1,2] && shunt["status"] == 1, network["shunt"]))
            )
        ),
        :control_constraints => Dict{Any, Any}(
            "constraint_voltage_magnitude_setpoint" => Dict{Any, Any}(
                "name"    => "constraint_voltage_magnitude_setpoint",
                "element" => :bus,
                "indexes" => parse.(Int, findall(bus->bus["bus_type"] == 1, network["bus"]))
            ),
            "constraint_voltage_angle_setpoint" => Dict{Any, Any}(
                "name"    => "constraint_voltage_angle_setpoint",
                "element" => :bus,
                "indexes" => parse.(Int, findall(bus->bus["bus_type"] in [1,2], network["bus"]))
            ),
            # "constraint_voltage_magnitude_bounds" => Dict{Any, Any}(
            #     "name"    => "constraint_voltage_magnitude_bounds",
            #     "element" => :bus,
            #     "indexes" => parse.(Int, findall(bus->bus["bus_type"] == 1, network["bus"]))
            # ),
            # "constraint_voltage_angle_bounds" => Dict{Any, Any}(
            #     "name"    => "constraint_voltage_angle_bounds",
            #     "element" => :bus,
            #     "indexes" => parse.(Int, findall(bus->bus["bus_type"] in [1,2], network["bus"]))
            # ),
            # "constraint_shunt" => Dict{Any, Any}(
            #     "name"    => "constraint_shunt",
            #     "element" => :shunt,
            #     "indexes"  => parse.(Int, findall(shunt->shunt["shunt_type"] == 2 && shunt["status"] == 1, network["shunt"]))
            # ),
        ),
        :slack_variables => Dict{Any, Any}(
            "constraint_voltage_magnitude_setpoint" => Dict{Any, Any}(
                "name"    => "constraint_voltage_magnitude_setpoint",
                "variable"=> "con_vol_mag_set",
                "weight" => 1.0,
                "element" => :bus,
                "indexes" => [parse(Int,i) for (i, bus) in network["bus"] if bus["bus_type"] != 4],
                "type" => :equalto
            ),
            "constraint_voltage_angle_setpoint" => Dict{Any, Any}(
                "name"    => "constraint_voltage_angle_setpoint",
                "variable"=> "con_vol_ang_set",
                "weight" => 1.0,
                "element" => :bus,
                "indexes" => [parse(Int,i) for (i, bus) in network["bus"] if bus["bus_type"] != 4],
                "type" => :equalto
            ),
            # "constraint_power_balance_active" => Dict{Any, Any}(
            #     "name"    => "constraint_power_balance_active",
            #     "variable"=> "con_pow_bal_act",
            #     "weight" => 1.0,
            #     "element" => :bus,
            #     "indexes" => [parse(Int,i) for (i, bus) in network["bus"] if bus["bus_type"] != 4],
            #     "type" => :equalto
            # ),
            # "constraint_power_balance_reactive" => Dict{Any, Any}(
            #     "name"    => "constraint_power_balance_reactive",
            #     "variable"=> "con_pow_bal_rea",
            #     "weight" => 1.0,
            #     "element" => :bus,
            #     "indexes" => [parse(Int,i) for (i, bus) in network["bus"] if bus["bus_type"] != 4],
            #     "type" => :equalto
            # ),
        )
    )
)

ControlPF.set_control_info!(network, control_info)
set_ac_pf_start_values!(network)
@time pm = instantiate_model(network, ACPPowerModel, ControlPF.build_br_pf);

# print(pm.model)
set_optimizer(pm.model, ipopt)
result = optimize_model!(pm)

for (i, bus) in result["solution"]["bus"]
    for (slack, value) in bus
        if occursin("sl", slack)
            if abs(value) > 0.01
                @show i, bus["vm"], slack, value
            end
        end
        # if abs(bus["va"]) > 75*3.14/180
        #     @show i, bus["vm"], slack, value
        #     break
        # end
    end
end


using CSV, DataFrames
fronteira_df = CSV.read("fronteira_ems\\pontosMust EMS - 2021_final.csv", DataFrame)

fronteira_ems = Matrix(fronteira_df[:, 2:end-1])

function handle_border(fronteira_ems::Matrix)
    fronteira = [
       # (branch, f_bus, t_bus)
    ]
    for i in 1:length(fronteira_ems[:, 1])
        tup = (fronteira_ems[i, 1], fronteira_ems[i, 2], fronteira_ems[i, 3])
        branch_id = parse.(Int, findall(branch -> branch["f_bus"] == tup[1] && branch["t_bus"] == tup[2] && branch["circuit"] == tup[3] , data["branch"]))
        if !isempty(branch_id)
            front = (branch_id[1], tup[1], tup[2])
            push!(fronteira, front)
        else
            branch_id = parse.(Int, findall(branch -> branch["f_bus"] == tup[2] && branch["t_bus"] == tup[1] && branch["circuit"] == tup[3] , data["branch"]))
            if !isempty(branch_id)
                front = (branch_id[1], tup[2], tup[1])
                push!(fronteira, front)
            else
                @warn("fronteira $tup não encontrada")
                push!(fronteira, nothing)
            end
        end
        
    end
    return fronteira
end

handle_border(fronteira_ems)

function handle_power_flow(fronteira_ems::Matrix, pm::PowerModels.AbstractPowerModel)
    border = handle_border(fronteira_ems)
    power_flow = Matrix{Any}(undef, length(border), 5)
    for (b, branch) in enumerate(border)
        if haskey(ref(pm, :branch), branch[1])
            p = value(var(pm, :p)[branch])
            q = value(var(pm, :q)[branch])
            power_flow[b, 1] = branch
            power_flow[b, 2] = p
            power_flow[b, 3] = q
            power_flow[b, 4] = ref(pm, :bus)[branch[2]]["name"]
            power_flow[b, 5] = ref(pm, :bus)[branch[3]]["name"]
        else
            @warn("Branch $branch is off")
            power_flow[b, 1] = branch
            power_flow[b, 2] = NaN
            power_flow[b, 3] = NaN
            power_flow[b, 4] = ref(pm, :bus)[branch[2]]["name"]
            power_flow[b, 5] = ref(pm, :bus)[branch[3]]["name"]
        end
    end
    return power_flow
end

handle_power_flow(fronteira_ems, pm)

