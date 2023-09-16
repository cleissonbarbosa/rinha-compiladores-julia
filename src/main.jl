include("eval.jl")
import Base.Threads: @async, @spawn
import Dates: now

using Dates
using ArgParse
using ErrorTypes

function parse_command_line(args)::Dict{String, Any}
    s = ArgParseSettings()

    @add_arg_table s begin
        "--file"
            help="The file to be executed"
            arg_type=String
            required=true
    end

    return parse_args(args, s)
end

function main()
    time_init = time()
    args = ARGS
    parsed_args = parse_command_line(args)  # Store the result in a separate variable
    program = nothing
    for (arg, val) in parsed_args
        file = try
            read(`./lib/bin/rinha $(val)`, String)
        catch e
            error("read error: $e")
        end
        program = try
            ErrorTypes.unwrap(parse_or_report(val, file))
        catch e
            error("parse error: $e")
        end
    end

    handle = try
        @async begin
            term = program.expression
            scope = Dict{String, Any}()
            val = try
                eval_core(term, scope)
            catch e
                error("evaluation error: $e")
            end

            time_end = time() - time_init
            println("\n\n\nExecution Time: $time_end seconds\n")

            if string(val) == "nothing"
                print("")
                return
            end

            println("\n$val")
        end
    catch e
        error("thread error: $e")
    end
    wait(handle)
end

main()
