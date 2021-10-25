const control_function = Dict(
    "shunt"   => ("shunt", "bs",    :shunt,  :shunt  , 0.0),
    "tap"     => ("tap",   "tap",   :branch, :branch , 1.0),
    "shift"   => ("shift", "shift", :branch, :branch , 0.0),
    # controls bellow don't need additional control variables
    "voltage"      => ("voltage",      nothing, :bus, nothing, nothing),
    "gen_active"   => ("gen_active",   nothing, :gen, nothing, nothing),
    "gen_reactive" => ("gen_reactive", nothing, :gen, nothing, nothing),
)

########### auxiliar  ###########

function handle_control_indexes(pm, nw, element, funct)
    or_ids = ids(pm, nw, element)
    filt_ids = ref(pm, nw, :control, funct)
    final_ids = or_ids
    if filt_ids != true
        try
            final_ids = intersection(or_ids, filt_ids)
        catch
            @error("Failed to create control variable in $funct. "
                        * "Check control variable dictionary for possible mistake")
        end
    end
    return final_ids
end

function ref_or_var(pm::_PM.AbstractPowerModel, n::Int, i::Int, funct_name::String)
    var_name, element = BrazilianPowerModels.control_function[funct_name][[2,3]]
    
    # if the element is controlable, return a decision variable
    # if not, return the scalar value
    if has_control(pm) && haskey(ref(pm, n, :control), funct_name)
        var_idxs = ref(pm, n, :control, funct_name)
        if var_idxs == true || i in var_idxs
            return var(pm, n, Symbol(var_name))[i]
        end
    end

    return ref(pm, n, element, i, var_name)
end

function has_control(pm::_PM.AbstractPowerModel)
    return haskey(ref(pm), :control)
end

function has_control(pm::_PM.AbstractPowerModel, funct_name::String)
    return has_control(pm) && haskey(ref(pm, :control), funct_name)
end

function pv_bus(pm::_PM.AbstractPowerModel, i::Int)
    return length(ref(pm, :bus_gens, i)) > 0 && !(i in ids(pm,:ref_buses))
end

function pq_bus(pm::_PM.AbstractPowerModel, i::Int)
    return length(ref(pm, :bus_gens, i)) == 0 
end

########### variables ###########

function variable_control(
    pm::_PM.AbstractPowerModel, nw::Int, bounded::Bool, report::Bool, 
    funct_name::String, var_name::String, el_sym::Symbol, sol_el_sym::Symbol,
    start_val::Float64)

    control_ids = handle_control_indexes(pm, nw, el_sym, funct_name)

    control = var(pm, nw)[Symbol(var_name)] = JuMP.@variable(pm.model,
        [i in control_ids], base_name="$(nw)_"*var_name,
        start = BrazilianPowerModels._PM.comp_start_value(ref(pm, nw, sol_el_sym, i), var_name*"_start", start_val) 
    )
    
    report && BrazilianPowerModels._PM.sol_component_value(pm, nw, sol_el_sym, Symbol(var_name), control_ids, control)
end

function variable_control(
    pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)
    for (funct_name, control) in ref(pm, nw, :control)
        if haskey(control_function, funct_name)
            args = control_function[funct_name]
            if !(args[2] === nothing)
                variable_control(pm, nw, bounded, report, args[1], args[2], args[3], args[4], args[5])
            end
        else
            @warn("There is no control called $funct_name. Creating model without it")
        end
    end
end

########## constraints ##########

function create_control_constraint(pm::_PM.AbstractPowerModel, nw::Int, i::Int, funct_name::String)
    element = control_function[funct_name][3]
    return i in handle_control_indexes(pm, nw, element, funct_name)
end

