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
    return _PM.run_model(network_data, model_type, optimizer, build_br_pf; kwargs...)
end

function run_pf(file::String, model_type, optimizer, model_constructor::Function; kwargs...)
    network_data = ParserPWF.parse_pwf_to_powermodels(file)
    return _PM.run_pf(network_data, model_type, optimizer, model_constructor; kwargs...)
end

function run_pf(network_data::Dict, model_type, optimizer, model_constructor::Function; kwargs...)
    return _PM.run_model(network_data, model_type, optimizer, model_constructor; kwargs...)
end

function variable(pm::_PM.AbstractPowerModel)
    _PM.variable_bus_voltage(pm, bounded = false)
    _PM.variable_dcline_power(pm, bounded = false)
    
    variable_gen_power(pm, bounded = false) 
    variable_shunt(pm)
    
    if haskey(ref(pm), :slack)
        variable_slack(pm)
    end
end

function objective(pm::_PM.AbstractPowerModel)
    if haskey(ref(pm), :slack)
        objective_slack(pm)
    end
end

function expression(pm::_PM.AbstractPowerModel)
    for i in ids(pm, :branch)
        _PM.expression_branch_power_ohms_yt_from(pm, i)
        _PM.expression_branch_power_ohms_yt_to(pm, i)
    end
end

function constraint_ref_bus(pm::_PM.AbstractPowerModel)
    for (i,bus) in ref(pm, :ref_buses)
        @assert bus["bus_type"] == 3
        constraint_theta_ref(pm, i)
        constraint_voltage_magnitude_setpoint(pm, i)

        # if multiple generators, fix power generation degeneracies
        if length(ref(pm, :bus_gens, i)) > 1
            for j in collect(ref(pm, :bus_gens, i))[2:end]
                constraint_gen_setpoint_active(pm, j)
                constraint_gen_setpoint_reactive(pm, j)
            end
        end
    end
end

function constraint_pv(pm::_PM.AbstractPowerModel, i::Int, bus::Dict)
     # this assumes inactive generators are filtered out of bus_gens
     @assert bus["bus_type"] == 2

     constraint_voltage_magnitude_setpoint(pm, controlled_bus(pm, i))
     for j in ref(pm, :bus_gens, i)
         constraint_gen_setpoint_active(pm, j)
        #  constraint_gen_reactive_bounds(pm, j)
     end
end

function constraint_pq(pm::_PM.AbstractPowerModel, i::Int, bus::Dict)
    @assert bus["bus_type"] == 1

    # constraint_voltage_bounds(pm, i)
end

function pv_bus(pm::_PM.AbstractPowerModel, i::Int)
    return length(ref(pm, :bus_gens, i)) > 0 && !(i in ids(pm,:ref_buses))
end

function pq_bus(pm::_PM.AbstractPowerModel, i::Int)
    return length(ref(pm, :bus_gens, i)) == 0 
end

function constraint_bus(pm::_PM.AbstractPowerModel)
    for (i,bus) in ref(pm, :bus)
        # Power balance constraints
        constraint_power_balance(pm, i)
        
        constraint_shunt(pm, i)

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

function constraint(pm::_PM.AbstractPowerModel)
    # Reference bus constraints
    constraint_ref_bus(pm)
    # Bus constraints
    constraint_bus(pm)
    # DC line constraints
    constraint_dcline(pm)
end

function build_br_pf(pm::_PM.AbstractPowerModel)
    # Create model variables
    variable(pm)
    # Define model objective function
    objective(pm)
    # Create JuMP expressions
    expression(pm)
    # Define the model constraints
    constraint(pm)
end