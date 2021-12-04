@testset "Verifying Generic Info Structure" begin

    file = joinpath(@__DIR__, "data/3busfrank.pwf")
    data = parse_pwf_to_powermodels(file)

    # control_info = 

end