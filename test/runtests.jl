using WORLD
using Compat
using Base.Test

@show WORLD.version

# Check consistency of the results between WORLD and WORLD.jl.
# Due to the results of the WORLD were dumped (see ./data) on linux,
# we test consistency only on linux.
@static is_linux() ? include("consistency.jl") : nothing

function test_dio(x, fs::Int=44100, period::Float64=5.0)
    println("test_dio: fs=$(fs), period=$(period)")
    opt = DioOption(71.0, 800.0, 2, period, 1)
    f0, timeaxis = dio(x, fs, opt)
    @test @compat all(isfinite.(f0))
    @test all(f0 .>= 0.0)
    @test @compat all(isfinite.(timeaxis))
end

function test_stonemask(x, fs::Int=44100, period::Float64=5.0)
    println("test_stonemask: fs=$(fs), period=$(period)")
    opt = DioOption(71.0, 800.0, 2, period, 1)
    f0, timeaxis = dio(x, fs, opt)
    f0 = stonemask(x, fs, timeaxis, f0)
    @test @compat all(isfinite.(f0))
    @test all(f0 .>= 0.0)
end

function test_cheaptrick(x, fs::Int=44100, period::Float64=5.0)
    println("test_cheaptrick: fs=$(fs), period=$(period)")
    opt = DioOption(71.0, 800.0, 2, period, 1)
    f0, timeaxis = dio(x, fs, opt)
    f0 = stonemask(x, fs, timeaxis, f0)
    spectrogram = cheaptrick(x, fs, timeaxis, f0)
    @test @compat all(isfinite.(spectrogram))
end

function test_d4c(x, fs::Int=44100, period::Float64=5.0)
    println("test_d4c: fs=$(fs), period=$(period)")
    opt = DioOption(71.0, 800.0, 2, period, 1)
    f0, timeaxis = dio(x, fs, opt)
    f0 = stonemask(x, fs, timeaxis, f0)
    aperiodicity = d4c(x, fs, timeaxis, f0)
    @test @compat all(isfinite.(aperiodicity))
end

# speech -> {f0, envelope, aperiodicity} -> speech
function test_synthesis(x::AbstractArray, fs::Int=44100,
                        period::Float64=5.0,
                        tol::Float64=0.1)
    println("test_synthesis: fs=$(fs), period=$(period), tol=$(tol)")

    opt = DioOption(71.0, 800.0, 2, period, 1)

    # Fundamental frequency (f0) estimation by DIO
    f0, timeaxis = dio(x, fs, opt)
    @test @compat all(isfinite.(f0))
    @test @compat all(isfinite.(timeaxis))

    # F0 re-estimation by StoneMask
    f0 = stonemask(x, fs, timeaxis, f0)
    @test @compat all(isfinite.(f0))

    # Spectral envelope estimation
    spectrogram = cheaptrick(x, fs, timeaxis, f0)
    @test @compat all(isfinite.(spectrogram))

    # Aperiodicity ratio estimation by D4C
    aperiodicity = d4c(x, fs, timeaxis, f0)
    @test @compat all(isfinite.(aperiodicity))

    # Sysnthesis from f0, spectral envelope and aperiodicity ratio.
    y_length = convert(Int, (length(f0)-1)*period/1000 * fs + 1)
    y = synthesis(f0, spectrogram, aperiodicity, period, fs, length(x))
    @test @compat all(isfinite.(y))

    minlen = min(length(x), length(y))
    errorrate = @compat mean(abs.(y[1:minlen]-x[1:minlen])) / maximum(abs, x[1:minlen])

    println("errorrate=$(errorrate)")

    @test errorrate < tol
end

# Read test data (male)
x = vec(readdlm(joinpath(dirname(@__FILE__), "data", "x.txt")))
fs = 16000

for period in [5.0, 7.0, 10.0]
    test_dio(x, fs, period)
    test_stonemask(x, fs, period)
    test_cheaptrick(x, fs, period)
    test_d4c(x, fs, period)
end

# Test WORLD speech decomposition and re-synthesis
for (period, tol) in ([5.0, 0.15],[10.0, 0.16])
    test_synthesis(x, fs, period, tol)
end

println("WORLD decomposition and re-synthesis tests passed.")

# spectrum envelop <-> mel-cepstrum conversion

let
    @assert fs == 16000
    f0, timeaxis = dio(x, fs)
    f0 = stonemask(x, fs, timeaxis, f0)
    spectrogram = cheaptrick(x, fs, timeaxis, f0)
    spec = spectrogram[:,30]

    α = 0.41
    fftlen = get_fftsize_for_cheaptrick(fs)

    # check normalized mean squared error
    approximate_spec = mc2sp(sp2mc(spec, 25, α), α, fftlen)
    nmse25 = @compat norm(log.(spec) - log.(approximate_spec)) / @compat norm(log.(spec))
    @test nmse25 <= 0.06

    approximate_spec = mc2sp(sp2mc(spec, 30, α), α, fftlen)
    nmse30 = @compat norm(log.(spec) - log.(approximate_spec)) / @compat norm(log.(spec))
    @test nmse30 <= 0.05

    approximate_spec = mc2sp(sp2mc(spec, 40, α), α, fftlen)
    nmse40 = @compat norm(log.(spec) - log.(approximate_spec)) / @compat norm(log.(spec))
    @test nmse40 <= 0.03

    @test nmse25 > nmse30 > nmse40

    # For matrix input
    spec_mat = spectrogram[:,30:31]
    approximate_spec_mat = mc2sp(sp2mc(spec_mat, 25, α), α, fftlen)
    @test_approx_eq approximate_spec_mat[:,1] mc2sp(sp2mc(spec_mat[:,1], 25, α), α, fftlen)
    @test_approx_eq approximate_spec_mat[:,2] mc2sp(sp2mc(spec_mat[:,2], 25, α), α, fftlen)
end

# get_fftsize

for fs in [16000, 20000]
    c = get_fftsize_for_cheaptrick(fs)
    @test c == 1024
end

for fs in [44100, 48000]
    c = get_fftsize_for_cheaptrick(fs)
    @test c == 2048
end

# DioOption

let
    try DioOption(); catch @test false; end

    # keyword arguments
    try DioOption(f0floor=60.0); catch @test false; end
    try DioOption(f0ceil=600.0); catch @test false; end
    try DioOption(channels_in_octave=2.0); catch @test false; end
    try DioOption(period=10.0); catch @test false; end
    try DioOption(speed=5); catch @test false; end

    # f0loor
    @test_throws ArgumentError DioOption(-1,  100, 2.0, 5.0, 11)
    @test_throws ArgumentError DioOption(200, 100, 2.0, 5.0, 11)
    # channels in octave
    @test_throws ArgumentError DioOption(80.0, 640.0, -1.0, 5.0, 11)
    # period
    @test_throws ArgumentError DioOption(80.0, 640.0, 2.0, -1.0, 11)
    @test_throws ArgumentError DioOption(80.0, 640.0, 2.0, 0.0, 11)
    # speed
    try DioOption(80.0, 640.0, 2.0, 5.0, 1); catch @test false; end
    try DioOption(80.0, 640.0, 2.0, 5.0, 12); catch @test false; end
    @test_throws ArgumentError DioOption(80.0, 640.0, 2.0, 5.0, 0)
    @test_throws ArgumentError DioOption(80.0, 640.0, 2.0, 5.0, 13)
    # allowed_range
    if WORLD.version >= v"0.2.1-2"
        try DioOption(allowed_range=0.1); catch @test false; end
        try DioOption(71.0, 800.0, 2.0, 5.0, 1, 0.0); catch @test false; end
        @test_throws ArgumentError DioOption(80.0, 640.0, 2.0, 5.0, 0, -1.0)
    end
end

# matlabfunctions

let
    opt = DioOption(71.0, 800.0, 2, 5.0, 1)
    f0, timeaxis = dio(x, fs, opt)
    spectrogram = cheaptrick(x, fs, timeaxis, f0)

    logspec = @compat(log.(spectrogram[:,100]))
    if isa(logspec, Array{Any,1})
        warn("huaaa, remove this after dropping v0.4")
        logspec = convert(Vector{Float64}, logspec)
    end
    fftsize = get_fftsize_for_cheaptrick(fs)

    freqaxis_src = collect(1:(fftsize>>1+1)) / fftsize * fs
    freqaxis_dst = freqaxis_src .* 2/3

    # spectral stretching
    interpolated_logspec = interp1(freqaxis_src, logspec, freqaxis_dst)
    @test @compat all(isfinite.(interpolated_logspec))

    interpolated_spec = @compat exp.(interpolated_logspec)

    interpolated_logspec2 = similar(logspec)
    interp1!(freqaxis_src, logspec, freqaxis_dst, interpolated_logspec2)
    @test interpolated_logspec == interpolated_logspec2
end
