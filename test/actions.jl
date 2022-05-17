@testset "Control Actions Structure" begin
    @testset "Verifying Control Info" begin
        # handle _handle_control_info functions
        control_info = ControlPowerFlow._control_info()
        @test control_info[:controllable_bus]    == false
        @test control_info[:control_variables]   == Dict{Any, Any}()
        @test control_info[:control_constraints] == Dict{Any, Any}()
        @test control_info[:control_slacks]      == Dict{Any, Any}()

        control_info = Dict{Any, Any}(
            :controllable_bus => true
        )

        ControlPowerFlow._handle_control_info!(control_info)
        @test control_info[:controllable_bus]    == true
        @test control_info[:control_variables]   == Dict{Any, Any}()
        @test control_info[:control_constraints] == Dict{Any, Any}()
        @test control_info[:control_slacks]      == Dict{Any, Any}()

        # Correct Control Info

        control_info = Dict{Any, Any}(
            :controllable_bus => true,
            :control_variables => Dict{Any, Any}(
                1 => Dict{Any, Any}(
                    "name" => "generic_name",
                    "variable" => "generic_name",
                    "indexes" => collect(1:10),
                    "element" => :bus,
                    "start" => [0.0 for i in 1:10]
                )
            ),
            :control_constraints => Dict{Any, Any}(
                1 => Dict{Any, Any}(
                    "name" => "generic_name",
                    "element" => :bus,
                    "indexes" => [1, 2],
                )
            ),
            :control_slacks => Dict{Any, Any}(
                1 => Dict{Any, Any}(
                    "name" => "generic_name",
                    "variable" => "generic_name",
                    "weight" => 1.0,
                    "element" => :bus,
                    "indexes" => [1, 2],
                    "type" => :equalto
                )
            )
        )

        @test true == ControlPowerFlow._handle_control_info!(control_info)

        # Incorrect control_info

        control_info = Dict{Any, Any}(
            :controllable_bus => true,
            :control_variables => Dict{Any, Any}(
                1 => Dict{Any, Any}(
                    "name" => "generic_name",
                    "indexes" => collect(1:10),
                    "element" => "bus",
                    "start" => "0.0"
                )
            ),
            :control_constraints => Dict{Any, Any}(
                1 => Dict{Any, Any}(
                    "name" => "generic_name",
                    "element" => "bus",
                    "indexes" => ["1", "2"],
                )
            ),
            :control_slacks => Dict{Any, Any}(
                1 => Dict{Any, Any}(
                    "name" => "generic_name",
                    "variable" => "generic_name",
                    "weight" => 1.0,
                    "element" => "bus",
                    "indexes" => ["1", "2"],
                    "type" => :equalto
                )
            )
        )

        @test_throws(ErrorException, ControlPowerFlow._handle_control_info!(control_info))

        @test             nothing == ControlPowerFlow._verify_key!(control_info, :control_variables, 1, "name", String)
        @test             nothing == ControlPowerFlow._verify_key!(control_info, :control_variables, 1, "indexes", Vector{Int})
        @test_throws(ErrorException, ControlPowerFlow._verify_key!(control_info, :control_variables, 1, "variable", String))
        @test_throws(ErrorException, ControlPowerFlow._verify_key!(control_info, :control_variables, 1, "element", Symbol))
        @test_throws(ErrorException, ControlPowerFlow._verify_key!(control_info, :control_variables, 1, "start", Number))

        @test             nothing == ControlPowerFlow._verify_key!(control_info, :control_constraints, 1, "name", String)
        @test_throws(ErrorException, ControlPowerFlow._verify_key!(control_info, :control_constraints, 1, "element", Symbol))
        @test_throws(ErrorException, ControlPowerFlow._verify_key!(control_info, :control_constraints, 1, "indexes", Vector{Int}))

        @test             nothing == ControlPowerFlow._verify_key!(control_info, :control_slacks, 1, "name", String)
        @test             nothing == ControlPowerFlow._verify_key!(control_info, :control_slacks, 1, "variable", String)
        @test             nothing == ControlPowerFlow._verify_key!(control_info, :control_slacks, 1, "weight", Number)
        @test             nothing == ControlPowerFlow._verify_key!(control_info, :control_slacks, 1, "type", Symbol)
        @test_throws(ErrorException, ControlPowerFlow._verify_key!(control_info, :control_slacks, 1, "element", Symbol))
        @test_throws(ErrorException, ControlPowerFlow._verify_key!(control_info, :control_slacks, 1, "indexes", Vector{Int}))
     
    end

    @testset "Verifying Generic Info Structure" begin

        # Correct generic_info example
        generic_info =  Dict{Any, Any}(
            :control_variables => Dict{Any, Any}(
                1 => Dict(
                    "name"     => "shunt",
                    "variable" => "bs",
                    "element"  => :shunt,
                    "start"    => 0.0, # if this is NaN, the code automatic gets the start values from the data (data -> element -> variable)
                    "filters" => [
                        (shunt, nw_ref) -> _control_data(shunt)["shunt_type"] == 2 # variable shunt
                    ],
                )
            ),
            :control_constraints => Dict(
                1 => Dict(
                    "name" => "constraint_voltage_magnitude_bounds",
                    "element" => :bus,
                    "filters" => [
                        (bus, nw_ref) -> bus["bus_type"] == 1 # PQ buses
                    ]
                )
            ),
            :control_slacks => Dict(
                1 => Dict(
                    "name" => "constraint_voltage_magnitude_bounds",
                    "element" => :bus,
                    "variable" => "con_vol_mag_bou",
                    "filters" => [
                        (bus, nw_ref) -> bus["bus_type"] == 1 # PQ buses
                    ],
                    "type" => :bound,
                )
            )
        )
        
        @test ControlPowerFlow._handle_generic_info!(generic_info)

        # Incorrect generic_info example
        generic_info =  Dict{Any, Any}(
            :control_variables => Dict{Any, Any}(
                1 => Dict(
                    "name"     => :shunt,
                    "variable" => "bs",
                    "element"  => :shunt,
                    "start"    => 0.0,
                    "filters" => [
                        (shunt) -> _control_data(shunt)["shunt_type"] == 2 # variable shunt
                    ],
                )
            ),
            :control_constraints => Dict(
                1 => Dict(
                    "name" => "constraint_voltage_magnitude_bounds",
                    "element" => "bus",
                    "filters" => [
                        (bus, nw_ref) -> bus["bus_type"] == 1 # PQ buses
                    ]
                )
            ),
            :control_slacks => Dict(
                1 => Dict(
                    "name" => "constraint_voltage_magnitude_bounds",
                    "element" => :bus,
                    "variable" => "con_vol_mag_bou",
                    "filters" => [
                        (nw_ref) -> bus["bus_type"] == 1 # PQ buses
                    ],
                    "type" => "bound",
                )
            )
        )

        @test_throws(ErrorException,ControlPowerFlow._handle_generic_info!(generic_info))

        @test_throws(ErrorException,ControlPowerFlow._verify_key!(generic_info, :control_variables, 1, "name", String))
        @test_throws(ErrorException,ControlPowerFlow._verify_filters!(generic_info, :control_variables, 1))
    
        @test_throws(ErrorException,ControlPowerFlow._verify_key!(generic_info, :control_constraints, 1, "element", Symbol))
    
        @test_throws(ErrorException,ControlPowerFlow._verify_key!(generic_info, :control_slacks, 1, "type", Symbol))
        @test_throws(ErrorException,ControlPowerFlow._verify_filters!(generic_info, :control_slacks, 1))

        # Slack Variables Generic Info
        generic_info =  Dict{Any, Any}(
            :control_variables => Dict{Any, Any}(
            ),
            :control_constraints => Dict(
            ),
            :control_slacks => Dict(
                1 => Dict(
                    "name" => "constraint_voltage_magnitude_setpoint",
                    "element" => :bus,
                    "variable" => "con_vol_mag_set",
                    "filters" => [
                        (bus, nw_ref) -> bus["bus_type"] in [2, 3] # PV, Vθ buses
                    ],
                    "type" => :equalto,
                ),
                2 => Dict(
                    "name" => "constraint_power_balance_active",
                    "element" => :bus,
                    "variable" => "con_pow_bal_act",
                    "filters" => [
                    ],
                    "type" => :equalto,
                ),
                3 => Dict(
                    "name" => "constraint_power_balance_reactive",
                    "element" => :bus,
                    "variable" => "con_pow_bal_rea",
                    "filters" => [
                    ],
                    "type" => :equalto,
                ),
                4 => Dict(
                    "name" => "constraint_gen_setpoint_active",
                    "element" => :gen,
                    "variable" => "con_gen_set_act",
                    "filters" => [
                        (gen, nw_ref) -> gen["gen_status"] == 1
                    ],
                    "type" => :equalto,
                )
            )
        )

        @test  ControlPowerFlow._handle_generic_info!(generic_info)
    end

end