using Documenter, WORLD

makedocs(
    modules = [WORLD],
    clean   = false,
    format   = :html,
    sitename = "WORLD.jl",
    pages = Any["Home" => "index.md"],
)

deploydocs(
    target = "build",
    deps = nothing,
    make = nothing,
    repo = "github.com/r9y9/WORLD.jl.git",
)
