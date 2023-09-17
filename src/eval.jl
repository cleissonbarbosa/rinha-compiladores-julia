using ErrorTypes
using .Terms
struct Closure
    body::Term
    params::AbstractVector{_Var}
    env::Dict{String, Any}
end

@noinline function eval_core(term::Term, scope::Dict{String, Any})
    if term isa _Int
        return term.value
    elseif term isa _Str
        return term.value
    elseif term isa _Bool
        return Bool(term.value)
    elseif term isa _Print
        __value = eval_core(term.value, scope)
        if __value isa Int || __value isa Bool || __value isa String
            print(__value)
        else
            throw(ErrorException("tipo inválido"))
        end
        return nothing
    elseif term isa _Binary
        return eval_bin(term, scope)
    elseif term isa _If
        condition_value = eval_core(term.condition, scope)
        if condition_value isa Bool
            return condition_value ? eval_core(term.then, scope) : eval_core(term.otherwise, scope)
        else
            throw(ErrorException("tipo inválido"))
        end
    elseif term isa _Let
        name = term.name.text
        value = eval_core(term.value, scope)
        new_scope = copy(scope)
        new_scope[name] = value
        return eval_core(term.next, new_scope)
    elseif term isa _Var
        if haskey(scope, term.text)
            return scope[term.text]
        else
            throw(ErrorException("variável não definida"))
        end
    elseif term isa _Function
        return Closure(term.value, term.parameters, scope)
    elseif term isa _Call
        callee_value = eval_core(term.callee, scope)
    
        if callee_value isa Closure
            body = callee_value.body
            params = callee_value.params
            env = callee_value.env
            
            new_scope = copy(scope)
            
            for (param, arg) ∈ zip(params, term.arguments)
                new_scope[param.text] = eval_core(arg, scope)
            end
            
            result = eval_core(body, new_scope)
            return result
        else
            throw(ErrorException("tipo inválido"))
        end
    elseif term isa _Error
        throw(ErrorException(term.message))
    else
        throw(ErrorException("tipo inválido"))
    end
end

function eval_bin(bin::_Binary, scope::Dict{String, Any})
    if bin.op == Terms.Add
        lhs = eval_core(bin.lhs, scope)
        rhs = eval_core(bin.rhs, scope)
        if lhs isa Int && rhs isa Int
            return lhs + rhs
        elseif lhs isa String && rhs isa String
            return string(lhs, rhs)
        elseif lhs isa String && rhs isa Int
            return string(lhs, rhs)
        elseif lhs isa Int && rhs isa String
            return string(lhs, rhs)
        else
            throw(ErrorException("tipo inválido"))
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
        