const cphs_info = Dict{Any, Any}(
    :control_variables => Dict{Any, Any}(
        "1" => Dict(
            "name" => "shift",
            "variable" => "shift",
            "element" => :branch,
            "start" => 0.0,
            "filters" => [
                (branch, nw_ref) -> _control_type(branch; control_type = "shift_control"),
                (branch, nw_ref) -> _constraint_type(branch; constraint_type = "setpoint")
            ],
        )
    ),
    :control_constraints => Dict(
        "1" => Dict(
            "name" => "constraint_shift_ratio_bounds",
            "element" => :branch,
            "filters" => [
                (branch, nw_ref) -> _control_type(branch; control_type = "shift_control"),
                (branch, nw_ref) -> _constraint_type(branch; constraint_type = "setpoint")
            ]
        ),
        "2" => Dict(
            "name" => "constraint_active_power_setpoint",
            "element" => :branch,
            "filters" => [
                (branch, nw_ref) -> _control_type(branch; control_type = "shift_control"),
                (branch, nw_ref) -> _constraint_type(branch; constraint_type = "setpoint")
            ]
        ),
    ),
    :control_slacks => Dict(
        "1" => Dict(
            "name" => "constraint_active_power_setpoint",
            "element" => :branch,
            "variable" => "con_act_pow_set",
            "filters" => [
                (branch, nw_ref) -> _control_type(branch; control_type = "shift_control"),
                (branch, nw_ref) -> _constraint_type(branch; constraint_type = "setpoint")
            ],
            "type" => :equalto,
        )
    )
)