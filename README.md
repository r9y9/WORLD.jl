# WORLD.jl

[![WORLD](http://pkg.julialang.org/badges/WORLD_0.3.svg)](http://pkg.julialang.org/?pkg=WORLD&ver=0.3)
[![WORLD](http://pkg.julialang.org/badges/WORLD_0.4.svg)](http://pkg.julialang.org/?pkg=WORLD&ver=0.4)
[![WORLD](http://pkg.julialang.org/badges/WORLD_0.5.svg)](http://pkg.julialang.org/?pkg=WORLD&ver=0.5)

[![Build Status](https://travis-ci.org/r9y9/WORLD.jl.svg?branch=master)](https://travis-ci.org/r9y9/WORLD.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/j6xrcx8s6wyahacs/branch/master?svg=true)](https://ci.appveyor.com/project/r9y9/world-jl/branch/master)
[![Coverage Status](https://coveralls.io/repos/r9y9/WORLD.jl/badge.svg?branch=master)](https://coveralls.io/r/r9y9/WORLD.jl?branch=master)
[![License](http://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat)](LICENSE.md)

WORLD.jl is a Julia wrapper for [WORLD](http://ml.cs.yamanashi.ac.jp/world/english/index.html) - a high-quality speech analysis, manipulation and synthesis system. WORLD provides a way to decompose a speech signal into

- Fundamental frequency (F0)
- spectral envelope
- aperiodicity

and re-synthesize a speech signal from these paramters. Please see the project page for more details on the WORLD.

**NOTE**: WORLD.jl is based on a modified version of WORLD ([r9y9/WORLD](https://github.com/r9y9/WORLD)).

## Supported Platforms

- Linux
- Mac OS X
- Windows

## Installation

Run the following commands on your julia interactive settion (REPL):

```julia
julia> Pkg.add("WORLD")
```

if you want the latest master, run

```julia
julia> Pkg.clone("https://github.com/r9y9/WORLD.jl")
julia> Pkg.build("WORLD")
```

All dependencies are resolved with `Pkg.clone` and `Pkg.build`.

## Documentation

- [**STABLE**][docs-stable-url] &mdash; **most recently tagged version of the documentation.**
- [**LATEST**][docs-latest-url] &mdash; *in-development version of the documentation.*

[docs-latest-url]: https://r9y9.github.io/WORLD.jl/latest
[docs-stable-url]: https://r9y9.github.io/WORLD.jl/stable
