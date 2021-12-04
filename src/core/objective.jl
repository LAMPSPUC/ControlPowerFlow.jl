function objective_slack(pm::ControlAbstractModel)
    obj = 0.0

    slack_info = ref(pm, :control_info, :control_slacks)
    for (n, nw_ref) in _PM.nws(pm)
        for (constraint, info) in slack_info
            if has_control_slacks(pm, constraint)
                var_nm = info["variable"]
                type   = info["type"]
                weight = info["weight"]
                if type == :bound
                    pos_nm = "sl_"*var_nm*"_upp"
                    neg_nm = "sl_"*var_nm*"_low"
    
                    obj += weight*sum(var(pm, n, Symbol(pos_nm)).^2)
                    obj += weight*sum(var(pm, n, Symbol(neg_nm)).^2)
                elseif type == :equalto
                    eq_to_nm = "sl_"*var_nm
                    obj += weight*sum(var(pm, n, Symbol(eq_to_nm)).^2)
                end
            end
        end
    end

    return obj
end

function objective_control(pm::ControlAbstractModel)
    obj = 0.0

    return obj
end