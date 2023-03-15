defmodule Parser do
  defstruct [:cur, :peek, :rest]

  def parser([cur | [peek | rest]]), do: %Parser{cur: cur, peek: peek, rest: rest}
  def parse(%Parser{} = p), do: parse p, []
  def parse(%Parser{cur: %Token{type: :EOF}}, stmts), do: Enum.reverse stmts
  def parse(%Parser{} = p, stmts) do
    {p, stmt} = declaration(p)
    parse(p, [stmt | stmts])
  end

  def declaration(p) do
    if match(p, :VAL) do
      p = next(p)
      name = p.cur.lexeme
      p = next(p)
      p = consume(p, :EQUAL, "Expected '<-'.")
      {p, expr} = expression(p)
      {p, %ValDeclaration{name: name, expr: expr}}
    else
      expression_statement(p)
    end
  end

  def expression_statement(p) do
    {p, expr} = expression(p)
    {p, %ExpressionStatement{expr: expr}}
  end

  def expression(p) do
    cond do
      match(p, :LET) -> next(p) |> let_expression
      match(p, :IF) -> next(p) |> if_expression
      match(p, :FN) -> next(p) |> fn_expression
      true -> equality(p)
    end
  end

  def let_expression(p), do: let_expression p, []
  def let_expression(p, stmts) do
    if match(p, :IN) do
      let_in_expression(consume(p, :IN, "Expected 'in'."), stmts)
    else
      {p, stmt} = declaration(p)
      let_expression(p, [stmt | stmts])
    end
  end

  def let_in_expression(p, stmts) do
    {p, expr} = expression(p)
    {p, %LetExpression{statements: Enum.reverse(stmts), expr: expr}}
  end

  def if_expression(p) do
    {p, if_expr} = expression(p)
    {p, then_expr} = expression(consume(p, :THEN))
    {p, else_expr} = expression(consume(p, :ELSE))
    {p, %IfExpression{if: if_expr, then: then_expr, else: else_expr}}
  end

  def fn_expression(p) do
    p = consume(p, :LEFT_PAREN, "Expected '('.")
    {p, params} = fn_params(p)
    {p, expr} = expression(p)
    {p, %FnExpression{params: params, expr: expr, is_native: false}}
  end

  def fn_params(p), do: fn_params p, []
  def fn_params(p, params) do
    if match(p, :RIGHT_PAREN) do
        {consume(p, :RIGHT_PAREN, "Expected ')'."), Enum.reverse(params)}
    else
      if match(next(p), :COMMA) do
        fn_params(next(next(p)), [p.cur.lexeme | params])
      else
        fn_params(next(p), [p.cur.lexeme | params])
      end
    end
  end

  def equality(p) do
    {p, expr} = comparison(p)
    equality(p, expr)
  end

  def equality(p, expr) do
    if match(p, :EQUAL_EQUAL) or match(p, :BANG_EQUAL) do
      op = p.cur.type
      {p, right} = next(p) |> comparison
      bin = %Binary{left: expr, op: op, right: right}
      equality(p, bin)
    else
      {p, expr}
    end
  end

  def comparison(p) do
    {p, expr} = term(p)
    comparison(p, expr)
  end

  def comparison(p, expr) do
    if match(p, :LESS) or match(p, :LESS_EQUAL) or match(p, :GREATER) or match(p, :GREATER_EQUAL) do
      op = p.cur.type
      {p, right} = next(p) |> term
      bin = %Binary{left: expr, op: op, right: right}
      comparison(p, bin)
    else
      {p, expr}
    end
  end

  def term(p) do
    {p, expr} = factor(p)
    term(p, expr)
  end

  def term(p, expr) do
    if match(p, :PLUS) or match(p, :MINUS) do
      op = p.cur.type
      {p, right} = next(p) |> factor
      bin = %Binary{left: expr, op: op, right: right}
      term(p, bin)
    else
      {p, expr}
    end
  end

  def factor(p) do
    {p, expr} = unary(p)
    factor(p, expr)
  end

  def factor(p, expr) do
    if match(p, :STAR) or match(p, :SLASH) do
      op = p.cur.type
      {p, right} = next(p) |> unary
      bin = %Binary{left: expr, op: op, right: right}
      factor(p, bin)
    else
      {p, expr}
    end
  end

  def unary(p) do
    if match(p, :MINUS) do
      op = p.cur.type
      {p, expr} = p |> next |> unary
      {p, %Unary{op: op, expr: expr}}
    else
      call(p)
    end
  end

  def call(p) do
    {p, expr} = primary(p)
    if match(p, :LEFT_PAREN) do
      parse_call(next(p), expr)
    else
      {p, expr}
    end
  end

  def call(p, expr) do
    if (match p, :LEFT_PAREN) do
      parse_call(next(p), expr)
    else
      {p, expr}
    end
  end

  def parse_call(p, expr) do
    {p, expr} = finish_call(p, expr, [])
    call(p, expr)
  end

  def finish_call(p, expr, args) do
    if match(p, :RIGHT_PAREN) do
      {consume(p, :RIGHT_PAREN, "Expected ')'."), %CallExpression{callee: expr, arguments: Enum.reverse(args)}}
    else
      {p, nexpr} = expression(p)
      if match(p, :COMMA) do
        finish_call(next(p), expr, [nexpr | args])
      else
        finish_call(p, expr, [nexpr | args])
      end
    end
  end

  def primary(p) do
    cond do
      match(p, :NUMBER) or match(p, :STRING) or match(p, :TRUE) or match(p, :FALSE) ->
        {next(p), %Literal{literal: p.cur.literal}}
      match(p, :IDENTIFIER) ->
        {next(p), %Variable{name: p.cur.lexeme}}
      match(p, :LEFT_PAREN) ->
        if true do
          {np, expr} = next(p) |> expression
          {consume(np, :RIGHT_PAREN, "Expected a ')'."), %Grouping{expr: expr}}
        end
      true ->
        raise "Expected a :NUMBER"
    end
  end

  def match(p, type), do: p.cur.type == type

  def consume(p, type) do
    if match(p, type) do
      next(p)
    else
      raise "Expected a )." <> " ::line:#{p.cur.line}"
    end
  end

  def consume(p, type, msg) do
    if match(p, type) do
      next(p)
    else
      raise msg <> " ::line:#{p.cur.line}"
    end
  end
  def next(%Parser{rest: []} = p), do: %Parser{cur: p.peek, peek: nil, rest: []}
  def next(%Parser{} = p), do: %Parser{cur: p.peek, peek: hd(p.rest), rest: tl(p.rest)}
end
