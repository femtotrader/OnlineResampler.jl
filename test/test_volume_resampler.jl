using Test
using OnlineResamplers
using OnlineStatsBase
using Dates

@testset "Volume-based Resampling" begin
    @testset "VolumeWindow" begin
        window = VolumeWindow(1000.0)
        @test window.target_volume == 1000.0
        @test window.current_volume == 0.0
    end

    @testset "OHLCResampler with VolumeWindow" begin
        resampler = OHLCResampler(VolumeWindow(1000.0))

        # First bar: accumulate until volume reaches 1000
        data1 = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 400.0)
        data2 = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 5), 102.0, 300.0)
        data3 = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 10), 99.0, 200.0)

        fit!(resampler, data1)
        fit!(resampler, data2)
        fit!(resampler, data3)

        result = value(resampler)
        @test result.ohlc.open == 100.0
        @test result.ohlc.high == 102.0
        @test result.ohlc.low == 99.0
        @test result.ohlc.close == 99.0
        @test result.volume == 900.0

        # This should trigger a new window (900 + 300 >= 1000)
        data4 = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 15), 101.0, 300.0)
        fit!(resampler, data4)

        result = value(resampler)
        @test result.ohlc.open == 101.0
        @test result.ohlc.close == 101.0
        @test result.volume == 300.0
    end

    @testset "MarketResampler with VolumeWindow" begin
        resampler = MarketResampler(VolumeWindow(1000.0))

        # Accumulate data points - first bar
        data1 = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 400.0)
        data2 = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 5), 105.0, 400.0)

        fit!(resampler, data1)
        fit!(resampler, data2)

        result = value(resampler)
        @test result.price.ohlc.open == 100.0
        @test result.price.ohlc.high == 105.0
        @test result.price.ohlc.low == 100.0
        @test result.price.ohlc.close == 105.0
        @test result.volume == 800.0

        # This should trigger a new window (800 + 300 >= 1000)
        data3 = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 10), 102.0, 300.0)
        fit!(resampler, data3)

        result = value(resampler)
        @test result.price.ohlc.open == 102.0
        @test result.price.ohlc.close == 102.0
        @test result.volume == 300.0
    end

    @testset "MeanResampler with VolumeWindow" begin
        resampler = MeanResampler(VolumeWindow(1000.0))

        data1 = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 400.0)
        data2 = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 5), 110.0, 400.0)
        data3 = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 10), 105.0, 100.0)

        fit!(resampler, data1)
        fit!(resampler, data2)
        fit!(resampler, data3)

        result = value(resampler)
        @test result.mean_price == (100.0 + 110.0 + 105.0) / 3
        @test result.volume == 900.0
    end
end

@testset "Tick-based Resampling" begin
    @testset "TickWindow" begin
        window = TickWindow(100)
        @test window.target_ticks == 100
        @test window.current_ticks == 0
    end

    @testset "OHLCResampler with TickWindow" begin
        resampler = OHLCResampler(TickWindow(3))

        data1 = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0)
        data2 = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 5), 102.0, 800.0)
        data3 = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 10), 99.0, 1200.0)

        fit!(resampler, data1)
        fit!(resampler, data2)
        fit!(resampler, data3)

        result = value(resampler)
        @test result.ohlc.open == 100.0
        @test result.ohlc.high == 102.0
        @test result.ohlc.low == 99.0
        @test result.ohlc.close == 99.0
        @test result.volume == 3000.0

        # Next tick should start a new window
        data4 = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 15), 101.0, 500.0)
        fit!(resampler, data4)

        result = value(resampler)
        @test result.ohlc.open == 101.0
        @test result.ohlc.close == 101.0
        @test result.volume == 500.0
    end

    @testset "MarketResampler with TickWindow" begin
        resampler = MarketResampler(TickWindow(2), price_method=:mean)

        data1 = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0)
        data2 = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 5), 110.0, 800.0)

        fit!(resampler, data1)
        fit!(resampler, data2)

        result = value(resampler)
        @test result.price.mean_price == 105.0
        @test result.volume == 1800.0
    end
end

@testset "Backward Compatibility - Time-based Resampling" begin
    # Ensure existing time-based API still works
    resampler = OHLCResampler(Minute(1))

    data1 = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0)
    data2 = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 30), 105.0, 800.0)

    fit!(resampler, data1)
    fit!(resampler, data2)

    result = value(resampler)
    @test result.ohlc.open == 100.0
    @test result.ohlc.high == 105.0
    @test result.ohlc.low == 100.0
    @test result.ohlc.close == 105.0
    @test result.volume == 1800.0
end
