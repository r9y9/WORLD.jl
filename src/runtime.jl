### Runtime initialization ###

# Check binary dependency compatibility

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
