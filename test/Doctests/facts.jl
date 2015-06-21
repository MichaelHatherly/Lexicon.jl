require(joinpath(dirname(@__FILE__), "DoctestsTestModule.jl"))

import DoctestsTestModule

import Docile.Collector: QualifiedSymbol

facts("Doctests.") do
    results = Lexicon.Doctests.doctest(DoctestsTestModule)

    context("Printing results.") do
        buf = IOBuffer()
        writemime(buf, "text/plain", results)

        expected = """

        # 'DoctestsTestModule' Doctest Results

        ## General

        - 1 empty docstrings.

        ## Codeblocks

        - 5 passed.
        - 1 skipped.
        - 1 failed.
        """

        @fact expected => takebuf_string(buf)
    end

    context("Passed.") do
        passed = results.passed

        @fact length(passed) => 4

        @fact length(passed[DoctestsTestModule.A]) => 2
        @fact length(passed[QualifiedSymbol(DoctestsTestModule, :K)]) => 2
        @fact haskey(passed, DoctestsTestModule.BT) => false
        for method in methods(DoctestsTestModule.f)
            @fact length(passed[method]) => 1
        end

        @fact passed[DoctestsTestModule.A][1][1] => sin(2)
        @fact passed[DoctestsTestModule.A][2][1] => sin(1)
        @fact passed[QualifiedSymbol(DoctestsTestModule, :K)][1][1] => 1
        @fact passed[QualifiedSymbol(DoctestsTestModule, :K)][2][1] => 4
        for method in methods(DoctestsTestModule.f)
            @fact typeof(passed[method][1][1]) => Matrix{Float64}
        end
    end

    context("Skipped.") do
        skipped = results.skipped

        @fact length(skipped) => 1
        @fact length(skipped[DoctestsTestModule.A]) => 1
    end

    context("Failed.") do
        failed = results.failed

        @fact length(failed) => 1
        @fact length(failed[DoctestsTestModule.A]) => 1
        @fact typeof(failed[DoctestsTestModule.A][1][1]) => UndefVarError
        @fact failed[DoctestsTestModule.A][1][1].var => :t
    end

    context("Empty Docstrings.") do
        empties = results.emptydocs

        @fact length(empties) => 1
    end
end
