function variables_iv_performance(pm::ControlAbstractModel)
    variable_bus_voltage(pm, bounded = false)
    # variable_branch_current(pm, bounded = false)

    variable_gen_current(pm, bounded = false)
    variable_dcline_current(pm, bounded = false)
end

function constraint_ref_bus_iv_performance(pm::ControlAbstractModel)
    for (i,bus) in ref(pm, :ref_buses)
        @assert bus["bus_type"] == 3
        constraint_theta_ref(pm, i)
        constraint_voltage_magnitude_setpoint(pm, i)

        # if multiple generators, fix power generation degeneracies
        for (l, j) in enumerate(collect(ref(pm, :bus_gens, i)))
            if l > 1 # powermodels allows more than one generator per bus
                constraint_gen_setpoint_active(pm, j)
                constraint_gen_setpoint_reactive(pm, j)
            end
        end
    end
end

function constraint_ref_iv_performance(pm::ControlAbstractModel, i::Int, bus::Dict)
    # this assumes inactive generators are filtered out of bus_gens
    @assert bus["bus_type"] == 3

    # constraint_balance_performance
    constraint_current_balance(pm, i)
end

function constraint_pv_iv_performance(pm::ControlAbstractModel, i::Int, bus::Dict)
    # this assumes inactive generators are filtered out of bus_gens
    @assert bus["bus_type"] == 2

    constraint_current_balance(pm, i)

    constraint_voltage_magnitude_setpoint(pm, controlled_bus(pm, i, "voltage_controlled_bus", "bus_i"))
    for j in ref(pm, :bus_gens, i)
        constraint_gen_setpoint_active(pm, j)        
    end
end

function constraint_pq_iv_performance(pm::ControlAbstractModel, i::Int, bus::Dict)
    @assert bus["bus_type"] == 1

    constraint_current_balance(pm, i)
end

function constraint_bus_iv_performance(pm::ControlAbstractModel)
    for (i,bus) in ref(pm, :bus)
        # Power balance constraints
        
        if pv_bus(pm, i)
            constraint_pv_iv_performance(pm, i, bus)
        elseif pq_bus(pm, i)
            constraint_pq_iv_performance(pm, i, bus)
        elseif bus["bus_type"] == 3
            constraint_ref_iv_performance(pm, i, bus) 
        end
    end
end

function constraint_branch_iv_performance(pm::ControlAbstractModel)
    # for i in ids(pm, :branch)
    #     constraint_current_from(pm, i)
    #     constraint_current_to(pm, i)

    #     constraint_voltage_drop(pm, i)
    # end
end

#= function expressions_iv_performance(pm::ControlAbstractModel)
    # current flow expressions
    for i in ids(pm, :branch)
        expression_branch_current_series_performance(pm, i)
        expression_branch_current_from_performance(pm, i)
        expression_branch_current_to_performance(pm, i)
    end
end =#
function expressions_iv_performance(pm::ControlAbstractModel)
    # current flow expressions
    for i in ids(pm, :branch)
        expression_branch_current_series_current_from_performance(pm, i)
        # expression_branch_current_series_performance(pm, i)
        # expression_branch_current_from_performance(pm, i)
        expression_branch_current_to_performance(pm, i)
    end
end


function constraint_dcline_iv_performance(pm::ControlAbstractModel)
    for (i,dcline) in ref(pm, :dcline)
        #constraint_dcline_power_losses(pm, i) not needed, active power flow fully defined by dc line setpoints
        constraint_dcline_setpoint_active(pm, i)

        f_bus = ref(pm, :bus)[dcline["f_bus"]]
        if f_bus["bus_type"] == 1
            constraint_voltage_magnitude_setpoint(pm, f_bus["index"])
        end

        t_bus = ref(pm, :bus)[dcline["t_bus"]]
        if t_bus["bus_type"] == 1
            constraint_voltage_magnitude_setpoint(pm, t_bus["index"])
        end
    end
end

function constraints_iv_performance(pm::ControlAbstractModel)
    # Reference bus constraints
    constraint_ref_bus_iv_performance(pm)
    # Bus constraints
    constraint_bus_iv_performance(pm)
    # Branch constraints
    constraint_branch_iv_performance(pm)
    # DC branch constraints
    constraint_dcline_iv_performance(pm)
end

function build_pf_iv_performance(pm::ControlAbstractModel)
    _handle_control_info(pm)
    # Create model variables
    variables_iv_performance(pm)
    # Create additional control variables
    control_variables(pm)
    # Create JuMP expressions
    expressions_iv_performance(pm)
    # Define model constraints
    constraints_iv_performance(pm)
    # Define additional control constraints
    control_constraints(pm)
    # Define model objective function
    objective(pm)
end