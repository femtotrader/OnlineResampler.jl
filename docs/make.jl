using Documenter
using OnlineResampler

makedocs(;
    modules = [OnlineResampler],
    sitename = "OnlineResampler.jl",
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://femtotrader.github.io/OnlineResampler.jl",
        assets = String[],
        sidebar_sitename = false
    ),
    pages = [
        "Home" => "index.md",
        "Tutorial" => "tutorial.md",
        "User Guide" => "user_guide.md",
        "API Reference" => "api_reference.md",
        "Edge Cases & Limitations" => "edge_cases.md"
    ],
    checkdocs = :none,  # Disable docstring checking for now
    doctest = false,
    repo = "https://github.com/femtotrader/OnlineResampler.jl",
    warnonly = [:missing_docs, :cross_references]  # Don't fail on these warnings
)

# Deploy documentation to GitHub Pages
deploydocs(;
    repo = "github.com/femtotrader/OnlineResampler.jl",
    devbranch = "main"
)