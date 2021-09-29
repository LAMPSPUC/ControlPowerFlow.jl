module BrazilianPowerModels

include("../parserpwf/src/ParserPWF.jl")

import JuMP
import JuMP: @variable, @constraint, @NLconstraint, @objective, @NLobjective, @expression, @NLexpression

import InfrastructureModels
const _IM = InfrastructureModels

import PowerModels; const _PM = PowerModels
import PowerModels: ids, ref, var, con, sol, nw_ids, nw_id_default

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
include("core/objective.jl")
include("core/slack.jl")
include("core/variable.jl")

include("form/acp.jl")
include("form/shared.jl")

include("prob/pf.jl")

end # module