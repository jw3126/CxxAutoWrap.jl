using CxxAutoWrap
using Base.Test
using Cxx
using Clang
using Clang.cindex

dir = Pkg.dir("CxxAutoWrap")
folder_intcontainer = joinpath(dir, "deps", "examples", "IntContainer")
addHeaderDir(folder_intcontainer)
path = joinpath(folder_intcontainer,"library.h")


cxxinclude(path)

libpath = joinpath(folder_intcontainer, "cmake-build-debug", "libIntContainer.so")
Libdl.dlopen(libpath, Libdl.RTLD_GLOBAL)

(wrapexpr_header(path)) |> eval

@testset "IntContainer" begin

    c = IntContainer(1)
    @test getIt(c) == 1
    setIt(c, 10)
    @test getIt(c) == 10
    delete(c)
end
@testset "StringContainer" begin
    s = StringContainer("asd")
    @test getIt(s) |> unsafe_string == "asd"
    setIt(s, "42")
    @test getIt(s) |> unsafe_string == "42"

end
