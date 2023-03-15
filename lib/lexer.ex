defmodule Lexer do
  def tokenize(string), do:
    to_charlist(string) |> tokenize([]) |> eof
  def tokenize(chars, tokens), do: tokenize chars, tokens, 1
  def tokenize([], tokens, _line), do: tokens |> Enum.reverse
  def tokenize([c | rest], tokens, line) do
    cond do
      c == ?= -> tokenize((tl rest), [Token.new(type: :EQUAL_EQUAL, lexeme: "=", line: line) | tokens], line)
      c == ?< -> case (hd rest) do
        ?= -> tokenize((tl rest), [Token.new(type: :LESS_EQUAL, lexeme: "<=", line: line) | tokens], line)
        ?- -> tokenize((tl rest), [Token.new(type: :EQUAL, lexeme: "<-", line: line) | tokens], line)
        _ -> tokenize(rest, [Token.new(type: :LESS, lexeme: "<", line: line) | tokens], line)
      end
      c == ?> -> if (hd rest) == ?= do
          tokenize((tl rest), [Token.new(type: :GREATER_EQUAL, lexeme: ">=", line: line) | tokens], line)
        else
          tokenize(rest, [Token.new(type: :GREATER, lexeme: ">", line: line) | tokens], line)
        end
      c == ?! -> if (hd rest) == ?= do
          tokenize((tl rest), [Token.new(type: :BANG_EQUAL, lexeme: "!=", line: line) | tokens], line)
        else
          tokenize(rest, [Token.new(type: :BANG, lexeme: "!", line: line) | tokens], line)
        end
      c == ?- -> tokenize(rest, [Token.new(type: :MINUS, lexeme: "-", line: line) | tokens], line)
      c == ?+ -> tokenize(rest, [Token.new(type: :PLUS, lexeme: "+", line: line) | tokens], line)
      c == ?* -> tokenize(rest, [Token.new(type: :STAR, lexeme: "*", line: line) | tokens], line)
      c == ?/ -> tokenize(rest, [Token.new(type: :SLASH, lexeme: "/", line: line) | tokens], line)
      c == ?( -> tokenize(rest, [Token.new(type: :LEFT_PAREN, lexeme: "(", line: line) | tokens], line)
      c == ?) -> tokenize(rest, [Token.new(type: :RIGHT_PAREN, lexeme: ")", line: line) | tokens], line)
      c == ?{ -> tokenize(rest, [Token.new(type: :LEFT_BRACE, lexeme: "{", line: line) | tokens], line)
      c == ?} -> tokenize(rest, [(Token.new type: :RIGHT_BRACE, lexeme: "}", line: line) | tokens], line)
      c == ?[ -> tokenize(rest, [Token.new(type: :LEFT_SQUARE, lexeme: "[", line: line) | tokens], line)
      c == ?] -> tokenize(rest, [(Token.new type: :RIGHT_SQUARE, lexeme: "]", line: line) | tokens], line)
      c == ?, -> tokenize(rest, [Token.new(type: :COMMA, lexeme: ",", line: line) | tokens], line)
      c == ?. -> tokenize(rest, [Token.new(type: :DOT, lexeme: ".", line: line) | tokens], line)
      c == ?; -> (tokenize rest, [Token.new(type: :SEMICOLON, lexeme: ";", line: line) | tokens], line)
      c == ?\s -> (tokenize rest, tokens, line)
      c == ?\t -> (tokenize rest, tokens, line)
      c == ?\n -> (tokenize rest, tokens, line + 1)
      c == ?" -> (string rest, tokens, line)
      true -> cond do
          (is_digit c) -> (number [c | rest], tokens, line)
          (is_alpha c) -> (identifier [c | rest], tokens, line)
          true -> raise "Unidentified token."
        end
    end
  end

  def string([c | rest], tokens, line), do: string([c | rest], tokens, line, [])
  def string([], _tokens, _line, _acc), do: raise "Unterminated string."
  def string([c | rest], tokens, line, acc) do
    cond do
      c == ?\n -> (string rest, tokens, line + 1, [c | acc])
      c == ?" -> (tokenize rest, [(Token.new type: :STRING, lexeme: ((Enum.reverse acc) |> to_string), literal: ((Enum.reverse acc) |> to_string), line: line) | tokens], line)
      true -> (string rest, tokens, line, [c | acc])
    end
  end

  def number([c | rest], tokens, line), do: number([c | rest], tokens, line, [])
  # todo, this is not correct
  def number([], tokens, _line), do: tokens
  def number([c | rest], tokens, line, acc) do
    cond do
      is_digit(c) -> if length(rest) == 0 do
        lexed = ([c | acc] |> Enum.reverse |> to_string)
        tokenize([], [Token.new(type: :NUMBER, lexeme: lexed, literal: Float.parse(lexed)|>(elem 0), line: line) | tokens], line)
      else
        number(rest, tokens, line, [c | acc])
      end
      c == ?. -> number(rest, tokens, line, [c | acc])
      true ->
        tokenize([c | rest], [Token.new(type: :NUMBER, lexeme: (acc |> Enum.reverse |> to_string), literal: Float.parse(acc |> Enum.reverse |> to_string)|>(elem 0), line: line) | tokens], line)
    end
  end

  # todo, this is not correct
  def identifier([], tokens, _line), do: tokens
  def identifier([c | rest], tokens, line), do: identifier([c | rest], tokens, line, [])
  def identifier([c | rest], tokens, line, acc) do
    cond do
      is_alpha_numeric(c) -> if length(rest) == 0 do
        t = (Token.new type: :IDENTIFIER, lexeme: ([c | acc] |> Enum.reverse |> to_string), line: line)
        tokenize([], [t | tokens], line)
      else
        identifier(rest, tokens, line, [c | acc])
      end
      true ->
        case (get_keyword (acc |> Enum.reverse |> to_string)) do
          nil ->
            tokenize([c | rest], [(Token.new type: :IDENTIFIER, lexeme: (acc |> Enum.reverse |> to_string), line: line) | tokens], line)
          :TRUE ->
            tokenize([c | rest], [(Token.new type: :TRUE, lexeme: "true", literal: true, line: line) | tokens], line)
          :FALSE ->
            tokenize([c | rest], [(Token.new type: :FALSE, lexeme: "false", literal: false, line: line) | tokens], line)
          :NIL ->
            tokenize([c | rest], [(Token.new type: :NIL, lexeme: "nil", literal: nil, line: line) | tokens], line)
          :ASSERT ->
            tokenize([c | rest], [(Token.new type: :ASSERT, line: line) | tokens], line)
          _ ->
            tokenize([c | rest], [(Token.new type: (get_keyword(acc |> Enum.reverse |> to_string)), lexeme: (acc |> Enum.reverse |> to_string), line: line) | tokens], line)
        end
    end
  end

  @spec get_keyword(atom) :: atom
  def get_keyword(string) do
    m = %{
      "false" => :FALSE,
      "true" => :TRUE,
      "val" => :VAL,
      "end" => :END,
      "nil" => :NIL,
      "let" => :LET,
      "fn" => :FN,
      "and" => :AND,
      "if" => :IF,
      "then" => :THEN,
      "else" => :ELSE,
      "or" => :OR,
      "in" => :IN,
    }
    m |> Map.get(string)
  end

  @spec is_digit(char) :: boolean
  def is_digit(c), do: ?0 <= c and c <= ?9

  @spec is_alpha(char) :: boolean
  def is_alpha(c), do: ?a <= c and c <= ?z or ?A <= c and c <= ?Z

  def is_alpha_numeric(c), do: is_digit(c) or is_alpha(c)

  def eof(tokens), do: tokens ++ [Token.new(type: :EOF, lexeme: nil)]
end
