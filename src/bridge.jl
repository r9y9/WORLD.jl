@assert isdefined(:libworld)

if version >= v"0.2.1-2"
    # DioOption represents a set of options that is used in DIO,
    # a fundamental frequency analysis.
    immutable DioOption
        f0floor::Cdouble
        f0ceil::Cdouble
        channels_in_octave::Cdouble
        period::Cdouble # ms
        speed::Cint
        allowed_range::Cdouble # added in v0.2.1-2 (WORLD 0.2.0_2)

        function DioOption(f0floor, f0ceil, channels_in_octave, period, speed,
                           allowed_range = 0.1)
            f0floor > f0ceil && throw(ArgumentError("F0floor must be larger than F0ceil"))
            f0floor < 0 && throw(ArgumentError("f0floor must be positive"))
            if channels_in_octave < 0
                throw(ArgumentError("channels_in_octave must be positive"))
            end
            period <= 0 && throw(ArgumentError("period must be positive"))
            (1 <= speed <= 12) || throw(ArgumentError("1 ≤ speed ≤ 12 is supprted"))
            allowed_range >= 0 || throw(ArgumentError("allowed_range >= 0 is supported"))
            new(f0floor, f0ceil, channels_in_octave, period, speed, allowed_range)
        end
    end
else
    immutable DioOption
        f0floor::Cdouble
        f0ceil::Cdouble
        channels_in_octave::Cdouble
        period::Cdouble # ms
        speed::Cint

        function DioOption(f0floor, f0ceil, channels_in_octave, period, speed)
            f0floor > f0ceil && throw(ArgumentError("F0floor must be larger than F0ceil"))
            f0floor < 0 && throw(ArgumentError("f0floor must be positive"))
            if channels_in_octave < 0
                throw(ArgumentError("channels_in_octave must be positive"))
            end
            period <= 0 && throw(ArgumentError("period must be positive"))
            (1 <= speed <= 12) || throw(ArgumentError("1 ≤ speed ≤ 12 is supprted"))
            new(f0floor, f0ceil, channels_in_octave, period, speed)
        end
    end
end

# Note that the default options assume that the sampling frequency of a input
# speech signal is 44.1 kHz.
function DioOption(;
                   f0floor::Float64=71.0,
                   f0ceil::Float64=800.0,
                   channels_in_octave::Float64=2.0,
                   period::Float64=5.0,
                   speed::Integer=1,
                   allowed_range::Float64=0.1
                   )
    if version >= v"0.2.1-2"
        DioOption(f0floor, f0ceil, channels_in_octave, period, speed, allowed_range)
    else
        DioOption(f0floor, f0ceil, channels_in_octave, period, speed)
    end
end

function get_samples_for_dio(fs::Real, len::Integer, period::Real)
    ccall((:GetSamplesForDIO, libworld), Cint,
          (Cint, Cint, Cdouble), fs, len, period)
end

function dio(x::AbstractVector{Cdouble}, fs::Real, opt::DioOption=DioOption())
    expectedlen = get_samples_for_dio(fs, length(x), opt.period)
    f0 = Array(Cdouble, expectedlen)
    timeaxis = Array(Cdouble, expectedlen)
    # Note that value passinig of julia-type to C-struct doesn't work.
    ccall((:DioByOptPtr, libworld),  Void,
          (Ptr{Cdouble}, Cint, Cint, Ptr{DioOption}, Ptr{Cdouble}, Ptr{Cdouble}),
          x, length(x), fs, &opt, timeaxis, f0)
    f0, timeaxis
end

function stonemask(x::AbstractVector{Cdouble}, fs::Integer,
                   timeaxis::AbstractVector{Cdouble},
                   f0::AbstractVector{Cdouble})
    refinedF0 = Array(Cdouble, length(f0))
    ccall((:StoneMask, libworld),  Void,
          (Ptr{Cdouble}, Cint, Cint, Ptr{Cdouble}, Ptr{Cdouble}, Cint,
           Ptr{Cdouble}),
          x, length(x), fs, timeaxis, f0, length(f0), refinedF0)
    refinedF0
end

# Array{T,2} -> Array{Ptr{T}}
function ptrarray2d!{T<:Real}(dst::Array{Ptr{T},1}, src::Array{T,2})
    for i=1:size(src, 2)
        @inbounds dst[i] = pointer(sub(src, 1:size(src, 1), i), 1)
    end
end

function get_fftsize_for_cheaptrick(fs::Integer)
    fftsize = ccall((:GetFFTSizeForCheapTrick, libworld), Cint, (Cint,), fs)
    convert(Int, fftsize)
end

function cheaptrick(x::AbstractVector{Cdouble}, fs::Integer,
                    timeaxis::AbstractVector{Cdouble},
                    f0::AbstractVector{Cdouble})
    freqbins = get_fftsize_for_cheaptrick(fs)>>1 + 1
    spectrogram = Array(Cdouble, freqbins, length(f0))

    # Array{Cdouble,2} -> Array{Ptr{Cdouble}}
    cspectrogram = Array(Ptr{Cdouble}, size(spectrogram, 2))
    ptrarray2d!(cspectrogram, spectrogram)

    ccall((:CheapTrick, libworld), Void,
          (Ptr{Cdouble}, Cint, Cint, Ptr{Cdouble}, Ptr{Cdouble}, Cint,
           Ptr{Ptr{Cdouble}}),
          x, length(x), fs, timeaxis, f0, length(f0), cspectrogram)

    # Array{Cdouble,2} <- Array{Ptr{Cdouble}}
    for i=1:length(f0), j=1:freqbins
        @inbounds spectrogram[j,i] = unsafe_load(cspectrogram[i], j)
    end

    spectrogram
end

function d4c(x::AbstractVector{Cdouble}, fs::Integer,
             timeaxis::AbstractVector{Cdouble},
             f0::AbstractVector{Cdouble})
    fftsize = get_fftsize_for_cheaptrick(fs)
    freqbins = fftsize>>1 + 1
    aperiodicity = zeros(Cdouble, freqbins, length(f0))

    # Array{Cdouble,2} -> Array{Ptr{Cdouble}}
    caperiodicity = Array(Ptr{Cdouble}, size(aperiodicity, 2))
    ptrarray2d!(caperiodicity, aperiodicity)

    ccall((:D4C, libworld), Void,
          (Ptr{Cdouble}, Cint, Cint, Ptr{Cdouble}, Ptr{Cdouble}, Cint, Cint,
           Ptr{Ptr{Cdouble}}),
          x, length(x), fs, timeaxis, f0, length(f0), fftsize, caperiodicity)

    # Array{Cdouble,2} <- Array{Ptr{Cdouble}}
    for i=1:length(f0), j=1:freqbins
        aperiodicity[j,i] = unsafe_load(caperiodicity[i], j)
    end

    aperiodicity
end

function synthesis(f0::AbstractVector{Cdouble},
                   spectrogram::AbstractMatrix{Cdouble},
                   aperiodicity::AbstractMatrix{Cdouble},
                   period::Real, fs::Integer, len::Integer)
    fftsize = get_fftsize_for_cheaptrick(fs)

    # Array{Cdouble,2} -> Array{Ptr{Cdouble}}
    cspectrogram = Array(Ptr{Cdouble}, size(spectrogram, 2))
    ptrarray2d!(cspectrogram, spectrogram)

    caperiodicity = Array(Ptr{Cdouble}, size(aperiodicity, 2))
    ptrarray2d!(caperiodicity, aperiodicity)

    synthesized = Array(Cdouble, len)
    ccall((:Synthesis, libworld), Void,
          (Ptr{Cdouble}, Cint, Ptr{Ptr{Cdouble}}, Ptr{Ptr{Cdouble}},
           Cint, Cdouble, Cint, Cint, Ptr{Cdouble}),
          f0, length(f0), cspectrogram, caperiodicity, fftsize, period, fs, len,
          synthesized)

    synthesized
end

# matlabfunctions

function interp1!(x::AbstractVector{Cdouble},
                  y::AbstractVector{Cdouble},
                  xi::AbstractVector{Cdouble},
                  yi::AbstractVector{Cdouble})
    @assert length(x) == length(y)
    @assert length(xi) == length(yi)
    ccall((:interp1, libworld), Void,
          (Ptr{Cdouble}, Ptr{Cdouble}, Cint, Ptr{Cdouble}, Cint, Ptr{Cdouble}),
          x, y, length(x), xi, length(xi), yi)
    yi
end

function interp1(x::AbstractVector{Cdouble},
                 y::AbstractVector{Cdouble},
                 xi::AbstractVector{Cdouble})
    yi = similar(xi)
    interp1!(x, y, xi, yi)
end
