# [ANN] OnlineResampler.jl - High-Performance Real-Time Financial Data Resampling

I'm excited to announce **OnlineResampler.jl**, a high-performance Julia package for real-time resampling of financial market data! 📈

## What is OnlineResampler.jl?

OnlineResampler.jl provides efficient streaming algorithms for aggregating tick-level market data into OHLC candlesticks and other time-based formats. Built on top of [OnlineStatsBase.jl](https://github.com/joshday/OnlineStatsBase.jl), it offers constant memory usage and zero-allocation operations for processing financial data streams.

## Key Features

🚀 **Real-time Processing**: Stream market data with constant memory usage - no need to store historical data in memory

📊 **Multiple Resampling Methods**:
- OHLC (Open, High, Low, Close) candlesticks
- Mean price aggregation
- Volume sum aggregation

🔢 **Parametric Types**: Full support for custom numeric types like `FixedPointDecimals.jl` for precise financial calculations

⚡ **High Performance**: Type-stable operations with zero allocations during steady-state processing

🔄 **Parallel Processing**: Built-in merge operations for distributed computing scenarios

🧩 **OnlineStatsBase Integration**: Seamless compatibility with Julia's online statistics ecosystem

## Quick Example

```julia
using OnlineResampler, OnlineStatsBase, Dates

# Create a 1-minute OHLC resampler
resampler = MarketResampler(Minute(1))

# Process streaming market data
data = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0)
fit!(resampler, data)

# Get results
result = value(resampler)
println("OHLC: $(result.price.ohlc)")  # OHLC(100.0, 100.0, 100.0, 100.0)
println("Volume: $(result.volume)")    # 1000.0
```

## Why OnlineResampler.jl?

Traditional approaches to market data resampling often require loading entire datasets into memory or using complex windowing mechanisms. OnlineResampler.jl takes a different approach by:

1. **Processing data point-by-point** as it arrives
2. **Automatically handling time window transitions**
3. **Maintaining constant memory usage** regardless of data volume
4. **Supporting high-precision numeric types** for financial applications

This makes it ideal for:
- Real-time trading systems
- Market data processing pipelines
- Financial analysis applications
- Any scenario requiring efficient time-series aggregation

## Advanced Usage

The package supports sophisticated scenarios like custom numeric types:

```julia
using FixedPointDecimals

# High-precision resampler
resampler = MarketResampler{DateTime, FixedDecimal{Int64,4}, FixedDecimal{Int64,2}}(
    Minute(1), price_method=:ohlc
)

# Process high-precision data
data = MarketDataPoint{DateTime, FixedDecimal{Int64,4}, FixedDecimal{Int64,2}}(
    DateTime(2024, 1, 1, 9, 30, 0),
    FixedDecimal{Int64,4}(100.5012),
    FixedDecimal{Int64,2}(1000.50)
)
```

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/femtotrader/OnlineResampler.jl")
```

## Documentation & Examples

- 📖 **Documentation**: Available in the [docs/](https://github.com/femtotrader/OnlineResampler.jl/tree/main/docs) directory
- 🔧 **API Reference**: Comprehensive function documentation
- 🎯 **Tutorial**: Step-by-step guide from basic to advanced usage
- 💡 **Examples**: Real-world usage scenarios

## Performance

OnlineResampler.jl is designed for high-frequency data processing. The streaming approach means:
- **O(1) memory usage** per resampler instance
- **Zero allocations** during steady-state processing
- **Type-stable operations** for maximum performance
- **Parallel processing support** via merge operations

## Get Involved

The package is open source and welcomes contributions! Whether you're working with financial data, time-series analysis, or online statistics, I'd love to hear about your use cases and feedback.

**Repository**: https://github.com/femtotrader/OnlineResampler.jl
**Issues**: https://github.com/femtotrader/OnlineResampler.jl/issues

---

*Built with ❤️ for the Julia community*

Would love to hear your thoughts and feedback! Has anyone been working on similar streaming data aggregation problems?