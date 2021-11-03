module BrazilianPowerModels

include("../parserpwf/src/ParserPWF.jl")

import JuMP
import JuMP: @variable, @constraint, @NLconstraint, @objective, @NLobjective, @expression, @NLexpression

import InfrastructureModels
const _IM = InfrastructureModels

import PowerModels; const _PM = PowerModels
import PowerModels: ids, ref, var, con, sol, nw_ids, nw_id_default

import ParserPWF: bus_type_num_to_str, bus_type_num_to_str, element_status

function silence()
    Memento.info(_LOGGER, "Suppressing information and warning messages for the rest of this session.  Use the Memento package for more fine-grained control of logging.")
    Memento.setlevel!(Memento.getlogger(InfrastructureModels), "error")
    Memento.setlevel!(Memento.getlogger(PowerModels), "error")
    Memento.setlevel!(Memento.getlogger(PowerModelsSecurityConstrained), "error")
end

include("core/base.jl")
include("core/constraint.jl")
include("core/constraint_template.jl")
include("core/data.jl")
include("core/expression_template.jl")
include("core/objective.jl")
include("core/variable.jl")

include("control/slack.jl")
include("control/control.jl")
include("control/control_info.jl")
include("control/control_actions.jl")
include("control/control_variables.jl")
include("control/control_constraints.jl")
include("control/slack_variables.jl")

include("form/acp.jl")
include("form/shared.jl")

include("prob/pf.jl")

include("util/visualization.jl")

end # module