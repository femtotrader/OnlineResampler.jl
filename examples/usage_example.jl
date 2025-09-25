using OnlineResamplers
using OnlineStatsBase
using Dates

println("=== OnlineResamplers Usage Examples ===\n")

# Example 1: Basic OHLC resampling with 1-minute windows
println("1. OHLC Resampling (1-minute windows)")
println("=====================================")

# Create a 1-minute OHLC resampler
resampler = MarketResampler(Minute(1), price_method=:ohlc)

# Sample market data
base_time = DateTime(2024, 1, 1, 9, 30, 0)  # Market open
market_data = [
    MarketDataPoint(base_time + Second(0), 100.0, 1000.0),
    MarketDataPoint(base_time + Second(15), 102.0, 800.0),
    MarketDataPoint(base_time + Second(30), 98.0, 1200.0),
    MarketDataPoint(base_time + Second(45), 101.0, 900.0),
    # Next minute
    MarketDataPoint(base_time + Minute(1) + Second(10), 105.0, 1500.0),
    MarketDataPoint(base_time + Minute(1) + Second(30), 103.0, 700.0),
]

println("Processing market data:")
for (i, data) in enumerate(market_data)
    fit!(resampler, data)
    result = value(resampler)

    println("Data $i: $(data.datetime) - Price: $(data.price), Volume: $(data.volume)")
    if result.price.ohlc !== nothing
        ohlc = result.price.ohlc
        println("  → Current OHLC: O=$(ohlc.open), H=$(ohlc.high), L=$(ohlc.low), C=$(ohlc.close)")
        println("  → Total Volume: $(result.volume)")
        println("  → Window: $(result.window.start_time) to $(window_end(result.window))")
    end
    println()
end

# Example 2: Mean price resampling
println("\n2. Mean Price Resampling (5-minute windows)")
println("==========================================")

mean_resampler = MarketResampler(Minute(5), price_method=:mean)

# Sample data over 5 minutes
mean_data = [
    MarketDataPoint(base_time + Minute(0), 100.0, 500.0),
    MarketDataPoint(base_time + Minute(1), 102.0, 600.0),
    MarketDataPoint(base_time + Minute(2), 99.0, 550.0),
    MarketDataPoint(base_time + Minute(3), 103.0, 700.0),
    MarketDataPoint(base_time + Minute(4), 101.0, 650.0),
]

println("Processing data for mean calculation:")
for data in mean_data
    fit!(mean_resampler, data)
end

result = value(mean_resampler)
println("Mean Price: $(result.price.mean_price)")
println("Total Volume: $(result.volume)")
println("Window: $(result.window.start_time) to $(window_end(result.window))")

# Example 3: Using parametric types with different numeric types
println("\n3. Using Rational Numbers as Custom Types")
println("========================================")

# Demonstrate with Rational numbers (built-in Julia type)
rational_resampler = MarketResampler{DateTime, Rational{Int}, Rational{Int}}(Minute(1), price_method=:ohlc)

# Create data with rational numbers
rational_data = [
    MarketDataPoint{DateTime, Rational{Int}, Rational{Int}}(
        base_time,
        Rational(10043, 100),  # 100.43
        Rational(1000, 1)      # 1000
    ),
    MarketDataPoint{DateTime, Rational{Int}, Rational{Int}}(
        base_time + Second(30),
        Rational(10567, 100),  # 105.67
        Rational(800, 1)       # 800
    )
]

println("Processing rational number data:")
for data in rational_data
    fit!(rational_resampler, data)
end

rational_result = value(rational_resampler)
println("Price type: $(typeof(rational_result.price.ohlc.open))")
println("Volume type: $(typeof(rational_result.volume))")
println("OHLC values:")
println("  Open: $(rational_result.price.ohlc.open)")
println("  High: $(rational_result.price.ohlc.high)")
println("  Low: $(rational_result.price.ohlc.low)")
println("  Close: $(rational_result.price.ohlc.close)")
println("Volume: $(rational_result.volume)")

# Example 4: OnlineStatsBase integration
println("\n4. OnlineStatsBase Integration")
println("=============================")

# Demonstrate the OnlineStatsBase interface
ohlc_resampler = OHLCResampler(Minute(1))

println("Initial state:")
println("  nobs: $(nobs(ohlc_resampler))")

# Add some data
test_data = [
    MarketDataPoint(base_time, 100.0, 1000.0),
    MarketDataPoint(base_time + Second(30), 105.0, 800.0),
]

for data in test_data
    fit!(ohlc_resampler, data)
    println("After adding data: nobs = $(nobs(ohlc_resampler))")
end

println("Final value: $(value(ohlc_resampler))")

# Example 5: Merge operation for parallel processing
println("\n5. Merge Operation (for parallel processing)")
println("==========================================")

resampler1 = OHLCResampler(Minute(1))
resampler2 = OHLCResampler(Minute(1))

# Process different data on each resampler
fit!(resampler1, MarketDataPoint(base_time, 100.0, 1000.0))
fit!(resampler1, MarketDataPoint(base_time + Second(15), 105.0, 800.0))

fit!(resampler2, MarketDataPoint(base_time + Second(30), 95.0, 1200.0))
fit!(resampler2, MarketDataPoint(base_time + Second(45), 102.0, 900.0))

println("Resampler 1: $(value(resampler1))")
println("Resampler 2: $(value(resampler2))")

# Merge the resamplers
merge!(resampler1, resampler2)
merged_result = value(resampler1)

println("After merge: $(merged_result)")
println("Combined OHLC should show:")
println("  Open: 100.0 (first from resampler1)")
println("  High: 105.0 (max from both)")
println("  Low: 95.0 (min from both)")
println("  Close: 102.0 (last from resampler2)")

println("\n=== Examples Complete ===")