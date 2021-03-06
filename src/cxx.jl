export wrapexpr,
argspellings,
eclass2type,
wrapexpr_header,
epreamble


"""
    wrapexpr_header(path; kw...)

Wraps C++ header at path.
"""
function wrapexpr_header(path; kw...)
    topcu = cindex.parse_header(path, cplusplus=true; kw...)
    ret = topcu |> analyze |> wrapexpr
    ret
end


function wrapexpr(c::WrappedClass, wc::WrapperConfig=WrapperConfig())
    cxxspell = cxxspelling(c)
    jlspell = jlspelling(c, wc)
    jlspell_destroy = jlspelling(Val{:Destructor} , wc)
    blk = quote end
    append!(blk.args, eclass2type(cxxspell, jlspell, jlspell_destroy).args)
    append!(blk.args, map(x -> wrapexpr(x, wc), c.constructors))
    append!(blk.args, map(x -> wrapexpr(x, wc), c.methods))
    blk
end

function wrapexpr(c::WrappedConstructor, wc::WrapperConfig=WrapperConfig())
    args = argspellings(c)
    cxxargs = argspellings_jl2cxx(c)
    sconstructor = c |> spelling |> Symbol
    cxxspell = cxxspelling(c)
    jlspell = jlspelling(c, wc)
    body = Expr(:block,
        eequals(:ptr, ecxxnew(cxxspell, cxxargs)),
        Expr(:call, cxxspell, :ptr)
    )
    efunction(jlspell, args, body)
end



isoperator(s::String) = startswith(s, "operator")
isoperator(m::CXXMethod) = m |> spelling |> isoperator
isoperator(m::WrappedMethod) = m |> raw |> isoperator
jlspelling_operator(x::CXXMethod) = x |> spelling |> jlspelling_operator
jlspelling_operator(x::String) = x[9:end] |> Symbol


cxxspelling(x) = Symbol(spelling(x))
jlspelling(x, wc::WrapperConfig) = jlspelling(raw(x), wc)
function jlspelling(x::CXXMethod, wc::WrapperConfig)
    if isoperator(x)
        # should also import from Base for overloading!
        x |> jlspelling_operator
    else
        x |> spelling |> wc.rename.method |> Symbol
    end
end
function jlspelling(x::ClassDecl, wc::WrapperConfig)
    x |> spelling |> wc.rename.class |> Symbol
end
jlspelling(x::WrappedConstructor, wc::WrapperConfig) = jlspelling(x.parent, wc)
jlspelling(x::Type{Val{:Destructor}}, wc::WrapperConfig) = wc.rename.destructor |> Symbol

function wrapexpr(x::WrappedMethod, wc::WrapperConfig)
    if isoperator(x)
        # wrapexpr_operator2(x, wc)
        println("not wrapping operator $x")
        :()
    else
        wrapexpr_method(x, wc)
    end
end

function wrapexpr_method(m::WrappedMethod, wc::WrapperConfig=WrapperConfig())
    jlspell = jlspelling(m, wc)
    jlargs = argspellings(m)
    cxxspell = cxxspelling(m)
    cxxargs = argspellings_jl2cxx(m)
    obj = :obj
    T = jlspelling(m.parent, wc)
    objT = etyped(obj, T)
    body = quote
        ret = $(emethodcall(:(jl2cxx($obj)), cxxspell, cxxargs))
        cxx2jl(ret)
    end
    efunction(jlspell, [objT; jlargs], body)
end

function methodsymbols(x::WrappedClass, wc::WrapperConfig=WrapperConfig())
    Symbol[jlspelling(m, wc) for m in x.methods]
end
function exportsymbols(x::WrappedClass, wc::WrapperConfig)
    [jlspelling(x, wc), methodsymbols(x, wc)...]
end
function exportsymbols(x::WrappedHeader, wc::WrapperConfig)
    mapreduce(node -> exportsymbols(node, wc), vcat, [], x.classnodes)
end

function wrapexpr(x::WrappedHeader, wc::WrapperConfig=WrapperConfig())
    content = mapreduce(node -> wrapexpr(node, wc).args, vcat, [], x.classnodes)

    Expr(:block,
    eexport(exportsymbols(x, wc)),
    epreamble().args..., # TODO this should not be reproduced for every header, but only once per project
    content...
    )
end

# binary operator
# function wrapexpr_operator2(m::WrappedMethod, wc::WrapperConfig)
#     op = jlspelling(m, wc)
#     body = Expr(:block,
#         eequals(:ocxx1, :(jl2cxx(obj1))),
#         eequals(:ocxx2, :(jl2cxx(obj2))),
#         eicxx( "&(\$ocxx1) $op &(\$ocxx2);" )
#     )
#     f = Expr(Symbol("."), :Base, QuoteNode(op))
#     T = jlspelling(m.parent, wc)
#     args = (etyped(:obj1, T), etyped(:obj2, T))
#     efunction(f, args, body)
# end


argspellings(m::WrappedMethod) = argspellings(m.args)
argspellings(m::WrappedConstructor) = argspellings(m.args)
function argspellings(args::Vector)
    ret = Symbol[]
    for (i, arg) in enumerate(args)
        nm = arg |> spelling
        if nm == ""
            arg_i = Symbol("arg_$i")
        else
            arg_i = Symbol(nm)
        end
        push!(ret, arg_i)
    end
    ret
end
function argspellings_jl2cxx(m)
    args = argspellings(m)
    [:(jl2cxx($arg)) for arg in args]
end


function epreamble()
    quote
        using Cxx

        """
            jl2cxx(x)

        Convert julia object to cxx object. This method is called on each argument before doing a
        C++ method call.
        """
        jl2cxx(x) = x
        jl2cxx(s::AbstractString) = pointer(String(s))

        """
            cxx2jl(x)

        Convert C++ object to julia object. This method is called after each C++ method call.
        """
        cxx2jl(x) = x
        # cxx2jl(p::Ptr{UInt8}) = unsafe_string(p)?

    end
end



function edestroy(jlspell_class, jlspell_destroy)
    obj = "obj"
    body = eicxx("delete \$($obj.pointer);")
    obj_typed = etyped(Symbol(obj), jlspell_class)
    efunction(jlspell_destroy, (obj_typed,), body)
end


function eclass2type(cxxspell, jlspell, jlspell_destroy)
    sT = jlspell
    sPtrT = Symbol("Ptr", jlspell)
    blk = quote
        typealias $sPtrT $(ecxxtype(cxxspell))
        immutable $sT
            pointer::$sPtrT
            $sT(p::$sPtrT) = new(p)
        end
        function cxx2jl(ptr::$sPtrT)
            $sT(ptr)
        end
        function jl2cxx(obj::$sT)
            obj.pointer
        end
    end
    push!(blk.args, edestroy(jlspell, jlspell_destroy))
    blk
end
