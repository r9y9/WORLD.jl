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
    ccoded_aperiodicity = Array{Ptr{Cdouble}}(undef, f0_length)
    ptrarray2d!(ccoded_aperiodicity, coded_aperiodicity)

    # Array{Cdouble,2} -> Array{Ptr{Cdouble}}
    caperiodicity = Array{Ptr{Cdouble}}(undef, f0_length)
    ptrarray2d!(caperiodicity, aperiodicity)

    ccall((:CodeAperiodicity, libworld), Cvoid,
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
    ccoded_aperiodicity = Array{Ptr{Cdouble}}(undef, f0_length)
    ptrarray2d!(ccoded_aperiodicity, coded_aperiodicity)

    # Array{Cdouble,2} -> Array{Ptr{Cdouble}}
    caperiodicity = Array{Ptr{Cdouble}}(undef, f0_length)
    ptrarray2d!(caperiodicity, aperiodicity)

    ccall((:DecodeAperiodicity, libworld), Cvoid,
          (Ptr{Ptr{Cdouble}}, Cint, Cint, Cint, Ptr{Ptr{Cdouble}}),
          ccoded_aperiodicity, f0_length, fs, fftsize, caperiodicity)

    # Array{Cdouble,2} <- Array{Ptr{Cdouble}}
    for i=1:f0_length, j=1:freqbins
        aperiodicity[j,i] = unsafe_load(caperiodicity[i], j)
    end

    aperiodicity
end


"""
$(SIGNATURES)

CodeSpectralEnvelope codes the spectral envelope.

**Parameters**

- `spectrogram` : spectrogram (time sequence of spectral envelope)
- `fs` : Sampling frequency
- `fftsize` : FFT size
- `number_of_dimentions` : Number of dimentions for coded spectral envelope

**Returns**

- `coded_spectral_envelope` : Coded spectral envelope
"""
function code_spectral_envelope(spectrogram, fs,
                                fftsize, number_of_dimentions)
    nd = number_of_dimentions
    f0_length = size(spectrogram, 2)
    coded_spectral_envelope = zeros(Cdouble, nd, f0_length)

    # Array{Cdouble,2} -> Array{Ptr{Cdouble}}
    ccoded_spectral_envelope = Array{Ptr{Cdouble}}(undef, f0_length)
    ptrarray2d!(ccoded_spectral_envelope, coded_spectral_envelope)

    # Array{Cdouble,2} -> Array{Ptr{Cdouble}}
    cspectrogram = Array{Ptr{Cdouble}}(undef, f0_length)
    ptrarray2d!(cspectrogram, spectrogram)

    ccall((:CodeSpectralEnvelope, libworld), Cvoid,
          (Ptr{Ptr{Cdouble}}, Cint, Cint, Cint, Cint, Ptr{Ptr{Cdouble}}),
          cspectrogram, f0_length, fs, fftsize, nd, ccoded_spectral_envelope)

    # Array{Cdouble,2} <- Array{Ptr{Cdouble}}
    for i=1:f0_length, j=1:nd
        coded_spectral_envelope[j,i] = unsafe_load(ccoded_spectral_envelope[i], j)
    end

    coded_spectral_envelope
end

"""
$(SIGNATURES)

DecodeSpectralEnvelope decodes the spectral envelope.

**Parameters**

- `coded_spectral_envelope` : Coded spectral envelope
- `fs` : Sampling frequency
- `fftsize` : FFT size

**Returns**

- `spectrogram` : decoded spectral envelope
"""
function decode_spectral_envelope(coded_spectral_envelope, fs, fftsize)
    freqbins = fftsize>>1 + 1
    nd = size(coded_spectral_envelope, 1)
    f0_length = size(coded_spectral_envelope, 2)
    spectrogram = zeros(Cdouble, freqbins, f0_length)

    # Array{Cdouble,2} -> Array{Ptr{Cdouble}}
    ccoded_spectral_envelope = Array{Ptr{Cdouble}}(undef, f0_length)
    ptrarray2d!(ccoded_spectral_envelope, coded_spectral_envelope)

    # Array{Cdouble,2} -> Array{Ptr{Cdouble}}
    cspectrogram = Array{Ptr{Cdouble}}(undef, f0_length)
    ptrarray2d!(cspectrogram, spectrogram)

    ccall((:DecodeSpectralEnvelope, libworld), Cvoid,
          (Ptr{Ptr{Cdouble}}, Cint, Cint, Cint, Cint, Ptr{Ptr{Cdouble}}),
          ccoded_spectral_envelope, f0_length, fs, fftsize, nd, cspectrogram)

    # Array{Cdouble,2} <- Array{Ptr{Cdouble}}
    for i=1:f0_length, j=1:freqbins
        spectrogram[j,i] = unsafe_load(cspectrogram[i], j)
    end

    spectrogram
end
