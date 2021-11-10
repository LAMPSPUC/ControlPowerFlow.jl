
## 

has_slack_variables(pm::_PM.AbstractPowerModel)  = has_control(pm) && haskey(ref(pm, :control_info), :slack_variables)
has_slack_variables(pm::_PM.AbstractPowerModel, constraint_name::String) = has_slack_variables(pm) && haskey(ref(pm, :control_info, :slack_variables), constraint_name) && !isempty(ref(pm, :control_info, :slack_variables)[constraint_name]["indexes"])

function create_slack_variables_bound(
    pm::_PM.AbstractPowerModel, nw::Int, report::Bool, 
    constraint_name::String, name::String, el_sym::Symbol)

    pos_nm = "sl_"*name*"_upp"
    neg_nm = "sl_"*name*"_low"

    slack_ids = ref(pm, nw, :control_info, :slack_variables)[constraint_name]["indexes"]

    if !isempty(slack_ids)
        slack_pos = var(pm, nw)[Symbol(pos_nm)] = JuMP.@variable(pm.model,
            [i in slack_ids], base_name="$(nw)_"*pos_nm,
            start = ControlPowerFlow._PM.comp_start_value(ref(pm, nw, el_sym, i), pos_nm*"_start")
        )
        
        slack_neg = var(pm, nw)[Symbol(neg_nm)] = JuMP.@variable(pm.model,
            [i in slack_ids], base_name="$(nw)_"*neg_nm,
            start = ControlPowerFlow._PM.comp_start_value(ref(pm, nw, el_sym, i), neg_nm*"_start")
        )

        report && ControlPowerFlow._PM.sol_component_value(pm, nw, el_sym, Symbol(pos_nm), slack_ids, slack_pos)
        report && ControlPowerFlow._PM.sol_component_value(pm, nw, el_sym, Symbol(neg_nm), slack_ids, slack_neg)
    end
end

function create_slack_variables_equalto(
    pm::_PM.AbstractPowerModel, nw::Int, report::Bool, 
    constraint_name::String, name::String, el_sym::Symbol)
    
    eq_to_nm = "sl_"*name

    slack_ids = ref(pm, nw, :control_info, :slack_variables)[constraint_name]["indexes"]

    if !isempty(slack_ids)
        slack = var(pm, nw)[Symbol(eq_to_nm)] = JuMP.@variable(pm.model,
            [i in slack_ids], base_name="$(nw)_"*eq_to_nm,
            start = ControlPowerFlow._PM.comp_start_value(ref(pm, nw, el_sym, i), eq_to_nm*"_start")
        )

        report && ControlPowerFlow._PM.sol_component_value(pm, nw, el_sym, Symbol(eq_to_nm), slack_ids, slack)
    end
end

function create_slack_variables(
    pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, report::Bool=true)

    for (name, slack_variable) in ref(pm, nw, :control_info, :slack_variables)
        if slack_variable["type"] == :bound 

            create_slack_variables_bound(
                pm, nw, report, 
                slack_variable["name"], slack_variable["variable"], slack_variable["element"]
            )

        elseif slack_variable["type"] == :equalto  

            create_slack_variables_equalto(
                pm, nw, report, 
                slack_variable["name"], slack_variable["variable"], slack_variable["element"]
            )

        end
    end
end


########### constraint ############

function slack_in_equality_constraint(
    pm::_PM.AbstractPolarModels, n::Int, i,
    constraint_name::String, slack)
    
    slack_info = ref(pm, n, :control_info, :slack_variables)[constraint_name]
    if i in slack_info["indexes"]
        var_nm = slack_info["variable"]
        eq_to_nm = "sl_"*var_nm

        return var(pm, n, Symbol(eq_to_nm))[i]
    end
    return 0.0
end

function slack_in_equality_constraint(
    pm::_PM.AbstractPolarModels, n::Int, i,
    constraint_name::String)
    slack = 0.0
    
    if has_slack_variables(pm, constraint_name)
        slack += slack_in_equality_constraint(pm, n, i, constraint_name, slack)
    end

    return slack
end

function slack_in_upper_constraint(
    pm::_PM.AbstractPolarModels, n::Int, i,
    constraint_name::String, slack)

    slack_info = ref(pm, n, :control_info, :slack_variables)[constraint_name]
    if i in slack_info["indexes"]
        var_nm = slack_info["variable"]
        pos_nm = "sl_"*var_nm*"_upp"

        return var(pm, n, Symbol(pos_nm))[i]
    end
    return 0.0
end

function slack_in_lower_constraint(
    pm::_PM.AbstractPolarModels, n::Int, i,
    constraint_name::String, slack)

    slack_info = ref(pm, n, :control_info, :slack_variables)[constraint_name]
    if i in slack_info["indexes"]
        var_nm = slack_info["variable"]
        neg_nm = "sl_"*var_nm*"_low"

        return var(pm, n, Symbol(neg_nm))[i]
    end
    return 0.0
end

function slack_in_bound_constraint(
    pm::_PM.AbstractPolarModels, n::Int, i,
    constraint_name::String)
    
    up  = 0.0
    low = 0.0
    
    if has_slack_variables(pm, constraint_name)
        up  += slack_in_upper_constraint(pm, n, i, constraint_name, up)
        low += slack_in_lower_constraint(pm, n, i, constraint_name, low)
    end

    return up, low
end