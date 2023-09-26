using ErrorTypes
using .Terms
struct Closure
    body::Term
    params::AbstractVector{_Var}
    env::Dict{String, Any}
end

function Base.show(io::IO, closure::Closure)
    print(io, "<#closure>")
end

cache = Dict{Tuple, Any}()
@noinline function eval_core(term::Term, scope::Dict{String, Any})

    if haskey(cache, (term, scope))
        return cache[(term, scope)]
    end

    result = if term isa _Int
        term.value
    elseif term isa _Str
        term.value
    elseif term isa _Bool
        Bool(term.value)
    elseif term isa _Print
        __value = eval_core(term.value, scope)
        if __value isa Int || __value isa Bool || __value isa String || __value isa Tuple || __value isa NamedTuple || __value isa Array
            println(__value)
            __value
        else
            throw(ErrorException("tipo inválido"))
        end
    elseif term isa _Binary
        eval_bin(term, scope)
    elseif term isa _If
        condition_value = eval_core(term.condition, scope)
        if condition_value isa Bool
            condition_value ? eval_core(term.then, scope) : eval_core(term.otherwise, scope)
        else
            throw(ErrorException("tipo inválido"))
        end
    elseif term isa _Let
        name = term.name.text
        value = eval_core(term.value, scope)

        if value isa Closure 
            closure = Closure(value.body, value.params, scope)
            value.env[name] = closure
            scope[name] = closure
        elseif value isa _Var
            scope[name] = eval_core(value, scope)
        end
        new_scope = copy(scope)
        new_scope[term.name.text] = value
        eval_core(term.next, new_scope)
    elseif term isa _Var
        if haskey(scope, term.text)
            scope[term.text]
        else
            throw(ErrorException("variável não definida"))
        end
    elseif term isa _Function
        Closure(term.value, term.parameters, scope)
    elseif term isa _Call
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
            
            eval_core(body, new_scope)
        else
            throw(ErrorException("tipo inválido"))
        end
    elseif term isa _Tuple
        (eval_core(term.first, scope), eval_core(term.second, scope))
    elseif term isa _First
        value = eval_core(term.value, scope)
        if value isa Tuple || value isa NamedTuple || value isa Array || value isa String
            value[1]
        else
            throw(ErrorException("tipo inválido"))
        end
    elseif term isa _Second
        value = eval_core(term.value, scope)
        if value isa Tuple || value isa NamedTuple || value isa Array || value isa String
            value[2]
        else
            throw(ErrorException("tipo inválido"))
        end
    elseif term isa _Error
        throw(ErrorException(term.message))
    else
        throw(ErrorException("tipo inválido"))
    end

    cache[(term, scope)] = result
    return result
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
        