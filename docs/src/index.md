# OnlineResamplers.jl Documentation

Welcome to the comprehensive documentation for OnlineResamplers.jl - a high-performance Julia package for real-time resampling of financial market data.

!!! warning "AI-Generated Code Notice"
    **Significant portions of this package were developed with AI assistance (Claude 3.5 Sonnet).**

    While extensively tested (>90% coverage, 94 BDD scenarios), users should exercise appropriate due diligence for production use.

    **📋 [Read Full AI Transparency Documentation →](ai_transparency.md)** | **📄 [Quick Reference (AI_NOTICE.md) →](https://github.com/femtotrader/OnlineResamplers.jl/blob/main/AI_NOTICE.md)**

## Documentation Overview

### 📚 Getting Started

- **[Tutorial](tutorial.md)** - Step-by-step guide from basic concepts to advanced usage
  - Installation and setup
  - Core concepts (MarketDataPoint, TimeWindow, OHLC)
  - Basic resampling strategies
  - Real-time processing patterns
  - Performance optimization tips

### 📖 Comprehensive Reference

- **[User Guide](user_guide.md)** - Complete guide with detailed examples and best practices
  - Installation options
  - Core concepts and data structures
  - Basic and advanced usage patterns
  - Real-world examples (CSV processing, multi-timeframe analysis)
  - Performance optimization strategies
  - OnlineStats integration
  - Troubleshooting and debugging

- **[API Reference](api_reference.md)** - Detailed technical documentation
  - Complete function signatures and parameters
  - Type specifications and compatibility
  - Return value documentation
  - Performance characteristics
  - Usage examples for each function

- **[Edge Cases & Limitations](edge_cases.md)** - Important behaviors and gotchas
  - Out-of-order data handling
  - Empty windows and single data points
  - Type mismatch issues
  - Memory considerations
  - Best practices for edge cases

### 💡 Examples and Patterns

- **[Advanced Examples](../examples/)** - Complex real-world scenarios
  - [`usage_example.jl`](../examples/usage_example.jl) - Basic usage patterns
  - [`advanced_examples.jl`](../examples/advanced_examples.jl) - Complex scenarios including:
    - Multi-timeframe analysis
    - High-precision calculations
    - Real-time streaming
    - Parallel processing
    - Performance demonstrations
  - [`out_of_order_data.jl`](../examples/out_of_order_data.jl) - Handling non-chronological data

### 🧪 Tests

- **[Test Suite](../test/)** - Comprehensive test coverage
  - [`test_resampler.jl`](../test/test_resampler.jl) - Core functionality tests

---

## Quick Navigation

### By Use Case

| **Use Case** | **Documentation** | **Examples** |
|--------------|-------------------|--------------|
| **Getting Started** | [Tutorial - Getting Started](tutorial.md#getting-started) | [Basic Usage](../examples/usage_example.jl) |
| **OHLC Candlesticks** | [User Guide - OHLC](user_guide.md#ohlc-resampling) | [OHLC Examples](../examples/usage_example.jl) |
| **High-Precision Data** | [Tutorial - Custom Types](tutorial.md#working-with-different-data-types) | [Precision Examples](../examples/advanced_examples.jl) |
| **Real-time Processing** | [Tutorial - Real-time](tutorial.md#real-time-data-processing) | [Streaming Examples](../examples/advanced_examples.jl) |
| **Performance Optimization** | [User Guide - Performance](user_guide.md#performance-optimization) | [Benchmarks](../examples/advanced_examples.jl) |
| **Parallel Processing** | [Tutorial - Parallel](tutorial.md#real-time-data-processing) | [Merge Examples](../examples/advanced_examples.jl) |
| **Out-of-Order Data** | [Edge Cases - Out-of-Order](edge_cases.md#out-of-order-data) | [Out-of-Order Examples](../examples/out_of_order_data.jl) |

### By Experience Level

| **Level** | **Start Here** | **Then Read** | **Finally Try** |
|-----------|----------------|---------------|-----------------|
| **Beginner** | [Tutorial](tutorial.md) | [User Guide - Basic Usage](user_guide.md#basic-usage) | [Basic Examples](../examples/usage_example.jl) |
| **Intermediate** | [User Guide](user_guide.md) | [API Reference](api_reference.md) | [Advanced Examples](../examples/advanced_examples.jl) |
| **Expert** | [API Reference](api_reference.md) | [Source Code](../src/) | Custom implementations |

### By Topic

#### Core Concepts
- [MarketDataPoint Structure](tutorial.md#market-data-structure)
- [Time Windows](tutorial.md#understanding-time-windows)
- [OHLC Data Format](api_reference.md#ohlc)
- [OnlineStatsBase Integration](user_guide.md#integration-with-onlinestats)

#### Resampling Methods
- [OHLC Resampling](user_guide.md#ohlc-resampling) - Candlestick aggregation
- [Mean Price Resampling](user_guide.md#mean-price-resampling) - Average price calculation
- [Volume Sum Resampling](api_reference.md#sumresampler) - Volume aggregation

#### Advanced Features
- [Chronological Validation](edge_cases.md#solution-3-built-in-chronological-validation) - Built-in out-of-order data detection
- [Custom Numeric Types](user_guide.md#custom-numeric-types)
- [Parallel Processing](user_guide.md#parallel-processing)
- [Multi-timeframe Analysis](user_guide.md#multi-timeframe-analysis)
- [Performance Optimization](user_guide.md#performance-optimization)

#### Integration
- [OnlineStats Ecosystem](user_guide.md#integration-with-onlinestats)
- [CSV Data Processing](user_guide.md#processing-csv-market-data)
- [Real-time Data Streams](tutorial.md#real-time-data-processing)

---

## Package Architecture

OnlineResamplers.jl is built on a clean, extensible architecture:

```
OnlineResamplers.jl
├── Core Types
│   ├── MarketDataPoint{T,P,V}      # Input data structure
│   ├── OHLC{P}                     # Price aggregation result
│   └── TimeWindow{T}               # Time interval definition
├── Abstract Types
│   └── AbstractResampler{T,P,V}    # Base for all resamplers
├── Concrete Resamplers
│   ├── OHLCResampler{T,P,V}        # OHLC price aggregation
│   ├── MeanResampler{T,P,V}        # Mean price aggregation
│   ├── SumResampler{T,P,V}         # Sum aggregation (volumes)
│   └── MarketResampler{T,P,V}      # Composite resampler
└── OnlineStatsBase Integration
    ├── fit!(resampler, data)       # Process data
    ├── value(resampler)            # Get results
    ├── nobs(resampler)             # Count observations
    └── merge!(r1, r2)              # Combine resamplers
```

## Type System

The package uses a comprehensive parametric type system:

- **`T`**: Timestamp type (DateTime, NanoDate, ZonedDateTime, etc.)
- **`P`**: Price type (Float64, FixedDecimal, Rational, etc.)
- **`V`**: Volume type (Float64, FixedDecimal, Int64, etc.)

This design enables:
- **Type Safety**: Compile-time type checking prevents runtime errors
- **Performance**: Type-stable operations for maximum speed
- **Flexibility**: Support for any numeric type with appropriate operations
- **Precision**: Use exact arithmetic types for financial calculations

## Performance Characteristics

OnlineResamplers.jl is designed for high-performance applications:

- **Memory**: O(1) constant memory usage regardless of data volume
- **Speed**: ~50 nanoseconds per operation on modern hardware
- **Throughput**: >2 million operations per second
- **Allocations**: Zero allocations in steady-state processing
- **Scalability**: Supports parallel processing with merge operations

## Contributing

We welcome contributions! Areas where help is especially appreciated:

- **New Resampling Methods**: Implement additional aggregation strategies
- **Performance Improvements**: Optimize hot code paths
- **Documentation**: Improve examples and explanations
- **Testing**: Add test cases for edge conditions
- **Integration**: Examples with other Julia packages

See the source code and test files for implementation examples.

---

## Support and Community

- **Issues**: Report bugs and request features on [GitHub Issues](https://github.com/femtotrader/OnlineResamplers.jl/issues)
- **Discussions**: Ask questions on [GitHub Discussions](https://github.com/femtotrader/OnlineResamplers.jl/discussions)
- **Documentation**: Contribute improvements to help others learn

---

*This documentation covers OnlineResamplers.jl v0.1.0 and later. For earlier versions, please refer to the appropriate git tags.*