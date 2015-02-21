@assert isdefined(:libworld)

# DioOption represents a set of options that is used in DIO,
# a fundamental frequency analysis.
immutable DioOption
    f0floor::Float64
    f0ceil::Float64
    channels_in_octave::Float64
    period::Float64 # ms
    speed::Int

    function DioOption(f0floor, f0ceil, channels_in_octave, period, speed)
        f0floor > f0ceil && throw(ArgumentError("F0floor must be larger than F0ceil"))
        f0floor < 0 && throw(ArgumentError("f0floor must be positive"))
        if channels_in_octave < 0
            throw(ArgumentError("channels_in_octave must be positive"))
        end
        period <= 0 && throw(ArgumentError("period must be positive"))
        (1 <= speed <= 12) || throw(ArgumentError("1 ≤ speed ≤ 12 is supprted"))
        new(convert(Float64, f0floor),
            convert(Float64, f0ceil),
            convert(Float64, channels_in_octave),
            convert(Float64, period),
            convert(Int, speed))
    end
end

# Note that the default options assume that the sampling frequency of a input
# speech signal is 44.1 kHz.
function DioOption(;
                   f0floor::Float64=80.0,
                   f0ceil::Float64=640.0,
                   channels_in_octave::Float64=2.0,
                   period::Float64=5.0,
                   speed::Integer=11
    )
    DioOption(f0floor, f0ceil, channels_in_octave, period, speed)
end

function get_samples_for_dio(fs::Real, len::Integer, period::Real)
    ccall((:GetSamplesForDIO, libworld), Int,
          (Int, Int, Float64), fs, len, period)
end

function dio(x::AbstractVector{Float64}, fs::Real, opt::DioOption)
    expectedlen = get_samples_for_dio(fs, length(x), opt.period)
    f0 = Array(Float64, expectedlen)
    timeaxis = Array(Float64, expectedlen)
    # Note that value passinig of julia-type to C-struct doesn't work.
    ccall((:DioByOptPtr, libworld),  Void,
          (Ptr{Float64}, Int64, Int64, Ptr{DioOption}, Ptr{Float64}, Ptr{Float64}),
          x, length(x), fs, &opt, timeaxis, f0)
    f0, timeaxis
end

function get_fftsize_for_star(fs::Integer)
    ccall((:GetFFTSizeForStar, libworld), Int, (Int,), fs)
end

function stonemask(x::AbstractVector{Float64}, fs::Integer,
                   timeaxis::AbstractVector{Float64},
                   f0::AbstractVector{Float64})
    refinedF0 = Array(Float64, length(f0))
    ccall((:StoneMask, libworld),  Void,
          (Ptr{Float64}, Int64, Int64, Ptr{Float64}, Ptr{Float64}, Int,
           Ptr{Float64}),
          x, length(x), fs, timeaxis, f0, length(f0), refinedF0)
    refinedF0
end

function get_fftsize_for_star(fs::Integer)
    ccall((:GetFFTSizeForStar, libworld), Int, (Int,), fs)
end

# Array{T,2} -> Array{Ptr{T}}
function ptrarray2d!{T<:Real}(dst::Array{Ptr{T},1}, src::Array{T,2})
    for i=1:size(src, 2)
        @inbounds dst[i] = pointer(sub(src, 1:size(src, 1), i), 1)
    end
end

function star(x::AbstractVector{Float64}, fs::Integer,
              timeaxis::AbstractVector{Float64},
              f0::AbstractVector{Float64})
    freqbins = get_fftsize_for_star(fs)>>1 + 1
    spectrogram = Array(Float64, freqbins, length(f0))

    # Array{Float64,2} -> Array{Ptr{Float64}}
    cspectrogram = Array(Ptr{Float64}, size(spectrogram, 2))
    ptrarray2d!(cspectrogram, spectrogram)

    ccall((:Star, libworld), Void,
          (Ptr{Float64}, Int64, Int64, Ptr{Float64}, Ptr{Float64}, Int64,
           Ptr{Ptr{Float64}}),
          x, length(x), fs, timeaxis, f0, length(f0), cspectrogram)

    # Array{Float64,2} <- Array{Ptr{Float64}}
    for i=1:length(f0), j=1:freqbins
        @inbounds spectrogram[j,i] = unsafe_load(cspectrogram[i], j)
    end

    spectrogram
end

function get_fftsize_for_cheaptrick(fs::Integer)
    ccall((:GetFFTSizeForCheapTrick, libworld), Int, (Int,), fs)
end

function cheaptrick(x::AbstractVector{Float64}, fs::Integer,
                    timeaxis::AbstractVector{Float64},
                    f0::AbstractVector{Float64})
    freqbins = get_fftsize_for_cheaptrick(fs)>>1 + 1
    spectrogram = Array(Float64, freqbins, length(f0))

    # Array{Float64,2} -> Array{Ptr{Float64}}
    cspectrogram = Array(Ptr{Float64}, size(spectrogram, 2))
    ptrarray2d!(cspectrogram, spectrogram)

    ccall((:CheapTrick, libworld), Void,
          (Ptr{Float64}, Int64, Int64, Ptr{Float64}, Ptr{Float64}, Int64,
           Ptr{Ptr{Float64}}),
          x, length(x), fs, timeaxis, f0, length(f0), cspectrogram)

    # Array{Float64,2} <- Array{Ptr{Float64}}
    for i=1:length(f0), j=1:freqbins
        @inbounds spectrogram[j,i] = unsafe_load(cspectrogram[i], j)
    end

    spectrogram
end

function platinum(x::AbstractVector{Float64}, fs::Integer,
                  timeaxis::AbstractVector{Float64},
                  f0::AbstractVector{Float64},
                  spectrogram::AbstractMatrix{Float64})
    fftsize = get_fftsize_for_cheaptrick(fs)
    freqbins = fftsize +1
    residual = zeros(Float64, freqbins, length(f0))

    # Array{Float64,2} -> Array{Ptr{Float64}}
    cspectrogram = Array(Ptr{Float64}, size(spectrogram, 2))
    ptrarray2d!(cspectrogram, spectrogram)

    cresidual = Array(Ptr{Float64}, size(residual, 2))
    ptrarray2d!(cresidual, residual)

    ccall((:Platinum, libworld), Void,
          (Ptr{Float64}, Int64, Int64, Ptr{Float64}, Ptr{Float64}, Int64,
           Ptr{Ptr{Float64}}, Int64, Ptr{Ptr{Float64}}),
          x, length(x), fs, timeaxis, f0, length(f0), cspectrogram, fftsize,
          cresidual)

    # Array{Float64,2} <- Array{Ptr{Float64}}
    for i=1:length(f0), j=1:freqbins
        @inbounds residual[j,i] = unsafe_load(cresidual[i], j)
    end

    residual
end

function synthesis(f0::AbstractVector{Float64},
                   spectrogram::AbstractMatrix{Float64},
                   residual::AbstractMatrix{Float64},
                   period::Real, fs::Integer, len::Integer)
    fftsize = get_fftsize_for_cheaptrick(fs)

    # Array{Float64,2} -> Array{Ptr{Float64}}
    cspectrogram = Array(Ptr{Float64}, size(spectrogram, 2))
    ptrarray2d!(cspectrogram, spectrogram)

    cresidual = Array(Ptr{Float64}, size(residual, 2))
    ptrarray2d!(cresidual, residual)

    synthesized = Array(Float64, len)
    ccall((:Synthesis, libworld), Void,
          (Ptr{Float64}, Int64, Ptr{Ptr{Float64}}, Ptr{Ptr{Float64}},
           Int64, Float64, Int64, Int64, Ptr{Float64}),
          f0, length(f0), cspectrogram, cresidual, fftsize, period, fs, len,
          synthesized)

    synthesized
end

function aperiodicityratio(x::AbstractVector{Float64}, fs::Integer,
                           f0::AbstractVector{Float64},
                           timeaxis::AbstractVector{Float64})
    fftsize::Int = get_fftsize_for_cheaptrick(fs)
    freqbins = div(fftsize, 2) + 1
    aperiodicity = Array(Float64, freqbins, length(f0))

    # Array{Float64,2} -> Array{Ptr{Float64}}
    caperiodicity = Array(Ptr{Float64}, size(aperiodicity, 2))
    ptrarray2d!(caperiodicity, aperiodicity)

    ccall((:AperiodicityRatio, libworld), Void,
          (Ptr{Float64}, Int64, Int64, Ptr{Float64}, Int, Ptr{Float64}, Int64,
           Ptr{Ptr{Float64}}),
          x, length(x), fs, f0, length(f0), timeaxis, fftsize, caperiodicity)

    # Array{Float64,2} <- Array{Ptr{Float64}}
    for i=1:length(f0), j=1:freqbins
        aperiodicity[j,i] = unsafe_load(caperiodicity[i], j)
    end

    aperiodicity
end

function synthesis_from_aperiodicity(f0::AbstractVector{Float64},
                                     spectrogram::AbstractMatrix{Float64},
                                     aperiodicity::AbstractMatrix{Float64},
                                     period::Real,
                                     fs::Integer, len::Integer)
    fftsize::Int = get_fftsize_for_cheaptrick(fs)

    # Array{Float64,2} -> Array{Ptr{Float64}}
    cspectrogram = Array(Ptr{Float64}, size(spectrogram, 2))
    ptrarray2d!(cspectrogram, spectrogram)

    caperiodicity = Array(Ptr{Float64}, size(aperiodicity, 2))
    ptrarray2d!(caperiodicity, aperiodicity)

    synthesized = Array(Float64, len)
    ccall((:SynthesisFromAperiodicity, libworld), Void,
          (Ptr{Float64}, Int64, Ptr{Ptr{Float64}}, Ptr{Ptr{Float64}},
           Int64, Float64, Int64, Int64, Ptr{Float64}),
          f0, length(f0), cspectrogram, caperiodicity, fftsize, period, fs,
          len, synthesized)

    synthesized
end
