function constraint_theta_ref(pm::_PM.AbstractPolarModels, n::Int, i::Int, va::Float64)
    slack = 0.0
    funct_name = "constraint_theta_ref"
    
    if haskey(ref(pm), :slack) && haskey(ref(pm, n, :slack), funct_name)
        slack += slack_in_equality_constraint!(pm, n, i, funct_name, con)
    end

    JuMP.@constraint(pm.model, var(pm, n, :va)[i] == va + slack)
end