# using Packages
using PowerModels, Ipopt, JuMP
using PWF

# Include ControlPowerFlow module
include("../src/ControlPowerFlow.jl")
ipopt = optimizer_with_attributes(Ipopt.Optimizer, "tol"=>0.001, "max_iter"=>100) 
# PWF system file
EMS_bpf = "scripts\\data\\pwf\\EMS\\EMS_base_fora_ponta.PWF"
EMS_bpf = "scripts\\data\\pwf\\EMS\\EMS_base_fora_ponta.PWF"

# Reading PWF and converting to PowerModels network data dictionary
data = PWF.parse_file(file, pm = true)
network = deepcopy(data)

set_ac_pf_start_values!(network)
pm = instantiate_model(network, ACPPowerModel, PowerModels.build_pf)
set_optimizer(pm.model, ipopt)
result = optimize_model!(pm)

print(m)

result["solution"]["shunt"]

pwf_dir = "./scripts/data/pwf"
matpower_dir = "./scripts/data/matpower"
function convert_pwf_files(pwf_dir, matpower_dir)
    for dir in readdir(pwf_dir)
        new_dir = joinpath(pwf_dir, dir)
        for file in readdir(new_dir)
            pwf_file = joinpath(pwf_dir, dir, file)
            data = PWF.parse_file(pwf_file, pm = true)
            matpower_file = split(lowercase(file), ".pwf")[1]
            matpower_file *= ".m"
            matpower_file = joinpath(matpower_dir, dir, matpower_file)
            PowerModels.export_matpower(matpower_file, data)
        end
    end
end

convert_pwf_files(pwf_dir, matpower_dir)

