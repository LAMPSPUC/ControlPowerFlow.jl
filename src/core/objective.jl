function objective_slack(pm::_PM.AbstractPowerModel)
    obj = 0.0

    for (n, nw_ref) in _PM.nws(pm)
        for (funct_name, filt) in ref(pm, n, :slack)
            if haskey(slack_function, funct_name)
                var_nm = slack_function[funct_name][2]
                pos_nm = "sl_"*var_nm*"_pos"
                neg_nm = "sl_"*var_nm*"_neg"

                obj += sum(var(pm, n, Symbol(pos_nm)))
                obj += sum(var(pm, n, Symbol(neg_nm)))
            end
        end
    end

    return obj
end

function objective_control(pm::_PM.AbstractPowerModel)
    obj = 0.0

    return obj
end