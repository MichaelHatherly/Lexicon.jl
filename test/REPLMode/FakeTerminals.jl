# From julia/test/TestHelpers.jl
module FakeTerminals

type FakeTerminal <: Base.Terminals.UnixTerminal
    in_stream  :: IO
    out_stream :: IO
    err_stream :: IO
    hascolor   :: Bool
    raw        :: Bool

    function FakeTerminal(stdin, stdout, stderr, hascolor = true)
        new(stdin, stdout, stderr, hascolor, false)
    end
end

Base.Terminals.hascolor(t::FakeTerminal) = t.hascolor
Base.Terminals.raw!(t::FakeTerminal, raw::Bool) = t.raw = raw
Base.Terminals.size(t::FakeTerminal) = (24, 80)

function fake_repl()
    # Use pipes so we can easily do blocking reads
    # In the future if we want we can add a test that the right object
    # gets displayed by intercepting the display
    stdin_read,stdin_write = (Base.Pipe(C_NULL), Base.Pipe(C_NULL))
    stdout_read,stdout_write = (Base.Pipe(C_NULL), Base.Pipe(C_NULL))
    stderr_read,stderr_write = (Base.Pipe(C_NULL), Base.Pipe(C_NULL))
    Base.link_pipe(stdin_read, true, stdin_write,true)
    Base.link_pipe(stdout_read, true, stdout_write,true)
    Base.link_pipe(stderr_read, true, stderr_write,true)

    repl = Base.REPL.LineEditREPL(FakeTerminal(stdin_read, stdout_write, stderr_write))
    stdin_write, stdout_read, stderr_read, repl
end

end
