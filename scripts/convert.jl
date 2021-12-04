using PWF, PowerModels

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
