""
function variable_branch_current(pm::ControlAbstractIVRModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true, kwargs...)
    _PM.variable_branch_current_real(pm, nw=nw, bounded=bounded, report=report; kwargs...)
    _PM.variable_branch_current_imaginary(pm, nw=nw, bounded=bounded, report=report; kwargs...)

    # store expressions in rectangular power variable space
    p = Dict()
    q = Dict()

    for (l,i,j) in _PM.ref(pm, nw, :arcs_from)
        vr_fr = var(pm, nw, :vr, i)
        vi_fr = var(pm, nw, :vi, i)
        cr_fr = var(pm, nw, :cr, (l,i,j))
        ci_fr = var(pm, nw, :ci, (l,i,j))

        vr_to = var(pm, nw, :vr, j)
        vi_to = var(pm, nw, :vi, j)
        cr_to = var(pm, nw, :cr, (l,j,i))
        ci_to = var(pm, nw, :ci, (l,j,i))
        p[(l,i,j)] = vr_fr*cr_fr  + vi_fr*ci_fr
        q[(l,i,j)] = vi_fr*cr_fr  - vr_fr*ci_fr
        p[(l,j,i)] = vr_to*cr_to  + vi_to*ci_to
        q[(l,j,i)] = vi_to*cr_to  - vr_to*ci_to
    end

    var(pm, nw)[:p] = p
    var(pm, nw)[:q] = q
    report && _PM._IM.sol_component_value_edge(pm, _PM.pm_it_sym, nw, :branch, :pf, :pt, ref(pm, nw, :arcs_from), ref(pm, nw, :arcs_to), p)
    report && _PM._IM.sol_component_value_edge(pm, _PM.pm_it_sym, nw, :branch, :qf, :qt, ref(pm, nw, :arcs_from), ref(pm, nw, :arcs_to), q)

    _PM.variable_branch_series_current_real(pm, nw=nw, bounded=bounded, report=report; kwargs...)
    _PM.variable_branch_series_current_imaginary(pm, nw=nw, bounded=bounded, report=report; kwargs...)
end

""
function variable_branch_current_perf(pm::ControlAbstractIVRModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true, kwargs...)
    _PM.variable_branch_current_real(pm, nw=nw, bounded=bounded, report=report; kwargs...)
    _PM.variable_branch_current_imaginary(pm, nw=nw, bounded=bounded, report=report; kwargs...)

    # store expressions in rectangular power variable space
    p = Dict()
    q = Dict()

    for (l,i,j) in _PM.ref(pm, nw, :arcs_from)
        vr_fr = var(pm, nw, :vr, i)
        vi_fr = var(pm, nw, :vi, i)
        cr_fr = var(pm, nw, :cr, (l,i,j))
        ci_fr = var(pm, nw, :ci, (l,i,j))

        vr_to = var(pm, nw, :vr, j)
        vi_to = var(pm, nw, :vi, j)
        cr_to = var(pm, nw, :cr, (l,j,i))
        ci_to = var(pm, nw, :ci, (l,j,i))
        p[(l,i,j)] = vr_fr*cr_fr  + vi_fr*ci_fr
        q[(l,i,j)] = vi_fr*cr_fr  - vr_fr*ci_fr
        p[(l,j,i)] = vr_to*cr_to  + vi_to*ci_to
        q[(l,j,i)] = vi_to*cr_to  - vr_to*ci_to
    end

    var(pm, nw)[:p] = p
    var(pm, nw)[:q] = q
    report && _PM._IM.sol_component_value_edge(pm, _PM.pm_it_sym, nw, :branch, :pf, :pt, ref(pm, nw, :arcs_from), ref(pm, nw, :arcs_to), p)
    report && _PM._IM.sol_component_value_edge(pm, _PM.pm_it_sym, nw, :branch, :qf, :qt, ref(pm, nw, :arcs_from), ref(pm, nw, :arcs_to), q)

    # _PM.variable_branch_series_current_real(pm, nw=nw, bounded=bounded, report=report; kwargs...)
    # _PM.variable_branch_series_current_imaginary(pm, nw=nw, bounded=bounded, report=report; kwargs...)
end

""
function variable_gen_current(pm::ControlAbstractIVRModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true, kwargs...)
    _PM.variable_gen_current_real(pm, nw=nw, bounded=bounded, report=report; kwargs...)
    _PM.variable_gen_current_imaginary(pm, nw=nw, bounded=bounded, report=report; kwargs...)

    # store active and reactive power expressions for use in objective + post processing
    pg = Dict()
    qg = Dict()
    for (i,gen) in _PM.ref(pm, nw, :gen)
        busid = gen["gen_bus"]
        vr = var(pm, nw, :vr, busid)
        vi = var(pm, nw, :vi, busid)
        crg = var(pm, nw, :crg, i)
        cig = var(pm, nw, :cig, i)
        pg[i] = JuMP.@NLexpression(pm.model, vr*crg  + vi*cig)
        qg[i] = JuMP.@NLexpression(pm.model, vi*crg  - vr*cig)
    end
    var(pm, nw)[:pg] = pg
    var(pm, nw)[:qg] = qg
    report && _PM.sol_component_value(pm, nw, :gen, :pg, ids(pm, nw, :gen), pg)
    report && _PM.sol_component_value(pm, nw, :gen, :qg, ids(pm, nw, :gen), qg)

end

""
function variable_dcline_current(pm::ControlAbstractIVRModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true, kwargs...)
    _PM.variable_dcline_current_real(pm, nw=nw, bounded=bounded, report=report; kwargs...)
    _PM.variable_dcline_current_imaginary(pm, nw=nw, bounded=bounded, report=report; kwargs...)
    # store expressions in rectangular power variable space
    p = Dict()
    q = Dict()

    for (l,i,j) in _PM.ref(pm, nw, :arcs_from_dc)
        vr_fr = var(pm, nw, :vr, i)
        vi_fr = var(pm, nw, :vi, i)
        cr_fr = var(pm, nw, :crdc, (l,i,j))
        ci_fr = var(pm, nw, :cidc, (l,i,j))

        vr_to = var(pm, nw, :vr, j)
        vi_to = var(pm, nw, :vi, j)
        cr_to = var(pm, nw, :crdc, (l,j,i))
        ci_to = var(pm, nw, :cidc, (l,j,i))

        p[(l,i,j)] = JuMP.@NLexpression(pm.model, vr_fr*cr_fr  + vi_fr*ci_fr)
        q[(l,i,j)] = JuMP.@NLexpression(pm.model, vi_fr*cr_fr  - vr_fr*ci_fr)
        p[(l,j,i)] = JuMP.@NLexpression(pm.model, vr_to*cr_to  + vi_to*ci_to)
        q[(l,j,i)] = JuMP.@NLexpression(pm.model, vi_to*cr_to  - vr_to*ci_to)
    end

    var(pm, nw)[:p_dc] = p
    var(pm, nw)[:q_dc] = q
    report && _PM._IM.sol_component_value_edge(pm, _PM.pm_it_sym, nw, :dcline, :pf, :pt, ref(pm, nw, :arcs_from_dc), ref(pm, nw, :arcs_to_dc), p)
    report && _PM._IM.sol_component_value_edge(pm, _PM.pm_it_sym, nw, :dcline, :qf, :qt, ref(pm, nw, :arcs_from_dc), ref(pm, nw, :arcs_to_dc), q)

end

"""
Kirchhoff's current law applied to buses
`sum(cr + im*ci) = 0`
"""
function constraint_current_balance_real(pm::ControlAbstractIVRModel, n::Int, i, bus_arcs, bus_arcs_dc, bus_gens, bus_pd, bus_qd, bus_gs, bus_bs)
    vr = var(pm, n, :vr, i)
    vi = var(pm, n, :vi, i)

    cr =  var(pm, n, :cr)
    crdc = var(pm, n, :crdc)

    crg = var(pm, n, :crg)

    JuMP.@NLconstraint(pm.model, sum(cr[a] for a in bus_arcs)
                                + sum(crdc[d] for d in bus_arcs_dc)
                                ==
                                sum(crg[g] for g in bus_gens)
                                - (sum(pd for pd in values(bus_pd))*vr + sum(qd for qd in values(bus_qd))*vi)/(vr^2 + vi^2)
                                - sum(gs for gs in values(bus_gs))*vr + sum(bs for bs in values(bus_bs))*vi
                                )
end

"""
Kirchhoff's current law applied to buses
`sum(cr + im*ci) = 0`
"""
function constraint_current_balance_imaginary(pm::ControlAbstractIVRModel, n::Int, i, bus_arcs, bus_arcs_dc, bus_gens, bus_pd, bus_qd, bus_gs, bus_bs)
    vr = var(pm, n, :vr, i)
    vi = var(pm, n, :vi, i)

    ci =  var(pm, n, :ci)
    cidc = var(pm, n, :cidc)

    cig = var(pm, n, :cig)

    JuMP.@NLconstraint(pm.model, sum(ci[a] for a in bus_arcs)
                                + sum(cidc[d] for d in bus_arcs_dc)
                                ==
                                sum(cig[g] for g in bus_gens)
                                - (sum(pd for pd in values(bus_pd))*vi - sum(qd for qd in values(bus_qd))*vr)/(vr^2 + vi^2)
                                - sum(gs for gs in values(bus_gs))*vi - sum(bs for bs in values(bus_bs))*vr
                                )
end

"""
Defines how current distributes over series and shunt impedances of a pi-model branch
"""
function constraint_current_from(pm::ControlAbstractIVRModel, n::Int, f_bus, f_idx, g_sh_fr, b_sh_fr, tr, ti, tm, i::Int)
    vr_fr = var(pm, n, :vr, f_bus)
    vi_fr = var(pm, n, :vi, f_bus)

    csr_fr =  var(pm, n, :csr, f_idx[1])
    csi_fr =  var(pm, n, :csi, f_idx[1])

    cr_fr =  var(pm, n, :cr, f_idx)
    ci_fr =  var(pm, n, :ci, f_idx)

    tap   = ref_or_var(pm, n, i, :branch, "tap")
    shift = ref_or_var(pm, n, i, :branch, "shift")

    # tr = (tap .* cos.(shift)) # cannot write cos(variable) outside NLexpression
    # ti = (tap .* sin.(shift)) # cannot write sin(variable) outside NLexpression
    tm² = tap^2 + 1e-8 # variable in denominator

    JuMP.@NLconstraint(pm.model, cr_fr == (tap*cos(shift)*csr_fr - tap*sin(shift)*csi_fr + g_sh_fr*vr_fr - b_sh_fr*vi_fr)/tm²)
    JuMP.@NLconstraint(pm.model, ci_fr == (tap*cos(shift)*csi_fr + tap*sin(shift)*csr_fr + g_sh_fr*vi_fr + b_sh_fr*vr_fr)/tm²)
end

function constraint_current_from_voltage_drop(pm::ControlAbstractIVRModel, n::Int, i::Int, f_bus, t_bus, f_idx, r, x, g_sh_fr, b_sh_fr)
    vr_fr = var(pm, n, :vr, f_bus)
    vi_fr = var(pm, n, :vi, f_bus)

    csr_fr =  var(pm, n, :csr, f_idx[1])
    csi_fr =  var(pm, n, :csi, f_idx[1])

    cr_fr =  var(pm, n, :cr, f_idx)
    ci_fr =  var(pm, n, :ci, f_idx)

    tap   = ref_or_var(pm, n, i, :branch, "tap")
    shift = ref_or_var(pm, n, i, :branch, "shift")

    # tr = (tap .* cos.(shift)) # cannot write cos(variable) outside NLexpression
    # ti = (tap .* sin.(shift)) # cannot write sin(variable) outside NLexpression
    tm² = tap^2 + 1e-8 # variable in denominator
    if typeof(shift) == JuMP.VariableRef
        cos_shift = JuMP.@variable(pm.model)
        sin_shift = JuMP.@variable(pm.model)
        JuMP.@NLconstraint(pm.model, cos_shift == cos(shift))
        JuMP.@NLconstraint(pm.model, sin_shift == sin(shift))
    else
        cos_shift = cos(shift)
        sin_shift = sin(shift)
    end
    
    if typeof(tap) == JuMP.VariableRef
        inv_tap = JuMP.@variable(pm.model)
        JuMP.@constraint(pm.model, tap*inv_tap == 1)
    else
        inv_tap = 1/tap
    end
    
    # JuMP.@NLconstraint(pm.model, cr_fr == (tap*cos(shift)*csr_fr - tap*sin(shift)*csi_fr + g_sh_fr*vr_fr - b_sh_fr*vi_fr)/tm²)
    # JuMP.@NLconstraint(pm.model, ci_fr == (tap*cos(shift)*csi_fr + tap*sin(shift)*csr_fr + g_sh_fr*vi_fr + b_sh_fr*vr_fr)/tm²)
    JuMP.@constraint(pm.model, cr_fr*tap == cos_shift*csr_fr - sin_shift*csi_fr + (g_sh_fr*vr_fr - b_sh_fr*vi_fr)*inv_tap)
    JuMP.@constraint(pm.model, ci_fr*tap == cos_shift*csi_fr + sin_shift*csr_fr + (g_sh_fr*vi_fr + b_sh_fr*vr_fr)*inv_tap)

    vr_to = var(pm, n, :vr, t_bus)
    vi_to = var(pm, n, :vi, t_bus)

    csr_fr =  var(pm, n, :csr, f_idx[1])
    csi_fr =  var(pm, n, :csi, f_idx[1])
    
    # tr = (tap .* cos.(shift)) # cannot write cos(variable) outside NLexpression
    # ti = (tap .* sin.(shift)) # cannot write sin(variable) outside NLexpression
    tm² = tap^2 + 1e-8 # variable in denominator

    JuMP.@constraint(pm.model, vr_to*tap == (vr_fr*cos_shift + vi_fr*sin_shift) - r*csr_fr*tap + x*csi_fr*tap)
    JuMP.@constraint(pm.model, vi_to*tap == (vi_fr*cos_shift - vr_fr*sin_shift) - r*csi_fr*tap - x*csr_fr*tap)
end

"""
Defines how current distributes over series and shunt impedances of a pi-model branch
"""
function constraint_current_to(pm::ControlAbstractIVRModel, n::Int, t_bus, f_idx, t_idx, g_sh_to, b_sh_to, i::Int)
    vr_to = var(pm, n, :vr, t_bus)
    vi_to = var(pm, n, :vi, t_bus)

    csr_to =  -var(pm, n, :csr, f_idx[1])
    csi_to =  -var(pm, n, :csi, f_idx[1])

    cr_to =  var(pm, n, :cr, t_idx)
    ci_to =  var(pm, n, :ci, t_idx)

    JuMP.@NLconstraint(pm.model, cr_to == csr_to + g_sh_to*vr_to - b_sh_to*vi_to)
    JuMP.@NLconstraint(pm.model, ci_to == csi_to + g_sh_to*vi_to + b_sh_to*vr_to)
end

function constraint_current_to_perf(pm::ControlAbstractIVRModel, n::Int, t_bus, f_idx, t_idx, g_sh_to, b_sh_to, i::Int)
    vr_to = var(pm, n, :vr, t_bus)
    vi_to = var(pm, n, :vi, t_bus)

    # csr_to =  var(pm, n, :csr, f_idx[1])
    # csi_to =  var(pm, n, :csi, f_idx[1])

    cr_to =  var(pm, n, :cr, t_idx)
    ci_to =  var(pm, n, :ci, t_idx)

    if !haskey(var(pm, n), :csr)
        var(pm, n)[:csr] = Dict()
        var(pm, n)[:csi] = Dict()
    end

    var(pm, n, :csr)[f_idx[1]] = JuMP.@expression(pm.model, -cr_to + g_sh_to*vr_to - b_sh_to*vi_to)
    var(pm, n, :csi)[f_idx[1]] = JuMP.@expression(pm.model, -ci_to + g_sh_to*vi_to + b_sh_to*vr_to)
end

"""
Defines voltage drop over a branch, linking from and to side complex voltage
"""
function constraint_voltage_drop(pm::ControlAbstractIVRModel, n::Int, i, f_bus, t_bus, f_idx, r, x, tr, ti, tm)
    vr_fr = var(pm, n, :vr, f_bus)
    vi_fr = var(pm, n, :vi, f_bus)

    vr_to = var(pm, n, :vr, t_bus)
    vi_to = var(pm, n, :vi, t_bus)

    csr_fr =  var(pm, n, :csr, f_idx[1])
    csi_fr =  var(pm, n, :csi, f_idx[1])
    
    tap   = ref_or_var(pm, n, i, :branch, "tap")
    shift = ref_or_var(pm, n, i, :branch, "shift")
    
    # tr = (tap .* cos.(shift)) # cannot write cos(variable) outside NLexpression
    # ti = (tap .* sin.(shift)) # cannot write sin(variable) outside NLexpression
    tm² = tap^2 + 1e-8 # variable in denominator

    JuMP.@NLconstraint(pm.model, vr_to*tap == (vr_fr*cos(shift) + vi_fr*sin(shift)) - r*csr_fr + x*csi_fr)
    JuMP.@NLconstraint(pm.model, vi_to*tap == (vi_fr*cos(shift) - vr_fr*sin(shift)) - r*csi_fr - x*csr_fr)
end

"`pg[i] == pg`"
function constraint_gen_setpoint_active(pm::ControlAbstractIVRModel, n::Int, i, pgref)
    gen = ref(pm, n, :gen, i)
    bus = gen["gen_bus"]
    vr = var(pm, n, :vr, bus)
    vi = var(pm, n, :vi, bus)
    cr = var(pm, n, :crg, i)
    ci = var(pm, n, :cig, i)

    slack = slack_in_equality_constraint(pm, n, i, "constraint_gen_setpoint_active")

    JuMP.@constraint(pm.model, pgref == vr*cr  + vi*ci + slack)
end

"`qg[i] == qg`"
function constraint_gen_setpoint_reactive(pm::ControlAbstractIVRModel, n::Int, i, qgref)
    gen = ref(pm, n, :gen, i)
    bus = gen["gen_bus"]
    vr = var(pm, n, :vr, bus)
    vi = var(pm, n, :vi, bus)
    cr = var(pm, n, :crg, i)
    ci = var(pm, n, :cig, i)

    slack = slack_in_equality_constraint(pm, n, i, "constraint_gen_setpoint_reactive")

    JuMP.@constraint(pm.model, qgref == vi*cr  - vr*ci)
end

""
function constraint_gen_active_bounds(pm::ControlAbstractIVRModel, n::Int, i, pgmax::Float64, pgmin::Float64)
    gen = ref(pm, n, :gen, i)
    bus = gen["gen_bus"]
    vr = var(pm, n, :vr, bus)
    vi = var(pm, n, :vi, bus)
    cr = var(pm, n, :crg, i)
    ci = var(pm, n, :cig, i)

    up, low = slack_in_bound_constraint(pm, n, i, "constraint_gen_active_bounds")
    
    JuMP.@constraint(pm.model, vr*cr  + vi*ci >= pgmin + up)
    JuMP.@constraint(pm.model, vr*cr  + vi*ci <= pgmax - low)
end

""
function constraint_gen_reactive_bounds(pm::ControlAbstractIVRModel, n::Int, i, qgmax::Float64, qgmin::Float64)
    gen = ref(pm, n, :gen, i)
    bus = gen["gen_bus"]
    vr = var(pm, n, :vr, bus)
    vi = var(pm, n, :vi, bus)
    cr = var(pm, n, :crg, i)
    ci = var(pm, n, :cig, i)

    up, low = slack_in_bound_constraint(pm, n, i, "constraint_gen_reactive_bounds")
    
    JuMP.@constraint(pm.model, vi*cr  - vr*ci >= qgmin + up)
    JuMP.@constraint(pm.model, vi*cr  - vr*ci <= qgmax - low)
end

"`p_fr[i] == pref_fr, p_to[i] == pref_to`"
function constraint_dcline_setpoint_active_fr(pm::ControlAbstractIVRModel, n::Int, f_idx, t_idx, pref_fr, pref_to)
    (l, f_bus, t_bus) = f_idx
    vr_fr = var(pm, n, :vr, f_bus)
    vi_fr = var(pm, n, :vi, f_bus)

    vr_to = var(pm, n, :vr, t_bus)
    vi_to = var(pm, n, :vi, t_bus)

    crdc_fr = var(pm, n, :crdc, f_idx)
    cidc_fr = var(pm, n, :cidc, f_idx)

    crdc_to = var(pm, n, :crdc, t_idx)
    cidc_to = var(pm, n, :cidc, t_idx)

    slack = slack_in_equality_constraint(pm, n, f_idx, "constraint_dcline_setpoint_active_fr")

    JuMP.@constraint(pm.model, pref_fr == vr_fr*crdc_fr + vi_fr*cidc_fr + slack)
end

"`p_fr[i] == pref_fr, p_to[i] == pref_to`"
function constraint_dcline_setpoint_active_to(pm::ControlAbstractIVRModel, n::Int, f_idx, t_idx, pref_fr, pref_to)
    (l, f_bus, t_bus) = f_idx
    vr_fr = var(pm, n, :vr, f_bus)
    vi_fr = var(pm, n, :vi, f_bus)

    vr_to = var(pm, n, :vr, t_bus)
    vi_to = var(pm, n, :vi, t_bus)

    crdc_fr = var(pm, n, :crdc, f_idx)
    cidc_fr = var(pm, n, :cidc, f_idx)

    crdc_to = var(pm, n, :crdc, t_idx)
    cidc_to = var(pm, n, :cidc, t_idx)

    slack = slack_in_equality_constraint(pm, n, f_idx, "constraint_dcline_setpoint_active_to")

    JuMP.@constraint(pm.model, pref_to == vr_to*crdc_to + vi_to*cidc_to + slack)
end

"`p[f_idx] == p`"
function constraint_active_power_setpoint(pm::ControlAbstractIVRModel, n::Int, i::Int, f_idx, p)
    (l, f, t) = f_idx
    vr_fr = var(pm, n, :vr, f)
    vi_fr = var(pm, n, :vi, f)
    cr_fr = var(pm, n, :cr, (l,f,t))
    ci_fr = var(pm, n, :ci, (l,f,t))

    vr_to = var(pm, n, :vr, t)
    vi_to = var(pm, n, :vi, t)
    cr_to = var(pm, n, :cr, (l,t,f))
    ci_to = var(pm, n, :ci, (l,t,f))
    
    pf = vr_fr*cr_fr  + vi_fr*ci_fr
    qf = vi_fr*cr_fr  - vr_fr*ci_fr
    
    slack = slack_in_equality_constraint(pm, n, i, "constraint_active_power_setpoint")

    JuMP.@NLconstraint(pm.model, pf == p + slack)
end

"`p[f_idx] == p`"
function constraint_reactive_power_setpoint(pm::ControlAbstractIVRModel, n::Int, i::Int, f_idx, q)
    (l, f, t) = f_idx
    vr_fr = var(pm, n, :vr, f)
    vi_fr = var(pm, n, :vi, f)
    cr_fr = var(pm, n, :cr, (l,f,t))
    ci_fr = var(pm, n, :ci, (l,f,t))

    vr_to = var(pm, n, :vr, t)
    vi_to = var(pm, n, :vi, t)
    cr_to = var(pm, n, :cr, (l,t,f))
    ci_to = var(pm, n, :ci, (l,t,f))
    
    pf = vr_fr*cr_fr  + vi_fr*ci_fr
    qf = vi_fr*cr_fr  - vr_fr*ci_fr
    
    pf = vr_fr*cr_fr  + vi_fr*ci_fr
    qf = vi_fr*cr_fr  - vr_fr*ci_fr
    
    slack = slack_in_equality_constraint(pm, n, i, "constraint_reactive_power_setpoint")

    JuMP.@NLconstraint(pm.model, qf == q + slack)
end
