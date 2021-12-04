
function fix_shunt!(network_data::Dict)
    for (s, shunt) in network_data["shunt"]
        shunt["shunt_type"] = 1
    end
end

function unfix_shunt!(network_data::Dict)
    for (s, shunt) in network_data["shunt"]
        shunt["shunt_type"] = shunt["shunt_type_orig"]
    end
end

function calc_branch_t(tap_ratio, angle_shift)
    tr = tap_ratio .* cos.(angle_shift)
    ti = tap_ratio .* sin.(angle_shift)

    return tr, ti
end

function set_control_info!(data::Dict, control_info::Dict)
    data["control_info"] = control_info["control_info"]
    return 
end
