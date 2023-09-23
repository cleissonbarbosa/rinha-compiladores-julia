include("terms.jl")
include("utils.jl")
include("eval.jl")

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

args = ARGS
parsed_args = parse_command_line(args)  # Store the result in a separate variable

function main()
    program = File("", _Error("", "", Location(0, 0, "")), Location(0, 0, ""))
    for (arg, val) ∈ parsed_args
        file = try
            endswith(".rinha")(val) ? read(`./lib/bin/rinha $(val)`, String) : read(val, String)
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
        end
    catch e
        error("thread error: $e")
    end
    wait(handle)
end

@time main()
