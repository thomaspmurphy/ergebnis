# Ergebnis

A typed Result/Either type for Elixir, built on idiomatic `{:ok, a} | {:error, e}` tuples.

Built as an exploration of the set-theoretic type checker introduced in Elixir 1.17+, which can infer types from pattern matches and flag dead clauses at compile time.

## Usage

```elixir
alias Ergebnis, as: R

# Construct
R.ok(42)        # {:ok, 42}
R.error(:oops)  # {:error, :oops}

# Transform
R.ok(10) |> R.map(& &1 * 2)          # {:ok, 20}
R.error(:x) |> R.map(& &1 * 2)       # {:error, :x}

# Chain
parse = fn s ->
  case Integer.parse(s) do
    {n, ""} -> R.ok(n)
    _       -> R.error({:parse_error, s})
  end
end

R.ok("21") |> R.flat_map(parse) |> R.map(& &1 * 2)  # {:ok, 42}

# Unwrap
R.unwrap!(R.ok(:hello))                        # :hello
R.unwrap_or(R.error(:miss), 0)                 # 0
R.unwrap_or_else(R.error(:x), fn _ -> 99 end)  # 99

# Conversion
R.from_nilable(nil, :missing)    # {:error, :missing}
R.from_nilable("hi", :missing)   # {:ok, "hi"}
R.try(fn -> 1 / 0 end)          # {:error, %ArithmeticError{}}
```

## Type checker

The `@type t(a, e) :: {:ok, a} | {:error, e}` union gives the Elixir 1.17+ type checker enough signal to infer through pattern-matched functions. See the commented-out `type_check_demo` in `lib/ergebnis.ex` for an example of a dead clause warning.
