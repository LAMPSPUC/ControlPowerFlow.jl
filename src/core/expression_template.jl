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