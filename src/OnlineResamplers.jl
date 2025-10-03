module OnlineResamplers

using OnlineStatsBase
using Dates

export MarketResampler, OHLCResampler, MeanResampler, SumResampler
export AbstractResampler
export fit!, value, merge!
export MarketDataPoint, OHLC
export AbstractWindow, TimeWindow, VolumeWindow, TickWindow
export window_end, belongs_to_window, next_window, should_finalize

"""
    MarketDataPoint{T,P,V}

A structure representing a single market data observation containing timestamp, price, and volume information.

This is the fundamental data unit processed by all resampling algorithms in the OnlineResamplers package.
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
using OnlineResamplers, Dates

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
    abstract type AbstractWindow end

Abstract base type for all window types used in resampling.

A window defines when data should be aggregated together and when a new window should begin.
Different window types enable different resampling criteria: time-based, volume-based, tick-based, etc.

# Interface
All subtypes must implement:
- `should_finalize(data::MarketDataPoint, window::AbstractWindow)::Bool` - Returns true if the data point belongs to a new window
- `next_window(window::AbstractWindow, data::MarketDataPoint)` - Creates the next window starting from the given data point
- `belongs_to_window(data::MarketDataPoint, window::AbstractWindow)::Bool` - Returns true if data belongs to current window

See also: [`TimeWindow`](@ref), [`VolumeWindow`](@ref), [`TickWindow`](@ref)
"""
abstract type AbstractWindow end

"""
    abstract type AbstractResampler{T,P,V,W<:AbstractWindow} <: OnlineStat{MarketDataPoint{T,P,V}} end

Abstract base type for all market data resampling algorithms.

This type extends `OnlineStat` from OnlineStatsBase.jl, providing the standard interface
for online statistical computations while specializing for financial market data resampling.
All concrete resampler types (`OHLCResampler`, `MeanResampler`, `SumResampler`) inherit from this type.

# Type Parameters
- `T`: Timestamp type (e.g., `DateTime`, `NanoDate`)
- `P`: Price type (e.g., `Float64`, `FixedDecimal`)
- `V`: Volume type (e.g., `Float64`, `FixedDecimal`)
- `W`: Window type (e.g., `TimeWindow`, `VolumeWindow`)

# Interface
All subtypes must implement:
- `OnlineStatsBase._fit!(resampler, data::MarketDataPoint{T,P,V})`
- `OnlineStatsBase.value(resampler)`
- `OnlineStatsBase._merge!(resampler1, resampler2)` (optional, for parallel processing)

See also: [`OHLCResampler`](@ref), [`MeanResampler`](@ref), [`SumResampler`](@ref)
"""
abstract type AbstractResampler{T,P,V,W<:AbstractWindow} <: OnlineStat{MarketDataPoint{T,P,V}} end

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
    TimeWindow{T} <: AbstractWindow

Represents a time-based window for grouping market data during resampling operations.

A `TimeWindow` defines a specific time interval with a start time and duration (period).
Market data points that fall within this window are aggregated together. This is the
traditional time-based resampling approach (e.g., 1-minute bars, 5-minute bars).

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
data = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 30), 100.0, 1000.0)
belongs = belongs_to_window(data, window)  # true

# Get the end time of the window
end_time = window_end(window)  # 2024-01-01T09:31:00

# Move to the next window
next_win = next_window(window, data)  # starts at 2024-01-01T09:31:00
```

See also: [`VolumeWindow`](@ref), [`TickWindow`](@ref), [`AbstractWindow`](@ref)
"""
struct TimeWindow{T} <: AbstractWindow
    start_time::T
    period::Period
end

function window_end(window::TimeWindow{T}) where T
    return window.start_time + window.period
end

function belongs_to_window(data::MarketDataPoint{T}, window::TimeWindow{T}) where T
    return window.start_time <= data.datetime < window_end(window)
end

function should_finalize(data::MarketDataPoint{T}, window::TimeWindow{T}) where T
    return !belongs_to_window(data, window)
end

function next_window(window::TimeWindow{T}, data::MarketDataPoint{T}) where T
    window_start = floor(data.datetime, window.period)
    return TimeWindow{T}(window_start, window.period)
end

# Backward compatibility: old API for TimeWindow
function belongs_to_window(datetime::T, window::TimeWindow{T}) where T
    return window.start_time <= datetime < window_end(window)
end

function next_window(window::TimeWindow{T}) where T
    return TimeWindow{T}(window_end(window), window.period)
end

"""
    VolumeWindow{V} <: AbstractWindow

Represents a volume-based window for grouping market data during resampling operations.

A `VolumeWindow` aggregates data until the cumulative volume reaches a target threshold,
then starts a new window. This is useful for volume-based bars, where each bar represents
a fixed amount of traded volume rather than a fixed time period.

# Type Parameters
- `V`: Volume type (e.g., `Float64`, `FixedDecimal`, `Int64`)

# Fields
- `target_volume::V`: The cumulative volume threshold that triggers a new window
- `current_volume::V`: The accumulated volume in the current window

# Examples
```julia
# Create a window that resets every 1000 units of volume
window = VolumeWindow{Float64}(1000.0, 0.0)

# Process data - window will finalize when cumulative volume >= 1000
data1 = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 600.0)
data2 = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 5), 101.0, 500.0)  # Total 1100, triggers new window

# Create a resampler with volume-based windows
resampler = OHLCResampler(VolumeWindow{Float64}(1000.0))
```

See also: [`TimeWindow`](@ref), [`TickWindow`](@ref), [`AbstractWindow`](@ref)
"""
mutable struct VolumeWindow{V} <: AbstractWindow
    target_volume::V
    current_volume::V
end

# Convenience constructor
VolumeWindow(target_volume::V) where V = VolumeWindow{V}(target_volume, zero(V))

function belongs_to_window(data::MarketDataPoint{T,P,V}, window::VolumeWindow{V}) where {T,P,V}
    return window.current_volume + data.volume < window.target_volume
end

function should_finalize(data::MarketDataPoint{T,P,V}, window::VolumeWindow{V}) where {T,P,V}
    return window.current_volume + data.volume >= window.target_volume
end

function next_window(window::VolumeWindow{V}, data::MarketDataPoint) where V
    return VolumeWindow{V}(window.target_volume, zero(V))
end

"""
    TickWindow <: AbstractWindow

Represents a tick-based window for grouping market data during resampling operations.

A `TickWindow` aggregates data for a fixed number of ticks (data points), regardless of
time or volume. Each window contains exactly `target_ticks` number of observations.

# Fields
- `target_ticks::Int`: The number of ticks that triggers a new window
- `current_ticks::Int`: The number of ticks processed in the current window

# Examples
```julia
# Create a window that resets every 100 ticks
window = TickWindow(100, 0)

# Each window will contain exactly 100 data points
resampler = OHLCResampler(TickWindow(100))
```

See also: [`TimeWindow`](@ref), [`VolumeWindow`](@ref), [`AbstractWindow`](@ref)
"""
mutable struct TickWindow <: AbstractWindow
    target_ticks::Int
    current_ticks::Int
end

# Convenience constructor
TickWindow(target_ticks::Int) = TickWindow(target_ticks, 0)

function belongs_to_window(data::MarketDataPoint, window::TickWindow)
    return window.current_ticks < window.target_ticks
end

function should_finalize(data::MarketDataPoint, window::TickWindow)
    return window.current_ticks >= window.target_ticks
end

function next_window(window::TickWindow, data::MarketDataPoint)
    return TickWindow(window.target_ticks, 0)
end

"""
    OHLCResampler{T,P,V,W} <: AbstractResampler{T,P,V,W}

A resampler that aggregates market data into OHLC (Open, High, Low, Close) format using a specified window type.

This resampler processes streaming market data and produces OHLC candlestick data for specified time intervals.
It tracks the first price (Open), highest price (High), lowest price (Low), and last price (Close) within
each time window, along with the total volume. This is the most common format for financial data visualization
and technical analysis.

The resampler automatically handles window transitions, finalizing completed windows when new data
belongs to a subsequent window.

# Type Parameters
- `T`: Timestamp type (e.g., `DateTime`, `NanoDate`)
- `P`: Price type (e.g., `Float64`, `FixedDecimal`)
- `V`: Volume type (e.g., `Float64`, `FixedDecimal`)
- `W`: Window type (e.g., `TimeWindow`, `VolumeWindow`, `TickWindow`)

# Fields
- `window_spec::W`: The window specification (period for time, target for volume/ticks)
- `current_window::Union{W, Nothing}`: The currently active window
- `ohlc::Union{OHLC{P}, Nothing}`: Current OHLC values for the active window
- `volume_sum::V`: Accumulated volume for the current window
- `count::Int`: Number of data points processed in current window

# Examples
```julia
using OnlineResamplers, OnlineStatsBase, Dates

# Create a time-based 1-minute OHLC resampler
resampler = OHLCResampler(Minute(1))

# Create a volume-based OHLC resampler (1000 volume per bar)
vol_resampler = OHLCResampler(VolumeWindow(1000.0))

# Create a tick-based OHLC resampler (100 ticks per bar)
tick_resampler = OHLCResampler(TickWindow(100))

# Process market data
data1 = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0)
fit!(resampler, data1)

# Get current OHLC values
result = value(resampler)
println(result.ohlc)  # OHLC(100.0, 100.0, 100.0, 100.0)
println(result.volume)  # 1000.0
```

See also: [`MarketResampler`](@ref), [`MeanResampler`](@ref), [`OHLC`](@ref)
"""
mutable struct OHLCResampler{T,P,V,W<:AbstractWindow} <: AbstractResampler{T,P,V,W}
    window_spec::W
    current_window::Union{W, Nothing}
    ohlc::Union{OHLC{P}, Nothing}
    volume_sum::V
    count::Int
    validate_chronological::Bool
    last_timestamp::Union{T, Nothing}

    function OHLCResampler{T,P,V,W}(window_spec::W; validate_chronological::Bool = false) where {T,P,V,W<:AbstractWindow}
        new{T,P,V,W}(window_spec, nothing, nothing, zero(V), 0, validate_chronological, nothing)
    end
end

# Convenience constructors for backward compatibility
OHLCResampler(period::Period; validate_chronological::Bool = false) =
    OHLCResampler{DateTime,Float64,Float64,TimeWindow{DateTime}}(
        TimeWindow{DateTime}(DateTime(0), period);
        validate_chronological=validate_chronological
    )

# 3-parameter constructor for backward compatibility
OHLCResampler{T,P,V}(period::Period; validate_chronological::Bool = false) where {T,P,V} =
    OHLCResampler{T,P,V,TimeWindow{T}}(
        TimeWindow{T}(T(0), period);
        validate_chronological=validate_chronological
    )

# Constructor for TimeWindow
OHLCResampler(window::TimeWindow{T}; validate_chronological::Bool = false) where T =
    OHLCResampler{T,Float64,Float64,TimeWindow{T}}(window; validate_chronological=validate_chronological)

# Constructor for VolumeWindow
OHLCResampler(window::VolumeWindow{V}; validate_chronological::Bool = false) where V =
    OHLCResampler{DateTime,Float64,V,VolumeWindow{V}}(window; validate_chronological=validate_chronological)

# Constructor for TickWindow
OHLCResampler(window::TickWindow; validate_chronological::Bool = false) =
    OHLCResampler{DateTime,Float64,Float64,TickWindow}(window; validate_chronological=validate_chronological)

"""
    MeanResampler{T,P,V,W} <: AbstractResampler{T,P,V,W}

Resamples price data by calculating mean price over specified windows.
"""
mutable struct MeanResampler{T,P,V,W<:AbstractWindow} <: AbstractResampler{T,P,V,W}
    window_spec::W
    current_window::Union{W, Nothing}
    price_sum::P
    volume_sum::V
    count::Int
    validate_chronological::Bool
    last_timestamp::Union{T, Nothing}

    function MeanResampler{T,P,V,W}(window_spec::W; validate_chronological::Bool = false) where {T,P,V,W<:AbstractWindow}
        new{T,P,V,W}(window_spec, nothing, zero(P), zero(V), 0, validate_chronological, nothing)
    end
end

# Convenience constructors
MeanResampler(period::Period; validate_chronological::Bool = false) =
    MeanResampler{DateTime,Float64,Float64,TimeWindow{DateTime}}(
        TimeWindow{DateTime}(DateTime(0), period);
        validate_chronological=validate_chronological
    )

# 3-parameter constructor for backward compatibility
MeanResampler{T,P,V}(period::Period; validate_chronological::Bool = false) where {T,P,V} =
    MeanResampler{T,P,V,TimeWindow{T}}(
        TimeWindow{T}(T(0), period);
        validate_chronological=validate_chronological
    )

MeanResampler(window::TimeWindow{T}; validate_chronological::Bool = false) where T =
    MeanResampler{T,Float64,Float64,TimeWindow{T}}(window; validate_chronological=validate_chronological)

MeanResampler(window::VolumeWindow{V}; validate_chronological::Bool = false) where V =
    MeanResampler{DateTime,Float64,V,VolumeWindow{V}}(window; validate_chronological=validate_chronological)

MeanResampler(window::TickWindow; validate_chronological::Bool = false) =
    MeanResampler{DateTime,Float64,Float64,TickWindow}(window; validate_chronological=validate_chronological)

"""
    SumResampler{T,P,V,W} <: AbstractResampler{T,P,V,W}

Resamples data by summing values over specified windows (used for volume).
"""
mutable struct SumResampler{T,P,V,W<:AbstractWindow} <: AbstractResampler{T,P,V,W}
    window_spec::W
    current_window::Union{W, Nothing}
    sum::V
    count::Int
    validate_chronological::Bool
    last_timestamp::Union{T, Nothing}

    function SumResampler{T,P,V,W}(window_spec::W; validate_chronological::Bool = false) where {T,P,V,W<:AbstractWindow}
        new{T,P,V,W}(window_spec, nothing, zero(V), 0, validate_chronological, nothing)
    end
end

# Convenience constructors
SumResampler(period::Period; validate_chronological::Bool = false) =
    SumResampler{DateTime,Float64,Float64,TimeWindow{DateTime}}(
        TimeWindow{DateTime}(DateTime(0), period);
        validate_chronological=validate_chronological
    )

# 3-parameter constructor for backward compatibility
SumResampler{T,P,V}(period::Period; validate_chronological::Bool = false) where {T,P,V} =
    SumResampler{T,P,V,TimeWindow{T}}(
        TimeWindow{T}(T(0), period);
        validate_chronological=validate_chronological
    )

SumResampler(window::TimeWindow{T}; validate_chronological::Bool = false) where T =
    SumResampler{T,Float64,Float64,TimeWindow{T}}(window; validate_chronological=validate_chronological)

SumResampler(window::VolumeWindow{V}; validate_chronological::Bool = false) where V =
    SumResampler{DateTime,Float64,V,VolumeWindow{V}}(window; validate_chronological=validate_chronological)

SumResampler(window::TickWindow; validate_chronological::Bool = false) =
    SumResampler{DateTime,Float64,Float64,TickWindow}(window; validate_chronological=validate_chronological)

"""
    MarketResampler{T,P,V,W}

A composite resampler that combines separate price and volume resampling strategies.

`MarketResampler` is the primary interface for resampling market data. It combines a price resampler
(either OHLC or mean-based) with a volume resampler (sum-based) to provide comprehensive market data
aggregation over specified windows.

This resampler automatically coordinates between price and volume aggregation strategies, ensuring
consistent window handling and providing a unified interface for accessing both price and volume
statistics.

# Type Parameters
- `T`: Timestamp type (e.g., `DateTime`, `NanoDate`)
- `P`: Price type (e.g., `Float64`, `FixedDecimal`)
- `V`: Volume type (e.g., `Float64`, `FixedDecimal`)
- `W`: Window type (e.g., `TimeWindow`, `VolumeWindow`, `TickWindow`)

# Fields
- `price_resampler::AbstractResampler{T,P,V,W}`: Strategy for aggregating prices (OHLC or Mean)
- `volume_resampler::AbstractResampler{T,P,V,W}`: Strategy for aggregating volumes (always Sum)

# Examples
```julia
using OnlineResamplers, OnlineStatsBase, Dates

# Create time-based OHLC resampler (default)
ohlc_resampler = MarketResampler(Minute(1))

# Create volume-based OHLC resampler
vol_resampler = MarketResampler(VolumeWindow(1000.0))

# Create tick-based mean price resampler
tick_resampler = MarketResampler(TickWindow(100), price_method=:mean)

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
struct MarketResampler{T,P,V,W<:AbstractWindow} <: OnlineStat{MarketDataPoint{T,P,V}}
    price_resampler::AbstractResampler{T,P,V,W}
    volume_resampler::AbstractResampler{T,P,V,W}
end

# Convenience constructor for Period (time-based, backward compatibility)
MarketResampler(period::Period; price_method::Symbol=:ohlc, validate_chronological::Bool=false) =
    MarketResampler(TimeWindow{DateTime}(DateTime(0), period); price_method=price_method, validate_chronological=validate_chronological)

# Generic window-based constructor
function MarketResampler(window::W; price_method::Symbol=:ohlc, validate_chronological::Bool=false) where {W<:AbstractWindow}
    price_resampler = if price_method == :ohlc
        OHLCResampler(window; validate_chronological=validate_chronological)
    elseif price_method == :mean
        MeanResampler(window; validate_chronological=validate_chronological)
    else
        throw(ArgumentError("price_method must be :ohlc or :mean"))
    end

    volume_resampler = SumResampler(window; validate_chronological=validate_chronological)
    # Use the automatically generated outer constructor from the struct definition
    return MarketResampler{typeof(price_resampler).parameters[1],
                          typeof(price_resampler).parameters[2],
                          typeof(price_resampler).parameters[3],
                          W}(price_resampler, volume_resampler)
end

# Helper function for chronological validation
function _validate_chronological_order!(resampler::AbstractResampler{T,P,V,W}, data::MarketDataPoint{T,P,V}) where {T,P,V,W}
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

# Helper to update window state for VolumeWindow
function _update_window_state!(window::VolumeWindow{V}, data::MarketDataPoint{T,P,V}) where {T,P,V}
    window.current_volume += data.volume
end

# Helper to update window state for TickWindow
function _update_window_state!(window::TickWindow, data::MarketDataPoint)
    window.current_ticks += 1
end

# Helper to update window state for TimeWindow (no-op, state is implicit)
function _update_window_state!(window::TimeWindow, data::MarketDataPoint)
    # Time windows don't need explicit state updates
end

# OnlineStatsBase interface implementation
OnlineStatsBase.nobs(r::AbstractResampler) = r.count
OnlineStatsBase.nobs(r::MarketResampler) = nobs(r.price_resampler)

function OnlineStatsBase._fit!(resampler::OHLCResampler{T,P,V,W}, data::MarketDataPoint{T,P,V}) where {T,P,V,W<:AbstractWindow}
    # Validate chronological order if enabled
    _validate_chronological_order!(resampler, data)

    if resampler.current_window === nothing
        # Initialize first window
        resampler.current_window = next_window(resampler.window_spec, data)
    end

    if should_finalize(data, resampler.current_window)
        # Data belongs to a new window, finalize current and move to next
        _finalize_window!(resampler)
        resampler.current_window = next_window(resampler.window_spec, data)
    end

    # Update window state (for volume/tick windows)
    _update_window_state!(resampler.current_window, data)

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

function OnlineStatsBase._fit!(resampler::MeanResampler{T,P,V,W}, data::MarketDataPoint{T,P,V}) where {T,P,V,W<:AbstractWindow}
    # Validate chronological order if enabled
    _validate_chronological_order!(resampler, data)

    if resampler.current_window === nothing
        resampler.current_window = next_window(resampler.window_spec, data)
    end

    if should_finalize(data, resampler.current_window)
        _finalize_window!(resampler)
        resampler.current_window = next_window(resampler.window_spec, data)
    end

    # Update window state (for volume/tick windows)
    _update_window_state!(resampler.current_window, data)

    resampler.price_sum += data.price
    resampler.volume_sum += data.volume
    resampler.count += 1

    return resampler
end

function OnlineStatsBase._fit!(resampler::SumResampler{T,P,V,W}, data::MarketDataPoint{T,P,V}) where {T,P,V,W<:AbstractWindow}
    # Validate chronological order if enabled
    _validate_chronological_order!(resampler, data)

    if resampler.current_window === nothing
        resampler.current_window = next_window(resampler.window_spec, data)
    end

    if should_finalize(data, resampler.current_window)
        _finalize_window!(resampler)
        resampler.current_window = next_window(resampler.window_spec, data)
    end

    # Update window state (for volume/tick windows)
    _update_window_state!(resampler.current_window, data)

    resampler.sum += data.volume
    resampler.count += 1

    return resampler
end

function OnlineStatsBase._fit!(resampler::MarketResampler{T,P,V,W}, data::MarketDataPoint{T,P,V}) where {T,P,V,W}
    fit!(resampler.price_resampler, data)
    fit!(resampler.volume_resampler, data)
    return resampler
end

function _finalize_window!(resampler::AbstractResampler{T,P,V,W}) where {T,P,V,W}
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
function OnlineStatsBase.value(resampler::OHLCResampler{T,P,V,W}) where {T,P,V,W}
    if resampler.ohlc === nothing
        return (ohlc=nothing, volume=zero(V), window=resampler.current_window)
    end
    return (ohlc=resampler.ohlc, volume=resampler.volume_sum, window=resampler.current_window)
end

function OnlineStatsBase.value(resampler::MeanResampler{T,P,V,W}) where {T,P,V,W}
    if resampler.count == 0
        return (mean_price=zero(P)/one(P), volume=zero(V), window=resampler.current_window)  # NaN equivalent
    end
    return (
        mean_price=resampler.price_sum / resampler.count,
        volume=resampler.volume_sum,
        window=resampler.current_window
    )
end

function OnlineStatsBase.value(resampler::SumResampler{T,P,V,W}) where {T,P,V,W}
    return (sum=resampler.sum, window=resampler.current_window)
end

function OnlineStatsBase.value(resampler::MarketResampler{T,P,V,W}) where {T,P,V,W}
    price_value = value(resampler.price_resampler)
    volume_value = value(resampler.volume_resampler)
    return (price=price_value, volume=volume_value.sum, window=price_value.window)
end

# Merge implementation for parallel processing
function OnlineStatsBase._merge!(resampler1::OHLCResampler{T,P,V,W}, resampler2::OHLCResampler{T,P,V,W}) where {T,P,V,W}
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

function OnlineStatsBase._merge!(resampler1::MeanResampler{T,P,V,W}, resampler2::MeanResampler{T,P,V,W}) where {T,P,V,W}
    resampler1.price_sum += resampler2.price_sum
    resampler1.volume_sum += resampler2.volume_sum
    resampler1.count += resampler2.count
    return resampler1
end

function OnlineStatsBase._merge!(resampler1::SumResampler{T,P,V,W}, resampler2::SumResampler{T,P,V,W}) where {T,P,V,W}
    resampler1.sum += resampler2.sum
    resampler1.count += resampler2.count
    return resampler1
end

end # module OnlineResamplerss
