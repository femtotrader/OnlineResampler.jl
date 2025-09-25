using OnlineResampler
using OnlineStatsBase
using Dates
using Test

@testset "Chronological Order Validation" begin

    @testset "Default Behavior (No Validation)" begin
        # Default behavior should allow out-of-order data
        resampler = MarketResampler(Minute(1))
        @test resampler.price_resampler.validate_chronological == false

        base_time = DateTime(2024, 1, 1, 9, 30, 0)

        # This should work without errors (default behavior)
        fit!(resampler, MarketDataPoint(base_time, 100.0, 1000.0))
        fit!(resampler, MarketDataPoint(base_time + Minute(1), 105.0, 800.0))
        fit!(resampler, MarketDataPoint(base_time + Second(30), 95.0, 1200.0))  # Out of order!

        # Should complete without throwing
        result = value(resampler)
        @test result.price.ohlc !== nothing
    end

    @testset "Enabled Validation - Chronological Data" begin
        # With validation enabled, chronological data should work fine
        resampler = MarketResampler(Minute(1), validate_chronological=true)
        @test resampler.price_resampler.validate_chronological == true
        @test resampler.volume_resampler.validate_chronological == true

        base_time = DateTime(2024, 1, 1, 9, 30, 0)
        chronological_data = [
            MarketDataPoint(base_time, 100.0, 1000.0),
            MarketDataPoint(base_time + Second(30), 105.0, 800.0),
            MarketDataPoint(base_time + Minute(1), 102.0, 1200.0),
            MarketDataPoint(base_time + Minute(1) + Second(30), 98.0, 900.0)
        ]

        # All should work fine
        for data in chronological_data
            fit!(resampler, data)
        end

        result = value(resampler)
        @test result.price.ohlc !== nothing
        @test nobs(resampler) == 2  # Two data points in the last window (9:31 window)
    end

    @testset "Enabled Validation - Out-of-Order Detection" begin
        base_time = DateTime(2024, 1, 1, 9, 30, 0)

        # Test OHLC resampler
        ohlc_resampler = OHLCResampler(Minute(1), validate_chronological=true)

        fit!(ohlc_resampler, MarketDataPoint(base_time, 100.0, 1000.0))
        fit!(ohlc_resampler, MarketDataPoint(base_time + Second(30), 105.0, 800.0))

        # This should throw an error
        @test_throws ArgumentError fit!(ohlc_resampler, MarketDataPoint(base_time + Second(15), 95.0, 1200.0))

        # Test Mean resampler
        mean_resampler = MeanResampler(Minute(1), validate_chronological=true)

        fit!(mean_resampler, MarketDataPoint(base_time, 100.0, 1000.0))

        @test_throws ArgumentError fit!(mean_resampler, MarketDataPoint(base_time - Second(1), 95.0, 1200.0))

        # Test Sum resampler
        sum_resampler = SumResampler(Minute(1), validate_chronological=true)

        fit!(sum_resampler, MarketDataPoint(base_time, 100.0, 1000.0))

        @test_throws ArgumentError fit!(sum_resampler, MarketDataPoint(base_time - Minute(1), 95.0, 1200.0))
    end

    @testset "Validation Error Messages" begin
        resampler = MarketResampler(Minute(1), validate_chronological=true)
        base_time = DateTime(2024, 1, 1, 9, 30, 0)

        fit!(resampler, MarketDataPoint(base_time + Second(30), 105.0, 800.0))

        # Try to add out-of-order data and check error message
        try
            fit!(resampler, MarketDataPoint(base_time, 100.0, 1000.0))
            @test false  # Should not reach here
        catch e
            @test e isa ArgumentError
            error_msg = e.msg
            @test occursin("Data not in chronological order", error_msg)
            @test occursin(string(base_time), error_msg)
            @test occursin(string(base_time + Second(30)), error_msg)
            @test occursin("validate_chronological=false", error_msg)
        end
    end

    @testset "Same Timestamp Allowed" begin
        # Same timestamp should be allowed (equal is not less than)
        resampler = MarketResampler(Minute(1), validate_chronological=true)
        base_time = DateTime(2024, 1, 1, 9, 30, 0)

        fit!(resampler, MarketDataPoint(base_time, 100.0, 1000.0))
        # Same timestamp should be fine
        fit!(resampler, MarketDataPoint(base_time, 105.0, 800.0))

        result = value(resampler)
        @test result.price.ohlc !== nothing
        @test result.price.ohlc.open == 100.0  # First data point
        @test result.price.ohlc.close == 105.0  # Last data point
        @test result.volume == 1800.0
    end

    @testset "Validation Across Windows" begin
        resampler = MarketResampler(Minute(1), validate_chronological=true)
        base_time = DateTime(2024, 1, 1, 9, 30, 0)

        # Process data across multiple windows chronologically
        fit!(resampler, MarketDataPoint(base_time, 100.0, 1000.0))
        fit!(resampler, MarketDataPoint(base_time + Second(30), 105.0, 800.0))
        fit!(resampler, MarketDataPoint(base_time + Minute(1), 110.0, 1200.0))  # Next window
        fit!(resampler, MarketDataPoint(base_time + Minute(1) + Second(30), 108.0, 900.0))

        # This should work fine
        result = value(resampler)
        @test result.price.ohlc !== nothing

        # But going backwards should fail
        @test_throws ArgumentError fit!(resampler, MarketDataPoint(base_time + Second(45), 95.0, 1500.0))
    end

    @testset "Individual Resampler Types" begin
        base_time = DateTime(2024, 1, 1, 9, 30, 0)

        # Test all individual resampler types
        resamplers = [
            OHLCResampler{DateTime,Float64,Float64}(Minute(1), validate_chronological=true),
            MeanResampler{DateTime,Float64,Float64}(Minute(1), validate_chronological=true),
            SumResampler{DateTime,Float64,Float64}(Minute(1), validate_chronological=true)
        ]

        for resampler in resamplers
            @test resampler.validate_chronological == true

            # Chronological should work
            fit!(resampler, MarketDataPoint{DateTime,Float64,Float64}(base_time, 100.0, 1000.0))
            fit!(resampler, MarketDataPoint{DateTime,Float64,Float64}(base_time + Second(30), 105.0, 800.0))

            # Out-of-order should fail
            @test_throws ArgumentError fit!(resampler, MarketDataPoint{DateTime,Float64,Float64}(base_time + Second(15), 95.0, 1200.0))
        end
    end

    @testset "MarketResampler with Different Price Methods" begin
        base_time = DateTime(2024, 1, 1, 9, 30, 0)

        # Test OHLC method
        ohlc_resampler = MarketResampler(Minute(1), price_method=:ohlc, validate_chronological=true)
        @test ohlc_resampler.price_resampler.validate_chronological == true

        fit!(ohlc_resampler, MarketDataPoint(base_time, 100.0, 1000.0))
        @test_throws ArgumentError fit!(ohlc_resampler, MarketDataPoint(base_time - Second(1), 95.0, 800.0))

        # Test Mean method
        mean_resampler = MarketResampler(Minute(1), price_method=:mean, validate_chronological=true)
        @test mean_resampler.price_resampler.validate_chronological == true

        fit!(mean_resampler, MarketDataPoint(base_time, 100.0, 1000.0))
        @test_throws ArgumentError fit!(mean_resampler, MarketDataPoint(base_time - Second(1), 95.0, 800.0))
    end

    @testset "Validation State Management" begin
        resampler = MarketResampler(Minute(1), validate_chronological=true)
        base_time = DateTime(2024, 1, 1, 9, 30, 0)

        # Initial state
        @test resampler.price_resampler.last_timestamp === nothing

        # After first data point
        fit!(resampler, MarketDataPoint(base_time, 100.0, 1000.0))
        @test resampler.price_resampler.last_timestamp == base_time

        # After second data point
        fit!(resampler, MarketDataPoint(base_time + Second(30), 105.0, 800.0))
        @test resampler.price_resampler.last_timestamp == base_time + Second(30)

        # The volume resampler should also track timestamps
        @test resampler.volume_resampler.last_timestamp == base_time + Second(30)
    end

    @testset "Performance: Validation Disabled vs Enabled" begin
        # This is more of a sanity check that validation doesn't break basic functionality
        base_time = DateTime(2024, 1, 1, 9, 30, 0)
        data = [MarketDataPoint(base_time + Second(i), 100.0 + i*0.1, 1000.0) for i in 1:100]

        # Without validation
        resampler_no_val = MarketResampler(Minute(1), validate_chronological=false)
        for d in data
            fit!(resampler_no_val, d)
        end
        result_no_val = value(resampler_no_val)

        # With validation
        resampler_with_val = MarketResampler(Minute(1), validate_chronological=true)
        for d in data
            fit!(resampler_with_val, d)
        end
        result_with_val = value(resampler_with_val)

        # Results should be identical for chronological data
        @test result_no_val.price.ohlc.open == result_with_val.price.ohlc.open
        @test result_no_val.price.ohlc.high == result_with_val.price.ohlc.high
        @test result_no_val.price.ohlc.low == result_with_val.price.ohlc.low
        @test result_no_val.price.ohlc.close == result_with_val.price.ohlc.close
        @test result_no_val.volume == result_with_val.volume
    end

end