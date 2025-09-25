using OnlineResamplers
using OnlineStatsBase
using Dates
using Test

@testset "OnlineResamplers Tests" begin

    @testset "MarketDataPoint" begin
        # Test basic construction
        dt = DateTime(2024, 1, 1, 10, 0, 0)
        data = MarketDataPoint(dt, 100.0, 1000.0)
        @test data.datetime == dt
        @test data.price == 100.0
        @test data.volume == 1000.0

        # Test parametric construction
        data_param = MarketDataPoint{DateTime, Float64, Float64}(dt, 100.0, 1000.0)
        @test data_param.datetime == dt
        @test data_param.price == 100.0
        @test data_param.volume == 1000.0
    end

    @testset "OHLC" begin
        ohlc = OHLC{Float64}(100.0, 105.0, 95.0, 102.0)
        @test ohlc.open == 100.0
        @test ohlc.high == 105.0
        @test ohlc.low == 95.0
        @test ohlc.close == 102.0
    end

    @testset "TimeWindow" begin
        dt = DateTime(2024, 1, 1, 10, 0, 0)
        window = TimeWindow{DateTime}(dt, Minute(1))
        @test window.start_time == dt
        @test window.period == Minute(1)
        @test window_end(window) == dt + Minute(1)

        # Test belongs_to_window
        @test belongs_to_window(dt, window)
        @test belongs_to_window(dt + Second(30), window)
        @test !belongs_to_window(dt + Minute(1), window)

        # Test next_window
        next_win = next_window(window)
        @test next_win.start_time == dt + Minute(1)
        @test next_win.period == Minute(1)
    end

    @testset "OHLCResampler" begin
        resampler = OHLCResampler(Minute(1))
        @test nobs(resampler) == 0

        # Test single data point
        dt = DateTime(2024, 1, 1, 10, 0, 0)
        data1 = MarketDataPoint(dt, 100.0, 1000.0)
        fit!(resampler, data1)

        @test nobs(resampler) == 1
        result = value(resampler)
        @test result.ohlc.open == 100.0
        @test result.ohlc.high == 100.0
        @test result.ohlc.low == 100.0
        @test result.ohlc.close == 100.0
        @test result.volume == 1000.0

        # Test multiple data points in same window
        data2 = MarketDataPoint(dt + Second(30), 105.0, 500.0)
        fit!(resampler, data2)

        result = value(resampler)
        @test result.ohlc.open == 100.0  # First price
        @test result.ohlc.high == 105.0  # Highest price
        @test result.ohlc.low == 100.0   # Lowest price
        @test result.ohlc.close == 105.0 # Last price
        @test result.volume == 1500.0    # Sum of volumes

        # Test data point with lower price
        data3 = MarketDataPoint(dt + Second(45), 95.0, 300.0)
        fit!(resampler, data3)

        result = value(resampler)
        @test result.ohlc.open == 100.0  # First price
        @test result.ohlc.high == 105.0  # Highest price
        @test result.ohlc.low == 95.0    # Lowest price
        @test result.ohlc.close == 95.0  # Last price
        @test result.volume == 1800.0    # Sum of volumes
    end

    @testset "MeanResampler" begin
        resampler = MeanResampler(Minute(1))
        @test nobs(resampler) == 0

        dt = DateTime(2024, 1, 1, 10, 0, 0)
        data1 = MarketDataPoint(dt, 100.0, 1000.0)
        data2 = MarketDataPoint(dt + Second(30), 110.0, 500.0)

        fit!(resampler, data1)
        fit!(resampler, data2)

        @test nobs(resampler) == 2
        result = value(resampler)
        @test result.mean_price ≈ 105.0  # (100 + 110) / 2
        @test result.volume == 1500.0    # Sum of volumes
    end

    @testset "MarketResampler" begin
        # Test OHLC mode
        resampler = MarketResampler(Minute(1), price_method=:ohlc)

        dt = DateTime(2024, 1, 1, 10, 0, 0)
        data1 = MarketDataPoint(dt, 100.0, 1000.0)
        data2 = MarketDataPoint(dt + Second(30), 105.0, 500.0)

        fit!(resampler, data1)
        fit!(resampler, data2)

        result = value(resampler)
        @test result.price.ohlc.open == 100.0
        @test result.price.ohlc.high == 105.0
        @test result.price.ohlc.low == 100.0
        @test result.price.ohlc.close == 105.0
        @test result.volume == 1500.0

        # Test Mean mode
        resampler_mean = MarketResampler(Minute(1), price_method=:mean)
        fit!(resampler_mean, data1)
        fit!(resampler_mean, data2)

        result_mean = value(resampler_mean)
        @test result_mean.price.mean_price ≈ 102.5
        @test result_mean.volume == 1500.0
    end

    @testset "Parametric Types" begin
        # Test with explicit types
        resampler = OHLCResampler{DateTime, Float64, Float64}(Minute(1))

        dt = DateTime(2024, 1, 1, 10, 0, 0)
        data = MarketDataPoint{DateTime, Float64, Float64}(dt, 100.0, 1000.0)

        fit!(resampler, data)
        result = value(resampler)

        @test result.ohlc isa OHLC{Float64}
        @test result.volume isa Float64
    end

    @testset "Window Transitions" begin
        resampler = OHLCResampler(Minute(1))

        dt = DateTime(2024, 1, 1, 10, 0, 0)

        # First window
        data1 = MarketDataPoint(dt, 100.0, 1000.0)
        fit!(resampler, data1)

        result1 = value(resampler)
        @test result1.ohlc.open == 100.0
        @test result1.volume == 1000.0

        # Second window (next minute)
        data2 = MarketDataPoint(dt + Minute(1), 110.0, 2000.0)
        fit!(resampler, data2)

        result2 = value(resampler)
        # Should be reset for new window
        @test result2.ohlc.open == 110.0
        @test result2.volume == 2000.0
        @test nobs(resampler) == 1  # Count reset for new window
    end
end