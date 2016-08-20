using Documenter, WORLD

makedocs(
    modules = [WORLD],
    clean   = false,
    format   = Documenter.Formats.HTML,
    sitename = "WORLD.jl",
    pages = Any["Home" => "index.md"],
)
