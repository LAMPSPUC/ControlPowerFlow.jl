function check_same_dict(dict1::Dict, dict2::Dict, key; atol = 1e-3)
    @assert keys(dict1) == keys(dict2)

    v1, v2 = dict1[key], dict2[key]
    if isa(v1, Dict)
        if isa(v2, Dict)
            return check_same_dict(v1,v2)
        else
            println("$v2 is not a dict")
            return false
        end
    elseif isa(v1, Real)
        if isa(v2, Real)
            if !isapprox(v1, v2, atol=atol)
                println("$v1 != $v2")
                return false
            end
        else
            println("$v2 is not a number")
            return false
        end
    else
        if v1 != v2
            println("$v1 != $v2")
            return false
        end
    end
    return true
end

function check_same_dict(dict1::Dict, dict2::Dict; atol = 1e-3, ignore = ["source_version", "source_type", "name"])
    @assert keys(dict1) == keys(dict2)

    bools = Bool[]
    for (k,v1) in dict1
        if !(k in ignore)
            res = check_same_dict(dict1, dict2, k)
            push!(bools, res)
            if res
            else
            end
        end
    end
    return !(false in bools)
end

function get_ordered_dict(dict::Dict)
    dict_keys = Int[]
    for key in keys(dict)
        push!(dict_keys, parse(Int,key)) 
    end
    return string.(sort(dict_keys))
end

function print_results_bus(dict::Dict)
    for k in get_ordered_dict(dict["bus"])
        va = round(dict["bus"][k]["va"]*180/π, digits = 3)
        vm = round(dict["bus"][k]["vm"], digits = 3)
        tp = dict["bus"][k]["bus_type"]
        println("Bus $(k) => vm: $(vm) - va: $(va) - tp: $(tp)")
    end
end

function find_keys_gens_from_bus(dict::Dict, bus::Int)
    findall(gen->gen["gen_bus"] == bus, dict["gen"])
end

function sum_gens(dict::Dict, gen_keys::Vector{String}; type = "g")
    pg = 0
    qg = 0
    base = dict["baseMVA"]

    for k in gen_keys
        pg += dict["gen"][k]["p"*type]
        qg += dict["gen"][k]["q"*type]
    end

    return string(round(pg*base, digits = 1)), string(round(qg*base, digits = 1))
end

_n_blank_spaces_lft_rght(n::Int)     = return n, n
_n_blank_spaces_lft_rght(n::Float64) = return Int(floor(n)), Int(floor(n))+1

function fit_string(str::String, len)
    n_bl_sp = (len - length(str) - 1)
    
    n_bl_sp_l, n_bl_sp_r = n_bl_sp%2 == 0 ? _n_blank_spaces_lft_rght(div(n_bl_sp, 2)) :
                     _n_blank_spaces_lft_rght(n_bl_sp/2)

    return string(" "^n_bl_sp_l, str, " "^n_bl_sp_r, "|")
end

function fit_results(elements::Vector{String}, len)
    row = "|"
    for el in elements
        row *= fit_string(el, len)
    end
    return row
end

function find_keys_shunt_from_bus(dict::Dict, bus::Int; section = "DBAR")
    findall(shunt->shunt["shunt_bus"] == bus && shunt["section"] == section, dict["shunt"])
end

function get_ordered_branch_keys(branch::Dict)
    f_bus_to_branch_key = Dict()
    for (k, v) in branch
        if haskey(f_bus_to_branch_key, "$(v["f_bus"])")
            push!(f_bus_to_branch_key["$(v["f_bus"])"], k)
        else
            f_bus_to_branch_key["$(v["f_bus"])"] = [k]
        end
    end
    ordered_branch_keys = []
    for k in get_ordered_dict(f_bus_to_branch_key)
        for branch in f_bus_to_branch_key[k]
            push!(ordered_branch_keys, branch)
        end
    end
    return ordered_branch_keys
end

function print_bus(dict; len = 11)
    header = ["BUS", "Type", "VM", "VA", "Bsht"]
    println(fit_results(header, len))

    for k in get_ordered_dict(dict["bus"])
        tp = string(dict["bus"][k]["bus_type"])
        va = string(round(dict["bus"][k]["va"]*180/π, digits = 2))
        vm = string(round(dict["bus"][k]["vm"], digits = 3))
        bsht = 0
        for (shunt_key) in find_keys_shunt_from_bus(dict, parse(Int,k))
            bsht += dict["shunt"][shunt_key]["bs"]*100
        end
        bsht =  string(round(bsht, digits = 1))
        row = String[string(k), tp, vm, va, bsht]
        println(fit_results(row, len))
    end
end

function print_gen(dict; len = 11)
    header = ["Bus", "PG", "QG", "PMin", "PMax", "QMin", "QMax"]
    println(fit_results(header, len))

    for k in get_ordered_dict(dict["bus"])
        pg, qg = sum_gens(
            dict, 
            find_keys_gens_from_bus(dict, parse(Int,k))
        )
        pmin, qmin = sum_gens(
            dict, 
            find_keys_gens_from_bus(dict, parse(Int,k));
            type = "min"
        )
        pmax, qmax = sum_gens(
            dict, 
            find_keys_gens_from_bus(dict, parse(Int,k));
            type = "max"
        )
        row = String[string(k), pg, qg, pmin, pmax, qmin, qmax]
        println(fit_results(row, len))
    end
end

function print_transmission_lines(dict; len = 11)
    header = ["Num", "From", "To", "Circ", "tap", "tmin", "tmax", "b_r", "b_x","b_fr", "b_to", "status"]

    println(fit_results(header, len))
    branch = dict["branch"]
    for k in get_ordered_branch_keys(branch::Dict)
        f_bus = string(round(branch[k]["f_bus"]))
        t_bus = string(round(branch[k]["t_bus"]))
        circuit = string(round(branch[k]["circuit"]))
        tap  = string(round(branch[k]["tap"]))
        tmin = string(round(branch[k]["tapmin"]))
        tmax = string(round(branch[k]["tapmax"]))
        br_r = string(round(branch[k]["br_r"], digits = 5))
        br_x = string(round(branch[k]["br_x"], digits = 5))
        b_fr = string(round(branch[k]["b_fr"], digits = 5))
        b_to = string(round(branch[k]["b_to"], digits = 5))
        status = string(round(branch[k]["br_status"]))
        row = String[string(k), f_bus, t_bus, circuit, tap, tmin, tmax, br_r, br_x, b_fr, b_to, status]
        println(fit_results(row, len))
    end
end

function handle_shunt(dict, dbsh_shunts, dcer_shunts)
    binit = 0.0
    mode = "fixed"
    status = "off"
    for k in dbsh_shunts
        if dict["shunt"][k]["status"] == 1
            status = "on"
            binit += dict["shunt"][k]["bs"]
            if dict["shunt"][k]["shunt_type"] == 2 && mode == "fixed"
                mode = "discrete"
            end
            if dict["shunt"][k]["shunt_type"] == 3 && mode in ["fixed","discrete"]
                mode = "continuos"
            end 
        end
    end
    for k in dcer_shunts
        status = "on"
        if dict["shunt"][k]["status"] == 1
            binit += dict["shunt"][k]["bs"]
            mode = "continuos"
        end
    end
    return mode, binit, status
end

function print_shunts(dict; len = 11)
    header = ["Bus", "Mode", "Binit", "status"]

    println(fit_results(header, len))
    
    for k in get_ordered_dict(dict["bus"])
        dcer_shunts = BrazilianPowerModels.find_keys_shunt_from_bus(dict, parse(Int, k); section = "DCER")
        dbsh_shunts = BrazilianPowerModels.find_keys_shunt_from_bus(dict, parse(Int, k); section = "DBSH")
        if !(isempty(dcer_shunts) && isempty(dbsh_shunts))
            mode, binit, status = handle_shunt(dict, dbsh_shunts, dcer_shunts)
        
            row = String[string(k), mode, string(binit), status]
            println(fit_results(row, len))
        end
    end
end

function print_results(dict; len = 11)
    header = ["BUS", "TP", "VM", "VA", "PG","QG"]
    println(fit_results(header, len))

    for k in get_ordered_dict(dict["bus"])
        va = string(round(dict["bus"][k]["va"]*180/π, digits = 2))
        vm = string(round(dict["bus"][k]["vm"], digits = 3))
        pg, qg = sum_gens(
            dict, 
            find_keys_gens_from_bus(dict, parse(Int,k))
        )
        tp = string(dict["bus"][k]["bus_type"])
        row = String[string(k), tp, vm, va, pg, qg]
        println(fit_results(row, len))
    end
end
