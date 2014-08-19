# const libworld = "libworld"

immutable DioOption
    f0Floor::Cdouble
    f0Ceil::Cdouble
    channelsInOctave::Cdouble
    framePeriod::Cdouble # ms
    speed::Cint
end

function DioOption(f0Floor::Float64, f0Ceil::Float64,
                   channelsInOctave::Float64,
                   framePeriod::Float64, speed::Int32)
    DioOption(convert(Cdouble, f0Floor), convert(Cdouble, f0Ceil),
              convert(Cdouble, channelsInOctave),
              convert(Cdouble, framePeriod), convert(Cint, speed))
end

function getSamplesForDio(fs::Int, len::Int, framePeriod::Float64)
    return ccall((:GetSamplesForDIO, libworld), Int,
                 (Int, Int, Float64), fs, len, framePeriod)
end

# This function doesn't work because currently julia doesn't support
# conversions between Julia types and C-struct.
# TODO(ryuichi) solution
function dio(x::Vector{Float64}, fs::Int, opt::DioOption)
    println(opt)
    expectedLen = getSamplesForDio(fs, length(x), opt.framePeriod)

    f0 = zeros(expectedLen)
    timeaxis = zeros(expectedLen)
    ccall((:Dio, libworld),  Void,
          (Ptr{Float64}, Int64, Int64, DioOption, Ptr{Float64}, Ptr{Float64}),
          x, length(x), fs, opt, timeaxis, f0)
    return f0, timeaxis
end

# dio v0.1.0, will be deprecated
function dio1(x::Vector{Float64}, fs::Int, framePeriod::Float64)
    expectedLen = getSamplesForDio(fs, length(x), framePeriod)

    f0 = zeros(expectedLen)
    timeaxis = zeros(expectedLen)
    ccall((:DioOld, libworld),  Void,
          (Ptr{Float64}, Int64, Int64, Float64, Ptr{Float64}, Ptr{Float64}),
          x, length(x), fs, framePeriod, timeaxis, f0)
    return f0, timeaxis
end

function getFFTSizeForStar(fs::Int)
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

function getFFTSizeForStar(fs::Int)
    ccall((:GetFFTSizeForStar, libworld), Int, (Int,), fs)
end

# Array{T,2} -> Array{Ptr{T}}
function make2dCArrayAlternative{T<:Real}(a::Array{T,2})
    [pointer(a[i,:],1) for i=1:size(a,1)]
end

function star(x::Vector{Float64}, fs::Int, timeaxis::Vector{Float64},
              f0::Vector{Float64})
    freqbins = int(getFFTSizeForStar(fs)/2+1)
    spectrogram = zeros(length(f0), freqbins)

    # Array{Float64,2} -> Array{Ptr{Float64}}
    spectrogramPassedToC = make2dCArrayAlternative(spectrogram)

    ccall((:Star, libworld), Void,
          (Ptr{Float64}, Int64, Int64, Ptr{Float64}, Ptr{Float64}, Int64,
           Ptr{Ptr{Float64}}),
          x, length(x), fs, timeaxis, f0, length(f0), spectrogramPassedToC)

    # TODO (ryuichi) Better solution
    # Array{Float64,2} <- Array{Ptr{Float64}}
    for i=1:length(f0)
        spectrogram[i,:] = pointer_to_array(spectrogramPassedToC[i], freqbins)
    end

    return spectrogram
end

function getFFTSizeForCheapTrick(fs::Int)
    return ccall((:GetFFTSizeForCheapTrick, libworld), Int,
                 (Int,), fs)
end

function cheaptrick(x::Vector{Float64}, fs::Int, timeaxis::Vector{Float64},
                    f0::Vector{Float64})
    freqbins = int(getFFTSizeForCheapTrick(fs)/2+1)
    spectrogram = zeros(length(f0), freqbins)

    # Array{Float64,2} -> Array{Ptr{Float64}}
    spectrogramPassedToC = make2dCArrayAlternative(spectrogram)

    ccall((:CheapTrick, libworld), Void,
          (Ptr{Float64}, Int64, Int64, Ptr{Float64}, Ptr{Float64}, Int64,
           Ptr{Ptr{Float64}}),
          x, length(x), fs, timeaxis, f0, length(f0), spectrogramPassedToC)

    # TODO (ryuichi) Better solution
    # Array{Float64,2} <- Array{Ptr{Float64}}
    for i=1:length(f0)
        spectrogram[i,:] = pointer_to_array(spectrogramPassedToC[i], freqbins)
    end

    return spectrogram
end

function platinum(x::Vector{Float64}, fs::Int, timeaxis::Vector{Float64},
                  f0::Vector{Float64},
                  spectrogram::Matrix{Float64})
    fftsize::Int = getFFTSizeForCheapTrick(fs)
    freqbins = fftsize+1
    residual = zeros(length(f0), freqbins)

    # Array{Float64,2} -> Array{Ptr{Float64}}
    spectrogramPassedToC = make2dCArrayAlternative(spectrogram)
    residualPassedToC = make2dCArrayAlternative(residual)

    ccall((:Platinum, libworld), Void,
          (Ptr{Float64}, Int64, Int64, Ptr{Float64}, Ptr{Float64}, Int64,
           Ptr{Ptr{Float64}}, Int64, Ptr{Ptr{Float64}}),
          x, length(x), fs, timeaxis, f0, length(f0), spectrogramPassedToC,
          fftsize, residualPassedToC)

    # TODO (ryuichi) Better solution
    # Array{Float64,2} <- Array{Ptr{Float64}}
    for i=1:length(f0)
        residual[i,:] = pointer_to_array(residualPassedToC[i], freqbins)
    end

    return residual
end

function synthesis(f0::Vector{Float64}, spectrogram::Matrix{Float64},
                   residual::Matrix{Float64},
                   framePeriod::Float64, fs::Int, len::Int)
    fftsize::Int = getFFTSizeForCheapTrick(fs)

    # Array{Float64,2} -> Array{Ptr{Float64}}
    spectrogramPassedToC = make2dCArrayAlternative(spectrogram)
    residualPassedToC = make2dCArrayAlternative(residual)

    synthesized = zeros(len)
    ccall((:Synthesis, libworld), Void,
          (Ptr{Float64}, Int64, Ptr{Ptr{Float64}}, Ptr{Ptr{Float64}},
           Int64, Float64, Int64, Int64, Ptr{Float64}),
          f0, length(f0), spectrogramPassedToC, residualPassedToC,
          fftsize, framePeriod, fs, len, synthesized)

    return synthesized
end

function aperiodicityratio(x::Vector{Float64}, fs::Int, f0::Vector{Float64},
                           timeaxis::Vector{Float64})
    fftsize::Int = getFFTSizeForCheapTrick(fs)
    freqbins = int(fftsize/2+1)
    aperiodicity = zeros(length(f0), freqbins)

    # Array{Float64,2} -> Array{Ptr{Float64}}
    aperiodicityPassedToC = make2dCArrayAlternative(aperiodicity)

    ccall((:AperiodicityRatio, libworld), Void,
          (Ptr{Float64}, Int64, Int64, Ptr{Float64}, Int, Ptr{Float64}, Int64,
           Ptr{Ptr{Float64}}),
          x, length(x), fs, f0, length(f0), timeaxis, fftsize,
          aperiodicityPassedToC)

    # TODO (ryuichi) Better solution
    # Array{Float64,2} <- Array{Ptr{Float64}}
    for i=1:length(f0)
        aperiodicity[i,:] =
        pointer_to_array(aperiodicityPassedToC[i], freqbins)
    end

    return aperiodicity
end

function synthesisFromAperiodicity(f0::Vector{Float64},
                                   spectrogram::MatrixFloat64},
                                   aperiodicity::Matrix{Float64},
                                   framePeriod::Float64,
                                   fs::Int, len::Int)
    fftsize::Int = getFFTSizeForCheapTrick(fs)

    # Array{Float64,2} -> Array{Ptr{Float64}}
    spectrogramPassedToC = make2dCArrayAlternative(spectrogram)
    aperiodicityPassedToC = make2dCArrayAlternative(aperiodicity)

    synthesized = zeros(len)
    ccall((:SynthesisFromAperiodicity, libworld), Void,
          (Ptr{Float64}, Int64, Ptr{Ptr{Float64}}, Ptr{Ptr{Float64}},
           Int64, Float64, Int64, Int64, Ptr{Float64}),
          f0, length(f0), spectrogramPassedToC, aperiodicityPassedToC,
          fftsize, framePeriod, fs, len, synthesized)

    return synthesized
end
