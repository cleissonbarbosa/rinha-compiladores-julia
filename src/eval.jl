using ErrorTypes
using .Terms
struct Closure
    body::Term
    params::AbstractVector{_Var}
    env::Dict{String, Any}
end

@noinline function eval_core(term::Term, scope::Dict{String, Any})
    if isa(term, _Int)
        return term.value
    elseif isa(term, _Str)
        return term.value
    elseif isa(term, _Bool)
        return Bool(term.value)
    elseif isa(term, _Print)
        __value = eval_core(term.value, scope)
        if isa(__value, Int)
            print(__value)
        elseif isa(__value, Bool)
            print(__value)
        elseif isa(__value, String)
            print(__value)
        else
            throw(ErrorException("tipo inválido"))
        end
        return nothing
    elseif isa(term, _Binary)
        return eval_bin(term, scope)
    elseif isa(term, _If)
        condition_value = eval_core(term.condition, scope)
        if isa(condition_value, Bool) && condition_value
            return eval_core(term.then, scope)
        elseif isa(condition_value, Bool) && !condition_value
            return eval_core(term.otherwise, scope)
        else
            throw(ErrorException("tipo inválido"))
        end
    elseif isa(term, _Let)
        name = term.name.text
        value = eval_core(term.value, scope)
        new_scope = copy(scope)
        new_scope[name] = value
        return eval_core(term.next, new_scope)
    elseif isa(term, _Var)
        if haskey(scope, term.text)
            return scope[term.text]
        else
            throw(ErrorException("variável não definida"))
        end
    elseif isa(term, _Function)
        return Closure(term.value, term.parameters, scope)
    elseif isa(term, _Call)
        callee_value = eval_core(term.callee, scope)
    
        if isa(callee_value, Any) && callee_value isa Closure
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
    elseif isa(term, _Error)
        throw(ErrorException(term.message))
    else
        throw(ErrorException("tipo inválido"))
    end
end

function eval_bin(bin::_Binary, scope::Dict{String, Any})
    if bin.op == Terms.Add
        lhs = eval_core(bin.lhs, scope)
        rhs = eval_core(bin.rhs, scope)
        if isa(lhs, Int) && isa(rhs, Int)
            return lhs + rhs
        elseif isa(lhs, String) && isa(rhs, String)
            return string(lhs, rhs)
        elseif isa(lhs, String) && isa(rhs, Int)
            return string(lhs, rhs)
        elseif isa(lhs, Int) && isa(rhs, String)
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
        