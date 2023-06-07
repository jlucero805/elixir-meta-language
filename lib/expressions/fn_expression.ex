defmodule FnExpression do
  defstruct [:params, :expr, :is_native, :native_function, :clenv]

  def native(name, args) do
    case name do
      "print" -> apply(__MODULE__, :print, args)
      "assert" -> apply(__MODULE__, :assert, args)
    end
  end

  def print(expr) do
    IO.puts (expr |> to_string)
  end

  def assert(expr) do
    if !expr do
      raise "Assertion failed."
    end
  end
end
