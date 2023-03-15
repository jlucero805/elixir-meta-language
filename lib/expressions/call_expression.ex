defmodule CallExpression do
  defstruct [:callee, :arguments, :is_native, :native_function]
end
