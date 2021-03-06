const qlim_info = Dict{Any, Any}(
    :control_variables => Dict(),
    :control_constraints => Dict(
        "1" => Dict(
            "name" => "constraint_gen_reactive_bounds",
            "element" => :gen,
            "filters" => [
                (gen, nw_ref) -> nw_ref[:bus][gen["gen_bus"]]["bus_type"] in [2],
                (gen, nw_ref) -> gen["gen_status"] == 1
            ]
        ),
    ),
    :control_slacks => Dict(
        "1" => Dict(
            "name" => "constraint_voltage_magnitude_setpoint",
            "element" => :bus,
            "variable" => "con_vol_mag_set",
            "filters" => [
                (bus, nw_ref) -> bus["bus_type"] in [2]
            ],
            "type" => :equalto,
        )
    )
)
