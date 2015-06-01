# deprecates related to the version up from WORLD v0.1.4 to v0.2.0

export
    star,
    platinum,
    aperiodicityratio,
    synthesis_from_aperiodicity

# Since `libworld.0.2.0` doesn't provide an interface to Platinum,
# I decided `platinum` simply throws an error for deprecation.
function platinum(x, fs, timeaxis, f0, spectrogram)
    error("Platinum was removed since WORLD v0.2.0. Please use d4c for aperiodicity (not excitation) estimation.")
end

@deprecate star cheaptrick
@deprecate aperiodicityratio(x, fs, f0, timeaxis) d4c(x, fs, timeaxis, f0)
@deprecate synthesis_from_aperiodicity synthesis
@deprecate get_fftsize_for_star(fs) get_fftsize_for_cheaptrick(fs)
