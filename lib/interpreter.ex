defmodule Interpreter do
  def interpret([stmt | stmts]), do: interpret([stmt | stmts], native_functions)
  def interpret([], _env), do: nil
  def interpret([stmt | stmts], env), do: interpret(stmts, execute(env, stmt)|>(elem 0))

  def native_functions() do
    Environment.new
    |> Environment.put("print", %FnExpression{params: ["print_expression"], is_native: true})
    |> Environment.put("assert", %FnExpression{params: ["assert_expression"], is_native: true})
  end

  def execute(env, %ExpressionStatement{} = stmt) do
    evaluate(env, stmt.expr)
  end

  def execute(env, %ValDeclaration{} = stmt) do
    {env, value} = evaluate(env, stmt.expr)
    {Environment.put(env, stmt.name, value), nil}
  end

  def evaluate(env, %LetExpression{} = expr), do: evaluate_let(env, expr.statements, expr.expr)
  def evaluate_let(env, [], expr), do: {env, evaluate(env, expr) |> (elem 1)}
  def evaluate_let(env, [stmt| stmts], expr), do:
    execute(env, stmt)
    |> (elem 0)
    |> evaluate_let(stmts, expr)

  def evaluate(env, %FnExpression{} = expr), do: {env, expr}

  def evaluate(env, %IfExpression{} = expr) do
    {env, value} = evaluate(env, expr.if)
    if value do
      evaluate(env, expr.then)
    else
      evaluate(env, expr.else)
    end
  end

  def evaluate(env, %CallExpression{} = expr) do
    {nenv, callee} = evaluate(env, expr.callee)
    fun = Environment.get(env, expr.callee.name)
    if fun.is_native == true do
      {env, FnExpression.native(expr.callee.name, evaluate_args(expr.arguments, [], env) |> (elem 1))}
    else
      {nnenv, args} = evaluate_args(expr.arguments, [], nenv)
      {env, evaluate_call(fun, args, env)}
    end
  end

  def evaluate_call(%FnExpression{} = f, args, closure) do
    Environment.new(closure)
    |> (&(put_args(f.params, args, &1))).()
    |> (&(evaluate(&1, f.expr))).()
    |> (elem 1)
  end

  def put_args([], [], env), do: env
  def put_args([param | params], [arg | args], env), do:
    Environment.put(env, param, arg)
    |> (&(put_args(params, args, &1))).()

  def evaluate_args([], evaluated, env) do
    {env, evaluated |> Enum.reverse}
  end
  def evaluate_args([arg | args], evaluated, env) do
    {nenv, expr} = evaluate(env, arg)
    evaluate_args(args, [expr | evaluated], nenv)
  end

  def evaluate(env, %Grouping{} = expr), do: {env, evaluate(env, expr.expr) |> (elem 1)}

  def evaluate(env, %Binary{} = expr) do
    {env, left} = evaluate(env, expr.left)
    {env, right} = evaluate(env, expr.right)
    result = cond do
      match(expr.op, :PLUS) -> left + right
      match(expr.op, :MINUS) -> left - right
      match(expr.op, :STAR) -> left * right
      match(expr.op, :SLASH) -> left / right
      match(expr.op, :EQUAL_EQUAL) -> left == right
      match(expr.op, :BANG_EQUAL) -> left != right
      match(expr.op, :LESS) -> left < right
      match(expr.op, :LESS_EQUAL) -> left <= right
      match(expr.op, :GREATER) -> left > right
      match(expr.op, :GREATER_EQUAL) -> left >= right
    end
    {env, result}
  end

  def evaluate(env, %Unary{} = expr) do
    op = expr.op
    {env, expr} = evaluate(env, expr.expr)
    result = case op do
      :MINUS -> -expr
      :BANG -> !expr
      _ -> expr
    end
    {env, result}
  end

  def evaluate(env, %Variable{} = expr), do: {env, Environment.get(env, expr.name)}

  def evaluate(env, %Literal{} = expr), do: {env, expr.literal}

  def match(left, right), do: left == right
end
