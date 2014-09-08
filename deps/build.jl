using BinDeps

@BinDeps.setup

deps = [
        world = library_dependency("libworld")
        ]

const version = "0.1.4_1"

provides(Sources,
         URI("https://github.com/r9y9/world/archive/v.$(version).tar.gz"),
         world,
         unpacked_dir="world-v.$(version)")

prefix = joinpath(BinDeps.depsdir(world), "usr")
srcdir = joinpath(BinDeps.depsdir(world), "src", "world-v.$(version)")

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
