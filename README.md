# erlang-lexer

Analisador léxico (lexer) implementado em Erlang como projeto académico. O programa recebe código-fonte como entrada, identifica e classifica cada token, e apresenta os resultados numa tabela formatada.

## Funcionalidades

- Reconhecimento de **inteiros** e **floats** (ex: `42`, `3.14`)
- Reconhecimento de **átomos** e **palavras-chave** (ex: `foo`, `if`, `case`)
- Reconhecimento de **variáveis** (ex: `X`, `MyVar`)
- Reconhecimento de **strings** com suporte a sequências de escape (ex: `"hello\n"`)
- Reconhecimento de **operadores** simples e compostos (ex: `+`, `->`, `=:=`)
- Ignorar **comentários** (linhas iniciadas com `%`)
- Reporte de **erros** para caracteres inválidos e strings não terminadas
- Rastreamento de **linha e coluna** de cada token

## Requisitos

- [Erlang/OTP](https://www.erlang.org/downloads) instalado na máquina

## Como usar

**1. Compilar o módulo:**

```bash
erl
```

```erlang
c(jogo).
```

**2. Executar o analisador:**

```erlang
jogo:test().
```

O programa irá pedir que escrevas o código a analisar. Quando terminares, escreve `###` numa linha sozinha para confirmar.

**Exemplo de entrada:**
```
X = 3.14 + 42.
###
```

**Exemplo de saída:**
```
=== Tokens ===
+-----------+----------------+--------+--------+
| Tipo      | Valor          | Linha  | Coluna |
+-----------+----------------+--------+--------+
|  variable | 'X'            | 1      | 1      |
|  operator | '='            | 1      | 3      |
|  float    | 3.14           | 1      | 5      |
|  operator | '+'            | 1      | 10     |
|  integer  | 42             | 1      | 12     |
|  operator | '.'            | 1      | 14     |
|  eof      | eof            | 1      | 15     |
```

Também é possível chamar `tokenize/1` diretamente:

```erlang
jogo:tokenize("X = 1 + 2.").
```

## Tipos de tokens reconhecidos

| Tipo      | Descrição                              | Exemplo         |
|-----------|----------------------------------------|-----------------|
| `integer` | Número inteiro                         | `42`            |
| `float`   | Número de ponto flutuante              | `3.14`          |
| `atom`    | Átomo (identificador em minúsculas)    | `foo`, `bar`    |
| `keyword` | Palavra reservada da linguagem         | `if`, `case`    |
| `variable`| Variável (inicia em maiúscula ou `_`)  | `X`, `_Var`     |
| `string`  | Cadeia de caracteres entre aspas       | `"hello"`       |
| `operator`| Operador ou símbolo de pontuação       | `+`, `->`, `=:=`|
| `eof`     | Fim do ficheiro                        | —               |
