function constraint_theta_ref(pm::_PM.AbstractPolarModels, n::Int, i::Int, va::Float64)
    slack = slack_in_equality_constraint(pm, n, i, "constraint_theta_ref")

    JuMP.@constraint(pm.model, var(pm, n, :va)[i] == va + slack)
end