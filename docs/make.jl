using Documenter
using OnlineResamplers

makedocs(;
    modules = [OnlineResamplers],
    sitename = "OnlineResamplers.jl",
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://femtotrader.github.io/OnlineResamplers.jl",
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
    repo = "https://github.com/femtotrader/OnlineResamplers.jl",
    warnonly = [:missing_docs, :cross_references]  # Don't fail on these warnings
)

# Deploy documentation to GitHub Pages
deploydocs(;
    repo = "github.com/femtotrader/OnlineResamplers.jl",
    devbranch = "main"
)