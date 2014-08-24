using WORLD
using Base.Test
using WAV

# speech -> {f0, envelope, residual} -> speech
function testworld(;use_cheaptrick=false, fs=44100, period=5.0, eps=0.1)
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
  spectrogram = Matrix{Float64}
  if use_cheaptrick
    # CheapTrick
    spectrogram = cheaptrick(w, x, timeaxis, f0)
  else
    # Star
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
function testworld_aperiodicity(;use_cheaptrick=false, fs=44100, period=5.0,
                               eps=0.1)
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
  spectrogram = Matrix{Float64}
  if use_cheaptrick
    # CheapTrick
    spectrogram = cheaptrick(w, x, timeaxis, f0)
  else
    # Star
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
@test !any(isnan(x))

# arayuru.wav is a monoral wav file
x = x[:] # Array{Float64,2} -> Array{Float64,1}

# Test WORLD speech decomposition and re-synthesis with aperiodicity
for (p, e) in ([5.0, 0.135], [7.0, 0.165], [10.0, 0.165])
  testworld_aperiodicity(fs=fs, period=p, eps=e)
  testworld_aperiodicity(fs=fs, period=p, use_cheaptrick=true, eps=e)
end

info("aperiodicity based decomposition and synthesis tests passed.")

# Test WORLD speech decomposition and re-synthesis
# probably fail
for (p, e) in ([5.0, 0.1], [7.0, 0.165], [10.0, 0.165])
  testworld(fs=fs, period=p, eps=e)
  testworld(fs=fs, period=p, use_cheaptrick=true, eps=e)
end
