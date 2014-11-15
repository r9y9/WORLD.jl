module WORLD

# A light-weight julia wrapper for WORLD.

# Types
export World, DioOption

# World methods
export dio, dio1, stonemask, star, cheaptrick, platinum, synthesis

# Aperiodiciy analysis
export aperiodicityratio, synthesis_from_aperiodicity

# utils
export get_fftsize_for_star, get_fftsize_for_cheaptrick

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
    fs::Int64       # Sample frequency
    period::Float64 # Frame period [ms]
end

const defaultdioopt = DioOption(80.0, 640.0, 2.0, 5.0, 4)

World(;fs::Real=44100, period::Float64=5.0) = World(fs, period)

function dio(w::World, x::Vector{Float64}; opt::DioOption=defaultdioopt)
    dio(x, w.fs, opt)
end

function dio1(w::World, x::Vector{Float64})
    dio1(x, w.fs, w.period)
end

function stonemask(w::World, x::Vector{Float64},
                   timeaxis::Vector{Float64}, f0::Vector{Float64})
    stonemask(x, w.fs, timeaxis, f0)
end

function star(w::World, x::Vector{Float64},
              timeaxis::Vector{Float64}, f0::Vector{Float64})
    star(x, w.fs, timeaxis, f0)
end

function cheaptrick(w::World, x::Vector{Float64},
                    timeaxis::Vector{Float64}, f0::Vector{Float64})
    cheaptrick(x, w.fs, timeaxis, f0)
end

function platinum(w::World, x::Vector{Float64},
                  timeaxis::Vector{Float64}, f0::Vector{Float64},
                  spectrogram::Matrix{Float64})
    platinum(x, w.fs, timeaxis, f0, spectrogram)
end

function synthesis(w::World, f0::Vector{Float64},
                   spectrogram::Matrix{Float64},
                   residual::Matrix{Float64}, len::Int)
    synthesis(f0, spectrogram, residual, w.period,  w.fs, len)
end

function aperiodicityratio(w::World, x::Vector{Float64},
                           f0::Vector{Float64},timeaxis::Vector{Float64})
    aperiodicityratio(x, w.fs, f0, timeaxis)
end

function synthesis_from_aperiodicity(w::World, f0::Vector{Float64},
                                     spectrogram::Matrix{Float64},
                                     aperiodicity::Matrix{Float64}, len::Int)
    synthesis_from_aperiodicity(f0, spectrogram, aperiodicity, w.period,
                                w.fs, len)
end

end # module WORLD
