function objective_slack(pm::_PM.AbstractPowerModel)
    obj = 0.0
    for (n, nw_ref) in _PM.nws(pm)
        obj += sum(var(pm, n, :sl_th_ref_pos))
        obj += sum(var(pm, n, :sl_th_ref_neg))
        obj += sum(var(pm, n, :sl_volt_sp_pos))
        obj += sum(var(pm, n, :sl_volt_sp_neg))
        obj += sum(var(pm, n, :sl_const_balance_p_pos))
        obj += sum(var(pm, n, :sl_const_balance_p_neg))
        obj += sum(var(pm, n, :sl_const_balance_q_pos))
        obj += sum(var(pm, n, :sl_const_balance_q_neg))
    end

    JuMP.@objective(pm.model, Min,
        obj
    )
end