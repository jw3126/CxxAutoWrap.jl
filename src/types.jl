export WrappedMethod, WrappedConstructor, WrappedClass, WrappedDestructor,
analyze

using QuickTypes
using Clang
using Clang.wrap_cpp
using Clang.cindex
import Clang.wrap_cpp: WrappedMethod, analyze_method, get_args, get_proxy

immutable WrappedConstructor
    name::String
    constructor::Constructor
    parent::ClassDecl
    args::Array{Any,1}
end

immutable WrappedDestructor
    destructor::Destructor
    parent::ClassDecl
end

immutable WrappedClass
    name::String
    constructors::Vector{WrappedConstructor}
    destructor::Nullable{WrappedDestructor}
    methods::Vector{WrappedMethod}
    class::ClassDecl
end
import Clang.cindex: name, spelling
name(x) = x.name

raw(x::WrappedClass) = x.class
raw(x::WrappedDestructor) = x.destructor
raw(x::WrappedMethod) = x.method
raw(x::WrappedConstructor) = x.constructor
spelling(x) = x |> raw |> spelling


identity_str(s::String) = s # for debug we use this instead of identity
function jlext(path)
    stem, ext = splitext(path)
    stem + ".jl"
end

"""
    Renamer(;kw...)

Captures renaming schemes for methods, files, ... for the translation C++ -> Julia.
"""
@qimmutable Renamer(;
    header=jlext,
    method=identity_str,
    class=identity_str,
    destructor=identity_str,
    )

immutable WrapperConfig
    rename::Renamer
    #header_paths::Vector{String} # paths to headers that should be wrapped

end
WrapperConfig() = WrapperConfig(Renamer())

type WrapperState
    # method list
    # operator list for Base import
    # exports
    # single vs multifile
end
