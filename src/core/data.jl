function fixed_shunt!(network_data::Dict)
    for (s, shunt) in network_data["shunt"]
        shunt["shunt_type"] = 1
    end
end

function unfix_shunt!(network_data::Dict)
    for (s, shunt) in network_data["shunt"]
        shunt["shunt_type"] = shunt["shunt_type_orig"]
    end
end