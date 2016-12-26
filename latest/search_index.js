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
    "text": "A lightweitht julia wrapper for WORLD\n\na high-quality speech analysis, manipulation and\n\nsynthesis system. WORLD provides a way to decompose a speech signal into:\n\nFundamental frequency (F0)\nspectral envelope\naperiodicity\n\nand re-synthesize a speech signal from these paramters. Please see the project page for more details on the WORLD.\n\nnote: Note\nWORLD.jl is based on a modified version of WORLD (r9y9/WORLD).\n\nhttps://github.com/r9y9/WORLD.jl\n\nUsage\n\nIn the following examples, suppose x::Vector{Float64} is a input monoral speech signal like:\n\n(Image: )\n\nF0 estimation and refinement\n\nDIO\n\nopt = DioOption(f0floor=71.0, f0ceil=800.0, channels_in_octave=2.0,\n        period=period, speed=1)\nf0, timeaxis = dio(x, fs, opt)\n\n(Image: )\n\nStoneMask\n\nf0 = stonemask(x, fs, timeaxis, f0)\n\n(Image: )\n\nSpectral envelope estimation by CheapTrick\n\nspectrogram = cheaptrick(x, fs, timeaxis, f0)\n\n(Image: )\n\nAperiodicity ratio estimation by D4C\n\naperiodicity = d4c(x, fs, timeaxis, f0)\n\n(Image: )\n\nSynthesis\n\ny = synthesis(f0, spectrogram, aperiodicity, period, fs, length(x))\n\n(Image: )\n\nCompact speech parameterization\n\nRaw spectrum envelope and aperiodicity spectrum are relatively high dimentional (offen more than 513 or 1025) so one might want to get more compact representation. To do so, mel-cepstrum could be a good choice. As far as I know, this would be useful in statistical speech synthesis and statistical voice conversion.\n\nspectrum envelope to mel-cepstrum\n\nmc = sp2mc(spectrogram, order, α) # e.g. order=40, α=0.41\n\nwhere order is the order of mel-cepstrum (except for 0th) and α is a frequency warping parameter.\n\n(Image: )\n\nmel-cepstrum to spectrum envelope\n\napproximate_spectrogram = mc2sp(mc, α, get_fftsize_for_cheaptrick(fs))\n\n(Image: )\n\naperiodicity spectrum to aperiodicity mel-cesptrum\n\nap_mc = sp2mc(aperiodicity, order, α) # e.g. order=40, α=0.41\n\n(Image: )\n\nnote: Note\nHTS v2.3 beta seems to parameterize aperiodicity spectrum in this way (but does this really make sense?).\n\naperiodicity mel-cepstrum to aperiodicity spectrum\n\napproximate_aperiodicity = mc2sp(ap_mc, α, get_fftsize_for_cheaptrick(fs))\n\n(Image: )\n\nFor the complete code of visualizations shown above, please check the IJulia notebook.\n\nExports\n\nCheapTrickOption\nD4COption\nDioOption\ncheaptrick\nd4c\ndio\nget_fftsize_for_cheaptrick\ninterp1\ninterp1!\nmc2sp\nsp2mc\nstonemask\nsynthesis\n\n\n\n"
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
    "location": "index.html#WORLD.d4c-Tuple{Union{Base.ReshapedArray{Float64,1,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray{Float64,1},SubArray{Float64,1,A<:Union{Base.ReshapedArray{T,N,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray},I<:Tuple{Vararg{Union{Base.AbstractCartesianIndex,Colon,Int64,Range{Int64}},N}},L}},Integer,Union{Base.ReshapedArray{Float64,1,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray{Float64,1},SubArray{Float64,1,A<:Union{Base.ReshapedArray{T,N,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray},I<:Tuple{Vararg{Union{Base.AbstractCartesianIndex,Colon,Int64,Range{Int64}},N}},L}},Union{Base.ReshapedArray{Float64,1,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray{Float64,1},SubArray{Float64,1,A<:Union{Base.ReshapedArray{T,N,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray},I<:Tuple{Vararg{Union{Base.AbstractCartesianIndex,Colon,Int64,Range{Int64}},N}},L}}}",
    "page": "Home",
    "title": "WORLD.d4c",
    "category": "Method",
    "text": "d4c(x, fs, timeaxis, f0; opt)\n\n\nD4C calculates the aperiodicity estimated by D4C.\n\nParameters\n\nx : Input signal\nfs : Sampling frequency\ntime_axis : Time axis\nf0 : F0 contour\n\nReturns\n\naperiodicity : Aperiodicity estimated by D4C.\n\n\n\n"
},

{
    "location": "index.html#WORLD.dio",
    "page": "Home",
    "title": "WORLD.dio",
    "category": "Function",
    "text": "dio(x, fs, opt)\ndio(x, fs)\n\n\nDio estimates F0 trajectory given a monoral input signal.\n\nParemters\n\nx  : Input signal\nfs : Sampling frequency\nopt : DioOption\n\nReturns\n\ntime_axis  : Temporal positions.\nf0         : F0 contour.\n\n\n\n"
},

{
    "location": "index.html#WORLD.get_fftsize_for_cheaptrick-Tuple{Integer}",
    "page": "Home",
    "title": "WORLD.get_fftsize_for_cheaptrick",
    "category": "Method",
    "text": "get_fftsize_for_cheaptrick(fs)\n\n\nGetFFTSizeForCheapTrick calculates the FFT size based on the sampling frequency and the lower limit of f0 (It is defined in world.h).\n\nParameters\n\nfs: Sampling frequency\n\nReturns\n\nfftsize : FFT size\n\n\n\n"
},

{
    "location": "index.html#WORLD.interp1!-NTuple{4,Union{Base.ReshapedArray{Float64,1,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray{Float64,1},SubArray{Float64,1,A<:Union{Base.ReshapedArray{T,N,A<:DenseArray,MI<:Tuple{Vararg{Base.MultiplicativeInverses.SignedMultiplicativeInverse{Int64},N}}},DenseArray},I<:Tuple{Vararg{Union{Base.AbstractCartesianIndex,Colon,Int64,Range{Int64}},N}},L}}}",
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
    "text": "CheapTrick options\n\nFields\n\nq1\n\n\n\n"
},

{
    "location": "index.html#WORLD.D4COption",
    "page": "Home",
    "title": "WORLD.D4COption",
    "category": "Type",
    "text": "D4C options (nothing for now, but for future changes)\n\nFields\n\ndummy\n\n\n\n"
},

{
    "location": "index.html#WORLD.DioOption",
    "page": "Home",
    "title": "WORLD.DioOption",
    "category": "Type",
    "text": "DioOption represents a set of options that is used in DIO, a fundamental frequency analysis.\n\nFields\n\nf0floor\nf0ceil\nchannels_in_octave\nperiod\nframe period in ms\nspeed\nallowed_range\nadded in v0.2.1-2 (WORLD 0.2.0_2)\n\n\n\n"
},

{
    "location": "index.html#Reference-1",
    "page": "Home",
    "title": "Reference",
    "category": "section",
    "text": "Modules = [WORLD]\nOrder = [:constant, :function, :type]"
},

]}
