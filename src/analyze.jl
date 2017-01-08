
function analyze(c::Constructor)
    arg_list = get_args(c)

    args = Any[]
    for arg in arg_list
        proxy = get_proxy(spelling(cu_type(arg)))
        (proxy == Union{}) ? push!(args, arg) : push!(args, proxy)
    end
    return WrappedConstructor(spelling(c),
                         c,
                         cindex.getCursorLexicalParent(c),
                         args)
end
analyze(d::Destructor) = WrappedDestructor(d, cindex.getCursorLexicalParent(d))
analyze(m::CXXMethod) = analyze_method(m)

function analyze(c::ClassDecl)

    constructors = WrappedConstructor[]
    destructors = WrappedDestructor[]
    methods = WrappedMethod[]
    for node in children(c)
        if isa(node, CXXMethod)
            push!(methods, analyze(node))
        elseif isa(node, Constructor)
            push!(constructors, analyze(node))
        elseif isa(node, Destructor)
            push!(destructors, analyze(node))
        end
    end

    if length(destructors) == 0
        destructor = Nullable{WrappedDestructor}()
    elseif length(destructors) == 1
        destructor = Nullable{WrappedDestructor}(first(destructors))
    else
        error("Multiple destructors $destructors in $c")
    end

    WrappedClass(
    spelling(c),
    constructors,
    destructor,
    methods,
    c
    )
end