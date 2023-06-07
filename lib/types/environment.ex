defmodule Environment do
  defstruct [:values, :enclosing]

  def new(), do: %Environment{values: %{}, enclosing: nil}

  def new(e), do: %Environment{values: %{}, enclosing: e}

  def extend(og, new) do
    %Environment{new | enclosing: og}
  end

  def has_key?(%Environment{} = e, key) do
    Map.has_key?(e.values, key)
  end

  def get(%Environment{enclosing: %Environment{}} = e, key) do
    if (has_key? e, key) do
      Map.get(e.values, key)
    else
      get(e.enclosing, key)
    end
  end

  def get(%Environment{} = e, key) do
    if (has_key? e, key) do
      Map.get(e.values, key)
    else
      raise "Undefined variable #{key}."
    end
  end

  def put(%Environment{} = e, key, val), do: %Environment{values: Map.put(e.values, key, val), enclosing: e.enclosing}

  def assign(%Environment{enclosing: %Environment{}} = e, key, val) do
    if has_key?(e, key) do
      put e, key, val
    else
      assign e.enclosing, key, val
    end
  end

  def assign(%Environment{} = e, key, val) do
    if has_key?(e, key) do
      put e, key, val
    else
      raise "Undefined variable #{key}"
    end
  end
end
