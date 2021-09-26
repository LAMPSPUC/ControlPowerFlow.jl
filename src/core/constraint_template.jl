function constraint_shunt(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)
    for (s, shunt) in elements_from_bus(pm, :shunt, i, nw)
        if shunt["shunt_type"] == 1 # fixed
            constraint_fixed_shunt(pm, s, shunt)
        elseif shunt["shunt_type"] == 2 # variable
            constraint_variable_shunt(pm, s, shunt)
        end
    end
end

function constraint_power_balance(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)
    bus = ref(pm, nw, :bus, i)
    bus_arcs = ref(pm, nw, :bus_arcs, i)
    bus_arcs_dc = ref(pm, nw, :bus_arcs_dc, i)
    bus_arcs_sw = ref(pm, nw, :bus_arcs_sw, i)
    bus_gens = ref(pm, nw, :bus_gens, i)
    bus_loads = ref(pm, nw, :bus_loads, i)
    bus_shunts = ref(pm, nw, :bus_shunts, i)
    bus_storage = ref(pm, nw, :bus_storage, i)

    bus_pd = Dict(k => ref(pm, nw, :load, k, "pd") for k in bus_loads)
    bus_qd = Dict(k => ref(pm, nw, :load, k, "qd") for k in bus_loads)

    bus_gs = Dict(k => ref(pm, nw, :shunt, k, "gs") for k in bus_shunts)
    bus_bs = Dict(k => var(pm, nw, :bs, k) for k in bus_shunts)

    constraint_power_balance(
        pm, nw, i, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs
    )
end

