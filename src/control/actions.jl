_has_control(nw_ref::Dict, control::String) = haskey(nw_ref[:info], control) && nw_ref[:info][control]

function ids_nw_ref(nw_ref::Dict, element::Symbol; filters::Vector = [])
    return findall(
            x -> (
                all([f(x, nw_ref) for f in filters])
            ), 
            nw_ref[element]
        )
end

function _control_info()
    return Dict{Any, Any}(
        :controllable_bus    => false,
        :control_variables   => Dict{Any, Any}(),
        :control_constraints => Dict{Any, Any}(),
        :slack_variables     => Dict{Any, Any}()
    )
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
            control_variables[name]["indexes"] = vcat(
                control_variables[name]["indexes"], 
                nw_indexes
            )
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
        constraint_name = nw_info["constraint"]
        element         = nw_info["element"]
        filters         = nw_info["filters"]
        nw_indexes      = ids_nw_ref(nw_ref, element; filters = filters)
        if haskey(control_constraints, constraint_name)
            control_constraints[constraint_name]["indexes"] = vcat(
                control_constraints[constraint_name]["indexes"], 
                nw_indexes
            )
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

function _handle_slack_variables!(nw_ref::Dict, info::Dict)
    slack_variables = nw_ref[:control_info][:slack_variables]
    for (i, nw_info) in info
        constraint_name = nw_info["constraint"]
        element         = nw_info["element"]
        variable        = nw_info["variable"]
        filters         = nw_info["filters"]
        type            = nw_info["type"]
        nw_indexes = ids_nw_ref(nw_ref, element; filters = filters)
        if haskey(slack_variables, constraint_name)
            slack_variables[constraint_name]["indexes"] = vcat(
                slack_variables[constraint_name]["indexes"], 
                nw_indexes
            )
        else
            nw_constraint = Dict{Any, Any}()
            nw_constraint["name"]     = constraint_name
            nw_constraint["variable"] = variable
            nw_constraint["weight"]   = 1.0
            nw_constraint["element"]  = element
            nw_constraint["indexes"]  = nw_indexes
            nw_constraint["type"]     = type
            slack_variables[constraint_name] = nw_constraint
        end
    end
end

function _control(nw_ref::Dict, info::Dict)
    _handle_control_variables!(nw_ref, info["control_variables"])
    _handle_control_constraints!(nw_ref, info["control_constraints"])
    _handle_slack_variables!(nw_ref, info["slack_variables"])
end

function _handle_control_info(pm::_PM.AbstractPowerModel)
    nw_ref = ref(pm)
    if haskey(nw_ref, :info) && !isempty(ref(nw_ref, :info))
        nw_ref[:control_info] = _control_info()
        _has_control(nw_ref, "qlim") ? _control(nw_ref, qlim_info) : nothing
        _has_control(nw_ref, "vlim") ? _control(nw_ref, vlim_info) : nothing
        _has_control(nw_ref, "crem") ? _control(nw_ref, crem_info) : nothing
        _has_control(nw_ref, "csca") ? _control(nw_ref, csca_info) : nothing
        _has_control(nw_ref, "ctap") ? _control(nw_ref, ctap_info) : nothing
        _has_control(nw_ref, "ctaf") ? _control(nw_ref, ctaf_info) : nothing
        _has_control(nw_ref, "cphs") ? _control(nw_ref, cphs_info) : nothing
        _has_control(nw_ref, "cint") ? _control(nw_ref, cint_info) : nothing
    end 
end