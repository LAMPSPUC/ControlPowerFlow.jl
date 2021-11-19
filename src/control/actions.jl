# Default Actions
const default_control_actions = Dict(
    "qlim" => qlim_info,
    "vlim" => vlim_info,
    "csca" => csca_info,
    "ctap" => ctap_info,
    "ctaf" => ctaf_info,
    "cphs" => cphs_info,
    "cslv" => cslv_info
)

# Generic info verifications 

function _verify_filters!(generic_info::Dict, control_action::Symbol, n)
    filters = generic_info[control_action][n]["filters"]
    for f in filters
        m = first(methods(f))
        if m.nargs != 3
            error("Wrong number of arguments in filter inside 'generic_info', action '$(control_action)', key '$n'." * 
                                                    " Expected 2 arguments, received 1")
        end
    end
end

function _verify_generic_control_variables!(generic_info::Dict)
    control_variables = generic_info[:control_variables]
    for k in keys(control_variables)
        _verify_key!(generic_info, :control_variables, k, "name", String)
        _verify_key!(generic_info, :control_variables, k, "variable", String)
        _verify_key!(generic_info, :control_variables, k, "element", Symbol)
        _verify_key!(generic_info, :control_variables, k, "start", Number)
        _verify_key!(generic_info, :control_variables, k, "filters", Vector)
        _verify_filters!(generic_info, :control_variables, k)
    end
end

function _verify_generic_control_constraints!(generic_info::Dict)
    control_constraints = generic_info[:control_constraints]
    for k in keys(control_constraints)
        _verify_key!(generic_info, :control_constraints, k, "name", String)
        _verify_key!(generic_info, :control_constraints, k, "element", Symbol)
        _verify_key!(generic_info, :control_constraints, k, "filters", Vector)
        _verify_filters!(generic_info, :control_constraints, k)
    end
end

function _verify_generic_control_slacks!(generic_info::Dict)
    control_slacks = generic_info[:control_slacks]
    for k in keys(control_slacks)
        _verify_key!(generic_info, :control_slacks, k, "name", String)
        _verify_key!(generic_info, :control_slacks, k, "variable", String)
        _verify_key!(generic_info, :control_slacks, k, "element", Symbol)
        _verify_key!(generic_info, :control_slacks, k, "type", Symbol)
        _verify_key!(generic_info, :control_slacks, k, "filters", Vector)
        _verify_filters!(generic_info, :control_slacks, k)
    end
end

function _handle_generic_info!(generic_info::Dict)
    if !haskey(generic_info, :controllable_bus)
        generic_info[:controllable_bus] = false
    end
    if !haskey(generic_info, :control_variables)
        generic_info[:control_variables] = Dict{Any, Any}()
    end
    if !haskey(generic_info, :control_constraints)
        generic_info[:control_constraints] = Dict{Any, Any}()
    end
    if !haskey(generic_info, :control_slacks)
        generic_info[:control_slacks] = Dict{Any, Any}()
    end
    _verify_generic_control_variables!(generic_info)
    _verify_generic_control_constraints!(generic_info)
    _verify_generic_control_slacks!(generic_info) 
    return true
end

function _has_control(nw_ref::Dict, control::String) 
    if haskey(nw_ref[:info]["actions"], control)
        if typeof(nw_ref[:info]["actions"][control]) == Bool
            return nw_ref[:info]["actions"][control]
        else
            return _handle_generic_info!(nw_ref[:info]["actions"][control])
        end
    end
end

# Control Info verifications 

function ids_nw_ref(nw_ref::Dict, element::Symbol; filters::Vector = [])
    return findall(
            x -> (
                all([f(x, nw_ref) for f in filters])
            ), 
            nw_ref[element]
        )
end

function _verify_key!(control_info::Dict, control_action::Symbol, n, key::String, type::Type)
    control = control_info[control_action][n]
    if !haskey(control, key)
        error("Error in ':control_info' data inside '$control_action' field: missing '$key' information") 
    end
    if !(typeof(control[key]) <: type)
        error("Error in ':control_info' data inside '$control_action' - '$key' field. Expected type '$type' and received '$(typeof(control[key]))'") 
    end
end

function _verify_control_variables!(control_info::Dict)
    control_variables = control_info[:control_variables]
    for k in keys(control_variables)
        _verify_key!(control_info, :control_variables, k, "name", String)
        _verify_key!(control_info, :control_variables, k, "variable", String)
        _verify_key!(control_info, :control_variables, k, "element", Symbol)
        _verify_key!(control_info, :control_variables, k, "start", Number)
        _verify_key!(control_info, :control_variables, k, "indexes", Vector{Int})
    end
end

function _verify_control_constraints!(control_info::Dict)
    control_constraints = control_info[:control_constraints]
    for k in keys(control_constraints)
        _verify_key!(control_info, :control_constraints, k, "name", String)
        _verify_key!(control_info, :control_constraints, k, "element", Symbol)
        _verify_key!(control_info, :control_constraints, k, "indexes", Vector{Int})
    end
end

function _verify_control_slacks!(control_info::Dict)
    control_slacks = control_info[:control_slacks]
    for k in keys(control_slacks)
        _verify_key!(control_info, :control_slacks, k, "name", String)
        _verify_key!(control_info, :control_slacks, k, "variable", String)
        _verify_key!(control_info, :control_slacks, k, "weight", Number)
        _verify_key!(control_info, :control_slacks, k, "element", Symbol)
        _verify_key!(control_info, :control_slacks, k, "indexes", Vector{Int})
        _verify_key!(control_info, :control_slacks, k, "type", Symbol)
    end
end

function _control_info()
    return Dict{Any, Any}(
        :controllable_bus    => false,
        :control_variables   => Dict{Any, Any}(),
        :control_constraints => Dict{Any, Any}(),
        :control_slacks     => Dict{Any, Any}()
    )
end

function _handle_control_info!(control_info::Dict)
    if !haskey(control_info, :controllable_bus)
        control_info[:controllable_bus] = false
    end
    if !haskey(control_info, :control_variables)
        control_info[:control_variables] = Dict{Any, Any}()
    end
    if !haskey(control_info, :control_constraints)
        control_info[:control_constraints] = Dict{Any, Any}()
    end
    if !haskey(control_info, :control_slacks)
        control_info[:control_slacks] = Dict{Any, Any}()
    end
    _verify_control_variables!(control_info)
    _verify_control_constraints!(control_info)
    _verify_control_slacks!(control_info)
    return true
end

function _handle_control_variables!(nw_ref::Dict, info::Dict)    
    control_variables = nw_ref[:control_info][:control_variables]
    for (i, nw_info) in info
        name       = nw_info["name"]
        variable   = nw_info["variable"]
        element    = nw_info["element"]
        start      = nw_info["start"]
        filters    = nw_info["filters"]
        nw_indexes = ids_nw_ref(nw_ref, element; filters = filters)
        if haskey(control_variables, name)
            control_variables[name]["indexes"] = unique(vcat(
                control_variables[name]["indexes"], 
                nw_indexes
            ))
        else
            nw_constraint = Dict{Any, Any}()
            nw_constraint["name"]     = name
            nw_constraint["variable"] = variable
            nw_constraint["element"]  = element
            nw_constraint["start"]    = start
            nw_constraint["indexes"]  = nw_indexes
            control_variables[name] = nw_constraint
        end
    end
    return
end

function _handle_control_constraints!(nw_ref::Dict, info::Dict)    
    control_constraints = nw_ref[:control_info][:control_constraints]
    for (i, nw_info) in info
        constraint_name = nw_info["name"]
        element         = nw_info["element"]
        filters         = nw_info["filters"]
        nw_indexes      = ids_nw_ref(nw_ref, element; filters = filters)
        if haskey(control_constraints, constraint_name)
            control_constraints[constraint_name]["indexes"] = unique(vcat(
                control_constraints[constraint_name]["indexes"], 
                nw_indexes
            ))
        else
            nw_constraint = Dict{Any, Any}()
            nw_constraint["name"]    = constraint_name
            nw_constraint["element"] = element
            nw_constraint["indexes"] = nw_indexes
            control_constraints[constraint_name] = nw_constraint
        end
    end
    return 
end

function _handle_control_slacks!(nw_ref::Dict, info::Dict)
    control_slacks = nw_ref[:control_info][:control_slacks]
    for (i, nw_info) in info
        constraint_name = nw_info["name"]
        element         = nw_info["element"]
        variable        = nw_info["variable"]
        filters         = nw_info["filters"]
        type            = nw_info["type"]
        nw_indexes = ids_nw_ref(nw_ref, element; filters = filters)
        if haskey(control_slacks, constraint_name)
            control_slacks[constraint_name]["indexes"] = unique(vcat(
                control_slacks[constraint_name]["indexes"], 
                nw_indexes
            ))
        else
            nw_constraint = Dict{Any, Any}()
            nw_constraint["name"]     = constraint_name
            nw_constraint["variable"] = variable
            nw_constraint["weight"]   = 1.0
            nw_constraint["element"]  = element
            nw_constraint["indexes"]  = nw_indexes
            nw_constraint["type"]     = type
            control_slacks[constraint_name] = nw_constraint
        end
    end
end

function _control(nw_ref::Dict, info::Dict)
    _handle_control_variables!(nw_ref, info[:control_variables])
    _handle_control_constraints!(nw_ref, info[:control_constraints])
    _handle_control_slacks!(nw_ref, info[:control_slacks])
end

function _handle_control_info(pm::_PM.AbstractPowerModel)
    nw_ref = ref(pm)
    if !_has_control_info(nw_ref)
        nw_ref[:control_info] = _control_info()
    else
        _handle_control_info!(nw_ref[:control_info])
    end
    if _has_actions(nw_ref) # control actions inside network -> data["info"]["action"]
        for code in keys(nw_ref[:info]["actions"])
            if _is_default_control(code) # if
                _has_control(nw_ref, code) ? _control(nw_ref, default_control_actions[code]) : nothing
            elseif _has_generic_info(nw_ref, code)
                _has_control(nw_ref, code) ? _control(nw_ref, nw_ref[:info]["actions"][code]) : nothing
            else
                @warn("Control $code not recognized. If your want to use this control, please insert a generic control info attached to it.")
            end
        end
    end 
end