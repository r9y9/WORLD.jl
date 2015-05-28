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

# World is a composite type that holds common settings that can be used during
# analysis
immutable World
    fs::Int         # Sample frequency
    period::Float64 # Frame period [ms]
end

# will be deprecated
World(;fs::Real=44100, period::Float64=5.0) = World(fs, period)

function dio(w::World, x::AbstractVector{Float64}; opt::DioOption=DioOption())
    w.period == opt.period ||
        throw(ArgmentError("Inconsistent frame period: $(w.period) != $(opt.period)"))
    dio(x, w.fs, opt)
end

function stonemask(w::World, x::AbstractVector{Float64},
                   timeaxis::AbstractVector{Float64},
                   f0::AbstractVector{Float64})
    stonemask(x, w.fs, timeaxis, f0)
end

function cheaptrick(w::World, x::AbstractVector{Float64},
                    timeaxis::AbstractVector{Float64},
                    f0::AbstractVector{Float64})
    cheaptrick(x, w.fs, timeaxis, f0)
end

function d4c(w::World, x::AbstractVector{Float64},
             timeaxis::AbstractVector{Float64},
             f0::AbstractVector{Float64})
    d4c(x, w.fs, timeaxis, f0)
end

function synthesis(w::World, f0::AbstractVector{Float64},
                   spectrogram::AbstractMatrix{Float64},
                   residual::AbstractMatrix{Float64},
                   len::Integer)
    synthesis(f0, spectrogram, residual, w.period,  w.fs, len)
end

end # module WORLD
