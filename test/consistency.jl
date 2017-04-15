# Check consistency with the original WORLD
# Ground truth data was genearted using `generate_groundtruth.sh` in
# https://github.com/r9y9/WORLD
# Note that all of the results of the original WORLD were dumped as %.16lf
# accuracy on Ubuntu 14.04 64bit machine. g++ v4.9.2 was used to compile the
# WORLD.

@assert WORLD.version >= v"0.2.1-4"

info("Check consistency with the original WORLD")

x = vec(readdlm(joinpath(dirname(@__FILE__), "data", "x.txt")))

fs = 16000
period = 5.0
opt = DioOption(71.0, 800.0, 2, period, 1, 0.1) # 0.1 = 0.02 * 5.0

# Fundamental frequency (f0) estimation by DIO
f0, timeaxis = dio(x, fs, opt)
f0_org = vec(readdlm(joinpath(dirname(@__FILE__), "data", "f0.txt")))

println("Maximum error in DIO is $(maximum(abs.(f0-f0_org)))")
@test length(f0) == length(f0_org)
@test_approx_eq_eps f0 f0_org 1.0e-10

# F0 refienment by StoneMask
f0 = stonemask(x, fs, timeaxis, f0)
f0_refined_org = vec(readdlm(joinpath(dirname(@__FILE__), "data", "f0_refined.txt")))

println("Maximum error in StoneMask is $(maximum(abs.(f0-f0_refined_org)))")
@test length(f0) == length(f0_refined_org)
@test_approx_eq_eps f0 f0_refined_org 1.0e-10

# Spectral envelope estimation by CheapTrick
spectrogram = cheaptrick(x, fs, timeaxis, f0; opt=CheapTrickOption(-0.15))
spectrogram_org = readdlm(joinpath(dirname(@__FILE__), "data", "spectrogram.txt"))'

println("Maximum error in CheapTrick is $(maximum(abs.(spectrogram - spectrogram_org)))")
@test size(spectrogram) == size(spectrogram_org)
@test_approx_eq_eps spectrogram spectrogram_org 1.0e-10

aperiodicity = d4c(x, fs, timeaxis, f0; opt=D4COption())
aperiodicity_org = readdlm(joinpath(dirname(@__FILE__), "data", "aperiodicity.txt"))'
println("Maximum error in D4C is $(maximum(abs.(aperiodicity-aperiodicity_org)))")
@test size(aperiodicity) == size(aperiodicity)
@test_approx_eq_eps aperiodicity aperiodicity_org 1.0e-10

# Synthesis
y_length = convert(Int, ((length(f0)-1)*period/1000 * fs) + 1)
y = synthesis(f0, spectrogram, aperiodicity, period, fs, y_length)
y_org = vec(readdlm(joinpath(dirname(@__FILE__), "data", "x_synthesized.txt")))
println("Maximum error in Synthesis is $(maximum(abs.(y-y_org)))")
@test length(y) == length(y_org)
@test_approx_eq_eps y y_org 1.0e-10
