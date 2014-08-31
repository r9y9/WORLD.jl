@assert isdefined(:libworld)

immutable DioOption
    f0Floor::Cdouble
    f0Ceil::Cdouble
    channelsInOctave::Cdouble
    period::Cdouble # ms
    speed::Cint
end

function DioOption(f0Floor::Float64, f0Ceil::Float64,
                   channelsInOctave::Float64,
                   period::Float64, speed::Int32)
    DioOption(convert(Cdouble, f0Floor), convert(Cdouble, f0Ceil),
              convert(Cdouble, channelsInOctave),
              convert(Cdouble, period), convert(Cint, speed))
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

    f0 = zeros(expectedlen)
    timeaxis = zeros(expectedlen)
    ccall((:Dio, libworld),  Void,
          (Ptr{Float64}, Int64, Int64, DioOption, Ptr{Float64}, Ptr{Float64}),
          x, length(x), fs, opt, timeaxis, f0)
    return f0, timeaxis
end

# dio v0.1.0, will be deprecated
function dio1(x::Vector{Float64}, fs::Int, period::Float64)
    expectedlen = get_samples_for_dio(fs, length(x), period)

    f0 = zeros(expectedlen)
    timeaxis = zeros(expectedlen)
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
    refinedF0 = zeros(length(f0))
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
function make_2dcarray_alternative{T<:Real}(a::Array{T,2})
    [pointer(a[:,i],1) for i=1:size(a,2)]
end

function star(x::Vector{Float64}, fs::Int, timeaxis::Vector{Float64},
              f0::Vector{Float64})
    freqbins = int(get_fftsize_for_star(fs)/2+1)
    spectrogram = zeros(freqbins, length(f0))

    # Array{Float64,2} -> Array{Ptr{Float64}}
    spectrogram_passed_to_C = make_2dcarray_alternative(spectrogram)

    ccall((:Star, libworld), Void,
          (Ptr{Float64}, Int64, Int64, Ptr{Float64}, Ptr{Float64}, Int64,
           Ptr{Ptr{Float64}}),
          x, length(x), fs, timeaxis, f0, length(f0), spectrogram_passed_to_C)

    # TODO (ryuichi) Better solution
    # Array{Float64,2} <- Array{Ptr{Float64}}
    for i=1:length(f0)
        spectrogram[:,i] = pointer_to_array(spectrogram_passed_to_C[i], freqbins)
    end

    return spectrogram
end

function get_fftsize_for_cheaptrick(fs::Int)
    return ccall((:GetFFTSizeForCheapTrick, libworld), Int,
                 (Int,), fs)
end

function cheaptrick(x::Vector{Float64}, fs::Int, timeaxis::Vector{Float64},
                    f0::Vector{Float64})
    freqbins = int(get_fftsize_for_cheaptrick(fs)/2+1)
    spectrogram = zeros(freqbins, length(f0))

    # Array{Float64,2} -> Array{Ptr{Float64}}
    spectrogram_passed_to_C = make_2dcarray_alternative(spectrogram)

    ccall((:CheapTrick, libworld), Void,
          (Ptr{Float64}, Int64, Int64, Ptr{Float64}, Ptr{Float64}, Int64,
           Ptr{Ptr{Float64}}),
          x, length(x), fs, timeaxis, f0, length(f0), spectrogram_passed_to_C)

    # TODO (ryuichi) Better solution
    # Array{Float64,2} <- Array{Ptr{Float64}}
    for i=1:length(f0)
        spectrogram[:,i] = pointer_to_array(spectrogram_passed_to_C[i], freqbins)
    end

    return spectrogram
end

function platinum(x::Vector{Float64}, fs::Int, timeaxis::Vector{Float64},
                  f0::Vector{Float64},
                  spectrogram::Matrix{Float64})
    fftsize::Int = get_fftsize_for_cheaptrick(fs)
    freqbins = fftsize+1
    residual = zeros(freqbins, length(f0))

    # Array{Float64,2} -> Array{Ptr{Float64}}
    spectrogram_passed_to_C = make_2dcarray_alternative(spectrogram)
    residual_passed_to_C = make_2dcarray_alternative(residual)

    ccall((:Platinum, libworld), Void,
          (Ptr{Float64}, Int64, Int64, Ptr{Float64}, Ptr{Float64}, Int64,
           Ptr{Ptr{Float64}}, Int64, Ptr{Ptr{Float64}}),
          x, length(x), fs, timeaxis, f0, length(f0), spectrogram_passed_to_C,
          fftsize, residual_passed_to_C)

    # TODO (ryuichi) Better solution
    # Array{Float64,2} <- Array{Ptr{Float64}}
    for i=1:length(f0)
        residual[:,i] = pointer_to_array(residual_passed_to_C[i], freqbins)
    end

    return residual
end

function synthesis(f0::Vector{Float64}, spectrogram::Matrix{Float64},
                   residual::Matrix{Float64},
                   period::Float64, fs::Int, len::Int)
    fftsize::Int = get_fftsize_for_cheaptrick(fs)

    # Array{Float64,2} -> Array{Ptr{Float64}}
    spectrogram_passed_to_C = make_2dcarray_alternative(spectrogram)
    residual_passed_to_C = make_2dcarray_alternative(residual)

    synthesized = zeros(len)
    ccall((:Synthesis, libworld), Void,
          (Ptr{Float64}, Int64, Ptr{Ptr{Float64}}, Ptr{Ptr{Float64}},
           Int64, Float64, Int64, Int64, Ptr{Float64}),
          f0, length(f0), spectrogram_passed_to_C, residual_passed_to_C,
          fftsize, period, fs, len, synthesized)

    return synthesized
end

function aperiodicityratio(x::Vector{Float64}, fs::Int, f0::Vector{Float64},
                           timeaxis::Vector{Float64})
    fftsize::Int = get_fftsize_for_cheaptrick(fs)
    freqbins = int(fftsize/2+1)
    aperiodicity = zeros(freqbins, length(f0))

    # Array{Float64,2} -> Array{Ptr{Float64}}
    aperiodicity_passed_to_C = make_2dcarray_alternative(aperiodicity)

    ccall((:AperiodicityRatio, libworld), Void,
          (Ptr{Float64}, Int64, Int64, Ptr{Float64}, Int, Ptr{Float64}, Int64,
           Ptr{Ptr{Float64}}),
          x, length(x), fs, f0, length(f0), timeaxis, fftsize,
          aperiodicity_passed_to_C)

    # TODO (ryuichi) Better solution
    # Array{Float64,2} <- Array{Ptr{Float64}}
    for i=1:length(f0)
        aperiodicity[:,i] =
        pointer_to_array(aperiodicity_passed_to_C[i], freqbins)
    end

    return aperiodicity
end

function synthesis_from_aperiodicity(f0::Vector{Float64},
                                   spectrogram::Matrix{Float64},
                                   aperiodicity::Matrix{Float64},
                                   period::Float64,
                                   fs::Int, len::Int)
    fftsize::Int = get_fftsize_for_cheaptrick(fs)

    # Array{Float64,2} -> Array{Ptr{Float64}}
    spectrogram_passed_to_C = make_2dcarray_alternative(spectrogram)
    aperiodicity_passed_to_C = make_2dcarray_alternative(aperiodicity)

    synthesized = zeros(len)
    ccall((:SynthesisFromAperiodicity, libworld), Void,
          (Ptr{Float64}, Int64, Ptr{Ptr{Float64}}, Ptr{Ptr{Float64}},
           Int64, Float64, Int64, Int64, Ptr{Float64}),
          f0, length(f0), spectrogram_passed_to_C, aperiodicity_passed_to_C,
          fftsize, period, fs, len, synthesized)

    return synthesized
end
