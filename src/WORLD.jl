VERSION >= v"0.4.0-dev+6521" && __precompile__()

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

# Binary dependency loading
# NOTE: I think this is ok to run in precompile time, since Julia is
# automatically recompiling the cache file if any change to deps.jl is detected.
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
