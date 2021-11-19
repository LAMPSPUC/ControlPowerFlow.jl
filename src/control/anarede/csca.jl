const csca_info = Dict{Any, Any}(
    :control_variables => Dict{Any, Any}(
        "1" => Dict(
            "name" => "shunt",
            "variable" => "bs",
            "element" => :shunt,
            "start" => 0.0,
            "filters" => [
                (shunt, nw_ref) -> _control_data(shunt)["shunt_type"] == 2
            ],
        )
    ),
    :control_constraints => Dict(
        "1" => Dict(
            "name" => "constraint_shunt_bounds",
            "element" => :shunt,
            "filters" => [
                (shunt, nw_ref) -> _control_data(shunt)["shunt_type"] == 2
            ]
        ),
        "2" => Dict(
            "name" => "constraint_shunt_setpoint",
            "element" => :shunt,
            "filters" => [
                (shunt, nw_ref) -> _control_data(shunt)["shunt_type"] == 2
            ]
        ),
        "3" => Dict(
            "name" => "constraint_voltage_magnitude_bounds",
            "element" => :bus,
            "filters" => [
                (bus, nw_ref) -> _controlled_by_shunt(nw_ref, bus; shunt_control_type = 2), #discrete
                (bus, nw_ref) -> bus["bus_type"] == 1 # PQ
            ]
        ),
        "4" => Dict(
            "name" => "constraint_voltage_magnitude_setpoint",
            "element" => :bus,
            "filters" => [
                (bus, nw_ref) -> _controlled_by_shunt(nw_ref, bus; shunt_control_type = 3), #continuous
                (bus, nw_ref) -> bus["bus_type"] == 1 # PQ
            ]
        ),
    ),
    :control_slacks => Dict(
        "1" => Dict(
            "name" => "constraint_shunt_setpoint",
            "element" => :shunt,
            "variable" => "con_shu_set",
            "filters" => [
                (shunt, nw_ref) -> _control_data(shunt)["shunt_type"] == 2
            ],
            "type" => :equalto,
            "weight" => 0.1
        ),
        "2" => Dict(
            "name" => "constraint_voltage_magnitude_bounds",
            "element" => :bus,
            "variable" => "con_vol_mag_bou",
            "filters" => [
                (bus, nw_ref) -> _controlled_by_shunt(nw_ref, bus; shunt_control_type = 2), #discrete
                (bus, nw_ref) -> bus["bus_type"] == 1 # PQ
            ],
            "type" => :bound,
        ),
        "3" => Dict(
            "name" => "constraint_voltage_magnitude_setpoint",
            "element" => :bus,
            "variable" => "con_vol_mag_set",
            "filters" => [
                (bus, nw_ref) -> _controlled_by_shunt(nw_ref, bus; shunt_control_type = 3), #continuous
                (bus, nw_ref) -> bus["bus_type"] == 1 # PQ
            ],
            "type" => :equalto,
        )
    )
)