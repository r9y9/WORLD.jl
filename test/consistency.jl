# Check consistency with the original WORLD
# Note that all of the results of the original WORLD are dumped as %.16lf
# accuracy.

info("Check consistency with the original WORLD")

x = vec(readdlm("data/x.txt"))

fs = 16000
period = 5.0
w = World(fs, period)
opt = DioOption(80.0, 640.0, 2, period, 12)

# Fundamental frequency (f0) estimation by DIO
f0, timeaxis = dio(w, x; opt=opt)
f0_org = vec(readdlm("data/f0.txt"))

println("Error in DIO is $(maximum(abs(f0-f0_org)))")
@test length(f0) == length(f0_org)
@test_approx_eq_eps f0 f0_org 1.0e-15

# F0 refienment by StoneMask
f0 = stonemask(w, x, timeaxis, f0)
f0_refined_org = vec(readdlm("data/f0_refined.txt"))

println("Error in StoneMask is $(maximum(abs(f0-f0_refined_org)))")
@test length(f0) == length(f0_refined_org)
@test_approx_eq_eps f0 f0_refined_org 1.0e-15

# Spectral envelope estimation by CheapTrick
spectrogram = cheaptrick(w, x, timeaxis, f0)
spectrogram_org = readdlm("data/spectrogram.txt")'

println("Error in CheapTrick is $(maximum(abs(spectrogram - spectrogram_org)))")
@test size(spectrogram) == size(spectrogram_org)
@test_approx_eq_eps spectrogram spectrogram_org 1.0e-15

residual = platinum(w, x, timeaxis, f0, spectrogram)
residual_org = readdlm("data/residual_spectrogram.txt")'
println("Error in Platinum is $(maximum(abs(residual-residual_org)))")
@test size(residual) == size(residual_org)
@test_approx_eq_eps residual residual_org 1.0e-15

aperiodicity = aperiodicityratio(w, x, f0, timeaxis)
aperiodicity_org = readdlm("data/aperiodicity.txt")'
println("Error in aperiodicy is $(maximum(abs(aperiodicity-aperiodicity_org)))")
@test size(aperiodicity) == size(aperiodicity)
@test_approx_eq_eps aperiodicity aperiodicity_org 1.0e-15

# Synthesis
y_length = int((length(f0)-1)*period/1000 * fs) + 1
y = synthesis(w, f0, spectrogram, residual, y_length)
y_org = vec(readdlm("data/x_synthesized.txt"))
println("Error in synthesis is $(maximum(abs(y-y_org)))")
@test length(y) == length(y_org)
@test_approx_eq_eps y y_org 1.0e-15

# Synthesis from aperiodicy
y = synthesis_from_aperiodicity(w, f0, spectrogram, aperiodicity, y_length)
y_org = vec(readdlm("data/x_synthesized_from_aperiodicity.txt"))
println("Error in synthesis from aperiodicy is $(maximum(abs(y-y_org)))")
@test length(y) == length(y_org)
@test_approx_eq_eps y y_org 1.0e-15
