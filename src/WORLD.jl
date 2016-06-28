VERSION >= v"0.4.0-dev+6521" && __precompile__()

module WORLD

using Compat

# A light-weight julia wrapper for WORLD.

export
    # Types
    DioOption,
    CheapTrickOption,
    D4COption,

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


### Binary dependency loading ###
deps = joinpath(Pkg.dir("WORLD"), "deps", "deps.jl")
if isfile(deps)
    include(deps)
else
    error("WORLD not properly installed. Please run Pkg.build(\"WORLD\")")
end

### Check binary dependency compatibility ###
# This should prevent segfaults when you are using WORLD on system paths (e.g.
# /usr/local/lib/libworld.so) and accidentaly change the verion of WORLD.
try
    # function GetWORLDVersion was added in v0.2.1-2
    versionstr = unsafe_string(ccall((:GetWORLDVersion, libworld), Ptr{Cchar}, ()))
    global const version = convert(VersionNumber, versionstr)
catch e
    try
        ccall((:GetFFTSizeForStar, libworld), Cint, (Cint,), 48000)
        version = v"0.1.4"
    catch e
        version = v"0.2.0"
    end
end

# v0.2.1-4 breaks API of CheapTrick and D4C, and it's hard to support both old
# and new WORLD library, so throws an error when older version of WORLD is
# detected.
if version < v"0.2.1-4"
    error("""Binary dependency incompatibility

          WORLD version 0.2.1-4 or later must be required ($(version) is detected).
          If you have WORLD installed on your system paths, please get the latest
          stable WORLD and install it, and then re-build WORLD.jl with:

          julia>  Pkg.build(\"WORLD\")

          If not, simpily re-building WORLD.jl with the above command. This
          should install the proper version of WORLD.

          If you want to use WORLD.jl with older WORLD, please downgrade WORLD.jl
          for your need. E.g.

          julia> cd(Pkg.dir(\"WORLD\"))
          shell> git checkout v0.1.3 # that supprts v0.2.0 to v0.2.1-3.
         """)
end

for name in ["bridge", "mcep", "deprecated"]
    include(string(name, ".jl"))
end

end # module WORLD
