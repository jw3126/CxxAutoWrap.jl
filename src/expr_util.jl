export eicxx, efunction


function efunction(name, args, body)
    Expr(:function, Expr(:call, name, args...), body)
end
