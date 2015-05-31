using BinDeps

@BinDeps.setup

deps = [
        world = library_dependency("libworld")
        ]

const version = "0.2.0_1"

provides(Sources,
         URI("https://github.com/r9y9/WORLD/archive/v$(version).tar.gz"),
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

@BinDeps.install [:libworld => :libworld]
