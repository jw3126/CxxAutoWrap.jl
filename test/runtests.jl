using CxxAutoWrap
using Base.Test
using Cxx
using Clang
using Clang.cindex


dir = Pkg.dir("CxxAutoWrap")
folder_intcontainer = joinpath(dir, "deps", "examples", "IntContainer")
path = joinpath(folder_intcontainer,"library.h")

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

cxxinclude(path)

libpath = joinpath(folder_intcontainer, "cmake-build-debug", "libIntContainer.so")
Libdl.dlopen(libpath, Libdl.RTLD_GLOBAL)

wrapexpr_header(path) |> eval

c = IntContainer(1)
@test getIt(c) == 1
setIt(c, 10)
@test getIt(c) == 10
