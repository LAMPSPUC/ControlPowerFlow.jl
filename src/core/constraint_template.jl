""
function constraint_theta_ref(pm::ControlAbstractModel, i::Int; nw::Int=nw_id_default)
    bus = ref(pm, nw, :bus, i)
    constraint_theta_ref(pm, nw, i, bus["va"])
end

""
function constraint_voltage_magnitude_setpoint(pm::ControlAbstractModel, i::Int; nw::Int=nw_id_default)
    bus = ref(pm, nw, :bus, i)
    constraint_voltage_magnitude_setpoint(pm, nw, bus["index"], bus["vm"])
end

""
function constraint_voltage_angle_setpoint(pm::ControlAbstractModel, i::Int; nw::Int=nw_id_default)
    bus = ref(pm, nw, :bus, i)
    constraint_voltage_angle_setpoint(pm, nw, bus["index"], bus["va"])
end

""
function constraint_voltage_magnitude_bounds(pm::ControlAbstractModel, i::Int; nw::Int=nw_id_default)
    bus = ref(pm, nw, :bus, i)
    vmmin = _control_data(bus)["vmmin"]
    vmmax = _control_data(bus)["vmmax"]
    constraint_voltage_magnitude_bounds(pm, nw, i, vmmax, vmmin)
end

""
function constraint_voltage_angle_bounds(pm::ControlAbstractModel, i::Int; nw::Int=nw_id_default)
    bus = ref(pm, nw, :bus, i)
    vamin = _control_data(bus)["vamin"]
    vamax = _control_data(bus)["vamax"]
    constraint_voltage_angle_bounds(pm, nw, i, vamax, vamin)
end

""
function constraint_power_balance(pm::ControlAbstractModel, i::Int; nw::Int=nw_id_default)
    bus = ref(pm, nw, :bus, i)
    bus_arcs = ref(pm, nw, :bus_arcs, i)
    bus_arcs_dc = ref(pm, nw, :bus_arcs_dc, i)
    bus_arcs_sw = ref(pm, nw, :bus_arcs_sw, i)
    bus_gens = ref(pm, nw, :bus_gens, i)
    bus_loads = ref(pm, nw, :bus_loads, i)
    bus_shunts = ref(pm, nw, :bus_shunts, i)
    bus_storage = ref(pm, nw, :bus_storage, i)

    bus_pd = Dict(k => ref(pm, nw, :load, k, "pd") for k in bus_loads)
    bus_qd = Dict(k => ref_or_var(pm, nw, k, :load, "qd") for k in bus_loads)

    bus_gs = Dict(k => ref(pm, nw, :shunt, k, "gs") for k in bus_shunts)
    bus_bs = Dict(k => ref_or_var(pm, nw, k, :shunt, "bs") for k in bus_shunts)

    constraint_power_balance_active(
        pm, nw, i, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs
    )
    constraint_power_balance_reactive(
        pm, nw, i, bus_arcs, bus_arcs_dc, bus_arcs_sw, bus_gens, bus_storage, bus_pd, bus_qd, bus_gs, bus_bs
    )
end

""
function constraint_load_setpoint_active(pm::ControlAbstractModel, i::Int; nw::Int=nw_id_default)
    load = ref(pm, nw, :load, i)
    constraint_load_setpoint_active(pm, nw, load["index"], load["pd"])
end

""
function constraint_load_setpoint_reactive(pm::ControlAbstractModel, i::Int; nw::Int=nw_id_default)
    load = ref(pm, nw, :load, i)
    constraint_load_setpoint_reactive(pm, nw, load["index"], load["qd"])
end

""
function constraint_gen_setpoint_active(pm::ControlAbstractModel, i::Int; nw::Int=nw_id_default)
    gen = ref(pm, nw, :gen, i)
    constraint_gen_setpoint_active(pm, nw, gen["index"], gen["pg"])
end

""
function constraint_gen_setpoint_reactive(pm::ControlAbstractModel, i::Int; nw::Int=nw_id_default)
    gen = ref(pm, nw, :gen, i)
    constraint_gen_setpoint_reactive(pm, nw, gen["index"], gen["qg"])
end

""
function constraint_gen_reactive_bounds(pm::ControlAbstractModel, i::Int; nw::Int=nw_id_default)
    gen = ref(pm, nw, :gen, i)
    constraint_gen_reactive_bounds(pm, nw, gen["index"], gen["qmax"], gen["qmin"])
end

""
function constraint_gen_active_bounds(pm::ControlAbstractModel, i::Int; nw::Int=nw_id_default)
    gen = ref(pm, nw, :gen, i)
    constraint_gen_active_bounds(pm, nw, gen["index"], gen["pmax"], gen["pmin"])
end

""
function constraint_active_power_setpoint(pm::ControlAbstractModel, i::Int; nw::Int=nw_id_default)
    branch = ref(pm, nw, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    
    controlled_bus = _control_data(branch)["controlled_bus"]
    b_idx = controlled_bus == f_bus ? (i, f_bus, t_bus) : (i, t_bus, f_bus)

    p = _control_data(branch)["valsp"]

    constraint_active_power_setpoint(pm, nw, i, b_idx, p)
end

""
function constraint_reactive_power_setpoint(pm::ControlAbstractModel, i::Int; nw::Int=nw_id_default)
    branch = ref(pm, nw, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    
    controlled_bus = _control_data(branch)["controlled_bus"]
    b_idx = controlled_bus == f_bus ? (i, f_bus, t_bus) : (i, t_bus, f_bus)

    q = _control_data(branch)["q"]

    constraint_active_power_setpoint(pm, nw, i, b_idx, q)
end

""
function constraint_tap_ratio_setpoint(pm::ControlAbstractModel, i::Int; nw::Int=nw_id_default)
    branch = ref(pm, nw, :branch, i)
    constraint_tap_ratio_setpoint(pm, nw, i, branch)
end

""
function constraint_tap_ratio_bounds(pm::ControlAbstractModel, i::Int; nw::Int=nw_id_default)
    branch = ref(pm, nw, :branch, i)
    constraint_tap_ratio_bounds(pm, nw, i, branch)
end

""
function constraint_shift_ratio_setpoint(pm::ControlAbstractModel, i::Int; nw::Int=nw_id_default)
    branch = ref(pm, nw, :branch, i)
    constraint_shift_ratio_setpoint(pm, nw, i, branch)
end

""
function constraint_shift_ratio_bounds(pm::ControlAbstractModel, i::Int; nw::Int=nw_id_default)
    branch = ref(pm, nw, :branch, i)
    constraint_shift_ratio_bounds(pm, nw, i, branch)
end

""
function constraint_shunt_setpoint(pm::ControlAbstractModel, s::Int; nw::Int=nw_id_default)
    shunt = ref(pm, :shunt, s)
    constraint_shunt_setpoint(pm, nw, s, shunt)
end

""
function constraint_shunt_bounds(pm::ControlAbstractModel, s::Int; nw::Int=nw_id_default)
    shunt = ref(pm, :shunt, s)
    constraint_shunt_bounds(pm, nw, s, shunt)
end


""
function constraint_dcline_setpoint_active(pm::ControlAbstractModel, i::Int; nw::Int=nw_id_default)
    dcline = ref(pm, nw, :dcline, i)
    f_bus = dcline["f_bus"]
    t_bus = dcline["t_bus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)
    pf = dcline["pf"]
    pt = dcline["pt"]

    constraint_dcline_setpoint_active_fr(pm, nw, f_idx, t_idx, pf, pt)
    constraint_dcline_setpoint_active_to(pm, nw, f_idx, t_idx, pf, pt)
end


##### IVR #####

""
function constraint_current_balance(pm::ControlAbstractModel, i::Int; nw::Int=nw_id_default)
    bus = ref(pm, nw, :bus, i)
    bus_arcs = ref(pm, nw, :bus_arcs, i)
    bus_arcs_dc = ref(pm, nw, :bus_arcs_dc, i)
    bus_gens = ref(pm, nw, :bus_gens, i)
    bus_loads = ref(pm, nw, :bus_loads, i)
    bus_shunts = ref(pm, nw, :bus_shunts, i)

    bus_pd = Dict(k => ref(pm, nw, :load, k, "pd") for k in bus_loads)
    bus_qd = Dict(k => ref_or_var(pm, nw, k, :load, "qd") for k in bus_loads)

    bus_gs = Dict(k => ref(pm, nw, :shunt, k, "gs") for k in bus_shunts)
    bus_bs = Dict(k => ref_or_var(pm, nw, k, :shunt, "bs") for k in bus_shunts)

    constraint_current_balance_real(pm, nw, i, bus_arcs, bus_arcs_dc, bus_gens, bus_pd, bus_qd, bus_gs, bus_bs)
    constraint_current_balance_imaginary(pm, nw, i, bus_arcs, bus_arcs_dc, bus_gens, bus_pd, bus_qd, bus_gs, bus_bs)
end

""
function constraint_current_from(pm::ControlAbstractIVRModel, i::Int; nw::Int=nw_id_default)
    branch = ref(pm, nw, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)

    tr, ti = _PM.calc_branch_t(branch)
    g_fr = branch["g_fr"]
    b_fr = branch["b_fr"]
    tm = branch["tap"]

    constraint_current_from(pm, nw, f_bus, f_idx, g_fr, b_fr, tr, ti, tm, i)
end

""
function constraint_current_to(pm::ControlAbstractIVRModel, i::Int; nw::Int=nw_id_default)
    branch = ref(pm, nw, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    tr, ti = _PM.calc_branch_t(branch)
    g_to = branch["g_to"]
    b_to = branch["b_to"]
    tm = branch["tap"]

    constraint_current_to(pm, nw, t_bus, f_idx, t_idx, g_to, b_to, i)
end

""
function constraint_voltage_drop(pm::ControlAbstractModel, i::Int; nw::Int=nw_id_default)
    branch = ref(pm, nw, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)

    tr, ti = _PM.calc_branch_t(branch)
    r = branch["br_r"]
    x = branch["br_x"]
    tm = branch["tap"]

    constraint_voltage_drop(pm, nw, i, f_bus, t_bus, f_idx, r, x, tr, ti, tm)
end
