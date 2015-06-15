module WORLD

# A light-weight julia wrapper for WORLD.

export
    # Types
    DioOption,

    # WORLD functions
    dio,
    stonemask,
    cheaptrick,
    d4c,
    synthesis,

    # utils
    get_fftsize_for_cheaptrick,

    # matlab functions
    interp1!,
    interp1,

    # conversion
    sp2mc,  # spectrum envelope to mel-cesptrum
    mc2sp   # mel-cepstrum to spectrum envelope

# Dependency
deps = joinpath(Pkg.dir("WORLD"), "deps", "deps.jl")
if isfile(deps)
    include(deps)
else
    error("WORLD not properly installed. Please run Pkg.build(\"WORLD\")")
end

try
    # function GetWORLDVersion was added in v0.2.1-2
    versionstr = bytestring(ccall((:GetWORLDVersion, libworld), Ptr{Cchar}, ()))
    global const version = convert(VersionNumber, versionstr)
catch e
    try
        ccall((:GetFFTSizeForStar, libworld), Cint, (Cint,), 48000)
        global const version = v"0.1.4"
    catch e
        global const version = v"0.2.0"
    end
end

if version < v"0.2.0"
    warn("""WORLD version incompatibility

         WORLD version 0.2.0 or later is recommended, but the detected version
         is $(version)). If you have WORLD installed, please get the latest
         stable WORLD and upgrade it, or re-build WORLD.jl with the following
         commands from REPL:

         julia> rm(joinpath(Pkg.dir(\"WORLD\"),  \"deps\", \"deps.jl\"))
         julia> Pkg.build(\"WORLD\")

         This should install the proper version of WORLD.
         """)
end

include("bridge.jl")
include("mcep.jl")
include("deprecated.jl")

end # module WORLD
