const qlim_info = Dict{Any, Any}(
    "control_variables" => Dict(),
    "control_constraints" => Dict(
        1 => Dict(
            "constraint" => "constraint_gen_reactive_bounds",
            "element" => :gen,
            "filters" => [
                (gen, nw_ref) -> nw_ref[:bus][gen["gen_bus"]]["bus_type"] in [2,3],
                (gen, nw_ref) -> gen["gen_status"] == 1
            ]
        )
    ),
    "slack_variables" => Dict(
        1 => Dict(
            "constraint" => "constraint_voltage_magnitude_setpoint",
            "element" => :bus,
            "variable" => "con_vol_mag_set",
            "filters" => [
                (bus, nw_ref) -> bus["bus_type"] in [2,3]
            ],
            "type" => :equalto,
        )
    )
)

const vlim_info = Dict{Any, Any}(
    "control_variables" => Dict{Any, Any}(
        1 => Dict(
            "name" => "load",
            "variable" => "qd",
            "element" => :load,
            "start" => 0.0,
            "filters" => [
                (load, nw_ref) -> nw_ref[:bus][load["load_bus"]]["bus_type"] == 1
            ],
        )
    ),
    "control_constraints" => Dict(
        1 => Dict(
            "constraint" => "constraint_voltage_bounds",
            "element" => :bus,
            "filters" => [
                (bus, nw_ref) -> bus["bus_type"] == 1,
            ]
        ),
        2 => Dict(
            "constraint" => "constraint_load_setpoint_reactive",
            "element" => :load,
            "filters" => [
                (load, nw_ref) -> nw_ref[:bus][load["load_bus"]]["bus_type"] == 1
            ]
        ),
    ),
    "slack_variables" => Dict(
        1 => Dict(
            "constraint" => "constraint_load_setpoint_reactive",
            "element" => :load,
            "variable" => "con_load_set_rea",
            "filters" => [
                (load, nw_ref) -> nw_ref[:bus][load["load_bus"]]["bus_type"] == 1
            ],
            "type" => :equalto,
        )
    )
)

# const crem_info

function is_controlled_by_shunt(nw_ref::Dict, bus::Dict)
    return !isempty(findall(shunt -> shunt["status"] == 1 && shunt["shunt_type"] == 2 && shunt["controlled_bus"] == bus["bus_i"], nw_ref[:shunt]))
end

const csca_info = Dict{Any, Any}(
    "control_variables" => Dict{Any, Any}(
        1 => Dict(
            "name" => "shunt",
            "variable" => "bs",
            "element" => :shunt,
            "start" => 0.0,
            "filters" => [
                (shunt, nw_ref) -> shunt["shunt_type"] == 2
            ],
        )
    ),
    "control_constraints" => Dict(
        1 => Dict(
            "constraint" => "constraint_shunt",
            "element" => :shunt,
            "filters" => [
                (shunt, nw_ref) -> shunt["shunt_type"] == 2
            ]
        ),
        2 => Dict(
            "constraint" => "constraint_voltage_bounds",
            "element" => :bus,
            "filters" => [
                (bus, nw_ref) -> is_controlled_by_shunt(nw_ref, bus),
                (bus, nw_ref) -> bus["bus_type"] == 1
            ]
        ),
    ),
    "slack_variables" => Dict(
        1 => Dict(
            "constraint" => "constraint_voltage_bounds",
            "element" => :bus,
            "variable" => "con_vol_bou",
            "filters" => [
                (bus, nw_ref) -> is_controlled_by_shunt(nw_ref, bus),
                (bus, nw_ref) -> bus["bus_type"] == 1
            ],
            "type" => :bound,
        )
    )
)



