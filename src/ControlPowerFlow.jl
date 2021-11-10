module ControlPowerFlow

include("../parserpwf/src/ParserPWF.jl")

import JuMP
import JuMP: @variable, @constraint, @NLconstraint, @objective, @NLobjective, @expression, @NLexpression

import InfrastructureModels
const _IM = InfrastructureModels

import PowerModels; const _PM = PowerModels
import PowerModels: ids, ref, var, con, sol, nw_ids, nw_id_default, pm_component_status

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
include("control/control_data.jl")
include("control/actions.jl")
include("control/variables.jl")
include("control/constraints.jl")
include("control/slack.jl")

# including defaults control actions

# Brazilian ANAREDE control actions
include("control/anarede/qlim.jl")
include("control/anarede/vlim.jl")
include("control/anarede/ctap.jl")
include("control/anarede/ctaf.jl")
include("control/anarede/csca.jl")
include("control/anarede/cphs.jl")

#

include("form/acp.jl")
include("form/shared.jl")

include("prob/pf.jl")

include("util/visualization.jl")

end # module