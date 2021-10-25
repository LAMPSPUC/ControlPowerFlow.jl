const bus_key = Dict(:shunt => "shunt_bus", :gen => "gen_bus", :load => "load_bus")

controlled_bus(pm::_PM.AbstractPowerModel, i::Int) = _PM.ref(pm, :bus, i, "voltage_controlled_bus")

function elements_from_bus(pm::BrazilianPowerModels._PM.AbstractPowerModel, 
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