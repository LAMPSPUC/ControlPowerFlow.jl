# constraint name
# variable name
# weight in objective function
# slack associated element
# constraint type

const slack_info_default = Dict(
    "constraint_voltage_bounds"             => ("constraint_voltage_bounds",             "volt_bou",     1.0,  :bus,    :bound),
    "constraint_theta_ref"                  => ("constraint_theta_ref",                  "th_ref",       1.0,  :bus,    :equalto),
    "constraint_voltage_magnitude_setpoint" => ("constraint_voltage_magnitude_setpoint", "volt_mag_set", 1.0,  :bus,    :equalto),
    "constraint_gen_setpoint_active"        => ("constraint_gen_setpoint_active",        "gen_set_act",  1.0,  :gen,    :equalto),
    "constraint_gen_setpoint_reactive"      => ("constraint_gen_setpoint_reactive",      "gen_set_rea",  1.0,  :gen,    :equalto),
    "constraint_gen_active_bounds"          => ("constraint_gen_active_bounds",          "gen_act_bou",  1.0,  :gen,    :bound),
    "constraint_gen_reactive_bounds"        => ("constraint_gen_reactive_bounds",        "gen_rea_bou",  1.0,  :gen,    :bound),
    "constraint_power_balance_active"       => ("constraint_power_balance_active",       "pow_bal_act",  1.0,  :bus,    :equalto),
    "constraint_power_balance_reactive"     => ("constraint_power_balance_reactive",     "pow_bal_rea",  1.0,  :bus,    :equalto),
    "constraint_shunt_setpoint"             => ("constraint_shunt_setpoint",             "fix_shunt",    1.0,  :shunt,  :equalto),
    "constraint_shunt_bounds"               => ("constraint_shunt_bounds",               "var_shunt",    1.0,  :shunt,  :bound),
    "constraint_tap_ratio"                  => ("constraint_tap_ratio",                  "tap_rat",      1.0,  :branch, :bound),
    "constraint_tap_shift"                  => ("constraint_tap_shift",                  "tap_shi",      1.0,  :branch, :bound),
    "constraint_dcline_setpoint_active_fr"  => ("constraint_dcline_setpoint_active_fr",  "dc_fr",        1.0,  :dcline, :equalto),
    "constraint_dcline_setpoint_active_to"  => ("constraint_dcline_setpoint_active_to",  "dc_to",        1.0,  :dcline, :equalto),
)

##### slack_info functions ######

function _create_slack_info(slack::Dict)
    slack_info = Dict{Any, Any}() # Type must be {Any, Any} to avoid interactions with instantiate_data in PowerModels
    for (key, defaults) in slack_info_default
            (name, variable, weight, element, type) = slack_info_default[key]
            info = Dict{String, Any}()
            info["name"]     = name
            info["variable"] = variable
            info["weight"]   = weight
            info["element"]  = element
            info["type"]     = type
            
            slack_info[key]  = info
    end
    if !isempty(setdiff(keys(slack), keys(slack_info_default)))
        error("Invalid control option. Verify control dictionary inside network data")   
    end
    return slack_info
end

function _verify_info!(info::Dict, key::String, type)
    @assert haskey(info, key)
    @assert (typeof(info[key]) == type) || (typeof(info[key]) == Nothing)
end

function _verify_slack_info!(slack_info::Dict)
    for (constraint, info) in slack_info
        @assert typeof(info) <: Dict
        _verify_info!(info, "name",     String)
        _verify_info!(info, "variable", String)
        _verify_info!(info, "weight",   Float64)
        _verify_info!(info, "element",  Symbol)
        _verify_info!(info, "type",     Symbol)
    end
end
function handle_slack_info!(network::Dict)
    if haskey(network, "slack_info")
        _verify_slack_info!(network["slack_info"])
    else
        if !haskey(network, "slack")
            network["slack"] = Dict{Any, Any}()
        end
        network["slack_info"] = _create_slack_info(network["slack"])
    end
    return
end

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

function handle_slack_indexes(pm, nw, element, constraint)
    or_ids = ids(pm, nw, element)
    slack = ref(pm, nw, :slack)
    filt_ids = haskey(slack, constraint) ? slack[constraint] : Int[]
    final_ids = or_ids
    if filt_ids != true
        try
            final_ids = intersection(or_ids, filt_ids)
        catch
            @error("Failed to create slack variable in $funct. "
                        * "Check slack variable dictionary for possible mistake")
        end
    end
    ref(pm, nw, :slack_info)[constraint]["indexes"] = final_ids
    ref(pm, nw, :slack_info)[constraint]["has_slack"] = isempty(final_ids) ? false : true
end


########### variables ###########


function prepare_slack_info(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default)
    for (constraint_name, slack) in ref(pm, nw, :slack_info)
        name = slack["name"]
        element = slack["element"]
        handle_slack_indexes(pm, nw, element, name)
    end
end

########### constraint ############
