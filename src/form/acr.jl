""
function variable_bus_voltage(pm::ControlAbstractACRModel; kwargs...)
    _PM.variable_bus_voltage_real(pm; kwargs...)
    _PM.variable_bus_voltage_imaginary(pm; kwargs...)
end

function constraint_power_balance_active(pm::ControlAbstractACRModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs)
    vr = var(pm, n, :vr, i)
    vi = var(pm, n, :vi, i)
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

    slack = slack_in_equality_constraint(pm, n, i, "constraint_power_balance_active")

    cstr_p = JuMP.@NLconstraint(pm.model,
        sum(p[a] for a in bus_arcs)
        + sum(p_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(psw[a_sw] for a_sw in bus_arcs_sw)
        ==
        sum(pg[g] for g in bus_gens)
        - sum(ps[s] for s in bus_storage)
        - sum(pd for pd in values(bus_pd))
        - sum(gs for gs in values(bus_gs))*(vr^2 + vi^2)
        + slack
    )

    if _IM.report_duals(pm)
        sol(pm, n, :bus, i)[:lam_kcl_r] = cstr_p
    end
end

function constraint_power_balance_reactive(pm::ControlAbstractACRModel, n::Int, i::Int, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs)
    vr = var(pm, n, :vr, i)
    vi = var(pm, n, :vi, i)
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

    slack = slack_in_equality_constraint(pm, n, i, "constraint_power_balance_reactive")

    cstr_q = JuMP.@NLconstraint(pm.model,
        sum(q[a] for a in bus_arcs)
        + sum(q_dc[a_dc] for a_dc in bus_arcs_dc)
        + sum(qsw[a_sw] for a_sw in bus_arcs_sw)
        ==
        sum(qg[g] for g in bus_gens)
        - sum(qs[s] for s in bus_storage)
        - sum(qd for qd in values(bus_qd))
        + sum(bs for bs in values(bus_bs))*(vr^2 + vi^2)
        + slack
    )

    if _IM.report_duals(pm)
        sol(pm, n, :bus, i)[:lam_kcl_i] = cstr_q
    end
end

"`v[i] == vm`"
function constraint_voltage_magnitude_setpoint(pm::ControlAbstractACRModel, n::Int, i, vm)
    vr = var(pm, n, :vr, i)
    vi = var(pm, n, :vi, i)

    slack = slack_in_equality_constraint(pm, n, i, "constraint_voltage_magnitude_setpoint")

    JuMP.@constraint(pm.model, (vr^2 + vi^2) == vm^2 + slack)
end


"reference bus angle constraint"
function constraint_theta_ref(pm::ControlAbstractACRModel, n::Int, i::Int, va)
    va = ref(pm, n, :bus, i, "va")
    vm = ref(pm, n, :bus, i, "vm")

    slack = slack_in_equality_constraint(pm, n, i, "constraint_theta_ref")

    JuMP.@constraint(pm.model, var(pm, n, :vi)[i] == vm*sin(va) + slack)
end

"reference bus angle constraint"
function constraint_voltage_angle_setpoint(pm::ControlAbstractACRModel, n::Int, i::Int)
    va = ref(pm, n, :bus, i, "va")
    vm = ref(pm, n, :bus, i, "vm")

    slack = slack_in_equality_constraint(pm, n, i, "constraint_voltage_angle_setpoint")

    JuMP.@constraint(pm.model, var(pm, n, :vi)[i] == vm*sin(va) + slack)
end

""
function expression_branch_power_ohms_yt_from(pm::ControlAbstractACRModel, n::Int, f_bus, t_bus, f_idx, t_idx, g, b, g_fr, b_fr, i::Int)
    vr_fr = var(pm, n, :vr, f_bus)
    vr_to = var(pm, n, :vr, t_bus)
    vi_fr = var(pm, n, :vi, f_bus)
    vi_to = var(pm, n, :vi, t_bus)

    tap   = ref_or_var(pm, n, i, :branch, "tap")
    shift = ref_or_var(pm, n, i, :branch, "shift")

    # tr = (tap .* cos.(shift)) # cannot write cos(variable) outside NLexpression
    # ti = (tap .* sin.(shift)) # cannot write sin(variable) outside NLexpression
    tm² = tap^2 + 1e-8 # variable in denominator
    
    var(pm, n, :p)[f_idx] = @NLexpression(pm.model, (g+g_fr)/tm²*(vr_fr^2 + vi_fr^2) + (-g*(tap * cos(shift))+b*(tap * sin(shift)))/tm²*(vr_fr*vr_to + vi_fr*vi_to) + (-b*(tap * cos(shift))-g*(tap * sin(shift)))/tm²*(vi_fr*vr_to - vr_fr*vi_to))
    var(pm, n, :q)[f_idx] = @NLexpression(pm.model, -(b+b_fr)/tm²*(vr_fr^2 + vi_fr^2) - (-b*(tap * cos(shift))-g*(tap * sin(shift)))/tm²*(vr_fr*vr_to + vi_fr*vi_to) + (-g*(tap * cos(shift))+b*(tap * sin(shift)))/tm²*(vi_fr*vr_to - vr_fr*vi_to))
end


""
function expression_branch_power_ohms_yt_to(pm::ControlAbstractACRModel, n::Int, f_bus, t_bus, f_idx, t_idx, g, b, g_to, b_to, i::Int)
    vr_fr = var(pm, n, :vr, f_bus)
    vr_to = var(pm, n, :vr, t_bus)
    vi_fr = var(pm, n, :vi, f_bus)
    vi_to = var(pm, n, :vi, t_bus)

    tap   = ref_or_var(pm, n, i, :branch, "tap")
    shift = ref_or_var(pm, n, i, :branch, "shift")
    
    # tr = (tap .* cos.(shift)) # cannot write cos(variable) outside NLexpression
    # ti = (tap .* sin.(shift)) # cannot write sin(variable) outside NLexpression
    tm² = tap^2 + 1e-8 # variable in denominator

    var(pm, n, :p)[t_idx] = @NLexpression(pm.model, (g+g_to)*(vr_to^2 + vi_to^2) + (-g*(tap * cos(shift))-b*(tap * sin(shift)))/tm²*(vr_fr*vr_to + vi_fr*vi_to) + (-b*(tap * cos(shift))+g*(tap * sin(shift)))/tm²*(-(vi_fr*vr_to - vr_fr*vi_to)))
    var(pm, n, :q)[t_idx] = @NLexpression(pm.model, -(b+b_to)*(vr_to^2 + vi_to^2) - (-b*(tap * cos(shift))+g*(tap * sin(shift)))/tm²*(vr_fr*vr_to + vi_fr*vi_to) + (-g*(tap * cos(shift))-b*(tap * sin(shift)))/tm²*(-(vi_fr*vr_to - vr_fr*vi_to)))
end
