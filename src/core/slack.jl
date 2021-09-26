########### variables ###########

function variable_slack(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)
    variable_slack_th_ref_pos(pm, nw, bounded, report)
    variable_slack_th_ref_neg(pm, nw, bounded, report)
    variable_slack_volt_sp_pos(pm, nw, bounded, report)
    variable_slack_volt_sp_neg(pm, nw, bounded, report)
    

    variable_slack_const_balance_p_pos(pm, nw, bounded, report)
    variable_slack_const_balance_p_neg(pm, nw, bounded, report)
    variable_slack_const_balance_q_pos(pm, nw, bounded, report)
    variable_slack_const_balance_q_neg(pm, nw, bounded, report)
end

function variable_slack_th_ref_pos(pm::_PM.AbstractPowerModel, nw::Int, bounded::Bool, report::Bool)
    sl_th_ref_pos = var(pm, nw)[:sl_th_ref_pos] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :ref_buses)], base_name="$(nw)_sl_th_ref_pos", lower_bound = 0,
        start = _PM.comp_start_value(ref(pm, nw, :ref_buses, i), "sl_th_ref_pos_start")
    )

    report && _PM.sol_component_value(pm, nw, :ref_buses, :sl_th_ref_pos, ids(pm, nw, :ref_buses), sl_th_ref_pos)
end

function variable_slack_th_ref_neg(pm::_PM.AbstractPowerModel, nw::Int, bounded::Bool, report::Bool)
    sl_th_ref_neg = var(pm, nw)[:sl_th_ref_neg] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :ref_buses)], base_name="$(nw)_sl_th_ref_neg", lower_bound = 0,
        start = _PM.comp_start_value(ref(pm, nw, :ref_buses, i), "sl_th_ref_neg_start")
    )

    report && _PM.sol_component_value(pm, nw, :ref_buses, :sl_th_ref_neg, ids(pm, nw, :ref_buses), sl_th_ref_neg)
end

function variable_slack_volt_sp_pos(pm::_PM.AbstractPowerModel, nw::Int, bounded::Bool, report::Bool)
    sl_volt_sp_pos = var(pm, nw)[:sl_volt_sp_pos] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :bus)], base_name="$(nw)_sl_volt_sp_pos", lower_bound = 0,
        start = _PM.comp_start_value(ref(pm, nw, :bus, i), "sl_volt_sp_pos_start")
    )

    report && _PM.sol_component_value(pm, nw, :bus, :sl_volt_sp_pos, ids(pm, nw, :bus), sl_volt_sp_pos)
end

function variable_slack_volt_sp_neg(pm::_PM.AbstractPowerModel, nw::Int, bounded::Bool, report::Bool)
    sl_volt_sp_neg = var(pm, nw)[:sl_volt_sp_neg] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :bus)], base_name="$(nw)_sl_volt_sp_neg", lower_bound = 0,
        start = _PM.comp_start_value(ref(pm, nw, :bus, i), "sl_volt_sp_neg_start")
    )

    report && _PM.sol_component_value(pm, nw, :bus, :sl_volt_sp_neg, ids(pm, nw, :bus), sl_volt_sp_neg)
end

function variable_slack_const_balance_p_pos(pm::_PM.AbstractPowerModel, nw::Int, bounded::Bool, report::Bool)
    sl_const_balance_p_pos = var(pm, nw)[:sl_const_balance_p_pos] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :bus)], base_name="$(nw)_sl_const_balance_p_pos", lower_bound = 0,
        start = _PM.comp_start_value(ref(pm, nw, :bus, i), "sl_const_balance_p_pos_start")
    )

    report && _PM.sol_component_value(pm, nw, :bus, :sl_const_balance_p_pos, ids(pm, nw, :bus), sl_const_balance_p_pos)
end

function variable_slack_const_balance_p_neg(pm::_PM.AbstractPowerModel, nw::Int, bounded::Bool, report::Bool)
    sl_const_balance_p_neg = var(pm, nw)[:sl_const_balance_p_neg] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :bus)], base_name="$(nw)_sl_const_balance_p_neg", lower_bound = 0,
        start = _PM.comp_start_value(ref(pm, nw, :bus, i), "sl_const_balance_p_neg_start")
    )

    report && _PM.sol_component_value(pm, nw, :bus, :sl_const_balance_p_neg, ids(pm, nw, :bus), sl_const_balance_p_neg)
end

function variable_slack_const_balance_q_pos(pm::_PM.AbstractPowerModel, nw::Int, bounded::Bool, report::Bool)
    sl_const_balance_q_pos = var(pm, nw)[:sl_const_balance_q_pos] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :bus)], base_name="$(nw)_sl_const_balance_q_pos", lower_bound = 0,
        start = _PM.comp_start_value(ref(pm, nw, :bus, i), "sl_const_balance_q_pos_start")
    )

    report && _PM.sol_component_value(pm, nw, :bus, :sl_const_balance_q_pos, ids(pm, nw, :bus), sl_const_balance_q_pos)
end

function variable_slack_const_balance_q_neg(pm::_PM.AbstractPowerModel, nw::Int, bounded::Bool, report::Bool)
    sl_const_balance_q_neg = var(pm, nw)[:sl_const_balance_q_neg] = JuMP.@variable(pm.model,
        [i in ids(pm, nw, :bus)], base_name="$(nw)_sl_const_balance_q_neg", lower_bound = 0,
        start = _PM.comp_start_value(ref(pm, nw, :bus, i), "sl_const_balance_q_neg_start")
    )

    report && _PM.sol_component_value(pm, nw, :bus, :sl_const_balance_q_neg, ids(pm, nw, :bus), sl_const_balance_q_neg)
end


######### constraints ##########

function constraint_theta_ref_slack(pm::_PM.AbstractPolarModels, n::Int, i::Int)
    JuMP.@constraint(pm.model, var(pm, n, :va)[i] == 0 + (var(pm, n, :sl_th_ref_pos)[i] - var(pm, n, :sl_th_ref_neg)[i]))
end

function constraint_voltage_magnitude_setpoint_slack(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)
    bus = ref(pm, nw, :bus, i)
    constraint_voltage_magnitude_setpoint_slack(pm, nw, bus["index"], bus["vm"])
end

function constraint_power_balance_slack(pm::_PM.AbstractACPModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs)
    vm   = var(pm, n, :vm, i)
    p    = get(var(pm, n),    :p, Dict()); _PM._check_var_keys(p, bus_arcs, "active power", "branch")
    q    = get(var(pm, n),    :q, Dict()); _PM._check_var_keys(q, bus_arcs, "reactive power", "branch")
    pg   = get(var(pm, n),   :pg, Dict()); _PM._check_var_keys(pg, bus_gens, "active power", "generator")
    qg   = get(var(pm, n),   :qg, Dict()); _PM._check_var_keys(qg, bus_gens, "reactive power", "generator")
    ps   = get(var(pm, n),   :ps, Dict()); _PM._check_var_keys(ps, bus_storage, "active power", "storage")
    qs   = get(var(pm, n),   :qs, Dict()); _PM._check_var_keys(qs, bus_storage, "reactive power", "storage")
    psw  = get(var(pm, n),  :psw, Dict()); _PM._check_var_keys(psw, bus_arcs_sw, "active power", "switch")
    qsw  = get(var(pm, n),  :qsw, Dict()); _PM._check_var_keys(qsw, bus_arcs_sw, "reactive power", "switch")
    p_dc = get(var(pm, n), :p_dc, Dict()); _PM._check_var_keys(p_dc, bus_arcs_dc, "active power", "dcline")
    q_dc = get(var(pm, n), :q_dc, Dict()); _PM._check_var_keys(q_dc, bus_arcs_dc, "reactive power", "dcline")

    sl_const_balance_p_pos = var(pm, n, :sl_const_balance_p_pos, i)
    sl_const_balance_p_neg = var(pm, n, :sl_const_balance_p_neg, i)    

    sl_const_balance_q_pos = var(pm, n, :sl_const_balance_q_pos, i)
    sl_const_balance_q_neg = var(pm, n, :sl_const_balance_q_neg, i)    

    # the check "typeof(p[arc]) <: JuMP.NonlinearExpression" is required for the
    # case when p/q are nonlinear expressions instead of decision variables
    # once NLExpressions are first order in JuMP it should be possible to
    # remove this.
    # nl_form = length(bus_arcs) > 0 && (typeof(p[iterate(bus_arcs)[1]]) <: JuMP.NonlinearExpression)


    cstr_p = JuMP.@NLconstraint(pm.model,
        sum(p[a] for a in bus_arcs)
        + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(psw[a_sw] for a_sw in bus_arcs_sw)
        ==
        sum(pg[g] for g in bus_gens)
        - sum(ps[s] for s in bus_storage)
        - sum(pd for (i,pd) in bus_pd)
        - sum(gs for (i,gs) in bus_gs)*vm^2 + (sl_const_balance_p_pos - sl_const_balance_p_neg)
    )

    cstr_q = JuMP.@NLconstraint(pm.model,
        sum(q[a] for a in bus_arcs)
        + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
        ==
        sum(qg[g] for g in bus_gens)
        - sum(qs[s] for s in bus_storage)
        - sum(qd for (i,qd) in bus_qd)
        + sum(bs for (i,bs) in bus_bs)*vm^2 + (sl_const_balance_q_pos - sl_const_balance_q_neg)
    )

    if _IM.report_duals(pm)
        sol(pm, n, :bus, i)[:lam_kcl_r] = cstr_p
        sol(pm, n, :bus, i)[:lam_kcl_i] = cstr_q
    end
end

function constraint_voltage_magnitude_setpoint_slack(pm::_PM.AbstractACPModel, n::Int, i::Int, vm)
    v = var(pm, n, :vm, i)
    sl_volt_sp_pos = var(pm, n, :sl_volt_sp_pos, i)
    sl_volt_sp_neg = var(pm, n, :sl_volt_sp_neg, i)
    v = var(pm, n, :vm, i)
    JuMP.@constraint(pm.model, v == vm + (sl_volt_sp_pos - sl_volt_sp_neg))
end

function constraint_power_balance_slack(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)
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

    constraint_power_balance_slack(
        pm, nw, i, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs
    )
end

function constraint_theta_ref_slack(pm::_PM.AbstractPowerModel, i::Int; nw::Int=nw_id_default)
    constraint_theta_ref_slack(pm, nw, i)
end