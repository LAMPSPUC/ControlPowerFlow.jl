const cslv_info = Dict{Any, Any}(
    :control_variables => Dict{Any, Any}(
    ),
    :control_constraints => Dict(
    ),
    :control_slacks => Dict(
        1 => Dict(
            "name" => "constraint_voltage_magnitude_setpoint",
            "element" => :bus,
            "variable" => "con_vol_mag_set",
            "filters" => [
                (bus, nw_ref) -> bus["bus_type"] in [2, 3] # PV, Vθ buses
            ],
            "type" => :equalto,
        ),
        2 => Dict(
            "name" => "constraint_power_balance_active",
            "element" => :bus,
            "variable" => "con_pow_bal_act",
            "filters" => [
            ],
            "type" => :equalto,
        ),
        3 => Dict(
            "name" => "constraint_power_balance_reactive",
            "element" => :bus,
            "variable" => "con_pow_bal_rea",
            "filters" => [
            ],
            "type" => :equalto,
        ),
        4 => Dict(
            "name" => "constraint_gen_setpoint_active",
            "element" => :gen,
            "variable" => "con_gen_set_act",
            "filters" => [
                (gen, nw_ref) -> gen["gen_status"] == 1,
                (gen, nw_ref) -> nw_ref[:bus][gen["gen_bus"]]["bus_type"] == 2,
            ],
            "type" => :equalto,
        )
    )
)
