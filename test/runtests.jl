using WORLD
using Base.Test
using WAV

# speech -> {f0, envelope, residual} -> speech
function testworld(x::AbstractArray, fs::Int=44100, period::Float64=5.0;
                   eps::Float64=0.1,
                   use_cheaptrick::Bool=false)
    info("fs=$(fs), period=$(period), eps=$(eps)")

    w = World(fs=fs, period=period)

    # Fundamental frequency (f0) estimation by DIO
    f0, timeaxis = dio1(w, x)
    @test !any(isnan(f0))
    @test !any(isnan(timeaxis))

    # F0 re-estimation by StoneMask
    f0 = stonemask(w, x, timeaxis, f0)
    @test !any(isnan(f0))

    # Spectral envelope estimation
    spectrogram = zeros(0,0)
    if use_cheaptrick
        spectrogram = cheaptrick(w, x, timeaxis, f0)
    else
        spectrogram = star(w, x, timeaxis, f0)
    end
    @test !any(isnan(spectrogram))

    # Residual spectrogram estimation by Platinum
    residual = platinum(w, x, timeaxis, f0, spectrogram)
    @test !any(isnan(residual))

    # Sysnthesis from f0, spectral envelope and residual spectrogram.
    y = synthesis(w, f0, spectrogram, residual, length(x))
    @test !any(isnan(y))

    @test length(y) == length(x)

    errorrate = mean(abs(y-x)) / maxabs(x)

    info("errorrate=$(errorrate)")

    @test errorrate < eps
end

# speech -> {f0, envelope, aperiodicity} -> speech
function testworld_aperiodicity(x::AbstractArray, fs::Int=44100,
                                period::Float64=5.0;
                                eps::Float64=0.1,
                                use_cheaptrick::Bool=false)
    info("fs=$(fs), period=$(period), eps=$(eps)")

    w = World(fs=fs, period=period)

    # Fundamental frequency (f0) estimation by DIO
    f0, timeaxis = dio1(w, x)
    @test !any(isnan(f0))
    @test !any(isnan(timeaxis))

    # F0 re-estimation by StoneMask
    f0 = stonemask(w, x, timeaxis, f0)
    @test !any(isnan(f0))

    # Spectral envelope estimation
    spectrogram = zeros(0,0)
    if use_cheaptrick
        spectrogram = cheaptrick(w, x, timeaxis, f0)
    else
        spectrogram = star(w, x, timeaxis, f0)
    end
    @test !any(isnan(spectrogram))

    # Aperiodicity ratio estimation
    # some bugs?
    aperiodicity = aperiodicityratio(w, x, f0, timeaxis)
    @test !any(isnan(aperiodicity))

    # Sysnthesis from f0, spectral envelope and aperiodicity ratio.
    y = synthesis_from_aperiodicity(w, f0, spectrogram, aperiodicity, length(x))
    @test !any(isnan(y))

    @test length(y) == length(x)

    errorrate = mean(abs(y-x)) / maxabs(x)

    info("errorrate=$(errorrate)")

    @test errorrate < eps
end

# Read test data (male)
fpath = joinpath(Pkg.dir("WORLD"), "test", "data", "arayuru.wav")
x, fs = wavread(fpath)
@assert size(x, 2) == 1 "The input data must be monoral."
@assert !any(isnan(x))
x = vec(x)
fs = int(fs)

# Test WORLD speech decomposition and re-synthesis with aperiodicity
for (p, e) in ([5.0, 0.135], [7.0, 0.165], [10.0, 0.165])
    testworld_aperiodicity(x, fs, p; eps=e)
    # TODO fix: some memory leak or double free?
    gc()
    testworld_aperiodicity(x, fs, p; use_cheaptrick=true, eps=e)
    gc()
end

info("aperiodicity based decomposition and synthesis tests passed.")

# Test WORLD speech decomposition and re-synthesis
# probably fail
for (p, e) in ([5.0, 0.1], [7.0, 0.165], [10.0, 0.165])
    testworld(x, fs, p; eps=e)
    gc()
    testworld(x, fs, p; use_cheaptrick=true, eps=e)
    gc()
end
