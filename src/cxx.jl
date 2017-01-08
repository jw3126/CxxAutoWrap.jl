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
    classnodes = filter(topcu |> children |> collect) do node
        isa(node, ClassDecl) && (basename(cu_file(node)) == basename(path))
    end
    ret = quote end
    for node in classnodes
        append!(ret.args, wrapexpr(analyze(node)).args)
    end
    ret
end

function wrapexpr(c::WrappedClass, wc::WrapperConfig=WrapperConfig())
    cxxspell = cxxspelling(c)
    jlspell = jlspelling(c, wc)
    jlspell_destroy = jlspelling(Val{:Destructor} , wc)
    blk = quote end
    append!(blk.args, eclass2type(cxxspell, jlspell, jlspell_destroy).args)
    append!(blk.args, map(wrapexpr, c.constructors))
    append!(blk.args, map(wrapexpr, c.methods))
    blk
end

function wrapexpr(c::WrappedConstructor, wc::WrapperConfig=WrapperConfig())
    args = argspellings(c)
    sconstructor = c |> spelling |> Symbol
    cxxspell = cxxspelling(c)
    jlspell = jlspelling(c, wc)

    body = quote
        ptr = $(ecxxnew(Symbol(cxxspell), args))
        $(Symbol(cxxspell))(ptr)
    end
    efunction(Symbol(jlspell), args, body)
end


function ecxxnew(constructor::Symbol, args)
    Expr(:macrocall, Symbol("@cxxnew"), Expr(:call, constructor, args...))
end


function emethodcall(obj, method, args)
    callargs = join(("\$($arg)" for arg in args), ", ")
    s = "\$($obj) -> $method($callargs);"
    Expr(:macrocall, Symbol("@icxx_str"), s)
end

isoperator(s::String) = startswith(s, "operator")
isoperator(m::CXXMethod) = m |> spelling |> isoperator
jlspelling_operator(s::String) = s[9:end] |> Symbol


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

function wrapexpr(m::WrappedMethod, wc::WrapperConfig=WrapperConfig())
    sm_args = argspellings(m)
    cxxspell = cxxspelling(m)
    jlspell = jlspelling(m, wc)
    sobj = :obj
    eobj_typed = Expr(Symbol("::"), sobj, jlspelling(m.parent, wc))
    body = emethodcall(:(jl2cxx($sobj)), cxxspell, sm_args)
    efunction(jlspell, [eobj_typed; sm_args], body)
end

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

function epreamble()
    quote
        using Cxx
        import Base: ==, !=  # for operator overloading

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
    end
end

function ecxxtype(name)
    # expression for something like
    # Cxx.CppPtr{Cxx.CppValue{Cxx.CxxQualType{Cxx.CppBaseType{name},(false,false,false)},N},(false,false,false)}
    Expr(:curly, :(Cxx.CppPtr),
        Expr(:macrocall, Symbol("@vcpp_str"), name),
        (false, false, false)
    )
end

function edestroy(jlspell_class, jlspell_destroy)
    obj = "obj"
    body = Expr(:macrocall, Symbol("@icxx_str"), "delete \$($obj.pointer);")
    obj_typed = Expr(Symbol("::"), Symbol(obj), jlspell_class)
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
