include("FakeTerminals.jl")

# Setup. #

stdin_write, stdout_read, stderr_read, repl = FakeTerminals.fake_repl()

repl.specialdisplay = Base.REPL.REPLDisplay(repl)

repltask = @async Base.REPL.run_repl(repl)

# Facts. #

facts("REPL Query Mode.") do
    context("Integration.") do
        Lexicon.REPLMode.setup_help_mode(repl)

        write(stdin_write, "?")
        readuntil(stdout_read, "help?> ")
        write(stdin_write, "\"\" 1\n")

        # Close REPL ^D. #
        write(stdin_write, '\x04')
        wait(repltask)
    end
    context("Line Parsing.") do
        Lexicon.REPLMode.help("\"\"")
        Lexicon.REPLMode.help("\"\" 1")
        Lexicon.REPLMode.help("Base & ::(Int, Int)")
        Lexicon.REPLMode.help("(Float64, Int, Int)")
        Lexicon.REPLMode.help("r\"\"")
        Lexicon.REPLMode.help("r\"...\"")
    end
end
