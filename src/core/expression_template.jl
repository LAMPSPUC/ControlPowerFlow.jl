""
function expression_branch_power_ohms_yt_from(pm::ControlAbstractModel, i::Int; nw::Int=nw_id_default)
    if !haskey(var(pm, nw), :p)
        var(pm, nw)[:p] = Dict{Tuple{Int,Int,Int},Any}()
    end
    if !haskey(var(pm, nw), :q)
        var(pm, nw)[:q] = Dict{Tuple{Int,Int,Int},Any}()
    end

    branch = ref(pm, nw, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    g, b = _PM.calc_branch_y(branch)
    g_fr = branch["g_fr"]
    b_fr = branch["b_fr"]
    
    expression_branch_power_ohms_yt_from(pm, nw, f_bus, t_bus, f_idx, t_idx, g, b, g_fr, b_fr, i)
end


""
function expression_branch_power_ohms_yt_to(pm::ControlAbstractModel, i::Int; nw::Int=nw_id_default)
    if !haskey(var(pm, nw), :p)
        var(pm, nw)[:p] = Dict{Tuple{Int,Int,Int},Any}()
    end
    if !haskey(var(pm, nw), :q)
        var(pm, nw)[:q] = Dict{Tuple{Int,Int,Int},Any}()
    end

    branch = ref(pm, nw, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    g, b = _PM.calc_branch_y(branch)
    g_to = branch["g_to"]
    b_to = branch["b_to"]

    expression_branch_power_ohms_yt_to(pm, nw, f_bus, t_bus, f_idx, t_idx, g, b, g_to, b_to, i)
end


#### IVR

""
function expression_branch_current_from_performance(pm::ControlAbstractModel, i::Int; nw::Int=nw_id_default)
    if !haskey(var(pm, nw), :cr)
        var(pm, nw)[:cr] = Dict{Tuple{Int,Int,Int},Any}()
    end
    if !haskey(var(pm, nw), :ci)
        var(pm, nw)[:ci] = Dict{Tuple{Int,Int,Int},Any}()
    end

    branch = ref(pm, nw, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    g, b = _PM.calc_branch_y(branch)
    tr, ti = _PM.calc_branch_t(branch)
    g_fr = branch["g_fr"]
    b_fr = branch["b_fr"]
    tm = branch["tap"]

    expression_branch_current_from_performance(pm, nw, i, f_bus, f_idx, g_fr, b_fr, tr, ti, tm)
end

""
function expression_branch_current_to_performance(pm::ControlAbstractModel, i::Int; nw::Int=nw_id_default)
    if !haskey(var(pm, nw), :cr)
        var(pm, nw)[:cr] = Dict{Tuple{Int,Int,Int},Any}()
    end
    if !haskey(var(pm, nw), :ci)
        var(pm, nw)[:ci] = Dict{Tuple{Int,Int,Int},Any}()
    end

    branch = _PM.ref(pm, nw, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)
    t_idx = (i, t_bus, f_bus)

    g, b = _PM.calc_branch_y(branch)
    tr, ti = _PM.calc_branch_t(branch)
    g_to = branch["g_to"]
    b_to = branch["b_to"]
    tm = branch["tap"]

    expression_branch_current_to_performance(pm, nw, i, t_bus, t_idx, g_to, b_to)
end

""
function expression_branch_current_series_performance(pm::ControlAbstractModel, i::Int; nw::Int=nw_id_default)
    if !haskey(var(pm, nw), :csr)
        var(pm, nw)[:csr] = Dict{Int,Any}()
    end
    if !haskey(var(pm, nw), :csi)
        var(pm, nw)[:csi] = Dict{Int,Any}()
    end

    branch = _PM.ref(pm, nw, :branch, i)
    f_bus = branch["f_bus"]
    t_bus = branch["t_bus"]
    f_idx = (i, f_bus, t_bus)

    tr, ti = _PM.calc_branch_t(branch)
    tm = branch["tap"]
    r = branch["br_r"]
    x = branch["br_x"]

    expression_branch_current_series_performance(pm, nw, i, f_bus, t_bus, f_idx, r, x, tr, ti, tm)
end