"""
Volume-Based Resampling Example

This example demonstrates how to use OnlineResamplers.jl with volume-based windows
instead of time-based windows. Volume bars are useful in financial analysis because
they normalize bars by trading activity rather than time.

Each bar represents a fixed amount of traded volume (e.g., 1000 shares), which can
provide better insights into market dynamics, especially during periods of varying
liquidity.
"""

using OnlineResamplers
using OnlineStatsBase
using Dates

println("=" ^ 70)
println("Volume-Based Resampling Examples")
println("=" ^ 70)
println()

# Example 1: OHLC Volume Bars
println("Example 1: OHLC Volume Bars (1000 volume per bar)")
println("-" ^ 70)

# Create a volume-based OHLC resampler
# Each bar will contain 1000 units of volume
resampler = OHLCResampler(VolumeWindow(1000.0))

# Simulate market data with varying volumes
market_data = [
    MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 300.0),
    MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 5), 102.0, 250.0),
    MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 10), 101.5, 200.0),
    MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 15), 99.0, 400.0),   # This completes first 1000-volume bar
    MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 20), 98.5, 500.0),
    MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 25), 99.5, 600.0),   # This completes second bar
    MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 30), 100.5, 200.0),
]

let bar_num = 1
    for data in market_data
        fit!(resampler, data)
        result = value(resampler)

        if result.volume >= 900.0  # Near completion of a bar
            println("Bar $bar_num:")
            println("  OHLC: O=$(result.ohlc.open), H=$(result.ohlc.high), L=$(result.ohlc.low), C=$(result.ohlc.close)")
            println("  Volume: $(result.volume)")
            if result.volume < 1000.0
                println("  Status: Accumulating ($(1000.0 - result.volume) volume remaining)")
            else
                println("  Status: Complete (new bar started)")
                bar_num += 1
            end
            println()
        end
    end
end

println()
println("=" ^ 70)
println("Example 2: Tick Bars (Fixed Number of Trades)")
println("-" ^ 70)

# Create a tick-based OHLC resampler
# Each bar will contain exactly 5 ticks (trades)
tick_resampler = OHLCResampler(TickWindow(5))

tick_data = [
    MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0),
    MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 1), 100.5, 500.0),
    MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 2), 100.2, 800.0),
    MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 3), 100.8, 600.0),
    MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 4), 100.3, 700.0),  # 5th tick - completes bar
    MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 5), 100.1, 900.0),  # Starts new bar
    MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 6), 99.9, 1100.0),
]

let bar_num = 1, tick_count = 0
    for data in tick_data
        fit!(tick_resampler, data)
        result = value(tick_resampler)
        tick_count += 1

        if tick_count % 5 == 0 || tick_count == length(tick_data)
            println("Bar $bar_num after $(nobs(tick_resampler)) ticks:")
            println("  OHLC: O=$(result.ohlc.open), H=$(result.ohlc.high), L=$(result.ohlc.low), C=$(result.ohlc.close)")
            println("  Total Volume: $(result.volume)")
            println()
            if nobs(tick_resampler) == 5
                bar_num += 1
            end
        end
    end
end

println()
println("=" ^ 70)
println("Example 3: Comparing Time-Based vs Volume-Based Bars")
println("-" ^ 70)

# Same data processed two different ways
println("\nProcessing the same tick data with different resampling strategies:")
println()

# Time-based: 10-second bars
time_resampler = MarketResampler(Second(10))

# Volume-based: 2000-volume bars
vol_resampler = MarketResampler(VolumeWindow(2000.0))

comparison_data = [
    MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 800.0),
    MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 5), 101.0, 600.0),
    MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 12), 102.0, 900.0),  # Time bar 1 ends at 10s, bar 2 starts
    MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 18), 101.5, 800.0),  # Volume bar 1 ends, bar 2 starts
    MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 22), 100.5, 500.0),  # Time bar 2 ends at 20s, bar 3 starts
]

println("Time-Based Bars (10-second intervals):")
for data in comparison_data
    fit!(time_resampler, data)
end
result = value(time_resampler)
println("  Current Bar: $(result.price.ohlc)")
println("  Volume: $(result.volume)")
println()

println("Volume-Based Bars (2000-volume intervals):")
for data in comparison_data
    fit!(vol_resampler, data)
end
result = value(vol_resampler)
println("  Current Bar: $(result.price.ohlc)")
println("  Volume: $(result.volume)")
println()

println("=" ^ 70)
println("Key Takeaways:")
println("=" ^ 70)
println("""
1. Volume bars normalize by trading activity, not time
   - During high activity, bars form faster
   - During low activity, bars form slower

2. Tick bars normalize by number of trades
   - Each bar represents the same number of transactions
   - Useful for analyzing order flow patterns

3. Time bars are still valuable for:
   - Calendar-based analysis
   - Regular reporting intervals
   - When time synchronization is important

4. Volume/tick bars are better for:
   - Comparing bars with similar information content
   - Reducing impact of non-trading periods
   - Market microstructure analysis
""")

println("\nFor more information, see: https://github.com/femtotrader/OnlineResamplers.jl")
