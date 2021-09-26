function run_br_pf(file::String, model_type::Type, optimizer; kwargs...)
    network_data = ParserPWF.parse_pwf_to_powermodels(file)
    return run_br_pf(network_data, model_type, optimizer; kwargs...)
end

function run_br_pf(network_data::Dict, model_type::Type, optimizer; kwargs...)
    return _PM.run_model(network_data, model_type, optimizer, build_br_pf; kwargs...)
end

function run_pf(file::String, model_type, optimizer, model_constructor::Function; kwargs...)
    network_data = ParserPWF.parse_pwf_to_powermodels(file)
    return _PM.run_model(network_data, model_type, optimizer, model_constructor; kwargs...)
end

function build_br_pf(pm::_PM.AbstractPowerModel)
    _PM.variable_bus_voltage(pm, bounded = false)
    _PM.variable_gen_power(pm, bounded = false)
    _PM.variable_dcline_power(pm, bounded = false)
    variable_shunt(pm)

    for i in ids(pm, :branch)
        _PM.expression_branch_power_ohms_yt_from(pm, i)
        _PM.expression_branch_power_ohms_yt_to(pm, i)
    end

    _PM.constraint_model_voltage(pm)
    
    for (i,bus) in ref(pm, :ref_buses)
        @assert bus["bus_type"] == 3
        _PM.constraint_theta_ref(pm, i)
        _PM.constraint_voltage_magnitude_setpoint(pm, i)

        # if multiple generators, fix power generation degeneracies
        if length(ref(pm, :bus_gens, i)) > 1
            for j in collect(ref(pm, :bus_gens, i))[2:end]
                _PM.constraint_gen_setpoint_active(pm, j)
                _PM.constraint_gen_setpoint_reactive(pm, j)
            end
        end
    end

    for (i,bus) in ref(pm, :bus)
        constraint_power_balance(pm, i)
        
        constraint_shunt(pm, i)

        # PV Bus Constraints
        if length(ref(pm, :bus_gens, i)) > 0 && !(i in ids(pm,:ref_buses))
            # this assumes inactive generators are filtered out of bus_gens
            @assert bus["bus_type"] == 2

            _PM.constraint_voltage_magnitude_setpoint(pm, controlled_bus(pm, i))
            for j in ref(pm, :bus_gens, i)
                _PM.constraint_gen_setpoint_active(pm, j)
            end
        end
    end


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

function build_br_slack_pf(pm::_PM.AbstractPowerModel)
    _PM.variable_bus_voltage(pm, bounded = false)
    _PM.variable_gen_power(pm, bounded = false)
    _PM.variable_dcline_power(pm, bounded = false)
    variable_shunt(pm)

    # create slack variables
    variable_slack(pm)
    # create slack objective
    objective_slack(pm)

    for i in ids(pm, :branch)
        _PM.expression_branch_power_ohms_yt_from(pm, i)
        _PM.expression_branch_power_ohms_yt_to(pm, i)
    end

    _PM.constraint_model_voltage(pm)
    
    for (i,bus) in ref(pm, :ref_buses)
        @assert bus["bus_type"] == 3
        constraint_theta_ref_slack(pm, i)
        constraint_voltage_magnitude_setpoint_slack(pm, i)

        # if multiple generators, fix power generation degeneracies
        if length(ref(pm, :bus_gens, i)) > 1
            for j in collect(ref(pm, :bus_gens, i))[2:end]
                _PM.constraint_gen_setpoint_active(pm, j)
                _PM.constraint_gen_setpoint_reactive(pm, j)
            end
        end
    end

    for (i,bus) in ref(pm, :bus)
        constraint_power_balance_slack(pm, i)
        
        constraint_shunt(pm, i)

        # PV Bus Constraints
        if length(ref(pm, :bus_gens, i)) > 0 && !(i in ids(pm,:ref_buses))
            # this assumes inactive generators are filtered out of bus_gens
            @assert bus["bus_type"] == 2

            constraint_voltage_magnitude_setpoint_slack(pm, controlled_bus(pm, i))
            for j in ref(pm, :bus_gens, i)
                _PM.constraint_gen_setpoint_active(pm, j)
            end
        end
    end


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


    

