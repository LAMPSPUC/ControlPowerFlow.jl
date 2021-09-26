function constraint_fixed_shunt(pm::_PM.AbstractPowerModel, s::Int, shunt::Dict)
    JuMP.@constraint(
        pm.model, 
        var(pm, 0)[:bs][s] == shunt["bs"]
    )
end

function constraint_variable_shunt(pm::_PM.AbstractPowerModel, s::Int, shunt::Dict)
    JuMP.@constraint(
        pm.model, 
        shunt["bsmin"] <= var(pm, 0)[:bs][s] <= shunt["bsmax"]
    )
end