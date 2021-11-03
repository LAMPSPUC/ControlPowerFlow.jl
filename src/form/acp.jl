function constraint_power_balance_active(pm::_PM.AbstractACPModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs)
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
    
    # the check "typeof(p[arc]) <: JuMP.NonlinearExpression" is required for the
    # case when p/q are nonlinear expressions instead of decision variables
    # once NLExpressions are first order in JuMP it should be possible to
    # remove this.
    # nl_form = length(bus_arcs) > 0 && (typeof(p[iterate(bus_arcs)[1]]) <: JuMP.NonlinearExpression)

    slack = slack_in_equality_constraint(pm, n, i, "constraint_power_balance_active")

    cstr_p = JuMP.@NLconstraint(pm.model,
        sum(p[a] for a in bus_arcs)
        + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(psw[a_sw] for a_sw in bus_arcs_sw)
        ==
        sum(pg[g] for g in bus_gens)
        - sum(ps[s] for s in bus_storage)
        - sum(pd for (i,pd) in bus_pd)
        - sum(gs for (i,gs) in bus_gs)*vm^2
        + slack
    )


    if _IM.report_duals(pm)
        sol(pm, n, :bus, i)[:lam_kcl_r] = cstr_p
    end
end

function constraint_power_balance_reactive(pm::_PM.AbstractACPModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs)
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

    # the check "typeof(p[arc]) <: JuMP.NonlinearExpression" is required for the
    # case when p/q are nonlinear expressions instead of decision variables
    # once NLExpressions are first order in JuMP it should be possible to
    # remove this.
    # nl_form = length(bus_arcs) > 0 && (typeof(p[iterate(bus_arcs)[1]]) <: JuMP.NonlinearExpression)

    slack = slack_in_equality_constraint(pm, n, i, "constraint_power_balance_reactive")

    cstr_q = JuMP.@NLconstraint(pm.model,
        sum(q[a] for a in bus_arcs)
        + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
        ==
        sum(qg[g] for g in bus_gens)
        - sum(qs[s] for s in bus_storage)
        - sum(qd for (i,qd) in bus_qd)
        + sum(bs for (i,bs) in bus_bs)*vm^2
        + slack
    )

    if _IM.report_duals(pm)
        sol(pm, n, :bus, i)[:lam_kcl_i] = cstr_q
    end
end

"`v[i] == vm`"
function constraint_voltage_magnitude_setpoint(pm::_PM.AbstractACPModel, n::Int, i::Int, vm)
    v = var(pm, n, :vm, i)

    slack = slack_in_equality_constraint(pm, n, i, "constraint_voltage_magnitude_setpoint")

    JuMP.@constraint(pm.model, v == vm + slack)
end

""
function expression_branch_power_ohms_yt_from(pm::_PM.AbstractACPModel, n::Int, f_bus, t_bus, f_idx, t_idx, g, b, g_fr, b_fr, i::Int)
    vm_fr = var(pm, n, :vm, f_bus)
    vm_to = var(pm, n, :vm, t_bus)
    va_fr = var(pm, n, :va, f_bus)
    va_to = var(pm, n, :va, t_bus)

    tap   = ref_or_var(pm, n, i, :branch, "tap")
    shift = ref_or_var(pm, n, i,  :branch, "shift")
    
    # tr = (tap .* cos.(shift)) # cannot write cos(variable) outside NLexpression
    # ti = (tap .* sin.(shift)) # cannot write sin(variable) outside NLexpression
    tm² = tap^2 + 1e-5 # variable in denominator
    
    var(pm, n, :p)[f_idx] = JuMP.@NLexpression(pm.model,  (g+g_fr)/tm²*vm_fr^2 + (-g*(tap * cos(shift))+b*(tap * sin(shift)))/tm²*(vm_fr*vm_to*cos(va_fr-va_to)) + (-b*(tap * cos(shift))-g*(tap * sin(shift)))/tm²*(vm_fr*vm_to*sin(va_fr-va_to)) )
    var(pm, n, :q)[f_idx] = JuMP.@NLexpression(pm.model, -(b+b_fr)/tm²*vm_fr^2 - (-b*(tap * cos(shift))-g*(tap * sin(shift)))/tm²*(vm_fr*vm_to*cos(va_fr-va_to)) + (-g*(tap * cos(shift))+b*(tap * sin(shift)))/tm²*(vm_fr*vm_to*sin(va_fr-va_to)) )
end

""
function expression_branch_power_ohms_yt_to(pm::_PM.AbstractACPModel, n::Int, f_bus, t_bus, f_idx, t_idx, g, b, g_to, b_to, i::Int)
    vm_fr = var(pm, n, :vm, f_bus)
    vm_to = var(pm, n, :vm, t_bus)
    va_fr = var(pm, n, :va, f_bus)
    va_to = var(pm, n, :va, t_bus)

    tap   = ref_or_var(pm, n, i, :branch, "tap")
    shift = ref_or_var(pm, n, i, :branch, "shift")
    
    # tr = (tap .* cos.(shift)) # cannot write cos(variable) outside NLexpression
    # ti = (tap .* sin.(shift)) # cannot write sin(variable) outside NLexpression
    tm² = tap^2 + 1e-5

    var(pm, n, :p)[t_idx] = JuMP.@NLexpression(pm.model,  (g+g_to)*vm_to^2 + (-g*(tap * cos(shift))-b*(tap * sin(shift)))/tm²*(vm_to*vm_fr*cos(va_to-va_fr)) + (-b*(tap * cos(shift))+g*(tap * sin(shift)))/tm²*(vm_to*vm_fr*sin(va_to-va_fr)) )
    var(pm, n, :q)[t_idx] = JuMP.@NLexpression(pm.model, -(b+b_to)*vm_to^2 - (-b*(tap * cos(shift))+g*(tap * sin(shift)))/tm²*(vm_to*vm_fr*cos(va_to-va_fr)) + (-g*(tap * cos(shift))-b*(tap * sin(shift)))/tm²*(vm_to*vm_fr*sin(va_to-va_fr)) )
end
