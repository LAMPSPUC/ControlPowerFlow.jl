#control::String
#variable::String
#bounds::Bool
#element::Symbol
#default_start::Float64

const control_info_default = Dict(
    "shunt"        => ("shunt",        "bs",    true, :shunt,  0.0),
    "tap"          => ("tap",          "tap",   true, :branch, 1.0),
    "shift"        => ("shift",        "shift", true, :branch, 0.0),
    "voltage"      => ("voltage",      nothing, true, :bus,    nothing),
    "gen_active"   => ("gen_active",   nothing, true, :gen,    nothing),
    "gen_reactive" => ("gen_reactive", nothing, true, :gen,    nothing),
)


#### control_info functions  ####
function _create_control_info(control::Dict)
    control_info = Dict{Any, Any}() # Type must be {Any, Any} to avoid interactions with instantiate_data in PowerModels
    for (key, defaults) in control_info_default
            (name, variable, bounds, element, start) = control_info_default[key]
            info = Dict{String, Any}()
            info["name"]     = name
            info["variable"] = variable
            info["bounds"]   = bounds
            info["element"]  = element
            info["start"]    = start
            
            control_info[key] = info
    end
    if !isempty(setdiff(keys(control), keys(control_info_default)))
        error("Invalid control option. Verify control dictionary inside network data")   
    end
    return control_info
end

function _verify_info!(info::Dict, key::String, type)
    @assert haskey(info, key)
    @assert (typeof(info[key]) == type) || (typeof(info[key]) == Nothing)
end

function _verify_control_info!(control_info::Dict)
    for (control, info) in control_info
        @assert typeof(info) <: Dict
        _verify_info!(info, "name",     String)
        _verify_info!(info, "variable", String)
        _verify_info!(info, "bounds",   Bool)
        _verify_info!(info, "element",  Symbol)
        _verify_info!(info, "start",    Float64)
    end
end

function handle_control_info!(network::Dict)
    if haskey(network, "control_info")
        _verify_control_info!(network["control_info"])
    else
        if !haskey(network, "control")
            network["control"] = Dict{Any, Any}()
        end
        network["control_info"] = _create_control_info(network["control"])
    end
    return
end

########### auxiliar  ###########

function handle_control_indexes(pm, nw, element, control_name)
    or_ids = ids(pm, nw, element)
    control = ref(pm, nw, :control)
    filt_ids = haskey(control, control_name) ? control[control_name] : Int[]
    final_ids = or_ids
    if filt_ids != true
        try
            final_ids = intersection(or_ids, filt_ids)
        catch
            @error("Failed to create control variable in $control_name. "
                        * "Check control variable dictionary for possible mistake")
        end
    end
    ref(pm, nw, :control_info)[control_name]["indexes"] = final_ids
    ref(pm, nw, :control_info)[control_name]["has_control"] = isempty(final_ids) ? false : true
end

########### variables ###########

function prepare_control_info(pm::_PM.AbstractPowerModel; nw::Int=nw_id_default)
    for (control_name, control) in ref(pm, nw, :control_info)
        name = control["name"]
        element = control["element"]
        handle_control_indexes(pm, nw, element, name)
    end
end

