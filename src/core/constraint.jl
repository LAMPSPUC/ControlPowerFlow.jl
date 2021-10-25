"`pf[i] == pf"
function constraint_dcline_setpoint_active_fr(pm::_PM.AbstractPowerModel, n::Int, f_idx, t_idx, pf, pt)
    p_fr = var(pm, n, :p_dc, f_idx)
    #ToDo add slacks
    JuMP.@constraint(pm.model, p_fr == pf)
end

"`pt[i] == pt"
function constraint_dcline_setpoint_active_to(pm::_PM.AbstractPowerModel, n::Int, f_idx, t_idx, pf, pt)
    p_to = var(pm, n, :p_dc, t_idx)
    #ToDo add slacks
    JuMP.@constraint(pm.model, p_to == pt)
end

"`pg[i] == pg`"
function constraint_gen_setpoint_active(pm::_PM.AbstractPowerModel, n::Int, i, pg)
    pg_var = var(pm, n, :pg, i)
    
    slack = slack_in_equality_constraint(pm, n, i, "constraint_gen_setpoint_active")

    JuMP.@constraint(pm.model, pg_var == pg + slack)
end

"`qq[i] == qq`"
function constraint_gen_setpoint_reactive(pm::_PM.AbstractPowerModel, n::Int, i, qg)
    qg_var = var(pm, n, :qg, i)
    
    slack = slack_in_equality_constraint(pm, n, i, "constraint_gen_setpoint_reactive")
    
    JuMP.@constraint(pm.model, qg_var == qg + slack)
end

"`qg[i] >= qmin; qg[i] <= qmax`"
function constraint_gen_reactive_bounds(pm::_PM.AbstractPowerModel, n::Int, i, qmax::Float64, qmin::Float64)
    qg  = var(pm, n, :qg, i)

    up, low = slack_in_bound_constraint(pm, n, i, "constraint_gen_reactive_bounds")

    JuMP.@constraint(pm.model, qg <= qmax + up)
    JuMP.@constraint(pm.model, qg >= qmin - low)
end

"`pg[i] >= pmin; pg[i] <= pmax`"
function constraint_gen_active_bounds(pm::_PM.AbstractPowerModel, n::Int, i, pmax::Float64, pmin::Float64)
    pg  = var(pm, n, :pg, i)
    
    up, low = slack_in_bound_constraint(pm, n, i, "constraint_gen_active_bounds")

    JuMP.@constraint(pm.model, pg <= pmax + up)
    JuMP.@constraint(pm.model, pg >= pmin - low)
end


""
function constraint_tap_ratio(pm::_PM.AbstractPowerModel,  n::Int, i::Int, branch::Dict)
    tap = var(pm, n)[:tap][i]
    @show i
    up, low = slack_in_bound_constraint(pm, n, i, "constraint_tap_ratio")

    JuMP.@constraint(
        pm.model, tap >= branch["tapmin"] - low
    )

    JuMP.@constraint(
        pm.model, tap <= branch["tapmax"] + up
    )
end

""
function constraint_tap_shift(pm::_PM.AbstractPowerModel,  n::Int, i::Int, branch::Dict)
    shift = var(pm, n)[:shift][i]
    shift_min = branch["angmin"]
    shift_max = branch["angmax"]

    up, low = slack_in_bound_constraint(pm, n, i, "constraint_tap_shift")

    JuMP.@constraint(
        pm.model, shift >= shift_min - low
    )

    JuMP.@constraint(
        pm.model, shift <= shift_max + up
    )
end

""
function constraint_voltage_bounds(pm::_PM.AbstractPowerModel, n::Int, i::Int, vmax::Float64, vmin::Float64)
    vm = var(pm, n)[:vm][i]

    up, low = slack_in_bound_constraint(pm, n, i, "constraint_voltage_bounds")

    JuMP.@constraint(
        pm.model, vm >= vmin - low
    )

    JuMP.@constraint(
        pm.model, vm <= vmax + up
    )
end

""
function constraint_fixed_shunt(pm::_PM.AbstractPowerModel, n::Int, i::Int, shunt::Dict)
    bs = var(pm, n)[:bs][i]
   
    slack = slack_in_equality_constraint(pm, n, i, "constraint_shunt")
    
    JuMP.@constraint(
        pm.model, 
        bs == shunt["bs"] + slack
    )
end

""
function constraint_variable_shunt(pm::_PM.AbstractPowerModel,  n::Int, i::Int, shunt::Dict)
    bs = var(pm, n)[:bs][i]

    up, low = slack_in_bound_constraint(pm, n, i, "constraint_shunt")

    JuMP.@constraint(
        pm.model, bs >= shunt["bsmin"] - low
    )

    JuMP.@constraint(
        pm.model, bs <= shunt["bsmax"] + up
    )
end