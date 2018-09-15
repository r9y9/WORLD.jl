"""
DioOption represents a set of options that is used in DIO, a fundamental
frequency analysis.

**Fields**

$(FIELDS)
"""
mutable struct DioOption
    f0floor::Cdouble
    f0ceil::Cdouble
    channels_in_octave::Cdouble
    "frame period in ms"
    period::Cdouble
    speed::Cint
    "added in v0.2.1-2 (WORLD 0.2.0_2)"
    allowed_range::Cdouble

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
    DioOption(f0floor, f0ceil, channels_in_octave, period, speed, allowed_range)
end


"""
HarvestOption represents a set of options that is used in Harvest, a fundamental
frequency analysis.

**Fields**

$(FIELDS)
"""
mutable struct HarvestOption
    f0floor::Cdouble
    f0ceil::Cdouble
    "frame period in ms"
    period::Cdouble
    function HarvestOption(f0floor, f0ceil, period)
        f0floor > f0ceil && throw(ArgumentError("F0floor must be larger than F0ceil"))
        f0floor < 0 && throw(ArgumentError("f0floor must be positive"))
        period <= 0 && throw(ArgumentError("period must be positive"))
        new(f0floor, f0ceil, period)
    end
end

function HarvestOption(;
                   f0floor::Float64=71.0,
                   f0ceil::Float64=800.0,
                   period::Float64=5.0)
   HarvestOption(f0floor, f0ceil, period)
end

"""
CheapTrick options

**Fields**

$(FIELDS)
"""
mutable struct CheapTrickOption
    q1::Cdouble
    f0floor::Cdouble
    fftsize::Cint
    function CheapTrickOption(fs; q1=-0.15, f0floor=71.0)
        p = new()
        ccall((:InitializeCheapTrickOption, libworld), Cvoid,
              (Cint, Ptr{CheapTrickOption},), fs, Ref(p))
        p.q1 = q1
        p.f0floor = f0floor
        p.fftsize = get_fftsize_for_cheaptrick(Int(fs), p)
        p
    end
end

"""
D4C options (nothing for now, but for future changes)

**Fields**

$(FIELDS)
"""
mutable struct D4COption
    threshold::Cdouble
    D4COption(threshold=0.85) = new(threshold)
end

function get_samples_for_dio(fs::Real, len::Integer, period::Real)
    ccall((:GetSamplesForDIO, libworld), Cint,
          (Cint, Cint, Cdouble), fs, len, period)
end

function get_samples_for_harvest(fs::Real, len::Integer, period::Real)
    ccall((:GetSamplesForHarvest, libworld), Cint,
          (Cint, Cint, Cdouble), fs, len, period)
end

"""
$(SIGNATURES)

Dio estimates F0 trajectory given a monoral input signal.

**Paremters**

- `x`  : Input signal
- `fs` : Sampling frequency
- `opt` : DioOption

**Returns**

- `time_axis`  : Temporal positions.
- `f0`         : F0 contour.

"""
function dio(x::StridedVector{Cdouble}, fs::Real, opt::DioOption=DioOption())
    expectedlen = get_samples_for_dio(fs, length(x), opt.period)
    f0 = Array{Cdouble}(undef, expectedlen)
    timeaxis = Array{Cdouble}(undef, expectedlen)
    ccall((:Dio, libworld),  Cvoid,
          (Ptr{Cdouble}, Cint, Cint, Ref{DioOption}, Ptr{Cdouble}, Ptr{Cdouble}),
          x, length(x), fs, opt, timeaxis, f0)
    f0, timeaxis
end

"""
$(SIGNATURES)

Harvest estimates F0 trajectory given a monoral input signal.

**Paremters**

- `x`  : Input signal
- `fs` : Sampling frequency
- `opt` : HarvestOption

**Returns**

- `time_axis`  : Temporal positions.
- `f0`         : F0 contour.
"""
function harvest(x::StridedVector{Cdouble}, fs::Real, opt::HarvestOption=HarvestOption())
    expectedlen = get_samples_for_harvest(fs, length(x), opt.period)
    f0 = Array{Cdouble}(undef, expectedlen)
    timeaxis = Array{Cdouble}(undef, expectedlen)
    ccall((:Harvest, libworld),  Cvoid,
          (Ptr{Cdouble}, Cint, Cint, Ref{HarvestOption}, Ptr{Cdouble}, Ptr{Cdouble}),
          x, length(x), fs, opt, timeaxis, f0)
    f0, timeaxis
end

"""
$(SIGNATURES)

StoneMask refines the estimated F0 by Dio,

**Parameters**

- `x` : Input signal
- `fs` : Sampling frequency
- `time_axis` : Temporal information
- `f0` : f0 contour

**Returns**

- `refined_f0` : Refined F0
"""
function stonemask(x::StridedVector{Cdouble}, fs::Integer,
                   timeaxis::StridedVector{Cdouble},
                   f0::StridedVector{Cdouble})
    refinedF0 = Array{Cdouble}(undef, length(f0))
    ccall((:StoneMask, libworld),  Cvoid,
          (Ptr{Cdouble}, Cint, Cint, Ptr{Cdouble}, Ptr{Cdouble}, Cint,
           Ptr{Cdouble}),
          x, length(x), fs, timeaxis, f0, length(f0), refinedF0)
    refinedF0
end

# Array{T,2} -> Array{Ptr{T}}
function ptrarray2d!(dst::Array{Ptr{T},1}, src::Array{T,2}) where {T<:Real}
    for i=1:size(src, 2)
        @inbounds dst[i] = pointer(view(src, 1:size(src, 1), i), 1)
    end
end

"""
$(SIGNATURES)

GetFFTSizeForCheapTrick calculates the FFT size based on the sampling
frequency and the lower limit of f0 (It is defined in world.h).

**Parameters**

- `fs`: Sampling frequency
- `opt`: CheapTrickOption

**Returns**

- `fftsize` : FFT size
"""
function get_fftsize_for_cheaptrick(fs::Integer,
                                    opt::CheapTrickOption=CheapTrickOption(fs))
    fftsize = ccall((:GetFFTSizeForCheapTrick, libworld), Cint,
                    (Cint,Ptr{CheapTrickOption}), fs, Ref(opt))
    convert(Int, fftsize)
end

"""
$(SIGNATURES)

CheapTrick calculates the spectrogram that consists of spectral envelopes
estimated by CheapTrick.

**Parameters**

- `x` : Input signal
- `fs` : Sampling frequency
- `time_axis` : Time axis
- `f0` : F0 contour
- `opt` : CheapTrick option

**Returns**

- `spectrogram`  : Spectrogram estimated by CheapTrick.
"""
function cheaptrick(x::StridedVector{Cdouble}, fs::Integer,
                    timeaxis::StridedVector{Cdouble},
                    f0::StridedVector{Cdouble};
                    opt::CheapTrickOption=CheapTrickOption(fs)
    )
    freqbins = get_fftsize_for_cheaptrick(fs, opt)>>1 + 1
    spectrogram = Array{Cdouble}(undef, freqbins, length(f0))

    # Array{Cdouble,2} -> Array{Ptr{Cdouble}}
    cspectrogram = Array{Ptr{Cdouble}}(undef, size(spectrogram, 2))
    ptrarray2d!(cspectrogram, spectrogram)

    ccall((:CheapTrick, libworld), Cvoid,
          (Ptr{Cdouble}, Cint, Cint, Ptr{Cdouble}, Ptr{Cdouble}, Cint,
           Ptr{CheapTrickOption}, Ptr{Ptr{Cdouble}}),
          x, length(x), fs, timeaxis, f0, length(f0), Ref(opt), cspectrogram)

    # Array{Cdouble,2} <- Array{Ptr{Cdouble}}
    for i=1:length(f0), j=1:freqbins
        @inbounds spectrogram[j,i] = unsafe_load(cspectrogram[i], j)
    end

    spectrogram
end

"""
$(SIGNATURES)

D4C calculates the aperiodicity estimated by D4C.

**Parameters**

- `x` : Input signal
- `fs` : Sampling frequency
- `time_axis` : Time axis
- `f0` : F0 contour

**Returns**

- `aperiodicity` : Aperiodicity estimated by D4C.
"""
function d4c(x::StridedVector{Cdouble}, fs::Integer,
             timeaxis::StridedVector{Cdouble},
             f0::StridedVector{Cdouble};
             opt::D4COption=D4COption())
    fftsize = get_fftsize_for_cheaptrick(fs, CheapTrickOption(fs))
    freqbins = fftsize>>1 + 1
    aperiodicity = zeros(Cdouble, freqbins, length(f0))

    # Array{Cdouble,2} -> Array{Ptr{Cdouble}}
    caperiodicity = Array{Ptr{Cdouble}}(undef, size(aperiodicity, 2))
    ptrarray2d!(caperiodicity, aperiodicity)

    ccall((:D4C, libworld), Cvoid,
          (Ptr{Cdouble}, Cint, Cint, Ptr{Cdouble}, Ptr{Cdouble}, Cint, Cint,
           Ptr{D4COption}, Ptr{Ptr{Cdouble}}),
          x, length(x), fs, timeaxis, f0, length(f0), fftsize, Ref(opt),
          caperiodicity)

    # Array{Cdouble,2} <- Array{Ptr{Cdouble}}
    for i=1:length(f0), j=1:freqbins
        aperiodicity[j,i] = unsafe_load(caperiodicity[i], j)
    end

    aperiodicity
end

"""
$(SIGNATURES)

Synthesis synthesize the voice based on f0, spectrogram and
aperiodicity (not excitation signal.

**Parameters**

- `f0` : f0 contour
- `spectrogram` : Spectrogram estimated by CheapTrick
- `aperiodicity` : Aperiodicity spectrogram based on D4C
- `period` :  Temporal period used for the analysis
- `fs` : Sampling frequency
- `len` : Length of the output signal

**Returns**

- `y` : Calculated speech
"""
function synthesis(f0::StridedVector{Cdouble},
                   spectrogram::StridedMatrix{Cdouble},
                   aperiodicity::StridedMatrix{Cdouble},
                   period::Real, fs::Integer, len::Integer)
    fftsize = get_fftsize_for_cheaptrick(fs, CheapTrickOption(fs))

    # Array{Cdouble,2} -> Array{Ptr{Cdouble}}
    cspectrogram = Array{Ptr{Cdouble}}(undef, size(spectrogram, 2))
    ptrarray2d!(cspectrogram, spectrogram)

    caperiodicity = Array{Ptr{Cdouble}}(undef, size(aperiodicity, 2))
    ptrarray2d!(caperiodicity, aperiodicity)

    synthesized = Array{Cdouble}(undef, len)
    ccall((:Synthesis, libworld), Cvoid,
          (Ptr{Cdouble}, Cint, Ptr{Ptr{Cdouble}}, Ptr{Ptr{Cdouble}},
           Cint, Cdouble, Cint, Cint, Ptr{Cdouble}),
          f0, length(f0), cspectrogram, caperiodicity, fftsize, period, fs, len,
          synthesized)

    synthesized
end

# matlabfunctions

"""
$(SIGNATURES)

inplace version of interp1

**Parameters**

- `x` : Input vector (Time axis)
- `y` : Values at x[n]
- `xi`: Required vector
- `yi` : Interpolated vector
"""
function interp1!(x::StridedVector{Cdouble},
                  y::StridedVector{Cdouble},
                  xi::StridedVector{Cdouble},
                  yi::StridedVector{Cdouble})
    @assert length(x) == length(y)
    @assert length(xi) == length(yi)
    ccall((:interp1, libworld), Cvoid,
          (Ptr{Cdouble}, Ptr{Cdouble}, Cint, Ptr{Cdouble}, Cint, Ptr{Cdouble}),
          x, y, length(x), xi, length(xi), yi)
    yi
end

"""
$(SIGNATURES)

interp1 interpolates to find yi, the values of the underlying function Y
at the points in the vector or array xi. x must be a vector.
http://www.mathworks.co.jp/help/techdoc/ref/interp1.html

**Parameters**

- `x` : Input vector (Time axis)
- `y` : Values at x[n]
- `xi`: Required vector

**Returns**

- `yi` : Interpolated vector
"""
function interp1(x::StridedVector{Cdouble},
                 y::StridedVector{Cdouble},
                 xi::StridedVector{Cdouble})
    yi = similar(xi)
    interp1!(x, y, xi, yi)
end
