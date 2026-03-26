-module(fibonacci).
-export([fib/1, fib_sequence/1]).

% Caso base
fib(0) -> 0;
fib(1) -> 1;

% Caso recursivo
fib(N) when N > 1 ->
    fib(N - 1) + fib(N - 2).

% Gerar sequência
fib_sequence(N) ->
    fib_sequence(0, N).

fib_sequence(Current, N) when Current < N ->
    [fib(Current) | fib_sequence(Current + 1, N)];
fib_sequence(N, N) ->
    [].