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

  # def compile() do
  #   System.argv
  #   |> Enum.at(0)
  #   |> (&(Path.join(File.cwd!, &1))).()
  #   |> File.read!
  #   |> Lexer.tokenize
  #   |> Parser.parser
  #   |> Parser.parse
  #   |> Compiler.interpret
  #   |> IO.puts
  # end
end

Eml.run()
