export eicxx, efunction

eexport(s) = Expr(:export, unique(s)...)

function efunction(name, args, body)
    Expr(:function, Expr(:call, name, args...), body)
end
eequals(x,y) = Expr(Symbol("="), x, y)
function ecxxnew(constructor::Symbol, args)
    Expr(:macrocall, Symbol("@cxxnew"), Expr(:call, constructor, args...))
end

eicxx(s::String) = Expr(:macrocall, Symbol("@icxx_str"), s)
etyped(obj, T) = Expr(Symbol("::"), obj, T)
function ecxxtype(name)
    # expression for something like
    # Cxx.CppPtr{Cxx.CppValue{Cxx.CxxQualType{Cxx.CppBaseType{name},(false,false,false)},N},(false,false,false)}
    Expr(:curly, :(Cxx.CppPtr),
        Expr(:macrocall, Symbol("@vcpp_str"), name),
        (false, false, false)
    )
end

function emethodcall(obj, method, args)
    callargs = join(("\$($arg)" for arg in args), ", ")
    s = "\$($obj) -> $method($callargs);"
    eicxx(s)
end
