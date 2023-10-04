using ErrorTypes
using .Terms
using Match
using Memoization

struct Closure
    body::Term
    params::AbstractVector{_Var}
    env::Dict{String, Any}
end

function Base.show(io::IO, closure::Closure)
    print(io, "<#closure>")
end

@memoize function eval_core(term::Term, scope::Dict{String, Any})
    @match term begin
        t::_Int => t.value
        t::_Str => t.value
        t::_Bool => Bool(t.value)
        t::_Print => eval_print(t, scope)
        t::_Binary => eval_bin(t, scope)
        t::_If => eval_if(t, scope)
        t::_Let => eval_let(t, scope)
        t::_Var => haskey(scope, t.text) ? scope[t.text] : throw(ErrorException("variável não definida"))
        t::_Function => Closure(t.value, t.parameters, scope)
        t::_Call => eval_call(t, scope)
        t::_Tuple => (eval_core(t.first, scope), eval_core(t.second, scope))
        t::_First => eval_position(t, scope, 1)
        t::_Second => eval_position(t, scope, 2)
        t::_Error => throw(ErrorException(t.message))
        _ => throw(ErrorException("tipo inválido"))
    end
end

function eval_bin(bin::_Binary, scope::Dict{String, Any})
    if bin.op == Terms.Add
        lhs = eval_core(bin.lhs, scope)
        rhs = eval_core(bin.rhs, scope)
        if lhs isa Int && rhs isa Int
            return lhs + rhs
        else
            return string(lhs, rhs)
        end
    elseif bin.op == Terms.Sub
        return eval_core(bin.lhs, scope) - eval_core(bin.rhs, scope)
    elseif bin.op == Terms.Mul
        return eval_core(bin.lhs, scope) * eval_core(bin.rhs, scope)
    elseif bin.op == Terms.Div
        return eval_core(bin.lhs, scope) / eval_core(bin.rhs, scope)
    elseif bin.op == Terms.Rem
        return eval_core(bin.lhs, scope) % eval_core(bin.rhs, scope)
    elseif  bin.op == Terms.Lt
        return eval_core(bin.lhs, scope) < eval_core(bin.rhs, scope)
    elseif bin.op == Terms.Eq
        return eval_core(bin.lhs, scope) == eval_core(bin.rhs, scope)
    elseif bin.op == Terms.Gt
        return eval_core(bin.lhs, scope) > eval_core(bin.rhs, scope)
    elseif bin.op == Terms.Lte
        return eval_core(bin.lhs, scope) <= eval_core(bin.rhs, scope)
    elseif bin.op == Terms.Gte
        return eval_core(bin.lhs, scope) >= eval_core(bin.rhs, scope)
    elseif bin.op == Terms.Neq
        return eval_core(bin.lhs, scope) != eval_core(bin.rhs, scope)
    elseif bin.op == Terms.And
        return eval_core(bin.lhs, scope) && eval_core(bin.rhs, scope)
    elseif bin.op == Terms.Or
        return eval_core(bin.lhs, scope) || eval_core(bin.rhs, scope)
    else
        throw(ErrorException("unknown binary operator"))
    end
end

function eval_print(term::Term, scope::Dict{String, Any})
    __value = eval_core(term.value, scope)
    if __value isa Int || __value isa Bool || __value isa String || __value isa Tuple || __value isa NamedTuple || __value isa Array
        println(__value)
        return __value
    end
    throw(ErrorException("tipo inválido"))
end

function eval_if(term::Term, scope::Dict{String, Any})
    condition_value = eval_core(term.condition, scope)
    if condition_value isa Bool
        return condition_value ? eval_core(term.then, scope) : eval_core(term.otherwise, scope)
    end
    throw(ErrorException("tipo inválido"))
end

function eval_let(term::Term, scope::Dict{String, Any})
    name = term.name.text
    value = eval_core(term.value, scope)

    if value isa Closure 
        closure = Closure(value.body, value.params, scope)
        value.env[name] = closure
        scope[name] = closure
    elseif value isa _Var
        scope[name] = eval_core(value, scope)
    end
    new_scope = scope
    new_scope[term.name.text] = value
    return eval_core(term.next, new_scope)
end

function eval_call(term::Term, scope::Dict{String, Any}) 
    callee_value = eval_core(term.callee, scope)
    if callee_value isa Closure
        if length(term.arguments) != length(callee_value.params)
            throw(ErrorException("número de argumentos inválido"))
        end

        body = callee_value.body
        params = callee_value.params
        env = callee_value.env
        
        new_scope = copy(env)
        
        for (param, arg) ∈ zip(params, term.arguments)
            new_scope[param.text] = eval_core(arg, scope)
        end
        
        return eval_core(body, new_scope)
    end
    throw(ErrorException("tipo inválido"))
end

function eval_position(term::Term,  scope::Dict{String, Any}, position::Int) 
    if position != 1 && position != 2
        throw(ErrorException("posição inválida"))
    end
    value = eval_core(term.value, scope)
    if value isa Tuple || value isa NamedTuple || value isa Array || value isa String
        return value[position]
    end
    throw(ErrorException("tipo inválido"))
end
