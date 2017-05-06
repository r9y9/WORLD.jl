var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#WORLD",
    "page": "Home",
    "title": "WORLD",
    "category": "Module",
    "text": "A lightweitht julia wrapper for WORLD, a high-quality speech analysis, manipulation and synthesis system. WORLD provides a way to decompose a speech signal into:\n\nFundamental frequency (F0)\nspectral envelope\naperiodicity\n\nand re-synthesize a speech signal from these paramters. Please see the project page for more details on the WORLD.\n\nnote: Note\nWORLD.jl is based on a fork of WORLD (r9y9/World-cmake).\n\nhttps://github.com/r9y9/WORLD.jl\n\nUsage\n\nIn the following examples, suppose x::Vector{Float64} is a input monoral speech signal like:\n\n(Image: )\n\nF0 estimation\n\nHarvest\n\nopt = HarvestOption(71.0, 800.0, period)\nf0, timeaxis = harvest(x, fs, opt)\n\n(Image: )\n\nDio\n\nopt = DioOption(f0floor=71.0, f0ceil=800.0, channels_in_octave=2.0,\n        period=period, speed=1)\nf0, timeaxis = dio(x, fs, opt)\n\n(Image: )\n\nStoneMask\n\nf0 = stonemask(x, fs, timeaxis, f0)\n\n(Image: )\n\nSpectral envelope estimation by CheapTrick\n\nspectrogram = cheaptrick(x, fs, timeaxis, f0)\n\n(Image: )\n\nAperiodicity ratio estimation by D4C\n\naperiodicity = d4c(x, fs, timeaxis, f0)\n\n(Image: )\n\nSynthesis\n\ny = synthesis(f0, spectrogram, aperiodicity, period, fs, length(x))\n\n(Image: )\n\nCompact speech parameterization\n\nRaw spectrum envelope and aperiodicity spectrum are relatively high dimentional (offen more than 513 or 1025) so one might want to get more compact representation. To handle this situation, WORLD provides coding/decoding APIs for spectrum envelope and aperiodicity. Additionally, WORLD.jl provides conversions from spectrum envelope to mel-cepstrum and vice versa. You can choose any of coding/decoding APIs depends on your purpose.\n\nspectrum envelope to mel-cepstrum\n\nmc = sp2mc(spectrogram, order, α) # e.g. order=40, α=0.41\n\nwhere order is the order of mel-cepstrum (except for 0th) and α is a frequency warping parameter.\n\n(Image: )\n\nmel-cepstrum to spectrum envelope\n\napproximate_spectrogram = mc2sp(mc, α, get_fftsize_for_cheaptrick(fs))\n\n(Image: )\n\nCode aperiodicity\n\ncoded_aperiodicity = code_aperiodicity(aperiodicity, fs)\n\n(Image: )\n\nDecode aperiodicity\n\ndecoded_aperiodicity = decode_aperiodicity(coded_aperiodicity, fs)\n\n(Image: )\n\nFor the complete code of visualizations shown above, please check the IJulia notebook.\n\nExports\n\nCheapTrickOption\nD4COption\nDioOption\nHarvestOption\ncheaptrick\ncode_aperiodicity\ncode_spectral_envelope\nd4c\ndecode_aperiodicity\ndecode_spectral_envelope\ndio\nget_fftsize_for_cheaptrick\nget_number_of_aperiodicities\nharvest\ninterp1\ninterp1!\nmc2sp\nsp2mc\nstonemask\nsynthesis\n\n\n\n"
},

{
    "location": "index.html#WORLD.jl-1",
    "page": "Home",
    "title": "WORLD.jl",
    "category": "section",
    "text": "WORLD"
},

{
    "location": "index.html#Index-1",
    "page": "Home",
    "title": "Index",
    "category": "section",
    "text": "Modules = [WORLD]\nOrder = [:constant, :function, :type]"
},

{
    "location": "index.html#WORLD.cheaptrick-Tuple{Union{Base.ReshapedArray{Float64,1,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray{Float64,1},SubArray{Float64,1,A<:Union{Base.ReshapedArray{T,N,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray},I<:Tuple{Vararg{Union{Base.AbstractCartesianIndex,Colon,Int64,Range{Int64}},N}},L}},Integer,Union{Base.ReshapedArray{Float64,1,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray{Float64,1},SubArray{Float64,1,A<:Union{Base.ReshapedArray{T,N,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray},I<:Tuple{Vararg{Union{Base.AbstractCartesianIndex,Colon,Int64,Range{Int64}},N}},L}},Union{Base.ReshapedArray{Float64,1,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray{Float64,1},SubArray{Float64,1,A<:Union{Base.ReshapedArray{T,N,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray},I<:Tuple{Vararg{Union{Base.AbstractCartesianIndex,Colon,Int64,Range{Int64}},N}},L}}}",
    "page": "Home",
    "title": "WORLD.cheaptrick",
    "category": "Method",
    "text": "cheaptrick(x, fs, timeaxis, f0; opt)\n\n\nCheapTrick calculates the spectrogram that consists of spectral envelopes estimated by CheapTrick.\n\nParameters\n\nx : Input signal\nfs : Sampling frequency\ntime_axis : Time axis\nf0 : F0 contour\nopt : CheapTrick option\n\nReturns\n\nspectrogram  : Spectrogram estimated by CheapTrick.\n\n\n\n"
},

{
    "location": "index.html#WORLD.code_aperiodicity",
    "page": "Home",
    "title": "WORLD.code_aperiodicity",
    "category": "Function",
    "text": "code_aperiodicity(aperiodicity, fs, fftsize)\ncode_aperiodicity(aperiodicity, fs)\n\n\nCodeAperiodicity codes the aperiodicity. The number of dimensions is determined by fs.\n\nParameters\n\naperiodicity : Aperiodicity before coding\nfs : Sampling frequency\nfftsize : FFT size (default : get_fftsize_for_cheaptrick(fs))\n\nReturns\n\ncoded_aperiodicity : Coded aperiodicity\n\n\n\n"
},

{
    "location": "index.html#WORLD.code_spectral_envelope-Tuple{Any,Any,Any,Any}",
    "page": "Home",
    "title": "WORLD.code_spectral_envelope",
    "category": "Method",
    "text": "code_spectral_envelope(spectrogram, fs, fftsize, number_of_dimentions)\n\n\nCodeSpectralEnvelope codes the spectral envelope.\n\nParameters\n\nspectrogram : spectrogram (time sequence of spectral envelope)\nfs : Sampling frequency\nfftsize : FFT size\nnumber_of_dimentions : Number of dimentions for coded spectral envelope\n\nReturns\n\ncoded_spectral_envelope : Coded spectral envelope\n\n\n\n"
},

{
    "location": "index.html#WORLD.d4c-Tuple{Union{Base.ReshapedArray{Float64,1,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray{Float64,1},SubArray{Float64,1,A<:Union{Base.ReshapedArray{T,N,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray},I<:Tuple{Vararg{Union{Base.AbstractCartesianIndex,Colon,Int64,Range{Int64}},N}},L}},Integer,Union{Base.ReshapedArray{Float64,1,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray{Float64,1},SubArray{Float64,1,A<:Union{Base.ReshapedArray{T,N,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray},I<:Tuple{Vararg{Union{Base.AbstractCartesianIndex,Colon,Int64,Range{Int64}},N}},L}},Union{Base.ReshapedArray{Float64,1,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray{Float64,1},SubArray{Float64,1,A<:Union{Base.ReshapedArray{T,N,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray},I<:Tuple{Vararg{Union{Base.AbstractCartesianIndex,Colon,Int64,Range{Int64}},N}},L}}}",
    "page": "Home",
    "title": "WORLD.d4c",
    "category": "Method",
    "text": "d4c(x, fs, timeaxis, f0; opt)\n\n\nD4C calculates the aperiodicity estimated by D4C.\n\nParameters\n\nx : Input signal\nfs : Sampling frequency\ntime_axis : Time axis\nf0 : F0 contour\n\nReturns\n\naperiodicity : Aperiodicity estimated by D4C.\n\n\n\n"
},

{
    "location": "index.html#WORLD.decode_aperiodicity",
    "page": "Home",
    "title": "WORLD.decode_aperiodicity",
    "category": "Function",
    "text": "decode_aperiodicity(coded_aperiodicity, fs)\ndecode_aperiodicity(coded_aperiodicity, fs, fftsize)\n\n\nDecodeAperiodicity decoes the coded aperiodicity.\n\nParameters\n\ncoded_aperiodicity : Coded aperiodicity\nfs : Sampling frequency\nfftsize : FFT size (default : get_fftsize_for_cheaptrick(fs))\n\nReturns\n\naperiodicity : Decoded aperiodicity\n\n\n\n"
},

{
    "location": "index.html#WORLD.decode_spectral_envelope-Tuple{Any,Any,Any}",
    "page": "Home",
    "title": "WORLD.decode_spectral_envelope",
    "category": "Method",
    "text": "decode_spectral_envelope(coded_spectral_envelope, fs, fftsize)\n\n\nDecodeSpectralEnvelope decodes the spectral envelope.\n\nParameters\n\ncoded_spectral_envelope : Coded spectral envelope\nfs : Sampling frequency\nfftsize : FFT size\n\nReturns\n\nspectrogram : decoded spectral envelope\n\n\n\n"
},

{
    "location": "index.html#WORLD.dio",
    "page": "Home",
    "title": "WORLD.dio",
    "category": "Function",
    "text": "dio(x, fs, opt)\ndio(x, fs)\n\n\nDio estimates F0 trajectory given a monoral input signal.\n\nParemters\n\nx  : Input signal\nfs : Sampling frequency\nopt : DioOption\n\nReturns\n\ntime_axis  : Temporal positions.\nf0         : F0 contour.\n\n\n\n"
},

{
    "location": "index.html#WORLD.get_fftsize_for_cheaptrick",
    "page": "Home",
    "title": "WORLD.get_fftsize_for_cheaptrick",
    "category": "Function",
    "text": "get_fftsize_for_cheaptrick(fs)\nget_fftsize_for_cheaptrick(fs, opt)\n\n\nGetFFTSizeForCheapTrick calculates the FFT size based on the sampling frequency and the lower limit of f0 (It is defined in world.h).\n\nParameters\n\nfs: Sampling frequency\nopt: CheapTrickOption\n\nReturns\n\nfftsize : FFT size\n\n\n\n"
},

{
    "location": "index.html#WORLD.get_number_of_aperiodicities-Tuple{Any}",
    "page": "Home",
    "title": "WORLD.get_number_of_aperiodicities",
    "category": "Method",
    "text": "get_number_of_aperiodicities(fs)\n\n\nGetNumberOfAperiodicities provides the number of dimensions for aperiodicity coding. It is determined by only fs.\n\nParameters\n\nfs : Sampleing frequency\n\nReturns\n\nn : Number of aperiodicities\n\n\n\n"
},

{
    "location": "index.html#WORLD.harvest",
    "page": "Home",
    "title": "WORLD.harvest",
    "category": "Function",
    "text": "harvest(x, fs)\nharvest(x, fs, opt)\n\n\nHarvest estimates F0 trajectory given a monoral input signal.\n\nParemters\n\nx  : Input signal\nfs : Sampling frequency\nopt : HarvestOption\n\nReturns\n\ntime_axis  : Temporal positions.\nf0         : F0 contour.\n\n\n\n"
},

{
    "location": "index.html#WORLD.interp1!-Tuple{Union{Base.ReshapedArray{Float64,1,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray{Float64,1},SubArray{Float64,1,A<:Union{Base.ReshapedArray{T,N,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray},I<:Tuple{Vararg{Union{Base.AbstractCartesianIndex,Colon,Int64,Range{Int64}},N}},L}},Union{Base.ReshapedArray{Float64,1,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray{Float64,1},SubArray{Float64,1,A<:Union{Base.ReshapedArray{T,N,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray},I<:Tuple{Vararg{Union{Base.AbstractCartesianIndex,Colon,Int64,Range{Int64}},N}},L}},Union{Base.ReshapedArray{Float64,1,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray{Float64,1},SubArray{Float64,1,A<:Union{Base.ReshapedArray{T,N,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray},I<:Tuple{Vararg{Union{Base.AbstractCartesianIndex,Colon,Int64,Range{Int64}},N}},L}},Union{Base.ReshapedArray{Float64,1,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray{Float64,1},SubArray{Float64,1,A<:Union{Base.ReshapedArray{T,N,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray},I<:Tuple{Vararg{Union{Base.AbstractCartesianIndex,Colon,Int64,Range{Int64}},N}},L}}}",
    "page": "Home",
    "title": "WORLD.interp1!",
    "category": "Method",
    "text": "interp1!(x, y, xi, yi)\n\n\ninplace version of interp1\n\nParameters\n\nx : Input vector (Time axis)\ny : Values at x[n]\nxi: Required vector\nyi : Interpolated vector\n\n\n\n"
},

{
    "location": "index.html#WORLD.interp1-Tuple{Union{Base.ReshapedArray{Float64,1,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray{Float64,1},SubArray{Float64,1,A<:Union{Base.ReshapedArray{T,N,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray},I<:Tuple{Vararg{Union{Base.AbstractCartesianIndex,Colon,Int64,Range{Int64}},N}},L}},Union{Base.ReshapedArray{Float64,1,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray{Float64,1},SubArray{Float64,1,A<:Union{Base.ReshapedArray{T,N,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray},I<:Tuple{Vararg{Union{Base.AbstractCartesianIndex,Colon,Int64,Range{Int64}},N}},L}},Union{Base.ReshapedArray{Float64,1,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray{Float64,1},SubArray{Float64,1,A<:Union{Base.ReshapedArray{T,N,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray},I<:Tuple{Vararg{Union{Base.AbstractCartesianIndex,Colon,Int64,Range{Int64}},N}},L}}}",
    "page": "Home",
    "title": "WORLD.interp1",
    "category": "Method",
    "text": "interp1(x, y, xi)\n\n\ninterp1 interpolates to find yi, the values of the underlying function Y at the points in the vector or array xi. x must be a vector. http://www.mathworks.co.jp/help/techdoc/ref/interp1.html\n\nParameters\n\nx : Input vector (Time axis)\ny : Values at x[n]\nxi: Required vector\n\nReturns\n\nyi : Interpolated vector\n\n\n\n"
},

{
    "location": "index.html#WORLD.mc2sp-Tuple{AbstractArray{T,1},Any,Any}",
    "page": "Home",
    "title": "WORLD.mc2sp",
    "category": "Method",
    "text": "mc2sp(mc, α, fftlen)\n\n\nmc2sp converts mel-cepstrum to power spectrum envelope.\n\nc_alpha(m) - X(omega)^2\n\nequivalent: exp(2real(MelGeneralizedCepstrums.mgc2sp(mc, α, 0.0, fftlen))) Note that MelGeneralizedCepstrums.mgc2sp returns log magnitude spectrum.\n\n\n\n"
},

{
    "location": "index.html#WORLD.sp2mc-Tuple{AbstractArray{T,1},Any,Any}",
    "page": "Home",
    "title": "WORLD.sp2mc",
    "category": "Method",
    "text": "sp2mc(powerspec, order, α; fftlen)\n\n\nsp2mc converts power spectrum envelope to mel-cepstrum\n\nX(omega)^2 - c_alpha(m)\n\n\n\n"
},

{
    "location": "index.html#WORLD.stonemask-Tuple{Union{Base.ReshapedArray{Float64,1,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray{Float64,1},SubArray{Float64,1,A<:Union{Base.ReshapedArray{T,N,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray},I<:Tuple{Vararg{Union{Base.AbstractCartesianIndex,Colon,Int64,Range{Int64}},N}},L}},Integer,Union{Base.ReshapedArray{Float64,1,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray{Float64,1},SubArray{Float64,1,A<:Union{Base.ReshapedArray{T,N,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray},I<:Tuple{Vararg{Union{Base.AbstractCartesianIndex,Colon,Int64,Range{Int64}},N}},L}},Union{Base.ReshapedArray{Float64,1,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray{Float64,1},SubArray{Float64,1,A<:Union{Base.ReshapedArray{T,N,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray},I<:Tuple{Vararg{Union{Base.AbstractCartesianIndex,Colon,Int64,Range{Int64}},N}},L}}}",
    "page": "Home",
    "title": "WORLD.stonemask",
    "category": "Method",
    "text": "stonemask(x, fs, timeaxis, f0)\n\n\nStoneMask refines the estimated F0 by Dio,\n\nParameters\n\nx : Input signal\nfs : Sampling frequency\ntime_axis : Temporal information\nf0 : f0 contour\n\nReturns\n\nrefined_f0 : Refined F0\n\n\n\n"
},

{
    "location": "index.html#WORLD.synthesis-Tuple{Union{Base.ReshapedArray{Float64,1,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray{Float64,1},SubArray{Float64,1,A<:Union{Base.ReshapedArray{T,N,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray},I<:Tuple{Vararg{Union{Base.AbstractCartesianIndex,Colon,Int64,Range{Int64}},N}},L}},Union{Base.ReshapedArray{Float64,2,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray{Float64,2},SubArray{Float64,2,A<:Union{Base.ReshapedArray{T,N,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray},I<:Tuple{Vararg{Union{Base.AbstractCartesianIndex,Colon,Int64,Range{Int64}},N}},L}},Union{Base.ReshapedArray{Float64,2,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray{Float64,2},SubArray{Float64,2,A<:Union{Base.ReshapedArray{T,N,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray},I<:Tuple{Vararg{Union{Base.AbstractCartesianIndex,Colon,Int64,Range{Int64}},N}},L}},Real,Integer,Integer}",
    "page": "Home",
    "title": "WORLD.synthesis",
    "category": "Method",
    "text": "synthesis(f0, spectrogram, aperiodicity, period, fs, len)\n\n\nSynthesis synthesize the voice based on f0, spectrogram and aperiodicity (not excitation signal.\n\nParameters\n\nf0 : f0 contour\nspectrogram : Spectrogram estimated by CheapTrick\naperiodicity : Aperiodicity spectrogram based on D4C\nperiod :  Temporal period used for the analysis\nfs : Sampling frequency\nlen : Length of the output signal\n\nReturns\n\ny : Calculated speech\n\n\n\n"
},

{
    "location": "index.html#WORLD.CheapTrickOption",
    "page": "Home",
    "title": "WORLD.CheapTrickOption",
    "category": "Type",
    "text": "CheapTrick options\n\nFields\n\nq1\nf0floor\nfftsize\n\n\n\n"
},

{
    "location": "index.html#WORLD.D4COption",
    "page": "Home",
    "title": "WORLD.D4COption",
    "category": "Type",
    "text": "D4C options (nothing for now, but for future changes)\n\nFields\n\nthreshold\n\n\n\n"
},

{
    "location": "index.html#WORLD.DioOption",
    "page": "Home",
    "title": "WORLD.DioOption",
    "category": "Type",
    "text": "DioOption represents a set of options that is used in DIO, a fundamental frequency analysis.\n\nFields\n\nf0floor\nf0ceil\nchannels_in_octave\nperiod\nframe period in ms\nspeed\nallowed_range\nadded in v0.2.1-2 (WORLD 0.2.0_2)\n\n\n\n"
},

{
    "location": "index.html#WORLD.HarvestOption",
    "page": "Home",
    "title": "WORLD.HarvestOption",
    "category": "Type",
    "text": "HarvestOption represents a set of options that is used in Harvest, a fundamental frequency analysis.\n\nFields\n\nf0floor\nf0ceil\nperiod\nframe period in ms\n\n\n\n"
},

{
    "location": "index.html#Reference-1",
    "page": "Home",
    "title": "Reference",
    "category": "section",
    "text": "Modules = [WORLD]\nOrder = [:constant, :function, :type]"
},

]}
