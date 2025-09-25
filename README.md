# OnlineResamplers.jl

[![Build Status](https://github.com/femtotrader/OnlineResamplers.jl/workflows/CI/badge.svg)](https://github.com/femtotrader/OnlineResamplers.jl/actions)
[![Coverage](https://codecov.io/gh/femtotrader/OnlineResamplers.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/femtotrader/OnlineResamplers.jl)
[![Docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://femtotrader.github.io/OnlineResamplers.jl)

A high-performance Julia package for real-time resampling of financial market data. Built on [OnlineStatsBase.jl](https://github.com/joshday/OnlineStatsBase.jl), it provides efficient streaming algorithms for aggregating tick-level market data into OHLC candlesticks and other time-based formats.

## Quick Start

```julia
using Pkg
Pkg.add(url="https://github.com/femtotrader/OnlineResamplers.jl")
```

```julia
using OnlineResamplers, OnlineStatsBase, Dates

# Create a 1-minute OHLC resampler
resampler = MarketResampler(Minute(1))

# Process market data
data = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0)
fit!(resampler, data)

# Get results
result = value(resampler)
println("OHLC: $(result.price.ohlc)")  # OHLC(100.0, 100.0, 100.0, 100.0)
println("Volume: $(result.volume)")    # 1000.0
```

## Key Features

- **Real-time Processing**: Stream market data with constant memory usage
- **Multiple Resampling Methods**: OHLC, Mean price, Volume sum
- **Parametric Types**: Support for custom numeric types (FixedPointDecimals, etc.)
- **High Performance**: Type-stable operations with zero allocations
- **Parallel Processing**: Built-in merge operations for distributed computing
- **OnlineStatsBase Integration**: Compatible with the Julia online statistics ecosystem

## Documentation

📖 **[Complete Documentation](docs/)**

### Build Documentation Locally

```bash
# Quick build and view
make docs-open

# Or manually:
julia docs/build.jl
julia docs/open.jl
```

### Documentation Sections

- **[Tutorial](docs/tutorial.md)** - Step-by-step guide from basic to advanced usage
- **[API Reference](docs/api_reference.md)** - Detailed function documentation
- **[User Guide](docs/user_guide.md)** - Comprehensive examples and best practices
- **[Advanced Examples](examples/)** - Complex real-world scenarios

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions welcome! Please see the documentation for development guidelines.

---

*Built with ❤️ for the Julia community*
