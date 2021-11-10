has_control_constraints(pm::_PM.AbstractPowerModel) = has_control(pm) && haskey(ref(pm, :control_info), :control_constraints)

has_control_constraints(pm::_PM.AbstractPowerModel, constraint_name::String) = has_control_constraints(pm) && haskey(ref(pm, :control_info, :control_constraints), constraint_name)

has_controlled_bus(pm::_PM.AbstractPowerModel) = has_control(pm) && haskey(ref(pm, :control_info), :cotrolled_bus) && ref(pm, :control_info, :cotrolled_bus)

function controlled_bus(pm::_PM.AbstractPowerModel, i::Int, cont_key::String, key::String) 
    if has_controlled_bus(pm)
        _PM.ref(pm, :bus, i, cont_key)
    else
        _PM.ref(pm, :bus, i, key)
    end
end

function create_control_constraint(pm::_PM.AbstractPowerModel, nw::Int, i::Int, constraint_name::String)
    if has_control_constraints(pm, constraint_name)
        return i in ref(pm, nw, :control_info, :control_constraints)[constraint_name]["indexes"]
    end
    return false
end

function ctr_ids(pm::_PM.AbstractPowerModel, constraint_name::String)
    if haskey(ref(pm, :control_info, :control_constraints), constraint_name)
        return ref(pm, :control_info, :control_constraints, constraint_name)["indexes"]
    end
    return Int[]
end
