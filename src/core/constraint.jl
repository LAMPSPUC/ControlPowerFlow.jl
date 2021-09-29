"`pf[i] == pf"
function constraint_dcline_setpoint_active_fr(pm::_PM.AbstractPowerModel, n::Int, f_idx, t_idx, pf, pt)
    p_fr = var(pm, n, :p_dc, f_idx)

    JuMP.@constraint(pm.model, p_fr == pf)
end

"`pt[i] == pt"
function constraint_dcline_setpoint_active_to(pm::_PM.AbstractPowerModel, n::Int, f_idx, t_idx, pf, pt)
    p_to = var(pm, n, :p_dc, t_idx)

    JuMP.@constraint(pm.model, p_to == pt)
end


"`pg[i] == pg`"
function constraint_gen_setpoint_active(pm::_PM.AbstractPowerModel, n::Int, i, pg)
    pg_var = var(pm, n, :pg, i)
    
    slack = 0.0
    funct_name = "constraint_gen_setpoint_active"
    
    if haskey(ref(pm), :slack) && haskey(ref(pm, n, :slack), funct_name)
        slack += slack_in_equality_constraint!(pm, n, i, funct_name, con)
    end

    JuMP.@constraint(pm.model, pg_var == pg + slack)
end

"`qq[i] == qq`"
function constraint_gen_setpoint_reactive(pm::_PM.AbstractPowerModel, n::Int, i, qg)
    qg_var = var(pm, n, :qg, i)
    
    slack = 0.0
    funct_name = "constraint_gen_setpoint_reactive"
    
    if haskey(ref(pm), :slack) && haskey(ref(pm, n, :slack), funct_name)
        slack += slack_in_equality_constraint!(pm, n, i, funct_name, con)
    end

    JuMP.@constraint(pm.model, qg_var == qg + slack)
end


"`pg[i] == pg`"
function constraint_gen_reactive_bounds(pm::_PM.AbstractPowerModel, n::Int, i, qmax::Float64, qmin::Float64)
    qg  = var(pm, n, :qg, i)
    up  = 0.0
    low = 0.0
    funct_name = "constraint_gen_reactive_bounds"
    
    if haskey(ref(pm), :slack) && haskey(ref(pm, n, :slack), funct_name)
        up  += slack_in_upper_constraint!(pm, n, i, funct_name, con)
        low += slack_in_lower_constraint!(pm, n, i, funct_name, con)
    end

    JuMP.@constraint(pm.model, qg <= qmax + up)
    JuMP.@constraint(pm.model, qg >= qmin - low)
end

function constraint_model_voltage(pm::_PM.AbstractPowerModel, n::Int, i::Int, vmax::Float64, vmin::Float64)
    vm = var(pm, n)[:vm][i]

    up  = 0.0
    low = 0.0
    funct_name = "constraint_model_voltage"
    
    if haskey(ref(pm), :slack) && haskey(ref(pm, n, :slack), funct_name)
        up  += slack_in_upper_constraint!(pm, n, i, funct_name, con)
        low += slack_in_lower_constraint!(pm, n, i, funct_name, con)
    end
    
    JuMP.@constraint(
        pm.model, vm >= vmin - low
    )

    JuMP.@constraint(
        pm.model, vm <= vmax + up
    )
end

function constraint_fixed_shunt(pm::_PM.AbstractPowerModel, n::Int, i::Int, shunt::Dict)
    slack = 0.0
    funct_name = "constraint_shunt"

    if haskey(ref(pm), :slack) && haskey(ref(pm, n, :slack), funct_name)
        slack += slack_in_equality_constraint!(pm, n, i, funct_name, con)
    end
    
    JuMP.@constraint(
        pm.model, 
        var(pm, 0)[:bs][i] == shunt["bs"] + slack
    )
end

function constraint_variable_shunt(pm::_PM.AbstractPowerModel,  n::Int, i::Int, shunt::Dict)
    up = 0.0
    low = 0.0
    funct_name = "constraint_shunt"

    if haskey(ref(pm), :slack) && haskey(ref(pm, n, :slack), funct_name)
        up  += slack_in_upper_constraint!(pm, n, i, funct_name, up)
        low += slack_in_lower_constraint!(pm, n, i, funct_name, low)
    end

    JuMP.@constraint(
        pm.model, var(pm, 0)[:bs][i] >= shunt["bsmin"] - low
    )

    JuMP.@constraint(
        pm.model, var(pm, 0)[:bs][i] <= shunt["bsmax"] + up
    )
end