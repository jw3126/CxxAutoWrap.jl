export wrapexpr,
argspellings,
eclass2type


function wrapexpr(c::WrappedClass)
    blk = quote end
    append!(blk.args, eclass2type(spelling(c)).args)
    append!(blk.args, map(wrapexpr, c.constructors))
    append!(blk.args, map(wrapexpr, c.methods))
    blk
end

function wrapexpr(c::WrappedConstructor)
    args = argspellings(c)
    sconstructor = c |> spelling |> Symbol
    body = quote
        ptr = $(ecxxnew(sconstructor, args))
        $sconstructor(ptr)
    end
    efunction(sconstructor, args, body)
end

function wrapexpr(d::WrappedDestructor)
    # TODO
    :nothing
end

function ecxxnew(constructor::Symbol, args)
    Expr(:macrocall, Symbol("@cxxnew"), Expr(:call, constructor, args...))
end


function eicxx(obj, method, args)
    callargs = join(("\$$arg" for arg in args), ", ")
    s = "\$$obj -> \$$method($callargs)"
    Expr(:macrocall, Symbol("@icxx_str"), s)
end

isoperator(s::String) = startswith(s, "operator")
isoperator(m::WrappedMethod) = m |> spelling |> isoperator
jlspelling_operator(s::String) = s[9:end]

function jlspelling_method(s::String)
    if isoperator(s)
        # should also import from Base for overloading!
        s |> jlspelling_operator
    else
        s
    end
end

function jlspelling_class(s::String)
    s
end

jlspelling(x) = x |> raw |> jlspelling
jlspelling(x::CXXMethod) = x |> spelling |> jlspelling_method
jlspelling(x::ClassDecl) = x |> spelling |> jlspelling_class
jlspelling(x::Destructor) = "destroy"
jlspelling(x::WrappedConstructor) = jlspelling(x.parent)

function wrapexpr(m::WrappedMethod)
    sm_args = argspellings(m)
    sm = m |> spelling |> Symbol
    smjl = m |> jlspelling |> Symbol
    sobj = :obj
    eobj_typed = Expr(Symbol("::"), sobj, jlspelling(m.parent))
    body = eicxx(sobj, sm, sm_args)
    efunction(smjl, [eobj_typed; sm_args], body)
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

epcpp(spelling::String) = Expr(:macrocall, Symbol("pcpp_str"), spelling)

function eclass2type(classspelling::String)
    sT = Symbol(classspelling)
    sPtrT = Symbol("Ptr", classspelling)
    quote
        typealias $sPtrT $(epcpp(classspelling))
        immutable $sT
            pointer::$sPtrT
        end
        function wrap(ptr::$sPtrT)
            $sT(ptr)
        end
        function unwrap(obj::$sT)
            obj.pointer
        end
    end
end
