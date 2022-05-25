const bus_key = Dict(:shunt => "shunt_bus", :gen => "gen_bus", :load => "load_bus")

""
abstract type ControlAbstractModel <: _PM.AbstractPowerModel end

""
abstract type ControlAbstractACRModel <: ControlAbstractModel end

""
mutable struct ControlACRPowerModel <: ControlAbstractACRModel @pm_fields end

""
abstract type ControlAbstractIVRModel <: ControlAbstractACRModel end

""
mutable struct ControlIVRPowerModel <: ControlAbstractIVRModel @pm_fields end

""
abstract type ControlAbstractACPModel <: ControlAbstractModel end

""
mutable struct ControlACPPowerModel <: ControlAbstractACPModel @pm_fields end

ControlAbstractPolarModels = Union{ControlACPPowerModel}

# functions

pv_bus(pm::_PM.AbstractPowerModel, i::Int) = length(ref(pm, :bus_gens, i)) > 0 && !(i in ids(pm,:ref_buses))

pq_bus(pm::_PM.AbstractPowerModel, i::Int) = length(ref(pm, :bus_gens, i)) == 0 

controlled_bus(pm::_PM.AbstractPowerModel, i::Int) = _PM.ref(pm, :bus, i, "control_data")["voltage_controlled_bus"]

function elements_from_bus(pm::ControlPowerFlow._PM.AbstractPowerModel, 
                          element::Symbol, bus::Int, nw::Int; 
                          filters::Vector = [])

    filters = vcat(filters, [shunt->shunt[bus_key[element]] == bus])
    filtered_keys = findall(
            x -> (
                all([f(x) for f in filters])
            ), 
            ref(pm, nw, element)
        )
    return Dict(k => ref(pm, nw, element, k) for k in filtered_keys)
end