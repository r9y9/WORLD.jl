"""
A lightweitht julia wrapper for [WORLD](https://github.com/mmorise/World),
a high-quality speech analysis, manipulation and synthesis system.
WORLD provides a way to decompose a speech signal into:

- Fundamental frequency (F0)
- spectral envelope
- aperiodicity

and re-synthesize a speech signal from these paramters. Please see the project
page for more details on the WORLD.

!!! note
    WORLD.jl is based on a fork of WORLD ([r9y9/World-cmake](https://github.com/r9y9/World-cmake)).

[https://github.com/r9y9/WORLD.jl](https://github.com/r9y9/WORLD.jl)

## Usage

In the following examples, suppose `x::Vector{Float64}` is a input monoral
speech signal like:

![](assets/x.png)

### F0 estimation

#### Harvest

```julia
opt = HarvestOption(71.0, 800.0, period)
f0, timeaxis = harvest(x, fs, opt)
```

![](assets/f0_by_harvest.png)

#### Dio

```julia
opt = DioOption(f0floor=71.0, f0ceil=800.0, channels_in_octave=2.0,
        period=period, speed=1)
f0, timeaxis = dio(x, fs, opt)
```

![](assets/f0_by_dio.png)

#### StoneMask

```julia
f0 = stonemask(x, fs, timeaxis, f0)
```

![](assets/f0_refinement.png)

### Spectral envelope estimation by CheapTrick

```julia
spectrogram = cheaptrick(x, fs, timeaxis, f0)
```

![](assets/envelope_by_cheaptrick.png)

### Aperiodicity ratio estimation by D4C

```julia
aperiodicity = d4c(x, fs, timeaxis, f0)
```

![](assets/aperiodicity_by_d4c.png)

### Synthesis

```julia
y = synthesis(f0, spectrogram, aperiodicity, period, fs, length(x))
```

![](assets/synthesis.png)

### Compact speech parameterization

Raw spectrum envelope and aperiodicity spectrum are relatively high dimentional
(offen more than 513 or 1025) so one might want to get more compact
representation. To handle this situation, WORLD provides coding/decoding APIs
for spectrum envelope and aperiodicity. Additionally, WORLD.jl provides
conversions from spectrum envelope to mel-cepstrum and vice versa. You can choose
any of coding/decoding APIs depends on your purpose.

#### spectrum envelope to mel-cepstrum

```julia
mc = sp2mc(spectrogram, order, α) # e.g. order=40, α=0.41
```

where `order` is the order of mel-cepstrum (except for 0th) and α is a frequency
warping parameter.

![](assets/melcepstrum.png)

#### mel-cepstrum to spectrum envelope

```julia
approximate_spectrogram = mc2sp(mc, α, get_fftsize_for_cheaptrick(fs))
```

![](assets/envelope_reconstructed_from_melcepstrum.png)

#### Code aperiodicity

```julia
coded_aperiodicity = code_aperiodicity(aperiodicity, fs)
```

![](assets/coded_aperiodicity.png)

#### Decode aperiodicity

```julia
decoded_aperiodicity = decode_aperiodicity(coded_aperiodicity, fs)
```

![](assets/decoded_aperiodicity.png)

For the complete code of visualizations shown above, please check
[the IJulia notebook](http://nbviewer.jupyter.org/github/r9y9/WORLD.jl/blob/master/docs/src/assets/WORLD-demo.ipynb).

## Exports

$(EXPORTS)
"""
module WORLD

using DocStringExtensions

export DioOption, HarvestOption, CheapTrickOption, D4COption, dio, harvest,
    stonemask, cheaptrick, d4c, synthesis, get_fftsize_for_cheaptrick,
    interp1!, interp1, sp2mc, mc2sp,
    get_number_of_aperiodicities, code_aperiodicity, decode_aperiodicity,
    code_spectral_envelope, decode_spectral_envelope


### Binary dependency loading ###
deps = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
if isfile(deps)
    include(deps)
else
    error("WORLD not properly installed. Please run Pkg.build(\"WORLD\")")
end

### Check binary dependency compatibility ###
# This should prevent segfaults when you are using WORLD on system paths (e.g.
# /usr/local/lib/libworld.so) and accidentaly change the verion of WORLD.
try
    # function GetWORLDVersion was added in v0.2.1-2
    versionstr = unsafe_string(convert(Ptr{UInt8},
        ccall((:GetWORLDVersion, libworld), Ptr{Cchar}, ())))
    global const version = VersionNumber(versionstr)
catch e
    try
        ccall((:GetFFTSizeForStar, libworld), Cint, (Cint,), 48000)
        global const version = v"0.1.4"
    catch e
        global const version = v"0.2.0"
    end
end

# v0.2.1-4 breaks API of CheapTrick and D4C, and it's hard to support both old
# and new WORLD library, so throws an error when older version of WORLD is
# detected.
if version < v"0.3.0"
    error("""Binary dependency incompatibility

          WORLD version 0.3.0 or later must be required ($(version) is detected).
          If you have WORLD installed on your system paths, please get the latest
          stable WORLD and install it, and then re-build WORLD.jl with:

          julia>  Pkg.build(\"WORLD\")

          If not, simpily re-building WORLD.jl with the above command. This
          should install the proper version of WORLD.

          If you want to use WORLD.jl with older WORLD, please downgrade WORLD.jl
          for your need. E.g.

          julia> cd(Pkg.dir(\"WORLD\"))
          shell> git checkout v0.1.3 # that supprts v0.2.0 to v0.2.1-3.
         """)
end

for name in ["bridge", "codec", "mcep", "deprecated"]
    include(string(name, ".jl"))
end

end # module WORLD
