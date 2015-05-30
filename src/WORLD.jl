module WORLD

# A light-weight julia wrapper for WORLD.

export
    # Types
    World,
    DioOption,

    # World methods
    dio,
    stonemask,
    cheaptrick,
    d4c,
    synthesis,

    # utils
    get_fftsize_for_cheaptrick,

    # conversion
    sp2mc,  # spectrum envelope to mel-cesptrum
    mc2sp   # mel-cepstrum to spectrum envelope

# Dependency
deps = joinpath(Pkg.dir("WORLD"), "deps", "deps.jl")
if isfile(deps)
    include(deps)
else
    error("WORLD not properly installed. Please run Pkg.build(\"WORLD\")")
end

include("bridge.jl")
include("mcep.jl")

end # module WORLD
