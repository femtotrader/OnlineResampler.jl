# OnlineResamplers.jl Specifications

This directory contains the formal specifications and test coverage documentation for OnlineResamplers.jl.

## Files

### [specs.md](specs.md)
The complete EARS (Easy Approach to Requirements Syntax) specification for OnlineResamplers.jl. This document defines all functional and non-functional requirements for the package, organized into:

- Package structure and dependencies
- Data structures (MarketDataPoint, OHLC)
- Window types (TimeWindow, VolumeWindow, TickWindow)
- Resampler types (OHLCResampler, MeanResampler, SumResampler, MarketResampler)
- Chronological validation
- OnlineStatsBase interface compliance
- Error handling
- Testing requirements
- Documentation requirements
- CI/CD requirements

**Total Requirements:** 100+ SHALL/MAY requirements

### [TEST_COVERAGE.md](TEST_COVERAGE.md)
A comprehensive mapping between the EARS specification requirements and the BDD (Behavior-Driven Development) test scenarios. This document provides:

- Traceability matrix: requirement → test scenario
- Test statistics (94 scenarios, 100% pass rate)
- Coverage summary for each requirement category
- Running instructions for tests

## Specification Format

The specification uses EARS (Easy Approach to Requirements Syntax), which structures requirements using keywords:

- **SHALL**: Mandatory requirements
- **SHOULD**: Recommended but not mandatory
- **MAY**: Optional features
- **WHEN...THEN**: Conditional requirements
- **WHERE**: Parameter definitions
- **IF...THEN**: Conditional logic

### Example Requirements

```
REQ-DATA-001: The system SHALL provide a MarketDataPoint{T,P,V} structure.
- WHERE T is the timestamp type
- WHERE P is the price type
- WHERE V is the volume type

REQ-VOLWIN-005: WHEN should_finalize(data, window) is called,
                THEN it SHALL return true
                IF current_volume + data.volume >= target_volume.
```

## Test Methodology

The package uses BDD-style tests that mirror the specification structure:

```julia
@scenario "Creating a VolumeWindow" begin
    @given "a target volume of 1000" begin
        target = 1000.0
    end

    @when "I create a VolumeWindow" begin
        window = VolumeWindow(1000.0)
    end

    @then "it should have the correct target_volume" begin
        @test window.target_volume == 1000.0
    end
end
```

This approach provides:
- ✅ Executable specifications
- ✅ Clear requirement traceability
- ✅ Self-documenting tests
- ✅ Verification of specification compliance

## Running Tests

```bash
# All tests including BDD specifications
julia --project=. -e 'using Pkg; Pkg.test()'

# BDD specifications only
julia --project=. test/test_bdd_specifications.jl
```

## Compliance Status

✅ **100% Specification Compliance**

All mandatory (SHALL) requirements from the EARS specification are:
1. Implemented in the source code
2. Verified by BDD test scenarios
3. Passing in continuous integration

See [TEST_COVERAGE.md](TEST_COVERAGE.md) for the complete traceability matrix.

## Version

**Current Version:** 0.1.0
**Specification Date:** 2025-10-03
**Author:** scelles

## References

- [EARS Syntax Guide](https://www.iaria.org/conferences2012/filesICCGI12/Tutorial%20EARS.pdf)
- [Behavior-Driven Development](https://en.wikipedia.org/wiki/Behavior-driven_development)
- [OnlineStatsBase.jl Interface](https://github.com/joshday/OnlineStatsBase.jl)
