# OnlineResampler.jl Tutorial

This tutorial will guide you through the main features of OnlineResampler.jl, from basic usage to advanced applications.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Basic Resampling](#basic-resampling)
3. [Understanding Time Windows](#understanding-time-windows)
4. [Working with Different Data Types](#working-with-different-data-types)
5. [Advanced Resampling Strategies](#advanced-resampling-strategies)
6. [Real-time Data Processing](#real-time-data-processing)
7. [Performance Optimization](#performance-optimization)
8. [Best Practices](#best-practices)

---

## Getting Started

### Installation

```julia
using Pkg
Pkg.add(url="https://github.com/femtotrader/OnlineResampler.jl")
```

### Basic Setup

```julia
using OnlineResampler, OnlineStatsBase, Dates
```

### Your First Resampler

```julia
# Create a simple 1-minute OHLC resampler
resampler = MarketResampler(Minute(1))

# Create some sample market data
data1 = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0)
data2 = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 30), 105.0, 800.0)
data3 = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 45), 98.0, 1200.0)

# Process the data
fit!(resampler, data1)
fit!(resampler, data2)
fit!(resampler, data3)

# Get the results
result = value(resampler)
println("OHLC: $(result.price.ohlc)")
println("Volume: $(result.volume)")
```

**Output:**
```
OHLC: OHLC(100.0, 105.0, 98.0, 98.0)
Volume: 3000.0
```

---

## Basic Resampling

### OHLC (Open, High, Low, Close) Resampling

OHLC resampling is the most common way to aggregate tick data into candlestick charts:

```julia
# Create OHLC resampler (this is the default)
ohlc_resampler = MarketResampler(Minute(1), price_method=:ohlc)

# Sample tick data within one minute
base_time = DateTime(2024, 1, 1, 14, 30, 0)
ticks = [
    MarketDataPoint(base_time + Second(0), 100.00, 1000.0),   # Open
    MarketDataPoint(base_time + Second(15), 102.50, 800.0),   # High
    MarketDataPoint(base_time + Second(30), 97.75, 1200.0),   # Low
    MarketDataPoint(base_time + Second(45), 101.25, 900.0)    # Close
]

# Process all ticks
for tick in ticks
    fit!(ohlc_resampler, tick)
end

result = value(ohlc_resampler)
ohlc = result.price.ohlc

println("Open:  $(ohlc.open)")     # 100.00 (first price)
println("High:  $(ohlc.high)")     # 102.50 (highest price)
println("Low:   $(ohlc.low)")      # 97.75  (lowest price)
println("Close: $(ohlc.close)")    # 101.25 (last price)
println("Volume: $(result.volume)") # 3900.0 (total volume)
```

### Mean Price Resampling

For applications requiring smoothed price data:

```julia
# Create mean price resampler
mean_resampler = MarketResampler(Minute(5), price_method=:mean)

# Process the same data
for tick in ticks
    fit!(mean_resampler, tick)
end

result = value(mean_resampler)
mean_price = result.price.mean_price

println("Mean Price: $(mean_price)")  # 100.375 ((100+102.5+97.75+101.25)/4)
println("Volume: $(result.volume)")   # 3900.0
```

## Chronological Data Validation

OnlineResampler is designed for streaming data and assumes chronological order. You can enable validation to detect and prevent out-of-order data:

### Default Behavior (No Validation)
```julia
# By default, validation is disabled for performance
resampler = MarketResampler(Minute(1))  # validate_chronological=false by default

# This allows out-of-order data but may cause unexpected behavior
fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0))
fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 29, 0), 99.0, 800.0))   # Out of order!
```

### Enabled Validation
```julia
# Enable chronological validation
validated_resampler = MarketResampler(Minute(1), validate_chronological=true)

# Process data chronologically - this works fine
fit!(validated_resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0))
fit!(validated_resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 30), 105.0, 800.0))

# This will throw an ArgumentError with detailed message
try
    fit!(validated_resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 15), 95.0, 1200.0))
catch e
    println("Error: Out-of-order data detected!")
    # ArgumentError: Data not in chronological order: 2024-01-01T09:30:15 <= 2024-01-01T09:30:30
end
```

**When to use validation:**
- ✅ When processing historical data that might be unsorted
- ✅ When debugging data quality issues
- ✅ When data integrity is critical
- ❌ High-frequency real-time streams (performance impact)
- ❌ When you're certain data is already chronologically ordered

---

## Understanding Time Windows

Time windows are fundamental to how OnlineResampler groups data:

### How Time Windows Work

```julia
using Dates

# Create a 1-minute window starting at 9:30 AM
window = TimeWindow{DateTime}(DateTime(2024, 1, 1, 9, 30, 0), Minute(1))

# The window covers [9:30:00, 9:31:00)
println("Window start: $(window.start_time)")          # 2024-01-01T09:30:00
println("Window end: $(window_end(window))")           # 2024-01-01T09:31:00

# Test timestamps
timestamps = [
    DateTime(2024, 1, 1, 9, 29, 59),  # Before window
    DateTime(2024, 1, 1, 9, 30, 0),   # Start of window
    DateTime(2024, 1, 1, 9, 30, 30),  # Middle of window
    DateTime(2024, 1, 1, 9, 31, 0)    # Start of next window
]

for ts in timestamps
    belongs = belongs_to_window(ts, window)
    println("$(ts): $(belongs)")
end
```

**Output:**
```
2024-01-01T09:29:59: false
2024-01-01T09:30:00: true
2024-01-01T09:30:30: true
2024-01-01T09:31:00: false
```

### Window Transitions

Resamplers automatically handle window transitions:

```julia
resampler = MarketResampler(Minute(1))

# First window data
data1 = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0)
data2 = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 30), 105.0, 800.0)

# Second window data (next minute)
data3 = MarketDataPoint(DateTime(2024, 1, 1, 9, 31, 0), 110.0, 1200.0)
data4 = MarketDataPoint(DateTime(2024, 1, 1, 9, 31, 30), 108.0, 900.0)

# Process first window
fit!(resampler, data1)
fit!(resampler, data2)
result1 = value(resampler)
println("First window OHLC: $(result1.price.ohlc)")
println("Window: $(result1.window.start_time)")

# Process second window - resampler automatically resets
fit!(resampler, data3)
fit!(resampler, data4)
result2 = value(resampler)
println("Second window OHLC: $(result2.price.ohlc)")
println("Window: $(result2.window.start_time)")
```

---

## Working with Different Data Types

### High-Precision Financial Data

OnlineResampler supports custom numeric types for high-precision calculations:

```julia
# Using Rational numbers for exact arithmetic
PrecisePrice = Rational{Int128}
PreciseVolume = Rational{Int64}

# Create high-precision resampler
precise_resampler = MarketResampler{DateTime, PrecisePrice, PreciseVolume}(
    Minute(1), price_method=:ohlc
)

# High-precision data
precise_data = MarketDataPoint{DateTime, PrecisePrice, PreciseVolume}(
    DateTime(2024, 1, 1, 9, 30, 0),
    PrecisePrice(1001234, 10000),  # 100.1234 exactly
    PreciseVolume(10005, 10)       # 1000.5 exactly
)

fit!(precise_resampler, precise_data)
result = value(precise_resampler)

println("Precise OHLC: $(result.price.ohlc)")
println("Precise Volume: $(result.volume)")
```

### Custom Time Types

```julia
# Example with custom time handling (conceptual)
# In practice, you'd use libraries like NanoDates.jl or TimeZones.jl

# Standard DateTime usage
datetime_resampler = MarketResampler{DateTime, Float64, Float64}(Minute(1))

# The resampler will work with any type T that supports:
# - T + Period -> T (arithmetic)
# - T comparison operators
# - floor(T, Period) -> T (for window alignment)
```

---

## Advanced Resampling Strategies

### Individual Resamplers

For specialized use cases, you can use individual resampler types:

```julia
# Pure OHLC resampler
ohlc_only = OHLCResampler(Minute(1))

# Mean price resampler
mean_only = MeanResampler(Minute(5))

# Volume sum resampler
volume_sum = SumResampler(Second(30))

# Process data
sample_data = MarketDataPoint(DateTime(2024, 1, 1, 10, 0, 0), 100.0, 1000.0)

fit!(ohlc_only, sample_data)
fit!(mean_only, sample_data)
fit!(volume_sum, sample_data)

# Get individual results
ohlc_result = value(ohlc_only)
mean_result = value(mean_only)
volume_result = value(volume_sum)

println("OHLC only: $(ohlc_result)")
println("Mean only: $(mean_result)")
println("Volume sum: $(volume_result)")
```

### Multi-timeframe Analysis

Analyze the same data stream across multiple timeframes:

```julia
# Create resamplers for different timeframes
timeframes = Dict(
    "1min" => MarketResampler(Minute(1)),
    "5min" => MarketResampler(Minute(5)),
    "15min" => MarketResampler(Minute(15)),
    "1hour" => MarketResampler(Hour(1))
)

# Generate sample data
base_time = DateTime(2024, 1, 1, 9, 0, 0)
sample_ticks = [
    MarketDataPoint(base_time + Minute(i), 100.0 + randn(), rand(500:1500))
    for i in 1:60  # 1 hour of minute-level data
]

# Process through all timeframes
for tick in sample_ticks
    for (name, resampler) in timeframes
        fit!(resampler, tick)
    end
end

# Display results
println("Multi-timeframe Analysis:")
for (name, resampler) in sort(collect(timeframes))
    result = value(resampler)
    if result.price.ohlc !== nothing
        ohlc = result.price.ohlc
        println("$name: O=$(round(ohlc.open, digits=2)), " *
                "H=$(round(ohlc.high, digits=2)), " *
                "L=$(round(ohlc.low, digits=2)), " *
                "C=$(round(ohlc.close, digits=2)), " *
                "Vol=$(round(result.volume))")
    end
end
```

---

## Real-time Data Processing

### Stream Processing with Window Detection

For real-time applications, you often need to detect when windows complete:

```julia
mutable struct RealTimeProcessor
    resampler::MarketResampler
    completed_bars::Vector{NamedTuple}
    current_window::Union{TimeWindow, Nothing}
end

function RealTimeProcessor(period::Period)
    RealTimeProcessor(
        MarketResampler(period),
        NamedTuple[],
        nothing
    )
end

function process_tick!(processor::RealTimeProcessor, tick::MarketDataPoint)
    # Get current state before processing
    old_result = value(processor.resampler)
    old_window = old_result.window

    # Process the tick
    fit!(processor.resampler, tick)

    # Check for window completion
    new_result = value(processor.resampler)
    new_window = new_result.window

    if old_window !== nothing && new_window != old_window
        # Window completed! Save the bar
        if old_result.price.ohlc !== nothing
            completed_bar = (
                timestamp = old_window.start_time,
                open = old_result.price.ohlc.open,
                high = old_result.price.ohlc.high,
                low = old_result.price.ohlc.low,
                close = old_result.price.ohlc.close,
                volume = old_result.volume
            )
            push!(processor.completed_bars, completed_bar)

            # Callback for completed bar
            on_bar_complete(completed_bar)
        end
    end

    processor.current_window = new_window
end

function on_bar_complete(bar)
    println("✅ Bar completed: $(bar.timestamp) - " *
            "OHLC($(bar.open), $(bar.high), $(bar.low), $(bar.close)) " *
            "Vol: $(bar.volume)")
end

# Usage example
processor = RealTimeProcessor(Minute(1))

# Simulate real-time tick stream
stream_base = DateTime(2024, 1, 1, 14, 30, 0)
for minute in 0:2, second in [0, 30]
    timestamp = stream_base + Minute(minute) + Second(second)
    tick = MarketDataPoint(timestamp, 100.0 + minute + randn()*0.1, rand(800:1200))
    process_tick!(processor, tick)
end
```

### Parallel Processing

For high-throughput applications, process data in parallel and merge results:

```julia
# Function to process a chunk of data
function process_chunk(data_chunk::Vector, period::Period)
    chunk_resampler = OHLCResampler{DateTime, Float64, Float64}(period)
    for data in data_chunk
        fit!(chunk_resampler, data)
    end
    return chunk_resampler
end

# Generate large dataset
large_dataset = [
    MarketDataPoint(DateTime(2024, 1, 1, 9, 0, i), 100.0 + sin(i/100), rand(500:1500))
    for i in 1:10000
]

# Split into chunks for parallel processing
chunk_size = 2500
chunks = [large_dataset[i:min(i+chunk_size-1, end)] for i in 1:chunk_size:length(large_dataset)]

# Process chunks (in real applications, use @distributed or threading)
chunk_resamplers = [process_chunk(chunk, Minute(1)) for chunk in chunks]

# Merge all results
final_resampler = chunk_resamplers[1]
for i in 2:length(chunk_resamplers)
    merge!(final_resampler, chunk_resamplers[i])
end

merged_result = value(final_resampler)
println("Merged OHLC: $(merged_result.ohlc)")
println("Total observations: $(nobs(final_resampler))")
```

---

## Performance Optimization

### Memory Efficiency

OnlineResampler uses constant memory regardless of data volume:

```julia
# Memory usage stays constant even with millions of data points
memory_test_resampler = MarketResampler(Minute(1))

println("Processing 1 million data points...")
for i in 1:1_000_000
    timestamp = DateTime(2024, 1, 1, 9, 0, 0) + Millisecond(i)
    data = MarketDataPoint(timestamp, 100.0 + sin(i/1000), 1000.0)
    fit!(memory_test_resampler, data)

    # Memory usage remains constant due to window transitions
end

result = value(memory_test_resampler)
println("Current window has $(nobs(memory_test_resampler)) observations")
println("Memory usage is O(1) - constant regardless of total data processed")
```

### Type Stability

For maximum performance, use concrete types:

```julia
# Good: Concrete types
fast_resampler = MarketResampler{DateTime, Float64, Float64}(Minute(1))

# Less optimal: Abstract types (avoid if performance is critical)
# slow_resampler = MarketResampler{Any, Any, Any}(Minute(1))

# Concrete types enable compiler optimizations
function high_performance_processing(resampler::MarketResampler{DateTime, Float64, Float64},
                                   data_stream::Vector{MarketDataPoint{DateTime, Float64, Float64}})
    for data in data_stream
        fit!(resampler, data)
    end
    return value(resampler)
end
```

### Batch Processing

Process data in batches for optimal performance:

```julia
function batch_process_ticks(resampler, ticks::Vector)
    # Process all ticks without intermediate value() calls
    for tick in ticks
        fit!(resampler, tick)
    end

    # Get result only once at the end
    return value(resampler)
end

# This is faster than calling value() after each fit!()
batch_resampler = MarketResampler(Minute(1))
batch_ticks = [MarketDataPoint(now(), 100.0 + randn(), 1000.0) for _ in 1:1000]

result = batch_process_ticks(batch_resampler, batch_ticks)
```

---

## Best Practices

### 1. Choose the Right Time Period

```julia
# High-frequency trading: sub-second intervals
hft_resampler = MarketResampler(Millisecond(100))

# Algorithmic trading: minute-level
algo_resampler = MarketResampler(Minute(1))

# Position management: hourly or daily
position_resampler = MarketResampler(Hour(1))
```

### 2. Handle Time Zone Consistency

```julia
# Always use consistent time zones
using TimeZones

# Convert all timestamps to UTC before processing
function to_utc(local_time::DateTime, tz::TimeZone)
    zoned_time = ZonedDateTime(local_time, tz)
    return DateTime(astimezone(zoned_time, tz"UTC"))
end

# Process in UTC, display in local time as needed
```

### 3. Validate Input Data

```julia
function safe_process_tick(resampler, timestamp, price, volume)
    # Validate inputs
    if price <= 0
        @warn "Invalid price: $price"
        return nothing
    end

    if volume < 0
        @warn "Invalid volume: $volume"
        return nothing
    end

    # Create and process data
    tick = MarketDataPoint(timestamp, price, volume)
    fit!(resampler, tick)
    return value(resampler)
end
```

### 4. Monitor Window Transitions

```julia
function monitored_processing(resampler, tick)
    old_window = value(resampler).window
    fit!(resampler, tick)
    new_window = value(resampler).window

    if old_window !== nothing && new_window != old_window
        @info "Window transition: $(old_window.start_time) -> $(new_window.start_time)"
        # Handle window completion logic here
    end
end
```

### 5. Error Handling

```julia
function robust_resampling(ticks)
    resampler = MarketResampler(Minute(1))
    successful_ticks = 0
    errors = 0

    for tick in ticks
        try
            fit!(resampler, tick)
            successful_ticks += 1
        catch e
            @warn "Failed to process tick: $tick" exception=(e, catch_backtrace())
            errors += 1
        end
    end

    @info "Processing complete: $successful_ticks successful, $errors errors"
    return value(resampler)
end
```

---

## Conclusion

OnlineResampler.jl provides a powerful and flexible framework for real-time market data aggregation. Key takeaways:

- **Start Simple**: Begin with `MarketResampler(Minute(1))` for basic OHLC resampling
- **Choose Your Types**: Use concrete types for performance, custom types for precision
- **Handle Windows**: Understand how time windows work and transition
- **Scale Up**: Use parallel processing and merging for high-throughput applications
- **Monitor Performance**: Leverage constant memory usage and type stability for optimal speed

For more advanced usage patterns and examples, see the `examples/` directory and the API reference documentation.

---

## Next Steps

- Explore the [API Reference](api_reference.md) for detailed function documentation
- Check out [Advanced Examples](../examples/advanced_examples.jl) for complex use cases
- Read the source code for implementation details
- Contribute improvements and new features!