using OnlineResamplers, OnlineStatsBase, Dates
using Printf  # For formatted printing

println("=== OnlineResamplers Advanced Usage Examples ===\n")

# Example 1: Multi-timeframe analysis
println("1. Multi-timeframe Analysis")
println("==============================")

# Create multiple resamplers for different timeframes
resamplers = Dict(
    "1min" => MarketResampler(Minute(1)),
    "5min" => MarketResampler(Minute(5)),
    "15min" => MarketResampler(Minute(15)),
    "1hour" => MarketResampler(Hour(1))
)

# Generate sample tick data (realistic intraday pattern)
base_time = DateTime(2024, 1, 1, 9, 30, 0)
tick_data = []

function generate_tick_data(base_time, n_ticks)
    tick_data = []
    price = 100.0

    for i in 1:n_ticks
        # Random walk with some trend and volatility
        price_change = randn() * 0.01 + 0.0001  # Small upward bias
        price += price_change
        price = max(price, 90.0)  # Floor price

        volume = rand(500:2000)
        timestamp = base_time + Second(i * 6)  # 6-second intervals

        push!(tick_data, MarketDataPoint(timestamp, price, volume))
    end

    return tick_data
end

println("Generating realistic tick data...")
tick_data = generate_tick_data(base_time, 1000)

# Process all data through all timeframes
println("Processing $(length(tick_data)) ticks through multiple timeframes...")
for data in tick_data
    for (name, resampler) in resamplers
        fit!(resampler, data)
    end
end

# Display results
println("\nMulti-timeframe OHLC Results:")
for (name, resampler) in sort(collect(resamplers), by=x->x[1])
    result = value(resampler)
    if result.price.ohlc !== nothing
        ohlc = result.price.ohlc
        @printf("%-6s | O: %6.2f | H: %6.2f | L: %6.2f | C: %6.2f | Vol: %8.0f\n",
                name, ohlc.open, ohlc.high, ohlc.low, ohlc.close, result.volume)
    end
end

# Example 2: Custom numeric types with high precision
println("\n2. High-Precision Financial Calculations")
println("=======================================")

# Simulate using FixedPoint decimals (using Rational as proxy)
PrecisePrice = Rational{Int128}    # High precision price
PreciseVolume = Rational{Int64}    # Volume with fractional shares

# Create high-precision resampler
precise_resampler = MarketResampler{DateTime, PrecisePrice, PreciseVolume}(
    Minute(1), price_method=:ohlc
)

# Generate high-precision data
precise_data = [
    MarketDataPoint{DateTime, PrecisePrice, PreciseVolume}(
        base_time + Second(i),
        PrecisePrice(10000 + i, 100) + PrecisePrice(rand(-50:50), 10000),  # Price with 4 decimal places
        PreciseVolume(1000 + rand(1:1000), 1)  # Whole share volume
    )
    for i in 1:60  # 1 minute of data
]

println("Processing high-precision data...")
for data in precise_data
    fit!(precise_resampler, data)
end

result = value(precise_resampler)
if result.price.ohlc !== nothing
    ohlc = result.price.ohlc
    println("High-Precision OHLC:")
    println("  Open:  $(Float64(ohlc.open))")
    println("  High:  $(Float64(ohlc.high))")
    println("  Low:   $(Float64(ohlc.low))")
    println("  Close: $(Float64(ohlc.close))")
    println("  Volume: $(Float64(result.volume))")
end

# Example 3: Real-time streaming with window callbacks
println("\n3. Real-time Streaming with Window Completion Detection")
println("=====================================================")

mutable struct WindowCollector
    completed_windows::Vector{NamedTuple}
    resampler::MarketResampler
    last_window::Union{TimeWindow, Nothing}
end

function WindowCollector(period::Period)
    WindowCollector(
        NamedTuple[],
        MarketResampler(period),
        nothing
    )
end

function process_tick!(collector::WindowCollector, data::MarketDataPoint)
    # Get window before processing
    old_result = value(collector.resampler)
    old_window = old_result.window

    # Process the new data
    fit!(collector.resampler, data)

    # Check if window changed (completed)
    new_result = value(collector.resampler)
    new_window = new_result.window

    if old_window !== nothing && new_window != old_window
        # Window completed! Store the result
        if old_result.price.ohlc !== nothing
            completed_bar = (
                timestamp = old_window.start_time,
                open = old_result.price.ohlc.open,
                high = old_result.price.ohlc.high,
                low = old_result.price.ohlc.low,
                close = old_result.price.ohlc.close,
                volume = old_result.volume,
                tick_count = nobs(collector.resampler)  # This will be reset for new window
            )
            push!(collector.completed_windows, completed_bar)

            println("✅ Completed bar: $(old_window.start_time) - " *
                   "OHLC($(completed_bar.open), $(completed_bar.high), " *
                   "$(completed_bar.low), $(completed_bar.close)) " *
                   "Vol: $(completed_bar.volume)")
        end
    end

    collector.last_window = new_window
end

# Create streaming collector
collector = WindowCollector(Minute(2))

# Simulate real-time streaming
println("Simulating real-time tick stream (2-minute bars)...")
stream_base = DateTime(2024, 1, 1, 14, 30, 0)

for minute in 0:5  # 6 minutes of data
    for second in 0:59:300  # Ticks every 5 seconds
        timestamp = stream_base + Minute(minute) + Second(second)
        price = 100.0 + minute * 0.5 + randn() * 0.1
        volume = rand(800:1200)

        tick = MarketDataPoint(timestamp, price, volume)
        process_tick!(collector, tick)

        # Simulate some delay
        sleep(0.001)  # 1ms delay per tick
    end
end

println("\nCompleted Bars Summary:")
println("======================")
for (i, bar) in enumerate(collector.completed_windows)
    @printf("Bar %d: %s | OHLC: %.2f/%.2f/%.2f/%.2f | Vol: %.0f\n",
            i, bar.timestamp, bar.open, bar.high, bar.low, bar.close, bar.volume)
end

# Example 4: Parallel processing with merge
println("\n4. Parallel Processing with Merge Operations")
println("============================================")

# Simulate processing large dataset in parallel chunks
function process_chunk(data_chunk::Vector{MarketDataPoint{DateTime, Float64, Float64}}, period::Period)
    chunk_resampler = OHLCResampler{DateTime, Float64, Float64}(period)
    for data in data_chunk
        fit!(chunk_resampler, data)
    end
    return chunk_resampler
end

# Generate large dataset
large_dataset_base = DateTime(2024, 1, 1, 9, 0, 0)
large_dataset = [
    MarketDataPoint(
        large_dataset_base + Second(i),
        100.0 + sin(i/100) * 5 + randn() * 0.5,  # Sinusoidal trend with noise
        rand(500:1500)
    )
    for i in 1:10000
]

println("Processing $(length(large_dataset)) data points in parallel chunks...")

# Split into chunks (simulating parallel processing)
chunk_size = 2500
chunks = [large_dataset[i:min(i+chunk_size-1, end)] for i in 1:chunk_size:length(large_dataset)]

println("Split into $(length(chunks)) chunks of ~$(chunk_size) points each")

# Process chunks (in real scenario, this would be parallel)
chunk_resamplers = [process_chunk(chunk, Minute(5)) for chunk in chunks]

# Merge all results
println("Merging chunk results...")
merged_resampler = chunk_resamplers[1]
for i in 2:length(chunk_resamplers)
    merge!(merged_resampler, chunk_resamplers[i])
end

merged_result = value(merged_resampler)
println("Merged Results:")
if merged_result.ohlc !== nothing
    ohlc = merged_result.ohlc
    println("  Final OHLC: $(ohlc)")
    println("  Total Volume: $(merged_result.volume)")
    println("  Data Points: $(nobs(merged_resampler))")
end

# Example 5: Mixed resampling strategies
println("\n5. Mixed Resampling Strategies")
println("==============================")

# Create different resampler types for comparison
strategies = Dict(
    "OHLC_1min" => OHLCResampler(Minute(1)),
    "Mean_1min" => MeanResampler(Minute(1)),
    "Volume_1min" => SumResampler(Minute(1))
)

# Test data with varying price and volume
test_base = DateTime(2024, 1, 1, 10, 0, 0)
test_data = [
    MarketDataPoint(test_base + Second(0), 100.0, 1000.0),
    MarketDataPoint(test_base + Second(15), 105.0, 800.0),
    MarketDataPoint(test_base + Second(30), 98.0, 1200.0),
    MarketDataPoint(test_base + Second(45), 103.0, 900.0),
]

println("Comparing resampling strategies on same data:")
println("Data: $(length(test_data)) points over 1 minute")

for data in test_data
    for (name, resampler) in strategies
        fit!(resampler, data)
    end
end

println("\nResults Comparison:")
for (name, resampler) in strategies
    result = value(resampler)
    print("$(rpad(name, 12)): ")

    if result isa NamedTuple && haskey(result, :ohlc) && result.ohlc !== nothing
        ohlc = result.ohlc
        println("OHLC($(ohlc.open), $(ohlc.high), $(ohlc.low), $(ohlc.close)) Vol: $(result.volume)")
    elseif result isa NamedTuple && haskey(result, :mean_price)
        println("Mean: $(result.mean_price), Vol: $(result.volume)")
    elseif result isa NamedTuple && haskey(result, :sum)
        println("Sum: $(result.sum)")
    else
        println("$result")
    end
end

# Example 6: Error handling and edge cases
println("\n6. Error Handling and Edge Cases")
println("===============================")

# Test with single data point
single_resampler = MarketResampler(Minute(1))
single_data = MarketDataPoint(DateTime(2024, 1, 1, 12, 0, 0), 100.0, 1000.0)

fit!(single_resampler, single_data)
single_result = value(single_resampler)

println("Single data point test:")
if single_result.price.ohlc !== nothing
    ohlc = single_result.price.ohlc
    println("  OHLC: All values should be equal")
    println("  O=$(ohlc.open), H=$(ohlc.high), L=$(ohlc.low), C=$(ohlc.close)")
    println("  All equal? $(ohlc.open == ohlc.high == ohlc.low == ohlc.close)")
end

# Test with zero volume
zero_vol_resampler = MarketResampler(Minute(1))
zero_vol_data = MarketDataPoint(DateTime(2024, 1, 1, 12, 1, 0), 100.0, 0.0)

fit!(zero_vol_resampler, zero_vol_data)
zero_vol_result = value(zero_vol_resampler)
println("Zero volume test: Volume = $(zero_vol_result.volume)")

# Test empty resampler
empty_resampler = MarketResampler(Minute(1))
empty_result = value(empty_resampler)
println("Empty resampler test:")
println("  OHLC: $(empty_result.price.ohlc === nothing ? "nothing" : empty_result.price.ohlc)")
println("  Window: $(empty_result.window === nothing ? "nothing" : empty_result.window)")

println("\n=== Advanced Examples Complete ===")

# Performance demonstration
println("\n7. Performance Demonstration")
println("============================")

# Setup for simple timing test
bench_resampler = MarketResampler(Minute(1))
bench_data = MarketDataPoint(DateTime(2024, 1, 1, 15, 0, 0), 100.0, 1000.0)

println("Testing performance with 100,000 operations...")

# Warm up
for i in 1:50
    timestamp = DateTime(2024, 1, 1, 15, 0, 0) + Second(i)
    fit!(bench_resampler, MarketDataPoint(timestamp, 100.0, 1000.0))
end

# Timing test
perf_resampler = MarketResampler(Minute(1))
n_ops = 100_000

start_time = time()
for i in 1:n_ops
    timestamp = DateTime(2024, 1, 1, 15, 0, 0) + Millisecond(i)
    data = MarketDataPoint(timestamp, 100.0 + randn() * 0.1, 1000.0)
    fit!(perf_resampler, data)
end
end_time = time()

elapsed = end_time - start_time
ops_per_sec = n_ops / elapsed

println("Processed $n_ops operations in $(round(elapsed, digits=3)) seconds")
println("Operations per second: $(round(Int, ops_per_sec))")
println("Average time per operation: $(round(elapsed * 1_000_000 / n_ops, digits=2)) microseconds")

# Memory efficiency demonstration
println("\nMemory efficiency test:")
println("Processing 1 million operations with constant memory usage...")

memory_test_resampler = MarketResampler(Minute(1))
before_memory = Base.gc_live_bytes()

for i in 1:1_000_000
    timestamp = DateTime(2024, 1, 1, 15, 0, 0) + Millisecond(i)
    data = MarketDataPoint(timestamp, 100.0 + sin(i/1000), 1000.0)
    fit!(memory_test_resampler, data)

    # Force GC every 100k operations to check memory
    if i % 100_000 == 0
        GC.gc()
    end
end

after_memory = Base.gc_live_bytes()
memory_used = after_memory - before_memory

println("Memory used for 1M operations: $(round(memory_used / 1024, digits=2)) KB")
println("Memory per operation: $(round(memory_used / 1_000_000, digits=2)) bytes")

result = value(memory_test_resampler)
println("Final result contains $(nobs(memory_test_resampler)) observations in current window")