using BinDeps

@BinDeps.setup

world = library_dependency("libworld", aliases=["libworld", "world-0"])

const version = "0.3.1"

# TODO
if Sys.iswindows() && Sys.WORD_SIZE == 32
    error("Your platform isn't supported yet.")
end

github_root = "https://github.com/r9y9/World-cmake"
arch = Sys.WORD_SIZE == 64 ? "x86_64" : "i686"
major = version[1]
provides(Binaries,
         URI("$(github_root)/releases/download/v$(version)/WORLD-$(major)_mingw$(Sys.WORD_SIZE)_$(arch).zip"),
         world, unpacked_dir = "usr/lib", os = :Windows)

provides(Sources,
         URI("$(github_root)/archive/v$(version).tar.gz"),
         world,
         unpacked_dir="World-cmake-$(version)")

prefix = joinpath(BinDeps.depsdir(world), "usr")
srcdir = joinpath(BinDeps.depsdir(world), "src", "World-cmake-$(version)")
builddir = joinpath(srcdir, "build")

provides(SimpleBuild,
          (@build_steps begin
              GetSources(world)
              @build_steps begin
                  ChangeDirectory(builddir)
                  `cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=$prefix ..`
                  `make`
                  `make install`
              end
           end), world, os = :Unix)

@BinDeps.install Dict(:libworld => :libworld)
