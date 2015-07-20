VERSION >= v"0.4.0-dev+6521" && __precompile__(@unix? true : false)

module WORLD

# A light-weight julia wrapper for WORLD.

export
    # Types
    DioOption,
    CheapTrickOption,
    D4COption,

    # WORLD functions
    dio,
    stonemask,
    cheaptrick,
    d4c,
    synthesis,

    # utils
    get_fftsize_for_cheaptrick,

    # matlab functions
    interp1!,
    interp1,

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

function __init__()
    @eval include(joinpath(dirname($(@__FILE__)), "runtime.jl"))
end

include("bridge.jl")
include("mcep.jl")
include("deprecated.jl")

end # module WORLD
