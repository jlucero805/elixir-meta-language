defmodule Eml do
  def run() do
    System.argv
    |> Enum.at(0)
    |> (&(Path.join(File.cwd!, &1))).()
    |> File.read!
    |> Lexer.tokenize
    |> Parser.parser
    |> Parser.parse
    |> Interpreter.interpret
  end
end

Eml.run()
