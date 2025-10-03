using Test

# Include all test files
include("test_bdd_specifications.jl")  # BDD-style specifications matching EARS requirements
include("test_resampler.jl")
include("test_chronological_validation.jl")
include("test_volume_resampler.jl")