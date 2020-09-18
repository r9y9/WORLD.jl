using Documenter, WORLD

makedocs(
    modules = [WORLD],
    clean   = false,
    sitename = "WORLD.jl",
    pages = ["Home" => "index.md"],
)

deploydocs(
    target = "build",
    deps = nothing,
    make = nothing,
    repo = "github.com/r9y9/WORLD.jl.git",
)
