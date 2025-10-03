using OnlineResamplers
using OnlineStatsBase
using Dates
using Test

# BDD-style macros for Given-When-Then structure
macro scenario(description, body)
    esc(quote
        @testset $description begin
            $body
        end
    end)
end

macro given(description, body)
    quote
        # Given block - setup
        $(esc(body))
    end
end

macro when(description, body)
    quote
        # When block - action
        $(esc(body))
    end
end

macro then(description, body)
    quote
        # Then block - assertion
        $(esc(body))
    end
end

macro and_(description, body)
    quote
        # And block - additional assertion
        $(esc(body))
    end
end

@testset "OnlineResamplers.jl - BDD Specifications" begin

    # ====================================================================================
    # REQ-PKG-001 & REQ-PKG-002: Package Structure
    # ====================================================================================

    @scenario "The package is properly configured" begin
        @given "the package OnlineResamplers" begin
            @test isdefined(@__MODULE__, :OnlineResamplers)
        end

        @when "I check the dependencies" begin
            @test isdefined(@__MODULE__, :OnlineStatsBase)
            @test isdefined(@__MODULE__, :Dates)
        end

        @then "OnlineStatsBase should be available as a dependency" begin
            @test true  # Already verified above
        end
    end

    # ====================================================================================
    # REQ-DATA-001, REQ-DATA-002: MarketDataPoint Structure
    # ====================================================================================

    @scenario "Creating a MarketDataPoint with explicit types" begin
        @given "timestamp, price, and volume values" begin
            dt = DateTime(2024, 1, 1, 9, 30, 0)
            price = 100.0
            volume = 1000.0
        end

        @when "I create a MarketDataPoint with explicit types" begin
            dt = DateTime(2024, 1, 1, 9, 30, 0)
            price = 100.0
            volume = 1000.0
            data = MarketDataPoint{DateTime, Float64, Float64}(dt, price, volume)
        end

        @then "it should have the correct datetime field" begin
            dt = DateTime(2024, 1, 1, 9, 30, 0)
            data = MarketDataPoint{DateTime, Float64, Float64}(dt, 100.0, 1000.0)
            @test data.datetime == dt
        end

        @and_ "it should have the correct price field" begin
            dt = DateTime(2024, 1, 1, 9, 30, 0)
            data = MarketDataPoint{DateTime, Float64, Float64}(dt, 100.0, 1000.0)
            @test data.price == 100.0
        end

        @and_ "it should have the correct volume field" begin
            dt = DateTime(2024, 1, 1, 9, 30, 0)
            data = MarketDataPoint{DateTime, Float64, Float64}(dt, 100.0, 1000.0)
            @test data.volume == 1000.0
        end
    end

    # REQ-DATA-003: Convenience Constructor
    @scenario "Creating a MarketDataPoint with convenience constructor" begin
        @given "DateTime timestamp and numeric price and volume" begin
            dt = DateTime(2024, 1, 1, 9, 30, 0)
            price = 100
            volume = 1000
        end

        @when "I use the convenience constructor" begin
            dt = DateTime(2024, 1, 1, 9, 30, 0)
            data = MarketDataPoint(dt, 100, 1000)
        end

        @then "it should create a MarketDataPoint with Float64 types" begin
            dt = DateTime(2024, 1, 1, 9, 30, 0)
            data = MarketDataPoint(dt, 100, 1000)
            @test data isa MarketDataPoint{DateTime, Float64, Float64}
            @test data.price isa Float64
            @test data.volume isa Float64
        end
    end

    # ====================================================================================
    # REQ-OHLC-001, REQ-OHLC-002: OHLC Structure
    # ====================================================================================

    @scenario "Creating an OHLC structure" begin
        @given "open, high, low, and close price values" begin
            o, h, l, c = 100.0, 105.0, 98.0, 103.0
        end

        @when "I create an OHLC structure" begin
            ohlc = OHLC{Float64}(100.0, 105.0, 98.0, 103.0)
        end

        @then "it should have all four price fields" begin
            ohlc = OHLC{Float64}(100.0, 105.0, 98.0, 103.0)
            @test ohlc.open == 100.0
            @test ohlc.high == 105.0
            @test ohlc.low == 98.0
            @test ohlc.close == 103.0
        end
    end

    # REQ-OHLC-003: Custom show method
    @scenario "Displaying an OHLC structure" begin
        @given "an OHLC structure" begin
            ohlc = OHLC{Float64}(100.0, 105.0, 98.0, 103.0)
        end

        @when "I convert it to a string" begin
            ohlc = OHLC{Float64}(100.0, 105.0, 98.0, 103.0)
            str = string(ohlc)
        end

        @then "it should display in OHLC format" begin
            ohlc = OHLC{Float64}(100.0, 105.0, 98.0, 103.0)
            str = string(ohlc)
            @test occursin("OHLC", str)
            @test occursin("100.0", str)
            @test occursin("105.0", str)
            @test occursin("98.0", str)
            @test occursin("103.0", str)
        end
    end

    # ====================================================================================
    # REQ-TIMEWIN-001 to REQ-TIMEWIN-005: TimeWindow
    # ====================================================================================

    @scenario "Creating a TimeWindow" begin
        @given "a start time and a period" begin
            start = DateTime(2024, 1, 1, 9, 30, 0)
            period = Minute(1)
        end

        @when "I create a TimeWindow" begin
            start = DateTime(2024, 1, 1, 9, 30, 0)
            window = TimeWindow{DateTime}(start, Minute(1))
        end

        @then "it should have the correct start_time" begin
            start = DateTime(2024, 1, 1, 9, 30, 0)
            window = TimeWindow{DateTime}(start, Minute(1))
            @test window.start_time == start
        end

        @and_ "it should have the correct period" begin
            window = TimeWindow{DateTime}(DateTime(2024, 1, 1, 9, 30, 0), Minute(1))
            @test window.period == Minute(1)
        end
    end

    @scenario "Checking if data belongs to TimeWindow" begin
        @given "a TimeWindow from 9:30 to 9:31" begin
            window = TimeWindow{DateTime}(DateTime(2024, 1, 1, 9, 30, 0), Minute(1))
        end

        @when "I check if data at 9:30:30 belongs to the window" begin
            window = TimeWindow{DateTime}(DateTime(2024, 1, 1, 9, 30, 0), Minute(1))
            data = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 30), 100.0, 1000.0)
        end

        @then "it should return true" begin
            window = TimeWindow{DateTime}(DateTime(2024, 1, 1, 9, 30, 0), Minute(1))
            data = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 30), 100.0, 1000.0)
            @test belongs_to_window(data, window) == true
        end

        @and_ "data at 9:31:00 should NOT belong to the window" begin
            window = TimeWindow{DateTime}(DateTime(2024, 1, 1, 9, 30, 0), Minute(1))
            data = MarketDataPoint(DateTime(2024, 1, 1, 9, 31, 0), 100.0, 1000.0)
            @test belongs_to_window(data, window) == false
        end
    end

    @scenario "Getting TimeWindow end time" begin
        @given "a TimeWindow from 9:30 with 1 minute period" begin
            window = TimeWindow{DateTime}(DateTime(2024, 1, 1, 9, 30, 0), Minute(1))
        end

        @when "I get the window end time" begin
            window = TimeWindow{DateTime}(DateTime(2024, 1, 1, 9, 30, 0), Minute(1))
            end_time = window_end(window)
        end

        @then "it should be 9:31:00" begin
            window = TimeWindow{DateTime}(DateTime(2024, 1, 1, 9, 30, 0), Minute(1))
            end_time = window_end(window)
            @test end_time == DateTime(2024, 1, 1, 9, 31, 0)
        end
    end

    @scenario "Checking if TimeWindow should finalize" begin
        @given "a TimeWindow from 9:30 to 9:31" begin
            window = TimeWindow{DateTime}(DateTime(2024, 1, 1, 9, 30, 0), Minute(1))
        end

        @when "I check if data at 9:31:00 should finalize the window" begin
            window = TimeWindow{DateTime}(DateTime(2024, 1, 1, 9, 30, 0), Minute(1))
            data = MarketDataPoint(DateTime(2024, 1, 1, 9, 31, 0), 100.0, 1000.0)
        end

        @then "it should return true" begin
            window = TimeWindow{DateTime}(DateTime(2024, 1, 1, 9, 30, 0), Minute(1))
            data = MarketDataPoint(DateTime(2024, 1, 1, 9, 31, 0), 100.0, 1000.0)
            @test should_finalize(data, window) == true
        end
    end

    # ====================================================================================
    # REQ-VOLWIN-001 to REQ-VOLWIN-007: VolumeWindow
    # ====================================================================================

    @scenario "Creating a VolumeWindow" begin
        @given "a target volume of 1000" begin
            target = 1000.0
        end

        @when "I create a VolumeWindow with convenience constructor" begin
            window = VolumeWindow(1000.0)
        end

        @then "it should have the correct target_volume" begin
            window = VolumeWindow(1000.0)
            @test window.target_volume == 1000.0
        end

        @and_ "it should initialize current_volume to zero" begin
            window = VolumeWindow(1000.0)
            @test window.current_volume == 0.0
        end
    end

    @scenario "Checking if data belongs to VolumeWindow" begin
        @given "a VolumeWindow with target 1000 and current 600" begin
            window = VolumeWindow{Float64}(1000.0, 600.0)
        end

        @when "I check if data with volume 300 belongs" begin
            window = VolumeWindow{Float64}(1000.0, 600.0)
            data = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 300.0)
        end

        @then "it should return true (600 + 300 < 1000)" begin
            window = VolumeWindow{Float64}(1000.0, 600.0)
            data = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 300.0)
            @test belongs_to_window(data, window) == true
        end

        @and_ "data with volume 500 should NOT belong (600 + 500 >= 1000)" begin
            window = VolumeWindow{Float64}(1000.0, 600.0)
            data = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 500.0)
            @test belongs_to_window(data, window) == false
        end
    end

    @scenario "Checking if VolumeWindow should finalize" begin
        @given "a VolumeWindow with target 1000 and current 800" begin
            window = VolumeWindow{Float64}(1000.0, 800.0)
        end

        @when "I check if data with volume 300 should finalize" begin
            window = VolumeWindow{Float64}(1000.0, 800.0)
            data = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 300.0)
        end

        @then "it should return true (800 + 300 >= 1000)" begin
            window = VolumeWindow{Float64}(1000.0, 800.0)
            data = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 300.0)
            @test should_finalize(data, window) == true
        end
    end

    @scenario "Creating next VolumeWindow" begin
        @given "a VolumeWindow with current volume 1200" begin
            window = VolumeWindow{Float64}(1000.0, 1200.0)
            data = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 100.0)
        end

        @when "I create the next window" begin
            window = VolumeWindow{Float64}(1000.0, 1200.0)
            data = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 100.0)
            next = next_window(window, data)
        end

        @then "it should reset current_volume to zero" begin
            window = VolumeWindow{Float64}(1000.0, 1200.0)
            data = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 100.0)
            next = next_window(window, data)
            @test next.current_volume == 0.0
        end

        @and_ "it should keep the same target_volume" begin
            window = VolumeWindow{Float64}(1000.0, 1200.0)
            data = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 100.0)
            next = next_window(window, data)
            @test next.target_volume == 1000.0
        end
    end

    # ====================================================================================
    # REQ-TICKWIN-001 to REQ-TICKWIN-007: TickWindow
    # ====================================================================================

    @scenario "Creating a TickWindow" begin
        @given "a target tick count of 100" begin
            target = 100
        end

        @when "I create a TickWindow with convenience constructor" begin
            window = TickWindow(100)
        end

        @then "it should have the correct target_ticks" begin
            window = TickWindow(100)
            @test window.target_ticks == 100
        end

        @and_ "it should initialize current_ticks to zero" begin
            window = TickWindow(100)
            @test window.current_ticks == 0
        end
    end

    @scenario "Checking if data belongs to TickWindow" begin
        @given "a TickWindow with target 100 and current 50" begin
            window = TickWindow(100, 50)
        end

        @when "I check if data belongs" begin
            window = TickWindow(100, 50)
            data = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0)
        end

        @then "it should return true (50 < 100)" begin
            window = TickWindow(100, 50)
            data = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0)
            @test belongs_to_window(data, window) == true
        end

        @and_ "when current equals target, it should return false" begin
            window = TickWindow(100, 100)
            data = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0)
            @test belongs_to_window(data, window) == false
        end
    end

    @scenario "Checking if TickWindow should finalize" begin
        @given "a TickWindow with target 100 and current 100" begin
            window = TickWindow(100, 100)
        end

        @when "I check if data should finalize" begin
            window = TickWindow(100, 100)
            data = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0)
        end

        @then "it should return true (100 >= 100)" begin
            window = TickWindow(100, 100)
            data = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0)
            @test should_finalize(data, window) == true
        end
    end

    # ====================================================================================
    # REQ-OHLC-RESAMP-001 to REQ-OHLC-RESAMP-007: OHLCResampler
    # ====================================================================================

    @scenario "Creating an OHLCResampler with Period" begin
        @given "a time period of 1 minute" begin
            period = Minute(1)
        end

        @when "I create an OHLCResampler" begin
            resampler = OHLCResampler(Minute(1))
        end

        @then "it should be an AbstractResampler" begin
            resampler = OHLCResampler(Minute(1))
            @test resampler isa AbstractResampler
        end

        @and_ "it should have validate_chronological set to false by default" begin
            resampler = OHLCResampler(Minute(1))
            @test resampler.validate_chronological == false
        end
    end

    @scenario "Creating an OHLCResampler with VolumeWindow" begin
        @given "a volume window with target 1000" begin
            window = VolumeWindow(1000.0)
        end

        @when "I create an OHLCResampler" begin
            resampler = OHLCResampler(VolumeWindow(1000.0))
        end

        @then "it should be an OHLCResampler with VolumeWindow type" begin
            resampler = OHLCResampler(VolumeWindow(1000.0))
            @test resampler isa OHLCResampler
            @test resampler.window_spec isa VolumeWindow
        end
    end

    @scenario "Processing first data point in OHLCResampler" begin
        @given "an empty OHLCResampler" begin
            resampler = OHLCResampler(Minute(1))
        end

        @when "I fit the first data point with price 100.0" begin
            resampler = OHLCResampler(Minute(1))
            data = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0)
            fit!(resampler, data)
        end

        @then "OHLC should have all values equal to 100.0" begin
            resampler = OHLCResampler(Minute(1))
            data = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0)
            fit!(resampler, data)
            result = value(resampler)
            @test result.ohlc.open == 100.0
            @test result.ohlc.high == 100.0
            @test result.ohlc.low == 100.0
            @test result.ohlc.close == 100.0
        end

        @and_ "volume should be 1000.0" begin
            resampler = OHLCResampler(Minute(1))
            data = MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0)
            fit!(resampler, data)
            result = value(resampler)
            @test result.volume == 1000.0
        end
    end

    @scenario "Processing multiple data points in same window" begin
        @given "an OHLCResampler with one data point" begin
            resampler = OHLCResampler(Minute(1))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 500.0))
        end

        @when "I add more data with varying prices in the same minute" begin
            resampler = OHLCResampler(Minute(1))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 500.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 20), 105.0, 300.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 40), 98.0, 200.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 50), 102.0, 400.0))
        end

        @then "open should remain 100.0" begin
            resampler = OHLCResampler(Minute(1))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 500.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 20), 105.0, 300.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 40), 98.0, 200.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 50), 102.0, 400.0))
            result = value(resampler)
            @test result.ohlc.open == 100.0
        end

        @and_ "high should be 105.0" begin
            resampler = OHLCResampler(Minute(1))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 500.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 20), 105.0, 300.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 40), 98.0, 200.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 50), 102.0, 400.0))
            result = value(resampler)
            @test result.ohlc.high == 105.0
        end

        @and_ "low should be 98.0" begin
            resampler = OHLCResampler(Minute(1))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 500.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 20), 105.0, 300.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 40), 98.0, 200.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 50), 102.0, 400.0))
            result = value(resampler)
            @test result.ohlc.low == 98.0
        end

        @and_ "close should be 102.0 (last price)" begin
            resampler = OHLCResampler(Minute(1))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 500.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 20), 105.0, 300.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 40), 98.0, 200.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 50), 102.0, 400.0))
            result = value(resampler)
            @test result.ohlc.close == 102.0
        end

        @and_ "total volume should be 1400.0" begin
            resampler = OHLCResampler(Minute(1))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 500.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 20), 105.0, 300.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 40), 98.0, 200.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 50), 102.0, 400.0))
            result = value(resampler)
            @test result.volume == 1400.0
        end
    end

    @scenario "Window finalization in OHLCResampler" begin
        @given "an OHLCResampler with data in the 9:30 minute window" begin
            resampler = OHLCResampler(Minute(1))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 30), 105.0, 800.0))
        end

        @when "I add data from the 9:31 minute window" begin
            resampler = OHLCResampler(Minute(1))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 30), 105.0, 800.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 31, 0), 103.0, 500.0))
        end

        @then "a new window should be started" begin
            resampler = OHLCResampler(Minute(1))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 30), 105.0, 800.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 31, 0), 103.0, 500.0))
            result = value(resampler)
            @test result.ohlc.open == 103.0
        end

        @and_ "the new window should have volume 500.0" begin
            resampler = OHLCResampler(Minute(1))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 30), 105.0, 800.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 31, 0), 103.0, 500.0))
            result = value(resampler)
            @test result.volume == 500.0
        end

        @and_ "observation count should be 1 in the new window" begin
            resampler = OHLCResampler(Minute(1))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 30), 105.0, 800.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 31, 0), 103.0, 500.0))
            @test nobs(resampler) == 1
        end
    end

    # ====================================================================================
    # REQ-MEAN-RESAMP-001 to REQ-MEAN-RESAMP-005: MeanResampler
    # ====================================================================================

    @scenario "Creating a MeanResampler" begin
        @given "a time period of 1 minute" begin
            period = Minute(1)
        end

        @when "I create a MeanResampler" begin
            resampler = MeanResampler(Minute(1))
        end

        @then "it should be an AbstractResampler" begin
            resampler = MeanResampler(Minute(1))
            @test resampler isa AbstractResampler
        end
    end

    @scenario "Calculating mean price in MeanResampler" begin
        @given "a MeanResampler" begin
            resampler = MeanResampler(Minute(1))
        end

        @when "I add data points with prices 100, 110, 105" begin
            resampler = MeanResampler(Minute(1))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 500.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 20), 110.0, 600.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 40), 105.0, 400.0))
        end

        @then "mean price should be 105.0" begin
            resampler = MeanResampler(Minute(1))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 500.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 20), 110.0, 600.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 40), 105.0, 400.0))
            result = value(resampler)
            @test result.mean_price ≈ 105.0
        end

        @and_ "total volume should be 1500.0" begin
            resampler = MeanResampler(Minute(1))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 500.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 20), 110.0, 600.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 40), 105.0, 400.0))
            result = value(resampler)
            @test result.volume == 1500.0
        end
    end

    # ====================================================================================
    # REQ-SUM-RESAMP-001 to REQ-SUM-RESAMP-004: SumResampler
    # ====================================================================================

    @scenario "Creating a SumResampler" begin
        @given "a time period of 1 minute" begin
            period = Minute(1)
        end

        @when "I create a SumResampler" begin
            resampler = SumResampler(Minute(1))
        end

        @then "it should be an AbstractResampler" begin
            resampler = SumResampler(Minute(1))
            @test resampler isa AbstractResampler
        end
    end

    @scenario "Summing volume in SumResampler" begin
        @given "a SumResampler" begin
            resampler = SumResampler(Minute(1))
        end

        @when "I add data points with volumes 500, 600, 400" begin
            resampler = SumResampler(Minute(1))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 500.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 20), 110.0, 600.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 40), 105.0, 400.0))
        end

        @then "sum should be 1500.0" begin
            resampler = SumResampler(Minute(1))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 500.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 20), 110.0, 600.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 40), 105.0, 400.0))
            result = value(resampler)
            @test result.sum == 1500.0
        end
    end

    # ====================================================================================
    # REQ-MARKET-RESAMP-001 to REQ-MARKET-RESAMP-008: MarketResampler
    # ====================================================================================

    @scenario "Creating a MarketResampler with OHLC price method" begin
        @given "a time period and price_method=:ohlc" begin
            period = Minute(1)
            method = :ohlc
        end

        @when "I create a MarketResampler" begin
            resampler = MarketResampler(Minute(1), price_method=:ohlc)
        end

        @then "price_resampler should be an OHLCResampler" begin
            resampler = MarketResampler(Minute(1), price_method=:ohlc)
            @test resampler.price_resampler isa OHLCResampler
        end

        @and_ "volume_resampler should be a SumResampler" begin
            resampler = MarketResampler(Minute(1), price_method=:ohlc)
            @test resampler.volume_resampler isa SumResampler
        end
    end

    @scenario "Creating a MarketResampler with mean price method" begin
        @given "a time period and price_method=:mean" begin
            period = Minute(1)
            method = :mean
        end

        @when "I create a MarketResampler" begin
            resampler = MarketResampler(Minute(1), price_method=:mean)
        end

        @then "price_resampler should be a MeanResampler" begin
            resampler = MarketResampler(Minute(1), price_method=:mean)
            @test resampler.price_resampler isa MeanResampler
        end
    end

    @scenario "Creating a MarketResampler with invalid price method" begin
        @given "an invalid price_method" begin
            method = :invalid
        end

        @when "I try to create a MarketResampler" begin
            # Will attempt creation
        end

        @then "it should throw an ArgumentError" begin
            @test_throws ArgumentError MarketResampler(Minute(1), price_method=:invalid)
        end

        @and_ "error message should mention valid methods" begin
            err = try
                MarketResampler(Minute(1), price_method=:invalid)
                nothing
            catch e
                e
            end
            @test err isa ArgumentError
            @test occursin("ohlc", err.msg) || occursin("mean", err.msg)
        end
    end

    @scenario "Processing data with MarketResampler" begin
        @given "a MarketResampler with OHLC method" begin
            resampler = MarketResampler(Minute(1), price_method=:ohlc)
        end

        @when "I fit data points" begin
            resampler = MarketResampler(Minute(1), price_method=:ohlc)
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 500.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 30), 105.0, 800.0))
        end

        @then "both price and volume resamplers should be updated" begin
            resampler = MarketResampler(Minute(1), price_method=:ohlc)
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 500.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 30), 105.0, 800.0))
            @test nobs(resampler.price_resampler) == 2
            @test nobs(resampler.volume_resampler) == 2
        end

        @and_ "value should return price and volume information" begin
            resampler = MarketResampler(Minute(1), price_method=:ohlc)
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 500.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 30), 105.0, 800.0))
            result = value(resampler)
            @test haskey(result, :price)
            @test haskey(result, :volume)
            @test haskey(result, :window)
            @test result.volume == 1300.0
        end
    end

    # ====================================================================================
    # REQ-CHRONO-001 to REQ-CHRONO-004: Chronological Validation
    # ====================================================================================

    @scenario "Creating a resampler with chronological validation enabled" begin
        @given "validate_chronological=true parameter" begin
            validate = true
        end

        @when "I create an OHLCResampler" begin
            resampler = OHLCResampler(Minute(1), validate_chronological=true)
        end

        @then "validate_chronological should be true" begin
            resampler = OHLCResampler(Minute(1), validate_chronological=true)
            @test resampler.validate_chronological == true
        end
    end

    @scenario "Processing in-order data with validation enabled" begin
        @given "a resampler with chronological validation" begin
            resampler = OHLCResampler(Minute(1), validate_chronological=true)
        end

        @when "I process data in chronological order" begin
            resampler = OHLCResampler(Minute(1), validate_chronological=true)
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 30), 105.0, 800.0))
        end

        @then "it should process without errors" begin
            resampler = OHLCResampler(Minute(1), validate_chronological=true)
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 30), 105.0, 800.0))
            @test nobs(resampler) == 2
        end
    end

    @scenario "Processing out-of-order data with validation enabled" begin
        @given "a resampler with chronological validation and existing data" begin
            resampler = OHLCResampler(Minute(1), validate_chronological=true)
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 30), 100.0, 1000.0))
        end

        @when "I try to process data with earlier timestamp" begin
            resampler = OHLCResampler(Minute(1), validate_chronological=true)
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 30), 100.0, 1000.0))
            # Will try to fit earlier data
        end

        @then "it should throw an ArgumentError" begin
            resampler = OHLCResampler(Minute(1), validate_chronological=true)
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 30), 100.0, 1000.0))
            @test_throws ArgumentError fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 105.0, 800.0))
        end

        @and_ "error message should mention chronological order" begin
            resampler = OHLCResampler(Minute(1), validate_chronological=true)
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 30), 100.0, 1000.0))
            err = try
                fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 105.0, 800.0))
                nothing
            catch e
                e
            end
            @test err isa ArgumentError
            @test occursin("chronological", lowercase(err.msg))
        end

        @and_ "error message should include both timestamps" begin
            resampler = OHLCResampler(Minute(1), validate_chronological=true)
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 30), 100.0, 1000.0))
            err = try
                fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 105.0, 800.0))
                nothing
            catch e
                e
            end
            @test occursin("9:30:30", err.msg) || occursin("09:30:30", err.msg)
            @test occursin("9:30:00", err.msg) || occursin("09:30:00", err.msg)
        end
    end

    @scenario "Processing out-of-order data with validation disabled" begin
        @given "a resampler with validation disabled" begin
            resampler = OHLCResampler(Minute(1), validate_chronological=false)
        end

        @when "I process data out of order" begin
            resampler = OHLCResampler(Minute(1), validate_chronological=false)
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 30), 100.0, 1000.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 105.0, 800.0))
        end

        @then "it should process without errors" begin
            resampler = OHLCResampler(Minute(1), validate_chronological=false)
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 30), 100.0, 1000.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 105.0, 800.0))
            @test nobs(resampler) == 2
        end
    end

    # ====================================================================================
    # REQ-MERGE-001 to REQ-MERGE-003: Merging Resamplers
    # ====================================================================================

    @scenario "Merging two OHLCResamplers" begin
        @given "two OHLCResamplers with different data" begin
            r1 = OHLCResampler(Minute(1))
            fit!(r1, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 500.0))
            fit!(r1, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 20), 105.0, 300.0))

            r2 = OHLCResampler(Minute(1))
            fit!(r2, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 40), 98.0, 400.0))
        end

        @when "I merge them" begin
            r1 = OHLCResampler(Minute(1))
            fit!(r1, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 500.0))
            fit!(r1, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 20), 105.0, 300.0))

            r2 = OHLCResampler(Minute(1))
            fit!(r2, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 40), 98.0, 400.0))

            merge!(r1, r2)
        end

        @then "open should be from first resampler" begin
            r1 = OHLCResampler(Minute(1))
            fit!(r1, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 500.0))
            fit!(r1, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 20), 105.0, 300.0))

            r2 = OHLCResampler(Minute(1))
            fit!(r2, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 40), 98.0, 400.0))

            merge!(r1, r2)
            result = value(r1)
            @test result.ohlc.open == 100.0
        end

        @and_ "high should be maximum of both" begin
            r1 = OHLCResampler(Minute(1))
            fit!(r1, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 500.0))
            fit!(r1, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 20), 105.0, 300.0))

            r2 = OHLCResampler(Minute(1))
            fit!(r2, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 40), 98.0, 400.0))

            merge!(r1, r2)
            result = value(r1)
            @test result.ohlc.high == 105.0
        end

        @and_ "low should be minimum of both" begin
            r1 = OHLCResampler(Minute(1))
            fit!(r1, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 500.0))
            fit!(r1, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 20), 105.0, 300.0))

            r2 = OHLCResampler(Minute(1))
            fit!(r2, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 40), 98.0, 400.0))

            merge!(r1, r2)
            result = value(r1)
            @test result.ohlc.low == 98.0
        end

        @and_ "close should be from second resampler" begin
            r1 = OHLCResampler(Minute(1))
            fit!(r1, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 500.0))
            fit!(r1, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 20), 105.0, 300.0))

            r2 = OHLCResampler(Minute(1))
            fit!(r2, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 40), 98.0, 400.0))

            merge!(r1, r2)
            result = value(r1)
            @test result.ohlc.close == 98.0
        end

        @and_ "volumes should be summed" begin
            r1 = OHLCResampler(Minute(1))
            fit!(r1, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 500.0))
            fit!(r1, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 20), 105.0, 300.0))

            r2 = OHLCResampler(Minute(1))
            fit!(r2, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 40), 98.0, 400.0))

            merge!(r1, r2)
            result = value(r1)
            @test result.volume == 1200.0
        end
    end

    @scenario "Merging two MeanResamplers" begin
        @given "two MeanResamplers with data" begin
            r1 = MeanResampler(Minute(1))
            fit!(r1, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 500.0))

            r2 = MeanResampler(Minute(1))
            fit!(r2, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 30), 110.0, 500.0))
        end

        @when "I merge them" begin
            r1 = MeanResampler(Minute(1))
            fit!(r1, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 500.0))

            r2 = MeanResampler(Minute(1))
            fit!(r2, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 30), 110.0, 500.0))

            merge!(r1, r2)
        end

        @then "mean price should be 105.0" begin
            r1 = MeanResampler(Minute(1))
            fit!(r1, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 500.0))

            r2 = MeanResampler(Minute(1))
            fit!(r2, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 30), 110.0, 500.0))

            merge!(r1, r2)
            result = value(r1)
            @test result.mean_price ≈ 105.0
        end
    end

    # ====================================================================================
    # Integration Tests: Volume-Based Resampling
    # ====================================================================================

    @scenario "Volume-based OHLC bar creation" begin
        @given "an OHLCResampler with 1000 volume target" begin
            resampler = OHLCResampler(VolumeWindow(1000.0))
        end

        @when "I process data that accumulates to 1000+ volume" begin
            resampler = OHLCResampler(VolumeWindow(1000.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 400.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 5), 102.0, 300.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 10), 99.0, 200.0))  # Total: 900
        end

        @then "the bar should not finalize yet" begin
            resampler = OHLCResampler(VolumeWindow(1000.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 400.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 5), 102.0, 300.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 10), 99.0, 200.0))
            result = value(resampler)
            @test result.volume == 900.0
            @test nobs(resampler) == 3
        end

        @and_ "adding more data should start a new bar" begin
            resampler = OHLCResampler(VolumeWindow(1000.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 400.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 5), 102.0, 300.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 10), 99.0, 200.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 15), 101.0, 300.0))  # 900 + 300 >= 1000
            result = value(resampler)
            @test result.ohlc.open == 101.0
            @test result.volume == 300.0
            @test nobs(resampler) == 1
        end
    end

    # ====================================================================================
    # Integration Tests: Tick-Based Resampling
    # ====================================================================================

    @scenario "Tick-based bar creation" begin
        @given "an OHLCResampler with 3 tick target" begin
            resampler = OHLCResampler(TickWindow(3))
        end

        @when "I process exactly 3 ticks" begin
            resampler = OHLCResampler(TickWindow(3))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 5), 102.0, 800.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 10), 99.0, 1200.0))
        end

        @then "the bar should have all 3 ticks" begin
            resampler = OHLCResampler(TickWindow(3))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 5), 102.0, 800.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 10), 99.0, 1200.0))
            @test nobs(resampler) == 3
        end

        @and_ "the next tick should start a new bar" begin
            resampler = OHLCResampler(TickWindow(3))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 5), 102.0, 800.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 10), 99.0, 1200.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 15), 101.0, 500.0))
            @test nobs(resampler) == 1
            result = value(resampler)
            @test result.ohlc.open == 101.0
        end
    end

    # ====================================================================================
    # REQ-RESAMP-002: OnlineStatsBase Interface
    # ====================================================================================

    @scenario "OnlineStatsBase nobs interface" begin
        @given "an OHLCResampler with some data" begin
            resampler = OHLCResampler(Minute(1))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 30), 105.0, 800.0))
        end

        @when "I call nobs" begin
            resampler = OHLCResampler(Minute(1))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 30), 105.0, 800.0))
            n = nobs(resampler)
        end

        @then "it should return the observation count" begin
            resampler = OHLCResampler(Minute(1))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 0), 100.0, 1000.0))
            fit!(resampler, MarketDataPoint(DateTime(2024, 1, 1, 9, 30, 30), 105.0, 800.0))
            @test nobs(resampler) == 2
        end
    end

end  # End of main testset
