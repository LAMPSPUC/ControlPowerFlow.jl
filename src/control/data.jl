_has_control_info(nw_ref::Dict) = haskey(nw_ref, :control_info)
_has_info(nw_ref::Dict) = haskey(nw_ref, :info)
_has_actions(nw_ref::Dict) = haskey(nw_ref, :info) && haskey(nw_ref[:info], :actions)
_has_generic_info(nw_ref, code) = typeof(nw_ref[:info][:actions][code]) <: Dict
_is_default_control(code) = haskey(default_control_actions, code)

_control_data(element::Dict) = element["control_data"]

function _controlled_by_shunt(nw_ref::Dict, bus::Dict; shunt_control_type = 2)
    return !isempty(
        findall(
            shunt -> shunt["status"] == 1 && 
            _control_data(shunt)["shunt_type"] == 2 && 
            _control_data(shunt)["shunt_control_type"] == shunt_control_type && 
            _control_data(shunt)["controlled_bus"] == bus["bus_i"], 
            nw_ref[:shunt]
            )
        )
end

function _controlled_by_transformer(nw_ref::Dict, bus::Dict; 
    control_type = "tap_control", constraint_type = "setpoint")

    status = pm_component_status["branch"]
    return !isempty(
        findall(
            branch -> branch[status] == 1 &&
                      _control_type(branch; control_type = control_type) &&
                      _constraint_type(branch; constraint_type  = constraint_type) &&
                      _controlled_bus(branch, bus["bus_i"]), 
            nw_ref[:branch])
        )
end

function _controlled_bus(element::Dict, bus::Int)
    return _control_data(element)["controlled_bus"] == bus
end

function _control_type(branch::Dict; control_type = "tap_control")
    return _control_data(branch)["control_type"] == control_type
end

function _constraint_type(branch::Dict; constraint_type = "setpoint")
    return _control_data(branch)["constraint_type"] == constraint_type
end

function _power_control(branch::Dict; power_control = "setpoint")
    return _control_data(branch)["power_control"] == power_control
end

