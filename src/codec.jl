"""
$(SIGNATURES)

GetNumberOfAperiodicities provides the number of dimensions for aperiodicity
coding. It is determined by only fs.

**Parameters**

- `fs` : Sampleing frequency

**Returns**

- `n` : Number of aperiodicities
"""
function get_number_of_aperiodicities(fs)
    ccall((:GetNumberOfAperiodicities, libworld), Cint, (Cint,), fs)
end

"""
$(SIGNATURES)

CodeAperiodicity codes the aperiodicity. The number of dimensions is
determined by fs.

**Parameters**

- `aperiodicity` : Aperiodicity before coding
- `fs` : Sampling frequency
- `fftsize` : FFT size (default : `get_fftsize_for_cheaptrick(fs)`)

**Returns**

- `coded_aperiodicity` : Coded aperiodicity
"""
function code_aperiodicity(aperiodicity, fs,
                           fftsize=get_fftsize_for_cheaptrick(fs))
    n = get_number_of_aperiodicities(fs)
    f0_length = size(aperiodicity, 2)
    coded_aperiodicity = zeros(Cdouble, n, f0_length)

    # Array{Cdouble,2} -> Array{Ptr{Cdouble}}
    ccoded_aperiodicity = Array{Ptr{Cdouble}}(f0_length)
    ptrarray2d!(ccoded_aperiodicity, coded_aperiodicity)

    # Array{Cdouble,2} -> Array{Ptr{Cdouble}}
    caperiodicity = Array{Ptr{Cdouble}}(f0_length)
    ptrarray2d!(caperiodicity, aperiodicity)

    ccall((:CodeAperiodicity, libworld), Void,
          (Ptr{Ptr{Cdouble}}, Cint, Cint, Cint, Ptr{Ptr{Cdouble}}),
          caperiodicity, f0_length, fs, fftsize, ccoded_aperiodicity)

    # Array{Cdouble,2} <- Array{Ptr{Cdouble}}
    for i=1:f0_length, j=1:n
        coded_aperiodicity[j,i] = unsafe_load(ccoded_aperiodicity[i], j)
    end

    coded_aperiodicity
end

"""
$(SIGNATURES)

DecodeAperiodicity decoes the coded aperiodicity.

**Parameters**

- `coded_aperiodicity` : Coded aperiodicity
- `fs` : Sampling frequency
- `fftsize` : FFT size (default : `get_fftsize_for_cheaptrick(fs)`)

**Returns**

- `aperiodicity` : Decoded aperiodicity
"""
function decode_aperiodicity(coded_aperiodicity, fs,
                             fftsize=get_fftsize_for_cheaptrick(fs, CheapTrickOption(fs)))
    freqbins = fftsize>>1 + 1
    f0_length = size(coded_aperiodicity, 2)
    aperiodicity = zeros(Cdouble, freqbins, f0_length)

    # Array{Cdouble,2} -> Array{Ptr{Cdouble}}
    ccoded_aperiodicity = Array{Ptr{Cdouble}}(f0_length)
    ptrarray2d!(ccoded_aperiodicity, coded_aperiodicity)

    # Array{Cdouble,2} -> Array{Ptr{Cdouble}}
    caperiodicity = Array{Ptr{Cdouble}}(f0_length)
    ptrarray2d!(caperiodicity, aperiodicity)

    ccall((:DecodeAperiodicity, libworld), Void,
          (Ptr{Ptr{Cdouble}}, Cint, Cint, Cint, Ptr{Ptr{Cdouble}}),
          ccoded_aperiodicity, f0_length, fs, fftsize, caperiodicity)

    # Array{Cdouble,2} <- Array{Ptr{Cdouble}}
    for i=1:f0_length, j=1:freqbins
        aperiodicity[j,i] = unsafe_load(caperiodicity[i], j)
    end

    aperiodicity
end
