struct Location
    start::Int
    endd::Int
    filename::String
end

@enum BinaryOp Add Sub Mul Div Rem Eq Neq Lt Gt Lte Gte And Or

function from_str_binaryOp(op::String)::BinaryOp
    op_dict = Dict(
        "Add" => Add,
        "Sub" => Sub,
        "Mul" => Mul,
        "Div" => Div,
        "Rem" => Rem,
        "Eq" => Eq,
        "Neq" => Neq,
        "Lt" => Lt,
        "Gt" => Gt,
        "Lte" => Lte,
        "Gte" => Gte,
        "And" => And,
        "Or" => Or
    )
    if haskey(op_dict, op)
        return op_dict[op]
    else
        throw(ErrorException("unknown binary operator"))
    end
end

abstract type Term end

struct _Int <: Term
    value::Int64
    location::Location
end
struct _Str <: Term
    value::String
    location::Location
end
struct _Bool <: Term
    value::Bool
    location::Location
end
struct _Binary <: Term
    lhs::Term
    op::BinaryOp
    rhs::Term
    location::Location
end
mutable struct _Var <: Term
    text::String
    location::Location
end    
struct _Call <: Term
    callee::Term
    arguments::Vector{Term}
    location::Location
end
struct _Function <: Term
    parameters::Vector{_Var}
    value::Term
    location::Location
end
struct _Print <: Term
    value::Term
    location::Location
end
struct _First <: Term
    value::Term
    location::Location
end
struct _Second
    value::Term
    location::Location
end
struct _Tuple <: Term
    first::Term
    second::Term
    location::Location
end
struct _Error <: Term
    message::String
    full_text::String
    location::Location
end
struct _If <: Term
    condition::Term
    then::Term
    otherwise::Term
    location::Location
end
struct _Let <: Term
    name::_Var
    value::Term
    next::Term
    location::Location
end

struct File
    name::String
    expression::Term
    location::Location
end

function fmt_expected(expected::Vector{String})::String
    f = ""
    if !isempty(expected)
        for (i, e) in enumerate(expected)
            sep = i == 1 ? "expected one of" : (i < length(expected) ? "," : " or")
            f *= " $sep $e"
        end
    end
    return f
end
