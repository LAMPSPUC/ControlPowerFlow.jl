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
