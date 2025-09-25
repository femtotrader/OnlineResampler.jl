# API Reference

This document provides detailed API reference for OnlineResampler.jl.

## Table of Contents

- [Core Types](#core-types)
  - [MarketDataPoint](#marketdatapoint)
  - [OHLC](#ohlc)
  - [TimeWindow](#timewindow)
- [Abstract Types](#abstract-types)
  - [AbstractResampler](#abstractresampler)
- [Resampler Types](#resampler-types)
  - [MarketResampler](#marketresampler)
  - [OHLCResampler](#ohlcresampler)
  - [MeanResampler](#meanresampler)
  - [SumResampler](#sumresampler)
- [Core Functions](#core-functions)
  - [OnlineStatsBase Interface](#onlinestatsbase-interface)
  - [Utility Functions](#utility-functions)
- [Type Constructors](#type-constructors)
- [Return Values](#return-values)

---

## Core Types

### MarketDataPoint

```julia
struct MarketDataPoint{T,P,V}
    datetime::T
    price::P
    volume::V
end
```

**Description**: Fundamental data structure representing a single market observation.

**Type Parameters**:
- `T`: Timestamp type (e.g., `DateTime`, `NanoDate`, `ZonedDateTime`)
- `P`: Price type (e.g., `Float64`, `FixedDecimal{Int64,4}`, `Rational{Int}`)
- `V`: Volume type (e.g., `Float64`, `FixedDecimal{Int64,2}`, `Int64`)

**Constructors**:
```julia
# Automatic type inference for common case
MarketDataPoint(datetime::DateTime, price::Real, volume::Real)

# Explicit type specification
MarketDataPoint{T,P,V}(datetime::T, price::P, volume::V)
```

**Examples**:
```julia
# Basic construction
data = MarketDataPoint(DateTime(2024,1,1,9,30,0), 100.0, 1000.0)

# High-precision construction
using FixedPointDecimals
precise_data = MarketDataPoint{DateTime, FixedDecimal{Int64,4}, FixedDecimal{Int64,2}}(
    DateTime(2024,1,1,9,30,0), FixedDecimal{Int64,4}(100.1234), FixedDecimal{Int64,2}(1000.50)
)
```

---

### OHLC

```julia
struct OHLC{P}
    open::P
    high::P
    low::P
    close::P
end
```

**Description**: Structure representing Open, High, Low, Close price data for a time period.

**Type Parameters**:
- `P`: Price type matching the price type used in market data

**Fields**:
- `open::P`: First price in the time period
- `high::P`: Highest price during the period
- `low::P`: Lowest price during the period
- `close::P`: Last price in the time period

**Examples**:
```julia
# Create OHLC manually
ohlc = OHLC{Float64}(100.0, 105.0, 98.0, 102.0)

# Access components
println("Range: $(ohlc.high - ohlc.low)")
println("Change: $(ohlc.close - ohlc.open)")
```

---

### TimeWindow

```julia
struct TimeWindow{T}
    start_time::T
    period::Period
end
```

**Description**: Represents a time interval for data aggregation.

**Type Parameters**:
- `T`: Timestamp type matching the datetime type used in market data

**Fields**:
- `start_time::T`: Beginning of the time window (inclusive)
- `period::Period`: Duration of the window (e.g., `Minute(1)`, `Hour(1)`)

**Examples**:
```julia
# Create 1-minute window
window = TimeWindow{DateTime}(DateTime(2024,1,1,9,30,0), Minute(1))

# Check window boundaries
end_time = window_end(window)  # DateTime(2024,1,1,9,31,0)
next = next_window(window)     # Starts at 9:31:00
```

---

## Abstract Types

### AbstractResampler

```julia
abstract type AbstractResampler{T,P,V} <: OnlineStat{MarketDataPoint{T,P,V}} end
```

**Description**: Base type for all market data resamplers, extending OnlineStatsBase functionality.

**Type Parameters**:
- `T`: Timestamp type
- `P`: Price type
- `V`: Volume type

**Required Interface** (for subtypes):
- `OnlineStatsBase._fit!(resampler, data::MarketDataPoint{T,P,V})`
- `OnlineStatsBase.value(resampler)`
- `OnlineStatsBase._merge!(r1, r2)` (optional, for parallel processing)

**Automatic Interface** (inherited from OnlineStatsBase):
- `fit!(resampler, data)`: Public fitting function
- `nobs(resampler)`: Number of observations processed
- `merge!(r1, r2)`: Public merging function

---

## Resampler Types

### MarketResampler

```julia
struct MarketResampler{T,P,V} <: OnlineStat{MarketDataPoint{T,P,V}}
    price_resampler::AbstractResampler{T,P,V}
    volume_resampler::AbstractResampler{T,P,V}
end
```

**Description**: Main composite resampler combining price and volume strategies.

**Constructors**:
```julia
# Default types with price method selection
MarketResampler(period::Period; price_method::Symbol = :ohlc, validate_chronological::Bool = false)

# Explicit types with price method selection
MarketResampler{T,P,V}(period::Period; price_method::Symbol = :ohlc, validate_chronological::Bool = false)
```

**Parameters**:
- `period`: Time period for resampling (e.g., `Minute(1)`, `Second(30)`)
- `price_method`: Either `:ohlc` or `:mean`
- `validate_chronological`: If `true`, validates that data points arrive in chronological order and throws `ArgumentError` for out-of-order data

**Return Value**: When calling `value(resampler)`:
```julia
(
    price = price_resampler_result,  # OHLC or Mean result
    volume = volume_sum,             # Total volume
    window = current_time_window     # TimeWindow
)
```

**Examples**:
```julia
# OHLC resampler (default)
ohlc_resampler = MarketResampler(Minute(1))

# Mean price resampler
mean_resampler = MarketResampler(Minute(5), price_method=:mean)

# High-precision resampler
using FixedPointDecimals
precision_resampler = MarketResampler{DateTime, FixedDecimal{Int64,4}, FixedDecimal{Int64,2}}(
    Minute(1), price_method=:ohlc
)

# Chronological validation enabled
validated_resampler = MarketResampler(Minute(1), validate_chronological=true)
fit!(validated_resampler, MarketDataPoint(DateTime(2024,1,1,9,30,0), 100.0, 1000.0))
# This will throw ArgumentError due to out-of-order timestamp
# fit!(validated_resampler, MarketDataPoint(DateTime(2024,1,1,9,29,0), 99.0, 800.0))
```

---

### OHLCResampler

```julia
mutable struct OHLCResampler{T,P,V} <: AbstractResampler{T,P,V}
    period::Period
    current_window::Union{TimeWindow{T}, Nothing}
    ohlc::Union{OHLC{P}, Nothing}
    volume_sum::V
    count::Int
end
```

**Description**: Resampler that aggregates data into OHLC format.

**Constructors**:
```julia
# Default types
OHLCResampler(period::Period; validate_chronological::Bool = false)

# Explicit types
OHLCResampler{T,P,V}(period::Period; validate_chronological::Bool = false)
```

**Return Value**: When calling `value(resampler)`:
```julia
(
    ohlc = OHLC{P}(...) | nothing,  # OHLC structure or nothing if no data
    volume = volume_sum,             # Total volume in current window
    window = current_window          # Current TimeWindow
)
```

**Examples**:
```julia
resampler = OHLCResampler(Minute(1))
fit!(resampler, MarketDataPoint(now(), 100.0, 1000.0))
result = value(resampler)
println(result.ohlc)  # OHLC(100.0, 100.0, 100.0, 100.0)
```

---

### MeanResampler

```julia
mutable struct MeanResampler{T,P,V} <: AbstractResampler{T,P,V}
    period::Period
    current_window::Union{TimeWindow{T}, Nothing}
    price_sum::P
    volume_sum::V
    count::Int
end
```

**Description**: Resampler that calculates mean prices over time periods.

**Constructors**:
```julia
# Default types
MeanResampler(period::Period; validate_chronological::Bool = false)

# Explicit types
MeanResampler{T,P,V}(period::Period; validate_chronological::Bool = false)
```

**Return Value**: When calling `value(resampler)`:
```julia
(
    mean_price = price_sum / count,  # Average price in window
    volume = volume_sum,             # Total volume in current window
    window = current_window          # Current TimeWindow
)
```

**Examples**:
```julia
resampler = MeanResampler(Minute(5))
fit!(resampler, MarketDataPoint(now(), 100.0, 1000.0))
fit!(resampler, MarketDataPoint(now(), 110.0, 500.0))
result = value(resampler)
println(result.mean_price)  # 105.0
```

---

### SumResampler

```julia
mutable struct SumResampler{T,P,V} <: AbstractResampler{T,P,V}
    period::Period
    current_window::Union{TimeWindow{T}, Nothing}
    sum::V
    count::Int
end
```

**Description**: Resampler that sums values over time periods (typically used for volumes).

**Constructors**:
```julia
# Default types
SumResampler(period::Period; validate_chronological::Bool = false)

# Explicit types
SumResampler{T,P,V}(period::Period; validate_chronological::Bool = false)
```

**Return Value**: When calling `value(resampler)`:
```julia
(
    sum = accumulated_sum,    # Sum of values in current window
    window = current_window   # Current TimeWindow
)
```

**Examples**:
```julia
resampler = SumResampler(Minute(1))
fit!(resampler, MarketDataPoint(now(), 100.0, 1000.0))  # Uses volume
fit!(resampler, MarketDataPoint(now(), 105.0, 500.0))   # Uses volume
result = value(resampler)
println(result.sum)  # 1500.0
```

---

## Core Functions

### OnlineStatsBase Interface

#### fit!(resampler, data)

```julia
fit!(resampler::AbstractResampler, data::MarketDataPoint)
```

**Description**: Process a new market data point through the resampler.

**Arguments**:
- `resampler`: Any resampler instance
- `data`: MarketDataPoint with compatible types

**Returns**: The resampler instance (for chaining)

**Side Effects**: Updates internal state; may trigger window transitions

**Examples**:
```julia
resampler = MarketResampler(Minute(1))
data = MarketDataPoint(DateTime(2024,1,1,9,30,0), 100.0, 1000.0)
fit!(resampler, data)

# Chaining
fit!(fit!(resampler, data1), data2)
```

---

#### value(resampler)

```julia
value(resampler::AbstractResampler)
```

**Description**: Extract current aggregated values from the resampler.

**Arguments**:
- `resampler`: Any resampler instance

**Returns**: Named tuple with resampler-specific structure (see individual resampler documentation)

**Examples**:
```julia
resampler = OHLCResampler(Minute(1))
# ... fit data ...
result = value(resampler)
println("OHLC: $(result.ohlc)")
println("Volume: $(result.volume)")
```

---

#### nobs(resampler)

```julia
nobs(resampler::AbstractResampler) -> Int
```

**Description**: Get the number of observations processed in the current time window.

**Arguments**:
- `resampler`: Any resampler instance

**Returns**: Integer count of data points in current window

**Examples**:
```julia
resampler = MarketResampler(Minute(1))
println("Initial count: $(nobs(resampler))")  # 0
fit!(resampler, data)
println("After data: $(nobs(resampler))")     # 1
```

---

#### merge!(r1, r2)

```julia
merge!(r1::T, r2::T) where T <: AbstractResampler
```

**Description**: Merge two resamplers of the same type for parallel processing.

**Arguments**:
- `r1`: Target resampler (will be modified)
- `r2`: Source resampler (will be consumed)

**Returns**: Modified `r1` containing combined results

**Requirements**: Both resamplers must have compatible types and time windows

**Examples**:
```julia
# Parallel processing example
r1 = OHLCResampler(Minute(1))
r2 = OHLCResampler(Minute(1))

# Process different data chunks
fit!(r1, data_chunk_1...)
fit!(r2, data_chunk_2...)

# Combine results
merge!(r1, r2)
combined_result = value(r1)
```

---

### Utility Functions

#### window_end(window)

```julia
window_end(window::TimeWindow{T}) -> T
```

**Description**: Calculate the end time of a time window.

**Arguments**:
- `window`: TimeWindow instance

**Returns**: End timestamp (start_time + period)

**Examples**:
```julia
window = TimeWindow{DateTime}(DateTime(2024,1,1,9,30,0), Minute(1))
end_time = window_end(window)  # DateTime(2024,1,1,9,31,0)
```

---

#### belongs_to_window(datetime, window)

```julia
belongs_to_window(datetime::T, window::TimeWindow{T}) -> Bool
```

**Description**: Check if a timestamp falls within a time window.

**Arguments**:
- `datetime`: Timestamp to check
- `window`: TimeWindow to check against

**Returns**: `true` if timestamp is in [start_time, end_time), `false` otherwise

**Note**: Window is inclusive of start time, exclusive of end time

**Examples**:
```julia
window = TimeWindow{DateTime}(DateTime(2024,1,1,9,30,0), Minute(1))
belongs_to_window(DateTime(2024,1,1,9,30,30), window)  # true
belongs_to_window(DateTime(2024,1,1,9,31,0), window)   # false (next window)
```

---

#### next_window(window)

```julia
next_window(window::TimeWindow{T}) -> TimeWindow{T}
```

**Description**: Create the next consecutive time window.

**Arguments**:
- `window`: Current time window

**Returns**: New TimeWindow starting at current window's end time

**Examples**:
```julia
current = TimeWindow{DateTime}(DateTime(2024,1,1,9,30,0), Minute(1))
next = next_window(current)
# next.start_time == DateTime(2024,1,1,9,31,0)
# next.period == Minute(1)
```

---

## Type Constructors

### Default Type Constructors

These constructors use `DateTime`, `Float64`, `Float64` as default types:

```julia
MarketResampler(period::Period; price_method=:ohlc, validate_chronological=false)
OHLCResampler(period::Period; validate_chronological=false)
MeanResampler(period::Period; validate_chronological=false)
SumResampler(period::Period; validate_chronological=false)
MarketDataPoint(datetime::DateTime, price::Real, volume::Real)
```

### Explicit Type Constructors

For custom numeric types or high-precision applications:

```julia
MarketResampler{T,P,V}(period::Period; price_method=:ohlc, validate_chronological=false)
OHLCResampler{T,P,V}(period::Period; validate_chronological=false)
MeanResampler{T,P,V}(period::Period; validate_chronological=false)
SumResampler{T,P,V}(period::Period; validate_chronological=false)
MarketDataPoint{T,P,V}(datetime::T, price::P, volume::V)
OHLC{P}(open::P, high::P, low::P, close::P)
TimeWindow{T}(start_time::T, period::Period)
```

---

## Return Values

### MarketResampler value() Return

```julia
(
    price = (
        ohlc = OHLC{P}(...) | nothing,     # If using :ohlc method
        # OR
        mean_price = P(...),               # If using :mean method
        volume = V(...),                   # Volume from price resampler
        window = TimeWindow{T}(...)        # Current window
    ),
    volume = V(...),                       # Total volume (same as price.volume)
    window = TimeWindow{T}(...)            # Current window (same as price.window)
)
```

### OHLCResampler value() Return

```julia
(
    ohlc = OHLC{P}(...) | nothing,    # OHLC data or nothing if no data yet
    volume = V(...),                  # Accumulated volume in current window
    window = TimeWindow{T}(...) | nothing  # Current window or nothing if no data yet
)
```

### MeanResampler value() Return

```julia
(
    mean_price = P(...),              # Average price in current window
    volume = V(...),                  # Accumulated volume in current window
    window = TimeWindow{T}(...) | nothing  # Current window or nothing if no data yet
)
```

### SumResampler value() Return

```julia
(
    sum = V(...),                     # Sum of values in current window
    window = TimeWindow{T}(...) | nothing  # Current window or nothing if no data yet
)
```

---

## Type Compatibility

### Supported Period Types

All Julia `Dates.Period` subtypes are supported:
- `Nanosecond`, `Microsecond`, `Millisecond`
- `Second`, `Minute`, `Hour`
- `Day`, `Week`, `Month`, `Year`

### Supported Timestamp Types

Any type `T` that supports:
- Arithmetic with `Period` types (`T + Period -> T`)
- Comparison operations (`<`, `<=`, `==`, `>=`, `>`)
- `floor(datetime::T, period::Period) -> T`

Common examples:
- `DateTime` (from Dates.jl)
- `NanoDate` (from NanoDates.jl)
- `ZonedDateTime` (from TimeZones.jl)

### Supported Numeric Types

Any numeric type that supports:
- `zero(Type)` and `one(Type)` for initialization
- Basic arithmetic (`+`, `-`, `*`, `/`)
- Comparison operations (`<`, `>`, `min`, `max`)

Common examples:
- `Float64`, `Float32`, `BigFloat`
- `FixedDecimal{T,N}` (from FixedPointDecimals.jl)
- `Rational{T}` (built-in Julia type)
- `Int64`, `Int32`, `BigInt` (for volumes)

---

## Performance Notes

### Memory Complexity
- **Space**: O(1) - Constant memory usage regardless of data volume
- **Allocations**: Zero allocations in steady-state processing

### Time Complexity
- **fit!()**: O(1) - Constant time per operation
- **value()**: O(1) - Constant time access
- **merge!()**: O(1) - Constant time merge operation

### Type Stability
All operations are type-stable when using concrete types, enabling Julia's compiler optimizations.

### SIMD Optimization
Numeric operations automatically leverage Julia's SIMD capabilities when using appropriate numeric types.