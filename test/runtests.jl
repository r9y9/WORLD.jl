using WORLD
using Base.Test
using WAV

function test_dio(x, fs::Int=44100, period::Float64=5.0)
    info("test_dio: fs=$(fs), period=$(period)")
    w = World(fs=fs, period=period)
    opt = DioOption(80.0, 640.0, 2, period, 4)
    f0, timeaxis = dio(w, x; opt=opt)
    @test !any(isnan(f0))
    @test !any(isnan(timeaxis))
end

function test_dio1(x, fs::Int=44100, period::Float64=5.0)
    info("test_dio1: fs=$(fs), period=$(period)")
    w = World(fs=fs, period=period)
    f0, timeaxis = dio1(w, x)
    @test !any(isnan(f0))
    @test !any(isnan(timeaxis))
end

function test_stonemask(x, fs::Int=44100, period::Float64=5.0)
    info("test_stonemask: fs=$(fs), period=$(period)")
    w = World(fs=fs, period=period)
    opt = DioOption(80.0, 640.0, 2, period, 4)
    f0, timeaxis = dio(w, x; opt=opt)
    f0 = stonemask(w, x, timeaxis, f0)
    @test !any(isnan(f0))
end

function test_envelope(x, fs::Int=44100, period::Float64=5.0,
                       usecheaptrick::Bool=true)
    w = World(fs=fs, period=period)
    opt = DioOption(80.0, 640.0, 2, period, 4)
    f0, timeaxis = dio(w, x; opt=opt)
    f0 = stonemask(w, x, timeaxis, f0)
    spectrogram = zeros(0, 0)
    if usecheaptrick
        spectrogram = cheaptrick(w, x, timeaxis, f0)
    else
        spectrogram = star(w, x, timeaxis, f0)
    end
    @test !any(isnan(spectrogram))
end

function test_cheaptrick(x, fs::Int=44100, period::Float64=5.0)
    info("test_cheaptrick: fs=$(fs), period=$(period)")
    test_envelope(x, fs, period, true)
end

function test_star(x, fs::Int=44100, period::Float64=5.0)
    info("test_star: fs=$(fs), period=$(period)")
    test_envelope(x, fs, period, false)
end

function test_platinum(x, fs::Int=44100, period::Float64=5.0)
    info("test_platinum: fs=$(fs), period=$(period)")
    w = World(fs=fs, period=period)
    opt = DioOption(80.0, 640.0, 2, period, 4)
    f0, timeaxis = dio(w, x; opt=opt)
    f0 = stonemask(w, x, timeaxis, f0)
    spectrogram = cheaptrick(w, x, timeaxis, f0)
    residual = platinum(w, x, timeaxis, f0, spectrogram)
    @test !any(isnan(residual))
end

function test_aperiodicity(x, fs::Int=44100, period::Float64=5.0)
    info("test_aperiodicity: fs=$(fs), period=$(period)")
    w = World(fs=fs, period=period)
    opt = DioOption(80.0, 640.0, 2, period, 4)
    f0, timeaxis = dio(w, x; opt=opt)
    f0 = stonemask(w, x, timeaxis, f0)
    aperiodicity = aperiodicityratio(w, x, f0, timeaxis)
    @test !any(isnan(aperiodicity))
end

# speech -> {f0, envelope, residual} -> speech
function test_synthesis(x::AbstractArray, fs::Int=44100, period::Float64=5.0,
                        usecheaptrick::Bool=false, tol::Float64=0.1,)
    info("test_synthesis: fs=$(fs), period=$(period),
         usecheaptrick=$(usecheaptrick), tol=$(tol)")

    w = World(fs=fs, period=period)
    opt = DioOption(80.0, 640.0, 2, period, 4)

    # Fundamental frequency (f0) estimation by DIO
    f0, timeaxis = dio(w, x; opt=opt)
    @test !any(isnan(f0))
    @test !any(isnan(timeaxis))

    # F0 re-estimation by StoneMask
    f0 = stonemask(w, x, timeaxis, f0)
    @test !any(isnan(f0))

    # Spectral envelope estimation
    spectrogram = zeros(0, 0)
    if usecheaptrick
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

    @test errorrate < tol
end

# speech -> {f0, envelope, aperiodicity} -> speech
function test_aperiodicity_synthesis(x::AbstractArray, fs::Int=44100,
                                     period::Float64=5.0,
                                     usecheaptrick::Bool=true,
                                     tol::Float64=0.1)
    info("test_aperiodicity_synthesis: fs=$(fs), period=$(period),
         usecheaptrick=$(usecheaptrick), tol=$(tol)")

    w = World(fs=fs, period=period)
    opt = DioOption(80.0, 640.0, 2, period, 4)

    # Fundamental frequency (f0) estimation by DIO
    f0, timeaxis = dio(w, x; opt=opt)
    @test !any(isnan(f0))
    @test !any(isnan(timeaxis))

    # F0 re-estimation by StoneMask
    f0 = stonemask(w, x, timeaxis, f0)
    @test !any(isnan(f0))

    # Spectral envelope estimation
    spectrogram = zeros(0, 0)
    if usecheaptrick
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

    @test errorrate < tol
end

# Read test data (male)
fpath = joinpath(Pkg.dir("WORLD"), "test", "data", "arayuru.wav")
x, fs = wavread(fpath)
@assert size(x, 2) == 1 "The input data must be monoral."
@assert !any(isnan(x))
x = vec(x)
fs = int(fs)

for period in [5.0, 7.0, 10.0]
    test_dio(x, fs, period)
    test_dio1(x, fs, period)
    test_stonemask(x, fs, period)
    test_cheaptrick(x, fs, period)
    test_star(x, fs, period)
    test_aperiodicity(x, fs, period)
    gc()
end

# Test WORLD speech decomposition and re-synthesis with aperiodicity
for (period, tol) in ([5.0, 0.135], [7.0, 0.165], [10.0, 0.165])
    test_aperiodicity_synthesis(x, fs, period, true, tol)
    # TODO fix: some memory leak or double free?
    gc()
    test_aperiodicity_synthesis(x, fs, period, false, tol)
    gc()
end

info("aperiodicity based decomposition and synthesis tests passed.")

# Test WORLD speech decomposition and re-synthesis
for (period, tol) in ([5.0, 0.1], [7.0, 0.165], [10.0, 0.165])
    test_synthesis(x, fs, period, true, tol)
    gc()
    test_synthesis(x, fs, period, false, tol)
    gc()
end
