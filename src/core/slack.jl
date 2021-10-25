const slack_function = Dict(
    "constraint_voltage_bounds"             => ("constraint_voltage_bounds",             "volt_bou",      :bus,       :bus),
    "constraint_theta_ref"                  => ("constraint_theta_ref",                  "th_ref",        :ref_buses, :bus),
    "constraint_voltage_magnitude_setpoint" => ("constraint_voltage_magnitude_setpoint", "volt_mag_set",  :bus,       :bus),
    "constraint_gen_setpoint_active"        => ("constraint_gen_setpoint_active",        "gen_set_act",   :gen,       :gen),
    "constraint_gen_setpoint_reactive"      => ("constraint_gen_setpoint_reactive",      "gen_set_rea",   :gen,       :gen),
    "constraint_gen_active_bounds"          => ("constraint_gen_active_bounds",          "gen_act_bou",   :gen,       :gen),
    "constraint_gen_reactive_bounds"        => ("constraint_gen_reactive_bounds",        "gen_rea_bou",   :gen,       :gen),
    "constraint_power_balance_active"       => ("constraint_power_balance_active",       "pow_bal_act",   :bus,       :bus),
    "constraint_power_balance_reactive"     => ("constraint_power_balance_reactive",     "pow_bal_rea",   :bus,       :bus),
    "constraint_shunt"                      => ("constraint_shunt",                      "shunt",         :shunt,     :shunt),
    "constraint_tap_ratio"                  => ("constraint_tap_ratio",                  "tap_rat",       :branch,    :branch),
    "constraint_tap_shift"                  => ("constraint_tap_shift",                  "tap_shi",       :branch,    :branch),
    "constraint_dcline_setpoint_active_fr"  => ("constraint_dcline_setpoint_active_fr",  "dc_set_act_fr", :dcline,    :dcline),
    "constraint_dcline_setpoint_active_to"  => ("constraint_dcline_setpoint_active_to",  "dc_set_act_to", :dcline,    :dcline),
)

########### auxiliar  ###########

function intersection(a, b)
    intersect = Int[]
    for (i, j) in enumerate(a)
        if j in b
            push!(intersect, j)
        end
    end
    return intersect
end

function handle_slack_indexes(pm, nw, element, funct)
    or_ids = ids(pm, nw, element)
    filt_ids = ref(pm, nw, :slack, funct)
    final_ids = or_ids
    if filt_ids != true
        try
            final_ids = intersection(or_ids, filt_ids)
        catch
            @error("Failed to create slack variable in $funct. "
                        * "Check slack variable dictionary for possible mistake")
        end
    end
    return final_ids
end

function has_slack(pm::_PM.AbstractPowerModel)
    return haskey(ref(pm), :slack)
end

########### variables ###########

function variable_slack(
    pm::_PM.AbstractPowerModel, nw::Int, bounded::Bool, report::Bool, 
    funct_name::String, name::String, el_sym::Symbol, sol_el_sym::Symbol)

    pos_nm = "sl_"*name*"_pos"
    neg_nm = "sl_"*name*"_neg"

    slack_ids = handle_slack_indexes(pm, nw, el_sym, funct_name)

    slack_pos = var(pm, nw)[Symbol(pos_nm)] = JuMP.@variable(pm.model,
        [i in slack_ids], base_name="$(nw)_"*pos_nm, lower_bound = 0,
        start = BrazilianPowerModels._PM.comp_start_value(ref(pm, nw, sol_el_sym, i), pos_nm*"_start")
    )
    
    slack_neg = var(pm, nw)[Symbol(neg_nm)] = JuMP.@variable(pm.model,
        [i in slack_ids], base_name="$(nw)_"*neg_nm, lower_bound = 0,
        start = BrazilianPowerModels._PM.comp_start_value(ref(pm, nw, sol_el_sym, i), neg_nm*"_start")
    )

    report && BrazilianPowerModels._PM.sol_component_value(pm, nw, sol_el_sym, Symbol(pos_nm), slack_ids, slack_pos)
    report && BrazilianPowerModels._PM.sol_component_value(pm, nw, sol_el_sym, Symbol(neg_nm), slack_ids, slack_neg)
end

function variable_slack(
    pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)

    for (funct_name, slack) in ref(pm, nw, :slack)
        if haskey(slack_function, funct_name)
            args = slack_function[funct_name]
            variable_slack(pm, nw, bounded, report, args[1], args[2], args[3], args[4])
        else
            @warn("There is no constraint called $funct_name to create slack variables")
        end
    end

end

########### constraint ############

function slack_in_equality_constraint(
    pm::_PM.AbstractPolarModels, n::Int, i::Int,
    funct_name::String, slack)
    
    var_idxs = ref(pm, n, :slack, funct_name)
    if var_idxs == true || i in var_idxs
        var_nm = BrazilianPowerModels.slack_function[funct_name][2]
        pos_nm = "sl_"*var_nm*"_pos"
        neg_nm = "sl_"*var_nm*"_neg"

        return (var(pm, n, Symbol(pos_nm))[i] - var(pm, n, Symbol(neg_nm))[i])
    end
    return 0.0
end

function slack_in_equality_constraint(
    pm::_PM.AbstractPolarModels, n::Int, i::Int,
    funct_name::String)
    slack = 0.0
    
    if haskey(ref(pm), :slack) && haskey(ref(pm, n, :slack), funct_name)
        slack += slack_in_equality_constraint(pm, n, i, funct_name, slack)
    end

    return slack
end

function slack_in_upper_constraint(
    pm::_PM.AbstractPolarModels, n::Int, i::Int,
    funct_name::String, slack)

    var_idxs = ref(pm, n, :slack, funct_name)
    if var_idxs == true || i in var_idxs
        var_nm = BrazilianPowerModels.slack_function[funct_name][2]
        pos_nm = "sl_"*var_nm*"_pos"

        return var(pm, n, Symbol(pos_nm))[i]
    end
    return 0.0
end

function slack_in_lower_constraint(
    pm::_PM.AbstractPolarModels, n::Int, i::Int,
    funct_name::String, slack)

    var_idxs = ref(pm, n, :slack, funct_name)
    if var_idxs == true || i in var_idxs
        var_nm = BrazilianPowerModels.slack_function[funct_name][2]
        neg_nm = "sl_"*var_nm*"_neg"

        return var(pm, n, Symbol(neg_nm))[i]
    end
    return 0.0
end

function slack_in_bound_constraint(
    pm::_PM.AbstractPolarModels, n::Int, i::Int,
    funct_name::String)
    
    up  = 0.0
    low = 0.0
    
    if haskey(ref(pm), :slack) && haskey(ref(pm, n, :slack), funct_name)
        up  += slack_in_upper_constraint(pm, n, i, funct_name, up)
        low += slack_in_lower_constraint(pm, n, i, funct_name, low)
    end

    return up, low
end
