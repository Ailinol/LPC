-module(lexer).
-export([tokenize/1, test/0]).

-record(token, {type, value, line, column}).

tokenize(String) ->
    tokenize(String, 1, 1, []).


tokenize([], Line, Col, Acc) ->
    lists:reverse([#token{type = eof, value = eof, line = Line, column = Col} | Acc]);

tokenize([Char | Rest], Line, Col, Acc)
    when Char =:= $\s; Char =:= $\t; Char =:= $\r ->
      tokenize(Rest, Line, Col +1, Acc);

tokenize([$\n | Rest], Line, _Col, Acc) ->
    tokenize(Rest, Line + 1, 1, Acc);

tokenize([$% | Rest], Line, _Col, Acc) ->
    NewRest = lists:dropwhile(fun(X) -> X =/= $\n end, Rest),
    tokenize(NewRest, Line, 1, Acc);

tokenize([Char | Rest], Line, Col, Acc) when Char >= $0, Char =< $9 ->
    {NumStr, NewRest, NewCol, NumType} = read_number(Rest, [Char], Col+1),
    {Type, Value} = case NumType of
        integer -> {integer, list_to_integer(NumStr)};
        float   -> {float,   list_to_float(NumStr)}
    end,
    Token = #token{type=Type, value=Value, line=Line, column=Col},
    tokenize(NewRest, Line, NewCol, [Token | Acc]);

tokenize([Char | Rest], Line, Col, Acc) when Char >= $a, Char =< $z ->
    {AtomStr, NewRest, NewCol} = read_atom(Rest, [Char], Col + 1),
    Type = case is_keyword(AtomStr) of
        true -> keyword;
        false -> atom
    end,
    Token = #token{type=Type, value=list_to_atom(AtomStr), line=Line, column=Col},
    tokenize(NewRest, Line, NewCol, [Token | Acc]);

tokenize([Char | Rest], Line, Col, Acc) when Char >= $A, Char =< $Z; Char =:= $_ ->
    {VarStr, NewRest, NewCol} = read_variable(Rest, [Char], Col + 1),
    Token = #token{type=variable, value=list_to_atom(VarStr), line=Line, column=Col},
    tokenize(NewRest, Line, NewCol, [Token | Acc]);

tokenize([$" | Rest], Line, Col, Acc) ->
    case read_string(Rest, Line, Col + 1, []) of
        {ok, Str, NewRest, NewLine, NewCol} ->
            Token = #token{type=string, value=Str, line=Line, column=Col},
            tokenize(NewRest, NewLine, NewCol, [Token | Acc]);
        {error, Reason} ->
            [{error, Reason, Line, Col}]
    end;

tokenize([Char | Rest], Line, Col, Acc) ->
    case read_operator([Char | Rest], Col) of
        {Op, NewRest, NewCol} ->
            Token = #token{type=operator, value=list_to_atom(Op), line=Line, column=Col},
            tokenize(NewRest, Line, NewCol, [Token | Acc]);
        undefined ->
            Error = {error, io_lib:format("Caractere invalido: ~c", [Char]), Line, Col},
            tokenize(Rest, Line, Col + 1, [Error | Acc])
    end.

read_number([Char | Rest], Acc, Col) when Char >= $0, Char =< $9 ->
    read_number(Rest, [Char | Acc], Col + 1);

read_number([$., Digit | Rest], Acc, Col) when Digit >= $0, Digit =< $9 ->
    read_number_float(Rest, [Digit, $. | Acc], Col + 2);

read_number(Rest, Acc, Col) ->
    {lists:reverse(Acc), Rest, Col, integer}.


read_number_float([Char | Rest], Acc, Col) when Char >= $0, Char =< $9 ->
    read_number_float(Rest, [Char | Acc], Col + 1);

read_number_float(Rest, Acc, Col) ->
    {lists:reverse(Acc), Rest, Col, float}.


read_atom([Char | Rest], Acc, Col) when (Char >= $a andalso Char =< $z) orelse
    (Char >= $0 andalso Char =< $9) orelse Char =:= $_ ->
    read_atom(Rest, [Char | Acc], Col + 1);

read_atom(Rest, Acc, Col) ->
    {lists:reverse(Acc), Rest, Col}.


read_variable([Char | Rest], Acc, Col) when (Char >= $a andalso Char =< $z) orelse
                                            (Char >= $A andalso Char =< $Z) orelse
                                            (Char >= $0 andalso Char =< $9) orelse
                                            Char =:= $_ ->
    read_variable(Rest, [Char | Acc], Col + 1);

read_variable(Rest, Acc, Col) ->
    {lists:reverse(Acc), Rest, Col}.


read_string([], _Line, _Col, _Acc) ->
    {error, "String nao terminada"};


read_string([$" | Rest], Line, Col, Acc) ->
    {ok, lists:reverse(Acc), Rest, Line, Col + 1};

read_string([$\\, Char | Rest], Line, Col, Acc) ->
    Escaped = case Char of
        $n -> $\n;
        $t -> $\t;
        $r -> $\r;
        $" -> $";
        $\\ -> $\\;
        _ -> Char
    end,
    read_string(Rest, Line, Col + 2, [Escaped | Acc]);

read_string([$\n | Rest], Line, _Col, Acc) ->
    read_string(Rest, Line + 1, 1, [$\n | Acc]);

read_string([Char | Rest], Line, Col, Acc) ->
    read_string(Rest, Line, Col + 1, [Char | Acc]).


read_operator([Char | Rest], Col) ->
    case Char of
        $, -> {",", Rest, Col + 1};
        $; -> {";", Rest, Col + 1};
        $. -> {".", Rest, Col + 1};
        $( -> {"(", Rest, Col + 1};
        $) -> {")", Rest, Col + 1};
        $[ -> {"[", Rest, Col + 1};
        $] -> {"]", Rest, Col + 1};
        ${ -> {"{", Rest, Col + 1};
        $} -> {"}", Rest, Col + 1};
        $+ -> {"+", Rest, Col + 1};
        $* -> {"*", Rest, Col + 1};
        $/ -> case Rest of
            [$= | R] -> {"/=", R, Col + 2};
            _ -> {"/", Rest, Col + 1}
        end;
        $= -> case Rest of
            [$= | R] -> {"==", R, Col + 2};
            [$: | R] ->
                case R of
                    [$= | R2] -> {"=:=", R2, Col + 3};
                    _ -> {"=", Rest, Col + 1}
                end;
            [$/ | R] ->
                case R of
                    [$= | R2] -> {"=/=", R2, Col + 3};
                    _ -> {"=", Rest, Col + 1}
                end;
            _ -> {"=", Rest, Col + 1}
            end;
        $- -> case Rest of
                  [$> | R] -> {"->", R, Col + 2};
                  _ -> {"-", Rest, Col + 1}
              end;
        $| -> case Rest of
                  [$| | R] -> {"||", R, Col + 2};
                  _ -> {"|", Rest, Col + 1}
              end;
        $< -> case Rest of
                  [$= | R] -> {"=<", R, Col + 2};
                  _ -> {"<", Rest, Col + 1}
              end;
        $> -> case Rest of
                  [$= | R] -> {">=", R, Col + 2};
                  _ -> {">", Rest, Col + 1}
              end;
        _ -> undefined
    end.

is_keyword(Str) ->
    Keywords = [
        "if", "case", "when", "end", "begin",
        "fun", "receive", "after", "of", "catch",
        "try", "and", "or", "not", "xor",
        "band", "bor", "bnot", "bxor", "bsl", "bsr",
        "div", "rem",
        "let", "query",
        "cond", "maybe", "else"
    ],
    lists:member(Str, Keywords).


test() ->
    io:format("=== Analisador Lexico ===~n"),
    io:format("Escreve o codigo a analisar (termina com '###'):~n"),
    Code = read_input([]),
    Tokens = tokenize(Code),

   {ValidTokens, Errors} = lists:partition(fun
        (T) when is_record(T, token) -> true;
        (_)                          -> false
    end, Tokens),

    %% Mostra tokens
    io:format("~n=== Tokens ===~n"),
    io:format("+-----------+----------------+--------+--------+~n"),
    io:format("| ~-8s | ~-14s | ~-6s | ~-6s |~n",
            ["Tipo", "Valor", "Linha", "Coluna"]),
    io:format("+-----------+----------------+--------+--------+~n"),
    lists:foreach(fun(T) ->
        io:format("|  ~-8s | ~-14s | ~-6B | ~-6B |~n",
            [
                atom_to_list(T#token.type),
                io_lib:format("~p", [T#token.value]),
                T#token.line,
                T#token.column
            ])
    end, ValidTokens),

    %% Mostra erros separadamente
    case Errors of
        [] -> ok;
        _  ->
            io:format("~n=== Erros ===~n"),
            lists:foreach(fun({error, Reason, Line, Col}) ->
                io:format("  [Linha ~B, Coluna ~B] ~s~n", [Line, Col, Reason])
            end, Errors)
    end.

read_input(Acc) ->
    Line = io:get_line(""),
    case string:trim(Line) of
        "###" -> lists:flatten(lists:reverse(Acc));
        _     -> read_input([Line | Acc])
    end.