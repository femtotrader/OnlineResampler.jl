using OnlineResamplers, OnlineStatsBase, Dates
using Printf

println("=== OnlineResamplers: Out-of-Order Data Behavior ===\n")

# The key insight: OnlineResamplers is designed for streaming data and uses a "current window" approach
# When data doesn't belong to the current window, it ALWAYS moves to the new data's window
# This means out-of-order data can cause issues with data integrity

println("1. Understanding Time Window Behavior")
println("====================================")

resampler = MarketResampler(Minute(1))

# Let's trace what happens step by step
base_time = DateTime(2024, 1, 1, 9, 30, 0)

# Data points in chronological order first
chronological_data = [
    MarketDataPoint(base_time + Second(0), 100.0, 1000.0),    # 9:30:00
    MarketDataPoint(base_time + Second(30), 105.0, 800.0),    # 9:30:30
    MarketDataPoint(base_time + Minute(1), 102.0, 1200.0),    # 9:31:00 (next window)
    MarketDataPoint(base_time + Minute(1) + Second(30), 98.0, 900.0)  # 9:31:30
]

println("Processing chronological data:")
for (i, data) in enumerate(chronological_data)
    old_result = value(resampler)
    old_window = old_result.window

    fit!(resampler, data)
    new_result = value(resampler)
    new_window = new_result.window

    window_changed = (old_window != new_window)

    println("Data $i: $(data.datetime) - Price: $(data.price)")
    if new_window !== nothing
        println("  → Current window: $(new_window.start_time) to $(window_end(new_window))")
        if window_changed && old_window !== nothing
            println("  ⚠️  Window transition occurred! Previous window was finalized")
        end
    end

    if new_result.price.ohlc !== nothing
        ohlc = new_result.price.ohlc
        println("  → OHLC: O=$(ohlc.open), H=$(ohlc.high), L=$(ohlc.low), C=$(ohlc.close)")
    end
    println()
end

println("\n" * "="^60)
println("2. Out-of-Order Data: Going Back in Time")
println("="^60)

# Reset resampler
resampler = MarketResampler(Minute(1))

# Process data in forward order first
forward_data = [
    MarketDataPoint(base_time + Second(0), 100.0, 1000.0),     # 9:30:00
    MarketDataPoint(base_time + Second(30), 105.0, 800.0),     # 9:30:30
    MarketDataPoint(base_time + Minute(1), 102.0, 1200.0),     # 9:31:00 (next window)
]

println("First, process some forward data:")
for data in forward_data
    fit!(resampler, data)
    result = value(resampler)
    println("Processed: $(data.datetime) - Current window: $(result.window.start_time)")
end

result_before_backward = value(resampler)
println("\nState before processing backward data:")
if result_before_backward.price.ohlc !== nothing
    ohlc = result_before_backward.price.ohlc
    println("  Current OHLC: O=$(ohlc.open), H=$(ohlc.high), L=$(ohlc.low), C=$(ohlc.close)")
    println("  Current Volume: $(result_before_backward.volume)")
    println("  Current Window: $(result_before_backward.window.start_time)")
end

# Now process data from the PAST (previous window)
backward_data = MarketDataPoint(base_time + Second(45), 95.0, 1500.0)  # 9:30:45 (goes back to first window!)

println("\n🚨 Processing BACKWARD data point:")
println("Data: $(backward_data.datetime) - Price: $(backward_data.price)")
println("This timestamp belongs to window: $(floor(backward_data.datetime, Minute(1)))")

fit!(resampler, backward_data)
result_after_backward = value(resampler)

println("\nState AFTER processing backward data:")
if result_after_backward.price.ohlc !== nothing
    ohlc = result_after_backward.price.ohlc
    println("  New OHLC: O=$(ohlc.open), H=$(ohlc.high), L=$(ohlc.low), C=$(ohlc.close)")
    println("  New Volume: $(result_after_backward.volume)")
    println("  New Window: $(result_after_backward.window.start_time)")
else
    println("  OHLC: nothing")
end

println("\n⚠️  CRITICAL ISSUE: The resampler has moved BACK to the 9:30 window!")
println("⚠️  All data from the 9:31 window has been LOST!")
println("⚠️  The 9:31 window was finalized when we moved back to 9:30")

println("\n" * "="^60)
println("3. Multiple Out-of-Order Scenarios")
println("="^60)

# Scenario A: Small out-of-order within same window
println("Scenario A: Small reordering within same window")
println("----------------------------------------------")

resampler_a = MarketResampler(Minute(1))
same_window_data = [
    MarketDataPoint(base_time + Second(0), 100.0, 1000.0),     # 9:30:00
    MarketDataPoint(base_time + Second(45), 105.0, 800.0),     # 9:30:45
    MarketDataPoint(base_time + Second(15), 95.0, 1200.0),     # 9:30:15 (out of order, but same window)
    MarketDataPoint(base_time + Second(50), 102.0, 900.0),     # 9:30:50
]

println("Processing data with small reordering:")
for (i, data) in enumerate(same_window_data)
    fit!(resampler_a, data)
    result = value(resampler_a)

    window_str = result.window !== nothing ? "$(result.window.start_time)" : "none"
    belongs = result.window !== nothing ? belongs_to_window(data.datetime, result.window) : false

    println("Data $i: $(data.datetime) - Price: $(data.price)")
    println("  → Belongs to current window? $(belongs)")
    println("  → Current window: $(window_str)")

    if result.price.ohlc !== nothing
        ohlc = result.price.ohlc
        println("  → OHLC: O=$(ohlc.open), H=$(ohlc.high), L=$(ohlc.low), C=$(ohlc.close)")
    end
    println()
end

final_result_a = value(resampler_a)
if final_result_a.price.ohlc !== nothing
    ohlc = final_result_a.price.ohlc
    println("✅ Result: All data processed in same window")
    println("   Final OHLC: O=$(ohlc.open), H=$(ohlc.high), L=$(ohlc.low), C=$(ohlc.close)")
    println("   Note: Open=$(ohlc.open) (first processed), Close=$(ohlc.close) (last processed)")
    println("   The 'Close' is NOT the chronologically last price!")
end

# Scenario B: Major out-of-order across windows
println("\n\nScenario B: Major reordering across windows")
println("-------------------------------------------")

resampler_b = MarketResampler(Minute(1))
cross_window_data = [
    MarketDataPoint(base_time, 100.0, 1000.0),                      # 9:30:00
    MarketDataPoint(base_time + Minute(2), 110.0, 1500.0),          # 9:32:00 (skip ahead 2 minutes)
    MarketDataPoint(base_time + Minute(1), 105.0, 800.0),           # 9:31:00 (go back 1 minute)
    MarketDataPoint(base_time + Second(30), 95.0, 1200.0),          # 9:30:30 (go back to first window)
]

windows_seen = Set()
for (i, data) in enumerate(cross_window_data)
    old_result = value(resampler_b)
    old_window = old_result.window

    fit!(resampler_b, data)
    new_result = value(resampler_b)
    new_window = new_result.window

    if new_window !== nothing
        push!(windows_seen, new_window.start_time)
    end

    window_changed = (old_window != new_window)

    println("Data $i: $(data.datetime) - Price: $(data.price)")
    if new_window !== nothing
        println("  → Moved to window: $(new_window.start_time)")
        if window_changed && old_window !== nothing
            println("  ⚠️  Window transition: $(old_window.start_time) → $(new_window.start_time)")
        end
    end

    if new_result.price.ohlc !== nothing
        ohlc = new_result.price.ohlc
        println("  → Current OHLC: O=$(ohlc.open), H=$(ohlc.high), L=$(ohlc.low), C=$(ohlc.close)")
    end
    println()
end

println("🚨 Windows that were visited: $(sort(collect(windows_seen)))")
println("🚨 Only the LAST window visited has data - all others are lost!")

println("\n" * "="^60)
println("4. Implications and Solutions")
println("="^60)

println("CURRENT BEHAVIOR (Streaming/Online Design):")
println("------------------------------------------")
println("✅ Optimized for real-time streaming data")
println("✅ Constant memory usage - O(1)")
println("✅ High performance - no sorting or buffering")
println("❌ Out-of-order data causes window transitions")
println("❌ Previous window data is lost when transitioning")
println("❌ 'Close' price is the last processed, not chronologically last")
println()

println("SOLUTIONS FOR OUT-OF-ORDER DATA:")
println("--------------------------------")

println("1. PRE-SORT DATA:")
println("   Sort your data by timestamp before processing")

# Example of pre-sorting solution
unsorted_data = [
    MarketDataPoint(base_time + Second(45), 105.0, 800.0),
    MarketDataPoint(base_time + Second(0), 100.0, 1000.0),
    MarketDataPoint(base_time + Second(30), 102.0, 1200.0),
    MarketDataPoint(base_time + Second(15), 95.0, 900.0),
]

sorted_data = sort(unsorted_data, by=x -> x.datetime)

println("   Original order: $(join([d.datetime for d in unsorted_data], ", "))")
println("   Sorted order:   $(join([d.datetime for d in sorted_data], ", "))")

resampler_sorted = MarketResampler(Minute(1))
for data in sorted_data
    fit!(resampler_sorted, data)
end

result_sorted = value(resampler_sorted)
if result_sorted.price.ohlc !== nothing
    ohlc = result_sorted.price.ohlc
    println("   ✅ Correct OHLC: O=$(ohlc.open), H=$(ohlc.high), L=$(ohlc.low), C=$(ohlc.close)")
end

println()
println("2. USE BATCH PROCESSING:")
println("   Collect data for each window, then process complete windows")

# Example of batch processing
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
        # Sort data within window
        sorted_window_data = sort(window_data, by=x -> x.datetime)

        # Process window
        window_resampler = MarketResampler(period)
        for data in sorted_window_data
            fit!(window_resampler, data)
        end

        result = value(window_resampler)
        if result.price.ohlc !== nothing
            push!(results, (
                window_start = window_start,
                ohlc = result.price.ohlc,
                volume = result.volume,
                count = length(sorted_window_data)
            ))
        end
    end

    return results
end

# Test batch processing
mixed_data = [
    MarketDataPoint(base_time + Second(45), 105.0, 800.0),     # 9:30:45
    MarketDataPoint(base_time + Minute(1) + Second(30), 108.0, 600.0),  # 9:31:30
    MarketDataPoint(base_time + Second(0), 100.0, 1000.0),     # 9:30:00
    MarketDataPoint(base_time + Minute(1), 110.0, 1200.0),     # 9:31:00
    MarketDataPoint(base_time + Second(30), 102.0, 1200.0),    # 9:30:30
]

println("   Processing mixed timestamp data with batch approach:")
batch_results = batch_process_by_windows(mixed_data, Minute(1))

for (i, result) in enumerate(batch_results)
    ohlc = result.ohlc
    println("   Window $i: $(result.window_start)")
    println("     ✅ OHLC: O=$(ohlc.open), H=$(ohlc.high), L=$(ohlc.low), C=$(ohlc.close)")
    println("     Volume: $(result.volume), Points: $(result.count)")
end

println()
println("3. VALIDATE DATA ORDER:")
println("   Check timestamps before processing")

function validate_chronological_order(data_points)
    if length(data_points) <= 1
        return true
    end

    for i in 2:length(data_points)
        if data_points[i].datetime < data_points[i-1].datetime
            @warn "Out-of-order data detected at index $i: $(data_points[i].datetime) < $(data_points[i-1].datetime)"
            return false
        end
    end
    return true
end

println("   Validating chronological order:")
is_ordered = validate_chronological_order(mixed_data)
println("   Data is chronologically ordered: $(is_ordered)")

if !is_ordered
    println("   ⚠️  Consider sorting data before processing with OnlineResamplers")
end

println("\n" * "="^60)
println("SUMMARY")
println("="^60)
println("OnlineResamplers is designed for STREAMING data and assumes:")
println("• Data arrives in chronological order")
println("• You want constant memory usage")
println("• You prioritize speed over handling out-of-order data")
println()
println("For out-of-order data, you should:")
println("• Sort data by timestamp before processing, OR")
println("• Use batch processing by time windows, OR")
println("• Use a different tool designed for historical data analysis")
println()
println("The current behavior is BY DESIGN for streaming use cases!")

println("\n=== Examples Complete ===")