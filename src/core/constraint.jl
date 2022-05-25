"`pf[i] == pf"
function constraint_dcline_setpoint_active_fr(pm::ControlAbstractModel, n::Int, f_idx, t_idx, pf, pt)
    p_fr = var(pm, n, :p_dc, f_idx)
    
    slack = slack_in_equality_constraint(pm, n, f_idx, "constraint_dcline_setpoint_active_fr")

    JuMP.@constraint(pm.model, p_fr == pf + slack)
end

"`pt[i] == pt"
function constraint_dcline_setpoint_active_to(pm::ControlAbstractModel, n::Int, f_idx, t_idx, pf, pt)
    p_to = var(pm, n, :p_dc, t_idx)
    
    slack = slack_in_equality_constraint(pm, n, t_idx, "constraint_dcline_setpoint_active_to")

    JuMP.@constraint(pm.model, p_to == pt + slack)
end

"`pd[i] == pd`"
function constraint_load_setpoint_active(pm::ControlAbstractModel, n::Int, i, pd)
    pd_var = var(pm, n, :pd, i)
    
    slack = slack_in_equality_constraint(pm, n, i, "constraint_load_setpoint_active")

    JuMP.@constraint(pm.model, pd_var == pd + slack)
end

"`qd[i] == qd`"
function constraint_load_setpoint_reactive(pm::ControlAbstractModel, n::Int, i, qd)
    qd_var = var(pm, n, :qd, i)
    
    slack = slack_in_equality_constraint(pm, n, i, "constraint_load_setpoint_reactive")
    
    JuMP.@constraint(pm.model, qd_var == qd + slack)
end

"`pg[i] == pg`"
function constraint_gen_setpoint_active(pm::ControlAbstractModel, n::Int, i, pg)
    pg_var = var(pm, n, :pg, i)
    
    slack = slack_in_equality_constraint(pm, n, i, "constraint_gen_setpoint_active")

    JuMP.@constraint(pm.model, pg_var == pg + slack)
end

"`qg[i] == qg`"
function constraint_gen_setpoint_reactive(pm::ControlAbstractModel, n::Int, i, qg)
    qg_var = var(pm, n, :qg, i)
    
    slack = slack_in_equality_constraint(pm, n, i, "constraint_gen_setpoint_reactive")
    
    JuMP.@constraint(pm.model, qg_var == qg + slack)
end

"`qg[i] >= qmin; qg[i] <= qmax`"
function constraint_gen_reactive_bounds(pm::ControlAbstractModel, n::Int, i, qmax::Float64, qmin::Float64)
    qg  = var(pm, n, :qg, i)

    up, low = slack_in_bound_constraint(pm, n, i, "constraint_gen_reactive_bounds")

    JuMP.@constraint(pm.model, qg <= qmax + up)
    JuMP.@constraint(pm.model, qg >= qmin - low)
end

"`pg[i] >= pmin; pg[i] <= pmax`"
function constraint_gen_active_bounds(pm::ControlAbstractModel, n::Int, i, pmax::Float64, pmin::Float64)
    pg  = var(pm, n, :pg, i)
    
    up, low = slack_in_bound_constraint(pm, n, i, "constraint_gen_active_bounds")

    JuMP.@constraint(pm.model, pg <= pmax + up)
    JuMP.@constraint(pm.model, pg >= pmin - low)
end

"`p[f_idx] == p`"
function constraint_active_power_setpoint(pm::ControlAbstractModel, n::Int, i::Int, f_idx, p)
    p_var = var(pm, n, :p)[f_idx]
    
    slack = slack_in_equality_constraint(pm, n, i, "constraint_active_power_setpoint")
    
    JuMP.@NLconstraint(pm.model, p_var == p + slack)
end

"`q[f_idx] == q`"
function constraint_reactive_power_setpoint(pm::ControlAbstractModel, n::Int, i::Int, f_idx, q)
    q_var = var(pm, n, :q)[f_idx]
    
    slack = slack_in_equality_constraint(pm, n, i, "constraint_reactive_power_setpoint")
    
    JuMP.@NLconstraint(pm.model, q_var == q + slack)
end


""
function constraint_tap_ratio_setpoint(pm::ControlAbstractModel,  n::Int, i::Int, branch::Dict)
    tap = var(pm, n)[:tap][i]
    tapsp = branch["tap"]
    
    slack = slack_in_equality_constraint(pm, n, i, "constraint_tap_ratio_setpoint")

    JuMP.@constraint(
        pm.model, tap == tapsp - slack
    )
end

""
function constraint_tap_ratio_bounds(pm::ControlAbstractModel,  n::Int, i::Int, branch::Dict)
    tap = var(pm, n)[:tap][i]
    tapmin = _control_data(branch)["tapmin"]
    tapmax =_control_data(branch)["tapmax"]
    
    up, low = slack_in_bound_constraint(pm, n, i, "constraint_tap_ratio_bounds")

    JuMP.@constraint(
        pm.model, tap >= tapmin - low
    )

    JuMP.@constraint(
        pm.model, tap <= tapmax + up
    )
end

""
function constraint_shift_ratio_setpoint(pm::ControlAbstractModel,  n::Int, i::Int, branch::Dict)
    shift = var(pm, n)[:shift][i]
    shiftsp = branch["shift"]
    
    slack = slack_in_equality_constraint(pm, n, i, "constraint_shift_ratio_setpoint")

    JuMP.@constraint(
        pm.model, shift == shiftsp - slack
    )
end

""
function constraint_shift_ratio_bounds(pm::ControlAbstractModel,  n::Int, i::Int, branch::Dict)
    shift = var(pm, n)[:shift][i]
    shift_min = _control_data(branch)["shiftmin"]
    shift_max = _control_data(branch)["shiftmax"]

    up, low = slack_in_bound_constraint(pm, n, i, "constraint_shift_ratio_bounds")

    JuMP.@constraint(
        pm.model, shift >= shift_min - low
    )

    JuMP.@constraint(
        pm.model, shift <= shift_max + up
    )
end


""
function constraint_shunt_setpoint(pm::ControlAbstractModel, n::Int, i::Int, shunt::Dict)
    bs = var(pm, n)[:bs][i]
   
    slack = slack_in_equality_constraint(pm, n, i, "constraint_shunt_setpoint")
    
    JuMP.@constraint(
        pm.model, 
        bs == shunt["bs"] + slack
    )
end

""
function constraint_shunt_bounds(pm::ControlAbstractModel,  n::Int, i::Int, shunt::Dict)
    bs = var(pm, n)[:bs][i]
    bsmin = _control_data(shunt)["bsmin"]
    bsmax = _control_data(shunt)["bsmax"]
    up, low = slack_in_bound_constraint(pm, n, i, "constraint_shunt_bounds")

    JuMP.@constraint(
        pm.model, bs >= bsmin - low
    )

    JuMP.@constraint(
        pm.model, bs <= bsmax + up
    )
end