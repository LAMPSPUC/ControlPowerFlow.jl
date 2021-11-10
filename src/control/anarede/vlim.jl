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
            "constraint" => "constraint_voltage_magnitude_bounds",
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