module OnlineResampler

using OnlineStatsBase
using Dates

export MarketResampler, OHLCResampler, MeanResampler, SumResampler
export fit!, value, merge!
export MarketDataPoint, OHLC, TimeWindow
export window_end, belongs_to_window, next_window

"""
    MarketDataPoint{T,P,V}

A structure representing a single market data observation containing timestamp, price, and volume information.

This is the fundamental data unit processed by all resampling algorithms in the OnlineResampler package.
The structure is parametrically typed to support various numeric and temporal types commonly used in
financial applications.

# Type Parameters
- `T`: Timestamp type (e.g., `DateTime`, `NanoDate`, `ZonedDateTime`)
- `P`: Price type (e.g., `Float64`, `FixedDecimal`, `Rational`)
- `V`: Volume type (e.g., `Float64`, `FixedDecimal`, `Int64`)

# Fields
- `datetime::T`: The timestamp of this market data point
- `price::P`: The price value at this timestamp
- `volume::V`: The volume traded at this timestamp

# Examples
```julia
using OnlineResampler, Dates

# Basic construction with default types
data = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.50, 1000.0)

# Explicit type construction
data = MarketDataPoint{DateTime, Float64, Float64}(
    DateTime(2024, 1, 1, 9, 30, 0),
    100.50,
    1000.0
)

# Using custom numeric types
using FixedPointDecimals
price_data = MarketDataPoint{DateTime, FixedDecimal{Int64,4}, FixedDecimal{Int64,2}}(
    DateTime(2024, 1, 1, 9, 30, 0),
    FixedDecimal{Int64,4}(100.5012),
    FixedDecimal{Int64,2}(1000.50)
)
```

See also: [`MarketResampler`](@ref), [`OHLCResampler`](@ref), [`MeanResampler`](@ref)
"""
struct MarketDataPoint{T,P,V}
    datetime::T
    price::P
    volume::V
end

# Convenience constructor for common case
MarketDataPoint(datetime::DateTime, price::Real, volume::Real) =
    MarketDataPoint{DateTime, Float64, Float64}(datetime, Float64(price), Float64(volume))

"""
    abstract type AbstractResampler{T,P,V} <: OnlineStat{MarketDataPoint{T,P,V}} end

Abstract base type for all market data resampling algorithms.

This type extends `OnlineStat` from OnlineStatsBase.jl, providing the standard interface
for online statistical computations while specializing for financial market data resampling.
All concrete resampler types (`OHLCResampler`, `MeanResampler`, `SumResampler`) inherit from this type.

# Type Parameters
- `T`: Timestamp type (e.g., `DateTime`, `NanoDate`)
- `P`: Price type (e.g., `Float64`, `FixedDecimal`)
- `V`: Volume type (e.g., `Float64`, `FixedDecimal`)

# Interface
All subtypes must implement:
- `OnlineStatsBase._fit!(resampler, data::MarketDataPoint{T,P,V})`
- `OnlineStatsBase.value(resampler)`
- `OnlineStatsBase._merge!(resampler1, resampler2)` (optional, for parallel processing)

See also: [`OHLCResampler`](@ref), [`MeanResampler`](@ref), [`SumResampler`](@ref)
"""
abstract type AbstractResampler{T,P,V} <: OnlineStat{MarketDataPoint{T,P,V}} end

"""
    OHLC{P}

A structure representing Open, High, Low, Close (OHLC) price data for a time period.

This is the standard representation of price action over a time interval, commonly used
in financial analysis and charting. The OHLC structure captures the essential price
movement information within a resampling window.

# Type Parameters
- `P`: Price type (e.g., `Float64`, `FixedDecimal`, `Rational`)

# Fields
- `open::P`: The first price in the time period
- `high::P`: The highest price during the time period
- `low::P`: The lowest price during the time period
- `close::P`: The last price in the time period

# Examples
```julia
# Create OHLC with Float64 prices
ohlc = OHLC{Float64}(100.0, 105.5, 98.2, 103.7)

# Access individual components
open_price = ohlc.open    # 100.0
high_price = ohlc.high    # 105.5
low_price = ohlc.low      # 98.2
close_price = ohlc.close  # 103.7
```

See also: [`OHLCResampler`](@ref)
"""
struct OHLC{P}
    open::P
    high::P
    low::P
    close::P
end

Base.show(io::IO, ohlc::OHLC) = print(io, "OHLC($(ohlc.open), $(ohlc.high), $(ohlc.low), $(ohlc.close))")

"""
    TimeWindow{T}

Represents a time interval used for grouping market data during resampling operations.

A `TimeWindow` defines a specific time interval with a start time and duration (period).
Market data points that fall within this window are aggregated together. This structure
is fundamental to the resampling process, determining how data is grouped temporally.

# Type Parameters
- `T`: Timestamp type (e.g., `DateTime`, `NanoDate`)

# Fields
- `start_time::T`: The beginning of the time window (inclusive)
- `period::Period`: The duration of the window (e.g., `Minute(1)`, `Hour(1)`)

# Examples
```julia
using Dates

# Create a 1-minute window starting at 9:30 AM
window = TimeWindow{DateTime}(DateTime(2024, 1, 1, 9, 30, 0), Minute(1))

# Check if a timestamp belongs to this window
timestamp = DateTime(2024, 1, 1, 9, 30, 30)
belongs = belongs_to_window(timestamp, window)  # true

# Get the end time of the window
end_time = window_end(window)  # 2024-01-01T09:31:00

# Move to the next window
next_win = next_window(window)  # starts at 2024-01-01T09:31:00
```

See also: [`window_end`](@ref), [`belongs_to_window`](@ref), [`next_window`](@ref)
"""
struct TimeWindow{T}
    start_time::T
    period::Period
end

function window_end(window::TimeWindow{T}) where T
    return window.start_time + window.period
end

function belongs_to_window(datetime::T, window::TimeWindow{T}) where T
    return window.start_time <= datetime < window_end(window)
end

function next_window(window::TimeWindow{T}) where T
    return TimeWindow{T}(window_end(window), window.period)
end

"""
    OHLCResampler{T,P,V} <: AbstractResampler{T,P,V}

A resampler that aggregates market data into OHLC (Open, High, Low, Close) format over fixed time periods.

This resampler processes streaming market data and produces OHLC candlestick data for specified time intervals.
It tracks the first price (Open), highest price (High), lowest price (Low), and last price (Close) within
each time window, along with the total volume. This is the most common format for financial data visualization
and technical analysis.

The resampler automatically handles time window transitions, finalizing completed windows when new data
belongs to a subsequent time period.

# Type Parameters
- `T`: Timestamp type (e.g., `DateTime`, `NanoDate`)
- `P`: Price type (e.g., `Float64`, `FixedDecimal`)
- `V`: Volume type (e.g., `Float64`, `FixedDecimal`)

# Fields
- `period::Period`: The resampling time period (e.g., `Minute(1)`, `Hour(1)`)
- `current_window::Union{TimeWindow{T}, Nothing}`: The currently active time window
- `ohlc::Union{OHLC{P}, Nothing}`: Current OHLC values for the active window
- `volume_sum::V`: Accumulated volume for the current window
- `count::Int`: Number of data points processed in current window

# Examples
```julia
using OnlineResampler, OnlineStatsBase, Dates

# Create a 1-minute OHLC resampler
resampler = OHLCResampler(Minute(1))

# Process market data
data1 = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0)
data2 = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 30), 105.0, 800.0)
data3 = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 45), 98.0, 1200.0)

fit!(resampler, data1)
fit!(resampler, data2)
fit!(resampler, data3)

# Get current OHLC values
result = value(resampler)
println(result.ohlc)  # OHLC(100.0, 105.0, 98.0, 98.0)
println(result.volume)  # 3000.0
```

See also: [`MarketResampler`](@ref), [`MeanResampler`](@ref), [`OHLC`](@ref)
"""
mutable struct OHLCResampler{T,P,V} <: AbstractResampler{T,P,V}
    period::Period
    current_window::Union{TimeWindow{T}, Nothing}
    ohlc::Union{OHLC{P}, Nothing}
    volume_sum::V
    count::Int
    validate_chronological::Bool
    last_timestamp::Union{T, Nothing}

    function OHLCResampler{T,P,V}(period::Period; validate_chronological::Bool = false) where {T,P,V}
        new{T,P,V}(period, nothing, nothing, zero(V), 0, validate_chronological, nothing)
    end
end

# Convenience constructors
OHLCResampler(period::Period; validate_chronological::Bool = false) =
    OHLCResampler{DateTime,Float64,Float64}(period; validate_chronological=validate_chronological)

"""
    MeanResampler{T,P,V} <: AbstractResampler{T,P,V}

Resamples price data by calculating mean price over specified time periods.
"""
mutable struct MeanResampler{T,P,V} <: AbstractResampler{T,P,V}
    period::Period
    current_window::Union{TimeWindow{T}, Nothing}
    price_sum::P
    volume_sum::V
    count::Int
    validate_chronological::Bool
    last_timestamp::Union{T, Nothing}

    function MeanResampler{T,P,V}(period::Period; validate_chronological::Bool = false) where {T,P,V}
        new{T,P,V}(period, nothing, zero(P), zero(V), 0, validate_chronological, nothing)
    end
end

MeanResampler(period::Period; validate_chronological::Bool = false) =
    MeanResampler{DateTime,Float64,Float64}(period; validate_chronological=validate_chronological)

"""
    SumResampler{T,P,V} <: AbstractResampler{T,P,V}

Resamples data by summing values over specified time periods (used for volume).
"""
mutable struct SumResampler{T,P,V} <: AbstractResampler{T,P,V}
    period::Period
    current_window::Union{TimeWindow{T}, Nothing}
    sum::V
    count::Int
    validate_chronological::Bool
    last_timestamp::Union{T, Nothing}

    function SumResampler{T,P,V}(period::Period; validate_chronological::Bool = false) where {T,P,V}
        new{T,P,V}(period, nothing, zero(V), 0, validate_chronological, nothing)
    end
end

SumResampler(period::Period; validate_chronological::Bool = false) =
    SumResampler{DateTime,Float64,Float64}(period; validate_chronological=validate_chronological)

"""
    MarketResampler{T,P,V}

A composite resampler that combines separate price and volume resampling strategies.

`MarketResampler` is the primary interface for resampling market data. It combines a price resampler
(either OHLC or mean-based) with a volume resampler (sum-based) to provide comprehensive market data
aggregation over specified time periods.

This resampler automatically coordinates between price and volume aggregation strategies, ensuring
consistent time window handling and providing a unified interface for accessing both price and volume
statistics.

# Type Parameters
- `T`: Timestamp type (e.g., `DateTime`, `NanoDate`)
- `P`: Price type (e.g., `Float64`, `FixedDecimal`)
- `V`: Volume type (e.g., `Float64`, `FixedDecimal`)

# Fields
- `price_resampler::AbstractResampler{T,P,V}`: Strategy for aggregating prices (OHLC or Mean)
- `volume_resampler::AbstractResampler{T,P,V}`: Strategy for aggregating volumes (always Sum)

# Examples
```julia
using OnlineResampler, OnlineStatsBase, Dates

# Create OHLC resampler (default)
ohlc_resampler = MarketResampler(Minute(1))

# Create mean price resampler
mean_resampler = MarketResampler(Minute(5), price_method=:mean)

# With explicit types for high precision
using FixedPointDecimals
precision_resampler = MarketResampler{DateTime, FixedDecimal{Int64,4}, FixedDecimal{Int64,2}}(
    Minute(1), price_method=:ohlc
)

# Process data
data = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0)
fit!(ohlc_resampler, data)

# Access results
result = value(ohlc_resampler)
println("Price OHLC: ", result.price.ohlc)
println("Volume: ", result.volume)
println("Window: ", result.window)
```

See also: [`OHLCResampler`](@ref), [`MeanResampler`](@ref), [`SumResampler`](@ref)
"""
struct MarketResampler{T,P,V} <: OnlineStat{MarketDataPoint{T,P,V}}
    price_resampler::AbstractResampler{T,P,V}
    volume_resampler::AbstractResampler{T,P,V}
end

"""
    MarketResampler{T,P,V}(period::Period; price_method=:ohlc, validate_chronological=false)

Create a MarketResampler with specified types and period.

# Example
```julia
using NanoDates, FixedPointDecimals

# Create a resampler with NanoDates and FixedPointDecimals
resampler = MarketResampler{NanoDate, FixedDecimal{Int64,4}, FixedDecimal{Int64,2}}(
    Minute(1), price_method=:ohlc
)

# Default DateTime/Float64 version
resampler = MarketResampler(Minute(1))
```
"""
function MarketResampler{T,P,V}(period::Period; price_method::Symbol=:ohlc, validate_chronological::Bool=false) where {T,P,V}
    price_resampler = if price_method == :ohlc
        OHLCResampler{T,P,V}(period; validate_chronological=validate_chronological)
    elseif price_method == :mean
        MeanResampler{T,P,V}(period; validate_chronological=validate_chronological)
    else
        throw(ArgumentError("price_method must be :ohlc or :mean"))
    end

    volume_resampler = SumResampler{T,P,V}(period; validate_chronological=validate_chronological)
    return MarketResampler{T,P,V}(price_resampler, volume_resampler)
end

# Convenience constructor for common case
MarketResampler(period::Period; price_method::Symbol=:ohlc, validate_chronological::Bool=false) =
    MarketResampler{DateTime,Float64,Float64}(period; price_method=price_method, validate_chronological=validate_chronological)

# Helper function for chronological validation
function _validate_chronological_order!(resampler::AbstractResampler{T,P,V}, data::MarketDataPoint{T,P,V}) where {T,P,V}
    if resampler.validate_chronological
        if resampler.last_timestamp !== nothing && data.datetime < resampler.last_timestamp
            throw(ArgumentError(
                "Data not in chronological order: $(data.datetime) < $(resampler.last_timestamp). " *
                "Received data point with timestamp $(data.datetime) but last processed timestamp was $(resampler.last_timestamp). " *
                "To disable this check, set validate_chronological=false in the constructor."
            ))
        end
        resampler.last_timestamp = data.datetime
    end
end

# OnlineStatsBase interface implementation
OnlineStatsBase.nobs(r::AbstractResampler) = r.count
OnlineStatsBase.nobs(r::MarketResampler) = nobs(r.price_resampler)

function OnlineStatsBase._fit!(resampler::OHLCResampler{T,P,V}, data::MarketDataPoint{T,P,V}) where {T,P,V}
    # Validate chronological order if enabled
    _validate_chronological_order!(resampler, data)

    if resampler.current_window === nothing
        # Initialize first window
        window_start = floor(data.datetime, resampler.period)
        resampler.current_window = TimeWindow{T}(window_start, resampler.period)
    end

    if !belongs_to_window(data.datetime, resampler.current_window)
        # Data belongs to a new window, finalize current and move to next
        _finalize_window!(resampler)
        window_start = floor(data.datetime, resampler.period)
        resampler.current_window = TimeWindow{T}(window_start, resampler.period)
    end

    # Update OHLC for current window
    if resampler.ohlc === nothing
        resampler.ohlc = OHLC{P}(data.price, data.price, data.price, data.price)
    else
        ohlc = resampler.ohlc
        resampler.ohlc = OHLC{P}(
            ohlc.open,  # Keep first price as open
            max(ohlc.high, data.price),
            min(ohlc.low, data.price),
            data.price  # Last price becomes close
        )
    end

    resampler.volume_sum += data.volume
    resampler.count += 1

    return resampler
end

function OnlineStatsBase._fit!(resampler::MeanResampler{T,P,V}, data::MarketDataPoint{T,P,V}) where {T,P,V}
    # Validate chronological order if enabled
    _validate_chronological_order!(resampler, data)

    if resampler.current_window === nothing
        window_start = floor(data.datetime, resampler.period)
        resampler.current_window = TimeWindow{T}(window_start, resampler.period)
    end

    if !belongs_to_window(data.datetime, resampler.current_window)
        _finalize_window!(resampler)
        window_start = floor(data.datetime, resampler.period)
        resampler.current_window = TimeWindow{T}(window_start, resampler.period)
    end

    resampler.price_sum += data.price
    resampler.volume_sum += data.volume
    resampler.count += 1

    return resampler
end

function OnlineStatsBase._fit!(resampler::SumResampler{T,P,V}, data::MarketDataPoint{T,P,V}) where {T,P,V}
    # Validate chronological order if enabled
    _validate_chronological_order!(resampler, data)

    if resampler.current_window === nothing
        window_start = floor(data.datetime, resampler.period)
        resampler.current_window = TimeWindow{T}(window_start, resampler.period)
    end

    if !belongs_to_window(data.datetime, resampler.current_window)
        _finalize_window!(resampler)
        window_start = floor(data.datetime, resampler.period)
        resampler.current_window = TimeWindow{T}(window_start, resampler.period)
    end

    resampler.sum += data.volume
    resampler.count += 1

    return resampler
end

function OnlineStatsBase._fit!(resampler::MarketResampler{T,P,V}, data::MarketDataPoint{T,P,V}) where {T,P,V}
    fit!(resampler.price_resampler, data)
    fit!(resampler.volume_resampler, data)
    return resampler
end

function _finalize_window!(resampler::AbstractResampler{T,P,V}) where {T,P,V}
    # Reset the current window data
    if resampler isa OHLCResampler
        resampler.ohlc = nothing
        resampler.volume_sum = zero(V)
    elseif resampler isa MeanResampler
        resampler.price_sum = zero(P)
        resampler.volume_sum = zero(V)
    elseif resampler isa SumResampler
        resampler.sum = zero(V)
    end
    resampler.count = 0
end

# Value extraction
function OnlineStatsBase.value(resampler::OHLCResampler{T,P,V}) where {T,P,V}
    if resampler.ohlc === nothing
        return (ohlc=nothing, volume=zero(V), window=resampler.current_window)
    end
    return (ohlc=resampler.ohlc, volume=resampler.volume_sum, window=resampler.current_window)
end

function OnlineStatsBase.value(resampler::MeanResampler{T,P,V}) where {T,P,V}
    if resampler.count == 0
        return (mean_price=zero(P)/one(P), volume=zero(V), window=resampler.current_window)  # NaN equivalent
    end
    return (
        mean_price=resampler.price_sum / resampler.count,
        volume=resampler.volume_sum,
        window=resampler.current_window
    )
end

function OnlineStatsBase.value(resampler::SumResampler{T,P,V}) where {T,P,V}
    return (sum=resampler.sum, window=resampler.current_window)
end

function OnlineStatsBase.value(resampler::MarketResampler{T,P,V}) where {T,P,V}
    price_value = value(resampler.price_resampler)
    volume_value = value(resampler.volume_resampler)
    return (price=price_value, volume=volume_value.sum, window=price_value.window)
end

# Merge implementation for parallel processing
function OnlineStatsBase._merge!(resampler1::OHLCResampler{T,P,V}, resampler2::OHLCResampler{T,P,V}) where {T,P,V}
    if resampler2.ohlc !== nothing
        if resampler1.ohlc === nothing
            resampler1.ohlc = resampler2.ohlc
        else
            # Combine OHLC data
            ohlc1, ohlc2 = resampler1.ohlc, resampler2.ohlc
            resampler1.ohlc = OHLC{P}(
                ohlc1.open,  # Keep first open
                max(ohlc1.high, ohlc2.high),
                min(ohlc1.low, ohlc2.low),
                ohlc2.close  # Use last close
            )
        end
    end
    resampler1.volume_sum += resampler2.volume_sum
    resampler1.count += resampler2.count
    return resampler1
end

function OnlineStatsBase._merge!(resampler1::MeanResampler{T,P,V}, resampler2::MeanResampler{T,P,V}) where {T,P,V}
    resampler1.price_sum += resampler2.price_sum
    resampler1.volume_sum += resampler2.volume_sum
    resampler1.count += resampler2.count
    return resampler1
end

function OnlineStatsBase._merge!(resampler1::SumResampler{T,P,V}, resampler2::SumResampler{T,P,V}) where {T,P,V}
    resampler1.sum += resampler2.sum
    resampler1.count += resampler2.count
    return resampler1
end

end # module OnlineResampler
