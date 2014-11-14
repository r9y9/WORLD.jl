@assert isdefined(:libworld)

immutable DioOption
    f0Floor::Cdouble
    f0Ceil::Cdouble
    channelsInOctave::Cdouble
    period::Cdouble # ms
    speed::Cint

    function DioOption(f0Floor, f0Ceil, channelsInOctave, period, speed)
        new(convert(Cdouble, f0Floor), convert(Cdouble, f0Ceil),
            convert(Cdouble, channelsInOctave),
            convert(Cdouble, period), convert(Cint, speed))
    end
end

function get_samples_for_dio(fs::Int, len::Int, period::Float64)
    return ccall((:GetSamplesForDIO, libworld), Int,
                 (Int, Int, Float64), fs, len, period)
end

# This function doesn't work because currently julia doesn't support
# conversions between Julia types and C-struct.
# TODO(ryuichi) solution
function dio(x::Vector{Float64}, fs::Int, opt::DioOption)
    println(opt)
    expectedlen = get_samples_for_dio(fs, length(x), opt.period)

    f0 = Array(Float64, expectedlen)
    timeaxis = Array(Float64, expectedlen)
    ccall((:Dio, libworld),  Void,
          (Ptr{Float64}, Int64, Int64, DioOption, Ptr{Float64}, Ptr{Float64}),
          x, length(x), fs, opt, timeaxis, f0)
    return f0, timeaxis
end

# dio v0.1.0, will be deprecated
function dio1(x::Vector{Float64}, fs::Int, period::Float64)
    expectedlen = get_samples_for_dio(fs, length(x), period)

    f0 = Array(Float64, expectedlen)
    timeaxis = Array(Float64, expectedlen)
    ccall((:DioOld, libworld),  Void,
          (Ptr{Float64}, Int64, Int64, Float64, Ptr{Float64}, Ptr{Float64}),
          x, length(x), fs, period, timeaxis, f0)
    return f0, timeaxis
end

function get_fftsize_for_star(fs::Int)
    ccall((:GetFFTSizeForStar, libworld), Int, (Int,), fs)
end

function stonemask(x::Vector{Float64}, fs::Int, timeaxis::Vector{Float64},
                   f0::Vector{Float64})
    refinedF0 = Array(Float64, length(f0))
    ccall((:StoneMask, libworld),  Void,
          (Ptr{Float64}, Int64, Int64, Ptr{Float64}, Ptr{Float64}, Int,
           Ptr{Float64}),
          x, length(x), fs, timeaxis, f0, length(f0), refinedF0)
    return refinedF0
end

function get_fftsize_for_star(fs::Int)
    ccall((:GetFFTSizeForStar, libworld), Int, (Int,), fs)
end

# Array{T,2} -> Array{Ptr{T}}
function ptrarray2d{T<:Real}(a::Array{T,2})
    [pointer(a[:,i],1) for i=1:size(a,2)]
end

function star(x::Vector{Float64}, fs::Int, timeaxis::Vector{Float64},
              f0::Vector{Float64})
    const freqbins = div(get_fftsize_for_star(fs), 2) + 1
    spectrogram = Array(Float64, freqbins, length(f0))

    # Array{Float64,2} -> Array{Ptr{Float64}}
    cspectrogram = ptrarray2d(spectrogram)

    ccall((:Star, libworld), Void,
          (Ptr{Float64}, Int64, Int64, Ptr{Float64}, Ptr{Float64}, Int64,
           Ptr{Ptr{Float64}}),
          x, length(x), fs, timeaxis, f0, length(f0), cspectrogram)

    # TODO (ryuichi) Better solution
    # Array{Float64,2} <- Array{Ptr{Float64}}
    for i=1:length(f0)
        spectrogram[:,i] = pointer_to_array(cspectrogram[i], freqbins)
    end

    return spectrogram
end

function get_fftsize_for_cheaptrick(fs::Int)
    return ccall((:GetFFTSizeForCheapTrick, libworld), Int,
                 (Int,), fs)
end

function cheaptrick(x::Vector{Float64}, fs::Int, timeaxis::Vector{Float64},
                    f0::Vector{Float64})
    const freqbins = div(get_fftsize_for_cheaptrick(fs), 2) + 1
    spectrogram = Array(Float64, freqbins, length(f0))

    # Array{Float64,2} -> Array{Ptr{Float64}}
    cspectrogram = ptrarray2d(spectrogram)

    ccall((:CheapTrick, libworld), Void,
          (Ptr{Float64}, Int64, Int64, Ptr{Float64}, Ptr{Float64}, Int64,
           Ptr{Ptr{Float64}}),
          x, length(x), fs, timeaxis, f0, length(f0), cspectrogram)

    # TODO (ryuichi) Better solution
    # Array{Float64,2} <- Array{Ptr{Float64}}
    for i=1:length(f0)
        spectrogram[:,i] = pointer_to_array(cspectrogram[i], freqbins)
    end

    return spectrogram
end

function platinum(x::Vector{Float64}, fs::Int, timeaxis::Vector{Float64},
                  f0::Vector{Float64},
                  spectrogram::Matrix{Float64})
    const fftsize::Int = get_fftsize_for_cheaptrick(fs)
    const freqbins = fftsize +1
    residual = Array(Float64, freqbins, length(f0))

    # Array{Float64,2} -> Array{Ptr{Float64}}
    cspectrogram = ptrarray2d(spectrogram)
    cresidual = ptrarray2d(residual)

    ccall((:Platinum, libworld), Void,
          (Ptr{Float64}, Int64, Int64, Ptr{Float64}, Ptr{Float64}, Int64,
           Ptr{Ptr{Float64}}, Int64, Ptr{Ptr{Float64}}),
          x, length(x), fs, timeaxis, f0, length(f0), cspectrogram,
          fftsize, cresidual)

    # TODO (ryuichi) Better solution
    # Array{Float64,2} <- Array{Ptr{Float64}}
    for i=1:length(f0)
        residual[:,i] = pointer_to_array(cresidual[i], freqbins)
    end

    return residual
end

function synthesis(f0::Vector{Float64}, spectrogram::Matrix{Float64},
                   residual::Matrix{Float64},
                   period::Float64, fs::Int, len::Int)
    const fftsize::Int = get_fftsize_for_cheaptrick(fs)

    # Array{Float64,2} -> Array{Ptr{Float64}}
    cspectrogram = ptrarray2d(spectrogram)
    cresidual = ptrarray2d(residual)

    synthesized = Array(Float64, len)
    ccall((:Synthesis, libworld), Void,
          (Ptr{Float64}, Int64, Ptr{Ptr{Float64}}, Ptr{Ptr{Float64}},
           Int64, Float64, Int64, Int64, Ptr{Float64}),
          f0, length(f0), cspectrogram, cresidual,
          fftsize, period, fs, len, synthesized)

    return synthesized
end

function aperiodicityratio(x::Vector{Float64}, fs::Int, f0::Vector{Float64},
                           timeaxis::Vector{Float64})
    const fftsize::Int = get_fftsize_for_cheaptrick(fs)
    const freqbins = div(fftsize, 2) + 1
    aperiodicity = Array(Float64, freqbins, length(f0))

    # Array{Float64,2} -> Array{Ptr{Float64}}
    caperiodicity = ptrarray2d(aperiodicity)

    ccall((:AperiodicityRatio, libworld), Void,
          (Ptr{Float64}, Int64, Int64, Ptr{Float64}, Int, Ptr{Float64}, Int64,
           Ptr{Ptr{Float64}}),
          x, length(x), fs, f0, length(f0), timeaxis, fftsize,
          caperiodicity)

    # TODO (ryuichi) Better solution
    # Array{Float64,2} <- Array{Ptr{Float64}}
    for i=1:length(f0)
        aperiodicity[:,i] =
        pointer_to_array(caperiodicity[i], freqbins)
    end

    return aperiodicity
end

function synthesis_from_aperiodicity(f0::Vector{Float64},
                                   spectrogram::Matrix{Float64},
                                   aperiodicity::Matrix{Float64},
                                   period::Float64,
                                   fs::Int, len::Int)
    const fftsize::Int = get_fftsize_for_cheaptrick(fs)

    # Array{Float64,2} -> Array{Ptr{Float64}}
    cspectrogram = ptrarray2d(spectrogram)
    caperiodicity = ptrarray2d(aperiodicity)

    synthesized = Array(Float64, len)
    ccall((:SynthesisFromAperiodicity, libworld), Void,
          (Ptr{Float64}, Int64, Ptr{Ptr{Float64}}, Ptr{Ptr{Float64}},
           Int64, Float64, Int64, Int64, Ptr{Float64}),
          f0, length(f0), cspectrogram, caperiodicity,
          fftsize, period, fs, len, synthesized)

    return synthesized
end
