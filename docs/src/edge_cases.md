# Edge Cases and Limitations

This document covers important edge cases, limitations, and unexpected behaviors when using OnlineResamplers.jl.

## Table of Contents

1. [Out-of-Order Data](#out-of-order-data)
2. [Empty Windows](#empty-windows)
3. [Single Data Points](#single-data-points)
4. [Type Mismatches](#type-mismatches)
5. [Very Large Time Gaps](#very-large-time-gaps)
6. [Precision Issues](#precision-issues)
7. [Memory Considerations](#memory-considerations)

---

## Out-of-Order Data

**⚠️ CRITICAL BEHAVIOR**: OnlineResamplers is designed for streaming data and assumes chronological order. Out-of-order data can cause unexpected behavior.

### The Problem

When data points arrive out of chronological order, OnlineResamplers will:

1. **Always move to the new data's time window**
2. **Finalize and lose all data from the previous window**
3. **Reset counters and aggregations for the new window**

### Example of the Issue

```julia
using OnlineResamplers, OnlineStatsBase, Dates

resampler = MarketResampler(Minute(1))

# Process some data in window 1 (9:30-9:31)
fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0))
fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 30), 105.0, 800.0))

# Move to window 2 (9:31-9:32)
fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 31, 0), 102.0, 1200.0))

result_before = value(resampler)
println("Before: $(result_before.price.ohlc)")  # OHLC(102.0, 102.0, 102.0, 102.0)
println("Window: $(result_before.window.start_time)")  # 2024-01-01T09:31:00

# Now process OUT-OF-ORDER data from window 1
fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 45), 95.0, 1500.0))

result_after = value(resampler)
println("After: $(result_after.price.ohlc)")   # OHLC(95.0, 95.0, 95.0, 95.0)
println("Window: $(result_after.window.start_time)")   # 2024-01-01T09:30:00

# 🚨 ALL DATA FROM THE 9:31 WINDOW IS LOST!
# 🚨 The resampler moved back to the 9:30 window and reset everything!
```

### Scenarios and Behaviors

#### 1. Within Same Window (Usually OK)

```julia
resampler = MarketResampler(Minute(1))

# Data arrives out of order but within same 1-minute window
fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0))   # First
fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 45), 105.0, 800.0))   # Last chronologically
fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 15), 95.0, 1200.0))   # Middle chronologically

result = value(resampler)
# ✅ All data is preserved in OHLC
# ❌ But Open=100.0 (first processed) and Close=95.0 (last processed)
# ❌ Close is NOT the chronologically last price (105.0)!
```

#### 2. Across Windows (Always Problematic)

```julia
resampler = MarketResampler(Minute(1))

# Process data in sequence: 9:30 → 9:32 → 9:31 → 9:30
fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0))  # Window 1
fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 32, 0), 110.0, 1500.0))  # Window 3
fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 31, 0), 105.0, 800.0))   # Window 2
fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 30), 95.0, 1200.0))  # Back to Window 1

# 🚨 Only the last window (9:30) has data
# 🚨 All data from windows 9:32 and 9:31 is lost
```

### Solutions

#### Solution 1: Pre-sort Data

```julia
# Always sort your data before processing
unsorted_data = [
    MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 45), 105.0, 800.0),
    MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0),
    MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 30), 102.0, 1200.0),
]

# Sort by timestamp
sorted_data = sort(unsorted_data, by=x -> x.datetime)

resampler = MarketResampler(Minute(1))
for data in sorted_data
    fit!(resampler, data)
end

result = value(resampler)
# ✅ Correct OHLC with proper chronological order
```

#### Solution 2: Batch Processing by Windows

```julia
function batch_process_by_windows(data_points, period)
    # Group data by time windows
    windows = Dict{DateTime, Vector{MarketDataPoint}}()

    for data in data_points
        window_start = floor(data.datetime, period)
        if !haskey(windows, window_start)
            windows[window_start] = MarketDataPoint[]
        end
        push!(windows[window_start], data)
    end

    # Process each window with sorted data
    results = []
    for window_start in sort(collect(keys(windows)))
        window_data = windows[window_start]
        sorted_window_data = sort(window_data, by=x -> x.datetime)

        window_resampler = MarketResampler(period)
        for data in sorted_window_data
            fit!(window_resampler, data)
        end

        result = value(window_resampler)
        if result.price.ohlc !== nothing
            push!(results, (
                window_start = window_start,
                ohlc = result.price.ohlc,
                volume = result.volume
            ))
        end
    end

    return results
end

# Usage
mixed_data = [/* your out-of-order data */]
results = batch_process_by_windows(mixed_data, Minute(1))
```

#### Solution 3: Built-in Chronological Validation

OnlineResamplers.jl now includes built-in validation to detect and prevent out-of-order data:

```julia
# Enable chronological validation
resampler = MarketResampler(Minute(1), validate_chronological=true)

# Process data normally
fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0))
fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 30), 105.0, 800.0))

# This will throw an ArgumentError with detailed message
try
    fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 15), 95.0, 1200.0))
catch e
    println("Error: $(e.msg)")
    # Error: Data not in chronological order: 2024-01-01T09:30:15 < 2024-01-01T09:30:30.
    # Received data point with timestamp 2024-01-01T09:30:15 but last processed timestamp was 2024-01-01T09:30:30.
    # To disable this check, set validate_chronological=false in the constructor.
end
```

#### Solution 4: Manual Validation

For cases where you want to validate before processing:

```julia
function validate_chronological_order(data_points)
    for i in 2:length(data_points)
        if data_points[i].datetime < data_points[i-1].datetime
            @warn "Out-of-order data at index $i: $(data_points[i].datetime) < $(data_points[i-1].datetime)"
            return false
        end
    end
    return true
end

# Always validate before processing
if !validate_chronological_order(your_data)
    @error "Data is not in chronological order. Consider sorting first."
end
```

---

## Empty Windows

OnlineResamplers handles empty windows gracefully, but you need to be aware of the behavior.

### Behavior

```julia
resampler = MarketResampler(Minute(1))

# No data processed yet
result = value(resampler)
println(result.price.ohlc)  # nothing
println(result.volume)      # 0.0
println(result.window)      # nothing
```

### After Processing Data

```julia
# Process one data point
fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0))

result = value(resampler)
println(result.price.ohlc)  # OHLC(100.0, 100.0, 100.0, 100.0)
println(result.window)      # TimeWindow{DateTime}(DateTime("2024-01-01T09:30:00"), Minute(1))
```

---

## Single Data Points

When only one data point exists in a window:

```julia
resampler = MarketResampler(Minute(1))
fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0))

result = value(resampler)
ohlc = result.price.ohlc

# All OHLC values are identical
@assert ohlc.open == ohlc.high == ohlc.low == ohlc.close == 100.0
```

This is correct behavior - with only one price point, all OHLC values should be the same.

---

## Type Mismatches

OnlineResamplers is strictly typed. Type mismatches will cause compile-time or runtime errors:

```julia
# This will fail
resampler = MarketResampler{DateTime, Float64, Float64}(Minute(1))
bad_data = MarketDataPoint{DateTime, Int64, Float64}(DateTime(2024, 1, 1, 9, 30, 0), 100, 1000.0)

# fit!(resampler, bad_data)  # MethodError: no method matching

# Solution: Ensure consistent types
good_data = MarketDataPoint{DateTime, Float64, Float64}(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0)
fit!(resampler, good_data)  # Works
```

### Type Conversion Helper

```julia
function convert_market_data(data::MarketDataPoint, ::Type{T}, ::Type{P}, ::Type{V}) where {T,P,V}
    return MarketDataPoint{T,P,V}(
        T(data.datetime),
        P(data.price),
        V(data.volume)
    )
end

# Usage
original = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100, 1000)  # Int types
converted = convert_market_data(original, DateTime, Float64, Float64)
```

---

## Very Large Time Gaps

OnlineResamplers handles arbitrary time gaps, but be aware of implications:

```julia
resampler = MarketResampler(Minute(1))

# Process data at 9:30
fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0))

# Process data much later (hours later)
fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 15, 30, 0), 200.0, 2000.0))

# The resampler immediately moves to the 15:30 window
# All intermediate windows (9:31, 9:32, ..., 15:29) are never created
result = value(resampler)
println(result.window.start_time)  # 2024-01-01T15:30:00
```

This is expected behavior - OnlineResamplers doesn't create empty intermediate windows.

---

## Precision Issues

### With Floating Point Types

```julia
# Floating point precision can affect comparisons
resampler = MarketResampler(Microsecond(1))

dt1 = DateTime(2024, 1, 1, 9, 30, 0) + Nanosecond(100)  # Not exactly representable
dt2 = DateTime(2024, 1, 1, 9, 30, 0) + Nanosecond(200)

# These might end up in the same microsecond window due to precision
```

### Solution: Use Appropriate Precision

```julia
using FixedPointDecimals

# For high-precision financial data
PreciseResampler = MarketResampler{DateTime, FixedDecimal{Int64,4}, FixedDecimal{Int64,2}}
precise_resampler = PreciseResampler(Minute(1))

precise_data = MarketDataPoint{DateTime, FixedDecimal{Int64,4}, FixedDecimal{Int64,2}}(
    DateTime(2024, 1, 1, 9, 30, 0),
    FixedDecimal{Int64,4}(100.1234),  # Exactly representable
    FixedDecimal{Int64,2}(1000.50)    # Exactly representable
)

fit!(precise_resampler, precise_data)
```

---

## Memory Considerations

### Normal Operation (Constant Memory)

```julia
# Memory usage stays constant regardless of data volume
resampler = MarketResampler(Minute(1))

for i in 1:1_000_000
    timestamp = DateTime(2024, 1, 1, 9, 0, 0) + Millisecond(i)
    data = MarketDataPoint(timestamp, 100.0, 1000.0)
    fit!(resampler, data)
end

# Memory usage is O(1) - constant
```

### Potential Memory Issues

```julia
# DON'T store all intermediate results
results = []  # This will grow without bound!
resampler = MarketResampler(Minute(1))

for data in huge_dataset
    fit!(resampler, data)
    push!(results, value(resampler))  # ❌ This defeats the purpose!
end
```

Instead, only store completed windows:

```julia
completed_bars = []
resampler = MarketResampler(Minute(1))
current_window = nothing

for data in huge_dataset
    old_result = value(resampler)
    old_window = old_result.window

    fit!(resampler, data)

    new_result = value(resampler)
    if new_result.window != old_window && old_window !== nothing
        # Window completed, save it
        push!(completed_bars, (
            timestamp = old_window.start_time,
            ohlc = old_result.price.ohlc,
            volume = old_result.volume
        ))
    end
end
```

---

## Best Practices for Edge Cases

### 1. Always Validate Input Data

```julia
function validate_market_data(data::MarketDataPoint)
    if data.price <= 0
        throw(ArgumentError("Price must be positive: $(data.price)"))
    end
    if data.volume < 0
        throw(ArgumentError("Volume cannot be negative: $(data.volume)"))
    end
    return true
end
```

### 2. Sort Before Processing

```julia
function safe_resample(data_points, period; price_method=:ohlc)
    # Always sort first
    sorted_data = sort(data_points, by=x -> x.datetime)

    resampler = MarketResampler(period, price_method=price_method)
    for data in sorted_data
        validate_market_data(data)
        fit!(resampler, data)
    end

    return value(resampler)
end
```

### 3. Handle Empty Results

```julia
function safe_get_ohlc(resampler)
    result = value(resampler)
    if result.price.ohlc === nothing
        @warn "No OHLC data available - no data points processed yet"
        return nothing
    end
    return result.price.ohlc
end
```

### 4. Monitor Window Transitions

```julia
function process_with_monitoring(resampler, data_stream)
    window_count = 0
    current_window = nothing

    for data in data_stream
        old_result = value(resampler)
        old_window = old_result.window

        fit!(resampler, data)

        new_result = value(resampler)
        if new_result.window != old_window
            window_count += 1
            @info "Window transition #$window_count: $(old_window) → $(new_result.window)"
        end
    end

    return window_count
end
```

---

These edge cases and limitations are important to understand when using OnlineResamplers.jl in production. The package is designed for streaming, chronologically-ordered data, and understanding these constraints will help you use it effectively.