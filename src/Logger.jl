#
# a simple event logger
#

mutable struct Logger <: SEngine
    sim::Union{Clock,Number}
    state::SState
    last::Array{Tuple}
    ltype::UInt64
    lvars::Array{Symbol,1}
    df::DataFrame

    Logger() = new(0, Undefined(), Tuple[], 0, Symbol[], DataFrame())
end

function step!(A::Logger, ::Undefined, σ::Init)
    A.sim = σ.info
    A.state = Empty()
end

function step!(A::Logger, ::Empty, σ::Setup)
    A.lvars = σ.vars
    A.df.time = Float64[]
    for v ∈ A.lvars
        A.df[!, v] = typeof(Core.eval(Main, v))[]
    end
    A.state = Idle()
end

function step!(A::Logger, ::Idle, ::Clear)
    A.last = Tuple[];
    deleterows!(A.df, 1:size(A.df,1))
end

"Logging event"
function step!(A::Logger, ::Idle, σ::Log)
    A.last = [(repr(v)[2:end], Core.eval(Main, v)) for v ∈ A.lvars]
    pushfirst!(A.last, ("time", now(A.sim)))
    if A.ltype == 1
        for i in A.last
            print(i[1], ": ", i[2], "; ")
        end
        println()
    elseif A.ltype == 2
        push!(A.df, [i[2] for i in A.last])
    end
end

"Switch type of logging 0: none, 1: print, 2: store in log table"
function step!(A::Logger, ::Idle, σ::Switch)
    if σ.to ∈ 0:2
        A.ltype = σ.to
    end
end

"Switch type of logging 0: none, 1: print, 2: store in log table."
switch!(L::Logger, to::Int64=0) = step!(L, L.state, Switch(to))

"Initialize a Logger"
init!(L::Logger, sim::Clock) = step!(L, L.state, Init(sim))

"""
    setup!(L::Logger, vars::Array{Symbol})

Setup a logger with logging variables.

# Arguments
- `L::Logger`
- `vars::Array{Symbol}`: An array of symbols, e.g. of global variables
"""
setup!(L::Logger, vars::Array{Symbol}) = step!(L, L.state, Setup(vars))

record!(L::Logger) = step!(L, L.state, Log())

clear!(L::Logger) = step!(L, L.state, Clear())