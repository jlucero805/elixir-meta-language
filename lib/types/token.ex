defmodule Token do
  defstruct [:type, :lexeme, :literal, :line]

  def new(type: type) do
    %Token{type: type, lexeme: nil, literal: nil, line: nil}
  end

  def new(type: type, lexeme: lexeme) do
    %Token{type: type, lexeme: lexeme, literal: nil, line: nil}
  end

  def new(type: type, line: line) do
    %Token{type: type, lexeme: nil, literal: nil, line: line}
  end

  def new(type: type, lexeme: lexeme, line: line) do
    %Token{type: type, lexeme: lexeme, literal: nil, line: line}
  end

  def new(type: type, literal: literal, line: line) do
    %Token{type: type, lexeme: nil, literal: literal, line: line}
  end

  def new(type: type, lexeme: lexeme, literal: literal, line: line) do
    %Token{type: type, lexeme: lexeme, literal: literal, line: line}
  end
end
