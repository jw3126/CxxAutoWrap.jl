__precompile__(true)
module CxxAutoWrap

# package code goes here

include("expr_util.jl")
include("types.jl")
include("cxx.jl")
include("globalize.jl")
include("analyze.jl")

end # module
