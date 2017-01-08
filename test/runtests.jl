using CxxAutoWrap
using Base.Test
using Cxx
using Clang
using Clang.cindex

@testset "IntContainer" begin
    dir = Pkg.dir("CxxAutoWrap")
    folder_intcontainer = joinpath(dir, "deps", "examples", "IntContainer")
    path = joinpath(folder_intcontainer,"library.h")


    cxxinclude(path)

    libpath = joinpath(folder_intcontainer, "cmake-build-debug", "libIntContainer.so")
    Libdl.dlopen(libpath, Libdl.RTLD_GLOBAL)

    wrapexpr_header(path) |> eval

    c = IntContainer(1)
    @test getIt(c) == 1
    setIt(c, 10)
    @test getIt(c) == 10
end
