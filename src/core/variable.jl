"variable: `t[i]` for `i` in `shunt`es"
function variable_shunt(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)
    bs = var(pm, nw)[:bs] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :shunt)], base_name="$(nw)_bs",
        start = _PM.comp_start_value(ref(pm, nw, :shunt, i), "bs_start")
    )

    report && _PM.sol_component_value(pm, nw, :shunt, :bs, ids(pm, nw, :shunt), bs)
end

