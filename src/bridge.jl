@assert isdefined(:libworld)

immutable DioOption
    f0floor::Float64
    f0ceil::Float64
    channels_in_octave::Float64
    period::Float64 # ms
    speed::Int

    function DioOption(f0floor, f0ceil, channels_in_octave, period, speed)
        new(convert(Float64, f0floor),
            convert(Float64, f0ceil),
            convert(Float64, channels_in_octave),
            convert(Float64, period),
            convert(Int, speed))
    end
end

function get_samples_for_dio(fs::Int, len::Int, period::Float64)
    return ccall((:GetSamplesForDIO, libworld), Int,
                 (Int, Int, Float64), fs, len, period)
end

function dio(x::Vector{Float64}, fs::Int, opt::DioOption)
    const expectedlen = get_samples_for_dio(fs, length(x), opt.period)
    f0 = Array(Float64, expectedlen)
    timeaxis = Array(Float64, expectedlen)
    # Note that value passinig of julia-type to C-struct doesn't work.
    ccall((:DioByOptPtr, libworld),  Void,
          (Ptr{Float64}, Int64, Int64, Ptr{DioOption}, Ptr{Float64}, Ptr{Float64}),
          x, length(x), fs, &opt, timeaxis, f0)
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
function ptrarray2d!{T<:Real}(dst::Array{Ptr{T},1}, src::Array{T,2})
    for i=1:size(src, 2)
        @inbounds dst[i] = pointer(sub(src, 1:size(src, 1), i), 1)
    end
end

function star(x::Vector{Float64}, fs::Int, timeaxis::Vector{Float64},
              f0::Vector{Float64})
    const freqbins = div(get_fftsize_for_star(fs), 2) + 1
    spectrogram = Array(Float64, freqbins, length(f0))

    # Array{Float64,2} -> Array{Ptr{Float64}}
    cspectrogram = Array(Ptr{Float64}, size(spectrogram, 2))
    ptrarray2d!(cspectrogram, spectrogram)

    ccall((:Star, libworld), Void,
          (Ptr{Float64}, Int64, Int64, Ptr{Float64}, Ptr{Float64}, Int64,
           Ptr{Ptr{Float64}}),
          x, length(x), fs, timeaxis, f0, length(f0), cspectrogram)

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
    cspectrogram = Array(Ptr{Float64}, size(spectrogram, 2))
    ptrarray2d!(cspectrogram, spectrogram)

    ccall((:CheapTrick, libworld), Void,
          (Ptr{Float64}, Int64, Int64, Ptr{Float64}, Ptr{Float64}, Int64,
           Ptr{Ptr{Float64}}),
          x, length(x), fs, timeaxis, f0, length(f0), cspectrogram)

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

    return synthesized
end

function aperiodicityratio(x::Vector{Float64}, fs::Int, f0::Vector{Float64},
                           timeaxis::Vector{Float64})
    const fftsize::Int = get_fftsize_for_cheaptrick(fs)
    const freqbins = div(fftsize, 2) + 1
    aperiodicity = Array(Float64, freqbins, length(f0))

    # Array{Float64,2} -> Array{Ptr{Float64}}
    caperiodicity = Array(Ptr{Float64}, size(aperiodicity, 2))
    ptrarray2d!(caperiodicity, aperiodicity)

    ccall((:AperiodicityRatio, libworld), Void,
          (Ptr{Float64}, Int64, Int64, Ptr{Float64}, Int, Ptr{Float64}, Int64,
           Ptr{Ptr{Float64}}),
          x, length(x), fs, f0, length(f0), timeaxis, fftsize, caperiodicity)

    # Array{Float64,2} <- Array{Ptr{Float64}}
    for i=1:length(f0)
        aperiodicity[:,i] = pointer_to_array(caperiodicity[i], freqbins)
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

    return synthesized
end
