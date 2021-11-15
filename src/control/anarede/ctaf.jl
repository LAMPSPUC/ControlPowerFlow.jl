const ctaf_info = Dict{Any, Any}(
    :control_variables => Dict{Any, Any}(
        "1" => Dict(
            "name" => "tap",
            "variable" => "tap",
            "element" => :branch,
            "start" => 1.0,
            "filters" => [
                (branch, nw_ref) -> _control_type(branch; control_type = "tap_control"),
                (branch, nw_ref) -> _constraint_type(branch; constraint_type = "bounds")
            ],
        )
    ),
    :control_constraints => Dict(
        "1" => Dict(
            "name" => "constraint_tap_ratio_bounds",
            "element" => :branch,
            "filters" => [
                (branch, nw_ref) -> _control_type(branch; control_type = "tap_control"),
                (branch, nw_ref) -> _constraint_type(branch; constraint_type = "bounds")
            ]
        ),
        "2" => Dict(
            "name" => "constraint_voltage_magnitude_bounds",
            "element" => :bus,
            "filters" => [
                (bus, nw_ref) -> _controlled_by_transformer(
                                    nw_ref, bus; 
                                    control_type = "tap_control",
                                    constraint_type = "bounds"
                                ),
                (bus, nw_ref) -> bus["bus_type"] == 1
            ]
        ),
    ),
    :control_slacks => Dict(
        "1" => Dict(
            "name" => "constraint_voltage_magnitude_bounds",
            "element" => :bus,
            "variable" => "con_vol_bou",
            "filters" => [
                (bus, nw_ref) -> _controlled_by_transformer(
                                    nw_ref, bus; 
                                    control_type = "tap_control",
                                    constraint_type = "bounds"
                                ),
                (bus, nw_ref) -> bus["bus_type"] == 1
            ],
            "type" => :bound,
        )
    )
)