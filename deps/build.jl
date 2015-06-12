using BinDeps
using Compat

@BinDeps.setup

world = library_dependency("libworld", aliases=["libworld", "world-0"])

const version = "0.2.1-2"

github_root = "https://github.com/r9y9/WORLD"
arch = WORD_SIZE == 64 ? "x86_64" : "i686"
major = version[1]
provides(Binaries,
         URI("$(github_root)/releases/download/v$(version)/world-$(major)_$(arch).zip"),
         world, unpacked_dir = "usr/lib", os = :Windows)

provides(Sources,
         URI("$(github_root)/archive/v$(version).tar.gz"),
         world,
         unpacked_dir="WORLD-$(version)")

prefix = joinpath(BinDeps.depsdir(world), "usr")
srcdir = joinpath(BinDeps.depsdir(world), "src", "WORLD-$(version)")

provides(SimpleBuild,
          (@build_steps begin
              GetSources(world)
              @build_steps begin
                  ChangeDirectory(srcdir)
                  `./waf configure --prefix=$prefix`
                  `./waf build`
                  `./waf install`
              end
           end), world, os = :Unix)

@BinDeps.install @compat Dict(:libworld => :libworld)
