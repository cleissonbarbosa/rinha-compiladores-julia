using JSON
using .Terms

function parse_json_ast_to_term(json_ast::Dict)::Term
    if json_ast["kind"] == "Int"
        return _Int(json_ast["value"], Location(json_ast["location"]["start"], json_ast["location"]["end"], json_ast["location"]["filename"]))
    elseif json_ast["kind"] == "Str"
        return _Str(json_ast["value"], Location(json_ast["location"]["start"], json_ast["location"]["end"], json_ast["location"]["filename"]))
    elseif json_ast["kind"] == "Bool"
        return _Bool(json_ast["value"], Location(json_ast["location"]["start"], json_ast["location"]["end"], json_ast["location"]["filename"]))
    elseif json_ast["kind"] == "Print"
        return _Print(
            parse_json_ast_to_term(json_ast["value"]), 
            Location(json_ast["location"]["start"], json_ast["location"]["end"], json_ast["location"]["filename"])
        )
    elseif json_ast["kind"] == "Binary"
        return _Binary(
            parse_json_ast_to_term(json_ast["lhs"]),
            from_str_binaryOp(json_ast["op"]),
            parse_json_ast_to_term(json_ast["rhs"]),
            Location(json_ast["location"]["start"], json_ast["location"]["end"], json_ast["location"]["filename"])
        )
    elseif json_ast["kind"] == "If"
        return _If(
            parse_json_ast_to_term(json_ast["condition"]),
            parse_json_ast_to_term(json_ast["then"]),
            parse_json_ast_to_term(json_ast["otherwise"]),
            Location(json_ast["location"]["start"], json_ast["location"]["end"], json_ast["location"]["filename"]),
        )
    elseif json_ast["kind"] == "Let"
        return _Let(
            _Var(json_ast["name"]["text"], Location(json_ast["name"]["location"]["start"], json_ast["name"]["location"]["end"], json_ast["name"]["location"]["filename"])),
            parse_json_ast_to_term(json_ast["value"]),
            parse_json_ast_to_term(json_ast["next"]),
            Location(json_ast["location"]["start"], json_ast["location"]["end"], json_ast["location"]["filename"]),
        )
    elseif json_ast["kind"] == "Var"
        return _Var(json_ast["text"], Location(json_ast["location"]["start"], json_ast["location"]["end"], json_ast["location"]["filename"]))
    elseif json_ast["kind"] == "Function"
        return _Function(
            [_Var(param["text"], Location(param["location"]["start"], param["location"]["end"], param["location"]["filename"])) for param ∈ json_ast["parameters"]],
            parse_json_ast_to_term(json_ast["value"]),
            Location(json_ast["location"]["start"], json_ast["location"]["end"], json_ast["location"]["filename"])
        )
    elseif json_ast["kind"] == "Call"
        return _Call(
            parse_json_ast_to_term(json_ast["callee"]),
            [parse_json_ast_to_term(param) for param ∈ json_ast["arguments"]],
            Location(json_ast["location"]["start"], json_ast["location"]["end"], json_ast["location"]["filename"])
        )
    elseif json_ast["kind"] == "Error"
        return _Error(json_ast["message"],json_ast["location"], Location(json_ast["location"]["start"], json_ast["location"]["end"], json_ast["location"]["filename"]))
    elseif json_ast["kind"] == "First"
        return _First(parse_json_ast_to_term(json_ast["value"]), Location(json_ast["location"]["start"], json_ast["location"]["end"], json_ast["location"]["filename"]))
    elseif json_ast["kind"] == "Second"
        return _Second(parse_json_ast_to_term(json_ast["value"]), Location(json_ast["location"]["start"], json_ast["location"]["end"], json_ast["location"]["filename"]))
    elseif json_ast["kind"] == "Tuple"
        return _Tuple(
            parse_json_ast_to_term(json_ast["first"]),
            parse_json_ast_to_term(json_ast["second"]),
            Location(json_ast["location"]["start"], json_ast["location"]["end"], json_ast["location"]["filename"])
        )
    else
        throw(ErrorException("unknown kind"))
    end
end

function parse_json_to_file(json_ast::Dict)::File
    # Extract relevant fields from the parsed data
    name = json_ast["name"]
    expression_json = json_ast["expression"]
    location_json = json_ast["location"]

    # Create the Location struct
    location = Location(location_json["start"], location_json["end"], location_json["filename"])

    # Recursively parse the expression JSON into a Term
    expression = parse_json_ast_to_term(expression_json)

    # Create and return the File struct
    file = File(name, expression, location)

    return file
end


function parse_or_report(filename::String, text::String)::Result{File, String}
    errors = []

    ast, parse_error = try
        ast = parse_json_to_file(JSON.parse(text))
        ast, nothing
    catch error
        (nothing, error)
    end

    if parse_error !== nothing
        push!(errors, parse_error)
    end

    if isempty(errors)
        return Ok(ast)
    end

    return Err("parse error")
end
