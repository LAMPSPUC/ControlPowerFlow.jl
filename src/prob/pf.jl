function run_br_pf(file::String, optimizer; kwargs...)
    network_data = ParserPWF.parse_pwf_to_powermodels(file)
    return run_br_pf(network_data, _PM.ACPPowerModel, optimizer; kwargs...)
end

function run_br_pf(network_data::Dict, optimizer; kwargs...)
    return run_br_pf(network_data, _PM.ACPPowerModel, optimizer; kwargs...)
end

function run_br_pf(file::String, model_type::Type, optimizer; kwargs...)
    network_data = ParserPWF.parse_pwf_to_powermodels(file)
    return run_br_pf(network_data, model_type, optimizer; kwargs...)
end

function run_br_pf(network_data::Dict, model_type::Type, optimizer; kwargs...)
    handle_control_info!(network_data)
    handle_slack_info!(network_data)
    
    return _PM.run_model(network_data, model_type, optimizer, build_br_pf; kwargs...)
end

function run_pf(file::String, model_type, optimizer, model_constructor::Function; kwargs...)
    network_data = ParserPWF.parse_pwf_to_powermodels(file)
    return run_pf(network_data, model_type, optimizer, model_constructor; kwargs...)
end

function run_pf(network_data::Dict, model_type, optimizer, model_constructor::Function; kwargs...)
    return _PM.run_model(network_data, model_type, optimizer, model_constructor; kwargs...)
end

function variables(pm::_PM.AbstractPowerModel)
    _PM.variable_bus_voltage(pm, bounded = false)
    _PM.variable_dcline_power(pm, bounded = false)
    variable_gen_power(pm, bounded = false) 
end

function objective(pm::_PM.AbstractPowerModel, obj)
    @objective(pm.model, Min, obj)
end

function objective(pm::_PM.AbstractPowerModel)
    obj = 0.0
    if has_slack_variables(pm)
        obj += objective_slack(pm)
    end
    objective(pm, obj)
end

function expressions(pm::_PM.AbstractPowerModel)
    for i in ids(pm, :branch)
        expression_branch_power_ohms_yt_from(pm, i)
        expression_branch_power_ohms_yt_to(pm, i)
    end
end

function constraint_ref_bus(pm::_PM.AbstractPowerModel)
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

function constraint_pv(pm::_PM.AbstractPowerModel, i::Int, bus::Dict)
    # this assumes inactive generators are filtered out of bus_gens
    @assert bus["bus_type"] == 2

    constraint_voltage_magnitude_setpoint(pm, controlled_bus(pm, i, "voltage_controlled_bus", "bus_i"))
    for j in ref(pm, :bus_gens, i)
        constraint_gen_setpoint_active(pm, j)        
    end
end

function constraint_pq(pm::_PM.AbstractPowerModel, i::Int, bus::Dict)
    @assert bus["bus_type"] == 1
end

function constraint_bus(pm::_PM.AbstractPowerModel)
    for (i,bus) in ref(pm, :bus)
        # Power balance constraints
        constraint_power_balance(pm, i)
        
        if pv_bus(pm, i)
            constraint_pv(pm, i, bus)
        elseif pq_bus(pm, i)
            constraint_pq(pm, i, bus)
        end

    end
end

function constraint_dcline(pm::_PM.AbstractPowerModel)
    for (i,dcline) in ref(pm, :dcline)
        #constraint_dcline_power_losses(pm, i) not needed, active power flow fully defined by dc line setpoints
        _PM.constraint_dcline_setpoint_active(pm, i)

        f_bus = ref(pm, :bus)[dcline["f_bus"]]
        if f_bus["bus_type"] == 1
            _PM.constraint_voltage_magnitude_setpoint(pm, f_bus["index"])
        end

        t_bus = ref(pm, :bus)[dcline["t_bus"]]
        if t_bus["bus_type"] == 1
            _PM.constraint_voltage_magnitude_setpoint(pm, t_bus["index"])
        end
    end
end

function constraint_branch(pm::_PM.AbstractPowerModel)
    
end

function constraints(pm::_PM.AbstractPowerModel)
    # Reference bus constraints
    constraint_ref_bus(pm)
    # Bus constraints
    constraint_bus(pm)
    # Branch constraints
    constraint_branch(pm)
    # DC branch constraints
    constraint_dcline(pm)
end

function control_variables(pm::_PM.AbstractPowerModel)
    has_control_variables(pm) ? create_control_variables(pm) : nothing
    has_slack_variables(pm)   ? create_slack_variables(pm)   : nothing
end

function control_constraints(pm::_PM.AbstractPowerModel)
    # bus constraints
    for b in ctr_ids(pm, "constraint_theta_ref")      constraint_theta_ref(pm, b)      end
    for b in ctr_ids(pm, "constraint_voltage_bounds") constraint_voltage_bounds(pm, b) end
    for b in ctr_ids(pm, "constraint_voltage_magnitude_setpoint") constraint_voltage_magnitude_setpoint(pm,  controlled_bus(pm, b, "voltage_controlled_bus", "bus_i")) end

    # load constraints
    for d in ctr_ids(pm, "constraint_load_setpoint_active")   constraint_load_setpoint_active(pm, d)   end
    for d in ctr_ids(pm, "constraint_load_setpoint_reactive") constraint_load_setpoint_reactive(pm, d) end

    # gen constraints
    for g in ctr_ids(pm, "constraint_gen_setpoint_active")   constraint_gen_setpoint_active(pm, g)   end
    for g in ctr_ids(pm, "constraint_gen_setpoint_reactive") constraint_gen_setpoint_reactive(pm, g) end
    for g in ctr_ids(pm, "constraint_gen_active_bounds")     constraint_gen_active_bounds(pm, g)     end
    for g in ctr_ids(pm, "constraint_gen_reactive_bounds")   constraint_gen_reactive_bounds(pm, g)   end
    
    # power constraints
    for p in ctr_ids(pm, "constraint_active_power_setpoint")   constraint_active_power_setpoint(pm, p)   end
    for q in ctr_ids(pm, "constraint_reactive_power_setpoint") constraint_reactive_power_setpoint(pm, q) end

    # transformer constraints
    for t in ctr_ids(pm, "constraint_tap_ratio") constraint_tap_ratio(pm, t) end
    for t in ctr_ids(pm, "constraint_tap_shift") constraint_tap_shift(pm, t) end

    # shunt constraints
    for s in ctr_ids(pm, "constraint_shunt") constraint_shunt(pm, s) end
    
    # dcline constraints
    for dc in ctr_ids(pm, "constraint_dcline_setpoint_active") constraint_dcline_setpoint_active(pm, dc) end
    for dc in ctr_ids(pm, "constraint_dcline_setpoint_active") constraint_dcline_setpoint_active(pm, dc) end
end

function build_br_pf(pm::_PM.AbstractPowerModel)
    _handle_control_info(pm)
    # Create model variables
    variables(pm)
    # Create additional control variables
    control_variables(pm)
    # Create JuMP expressions
    expressions(pm)
    # Define model constraints
    constraints(pm)
    # Define additional control constraints
    control_constraints(pm)
    # Define model objective function
    objective(pm)
end