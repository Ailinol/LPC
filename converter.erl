-module(tres_enderecos).
-export([converter/1]).

% Prioridade dos Converter
precedencia("+") -> 1;
precedencia("-") -> 1;
precedencia("*") -> 2;
precedencia("/") -> 2;
precedencia(_) -> 0.

% Verifica se é operando
is_operando(T) ->
    re:run(T, "^[A-Za-z0-9]+$") =/= nomatch.

% Tokenizar expressão (simples)
tokenizar(Str) ->
    string:tokens(Str, " ").

% Infix -> Postfix
infix_para_postfix(Tokens) ->
    infix_para_postfix(Tokens, [], []).

infix_para_postfix([], [], Output) ->
    lists:reverse(Output);
infix_para_postfix([], [H|T], Output) ->
    infix_para_postfix([], T, [H|Output]);

infix_para_postfix([Token|Rest], Stack, Output) ->
    case is_operando(Token) of
        true ->
            infix_para_postfix(Rest, Stack, [Token|Output]);
        false ->
            case Stack of
                [] ->
                    infix_para_postfix(Rest, [Token], Output);
                [Top|_] ->
                    if precedencia(Top) >= precedencia(Token) ->
                        infix_para_postfix([Token|Rest], tl(Stack), [Top|Output]);
                       true ->
                        infix_para_postfix(Rest, [Token|Stack], Output)
                    end
            end
    end.

% Gerar código de 3 endereços
gerar(Postfix) ->
    gerar(Postfix, [], 1, []).

gerar([], [Final], _, Instrucoes) ->
    {lists:reverse(Instrucoes), Final};

gerar([Token|Rest], Stack, Cont, Instrucoes) ->
    case is_operando(Token) of
        true ->
            gerar(Rest, [Token|Stack], Cont, Instrucoes);
        false ->
            [Op2, Op1 | Resto] = Stack,
            Temp = "t" ++ integer_to_list(Cont),
            Instr = Temp ++ " = " ++ Op1 ++ " " ++ Token ++ " " ++ Op2,
            gerar(Rest, [Temp|Resto], Cont+1, [Instr|Instrucoes])
    end.

% Função principal
converter(Expr) ->
    Tokens = tokenizar(Expr),
    Postfix = infix_para_postfix(Tokens),
    {Instrucoes, Resultado} = gerar(Postfix),
    lists:foreach(fun(X) -> io:format("~s~n", [X]) end, Instrucoes),
    io:format("Resultado final: ~s~n", [Resultado]).
