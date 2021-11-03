#### Auxiliar Functions ####

has_control(pm::_PM.AbstractPowerModel) = haskey(ref(pm), :control_info)

has_control_variables(pm::_PM.AbstractPowerModel) = has_control(pm) && haskey(ref(pm, :control_info), :control_variables)

has_control_variables(pm::_PM.AbstractPowerModel, control_name::String) = has_control_variables(pm) && haskey(ref(pm, :control_info, :control_variables), control_name)

function ref_or_var(pm::_PM.AbstractPowerModel, nw::Int, i::Int, element::Symbol, var_name::String)
    # if the element is controlable, return a decision variable
    # if not, return the scalar value
    return try 
        var(pm, nw, Symbol(var_name))[i]
    catch
        ref(pm, nw, element, i, var_name)
    end
end

#### Create Control Variables Functions ####

function create_control_variables(
    pm::_PM.AbstractPowerModel, nw::Int, report::Bool, 
    control_name::String, var_name::String, el_sym::Symbol, start_val::Float64)
    @show control_name
    control_ids = ref(pm, nw, :control_info, :control_variables)[control_name]["indexes"]

    if !isempty(control_ids)
        control = var(pm, nw)[Symbol(var_name)] = JuMP.@variable(pm.model,
            [i in control_ids], base_name="$(nw)_"*var_name,
            start = BrazilianPowerModels._PM.comp_start_value(ref(pm, nw, el_sym, i), var_name*"_start", start_val) 
        )
        
        report && _PM.sol_component_value(pm, nw, el_sym, Symbol(var_name), control_ids, control)
    end
end

function create_control_variables(
    pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, report::Bool=true)
    for (name, control_variable) in ref(pm, nw, :control_info, :control_variables)
        create_control_variables(
            pm, nw, report, control_variable["name"], control_variable["variable"], 
            control_variable["element"], control_variable["start"]
        )
    end
end