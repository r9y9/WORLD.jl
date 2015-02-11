module WORLD

# A light-weight julia wrapper for WORLD.

export
    # Types
    World,
    DioOption,

    # World methods
    dio,
    dio1, # deprecated
    stonemask,
    star,
    cheaptrick,
    platinum,
    synthesis,

    # Aperiodiciy analysis
    aperiodicityratio,
    synthesis_from_aperiodicity,

    # utils
    get_fftsize_for_star,
    get_fftsize_for_cheaptrick

# Dependency
deps = joinpath(Pkg.dir("WORLD"), "deps", "deps.jl")
if isfile(deps)
    include(deps)
else
    error("WORLD not properly installed. Please run Pkg.build(\"WORLD\")")
end

include("bridge.jl")

# World is a composite type that holds common settings that are used during
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

function star(w::World, x::AbstractVector{Float64},
              timeaxis::AbstractVector{Float64}, f0::AbstractVector{Float64})
    star(x, w.fs, timeaxis, f0)
end

function cheaptrick(w::World, x::AbstractVector{Float64},
                    timeaxis::AbstractVector{Float64},
                    f0::AbstractVector{Float64})
    cheaptrick(x, w.fs, timeaxis, f0)
end

function platinum(w::World, x::AbstractVector{Float64},
                  timeaxis::AbstractVector{Float64},
                  f0::AbstractVector{Float64},
                  spectrogram::AbstractMatrix{Float64})
    platinum(x, w.fs, timeaxis, f0, spectrogram)
end

function synthesis(w::World, f0::AbstractVector{Float64},
                   spectrogram::AbstractMatrix{Float64},
                   residual::AbstractMatrix{Float64},
                   len::Integer)
    synthesis(f0, spectrogram, residual, w.period,  w.fs, len)
end

function aperiodicityratio(w::World, x::AbstractVector{Float64},
                           f0::AbstractVector{Float64},
                           timeaxis::AbstractVector{Float64})
    aperiodicityratio(x, w.fs, f0, timeaxis)
end

function synthesis_from_aperiodicity(w::World, f0::AbstractVector{Float64},
                                     spectrogram::AbstractMatrix{Float64},
                                     aperiodicity::AbstractMatrix{Float64},
                                     len::Integer)
    synthesis_from_aperiodicity(f0, spectrogram, aperiodicity, w.period,
                                w.fs, len)
end

@deprecate dio1(w::World, x::AbstractVector{Float64}) dio(w, x, opt=DioOption(80.0, 640.0, 2.0, w.period, div(w.fs, 4000.0)))

end # module WORLD
