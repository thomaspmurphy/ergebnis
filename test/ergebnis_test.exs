defmodule ErgebnisTest do
  use ExUnit.Case, async: true
  doctest Ergebnis

  alias Ergebnis, as: R

  # ── Constructors ─────────────────────────────────────────────────────────────

  test "ok/1 wraps a value" do
    assert R.ok(42) == {:ok, 42}
  end

  test "error/1 wraps a reason" do
    assert R.error(:not_found) == {:error, :not_found}
  end

  # ── Predicates ───────────────────────────────────────────────────────────────

  test "ok?/1" do
    assert R.ok?(R.ok(1))
    refute R.ok?(R.error(:boom))
  end

  test "error?/1" do
    assert R.error?(R.error(:boom))
    refute R.error?(R.ok(1))
  end

  # ── map ───────────────────────────────────────────────────────────────────────

  test "map/2 transforms the ok value" do
    assert R.map(R.ok(10), &(&1 * 3)) == {:ok, 30}
  end

  test "map/2 passes through error unchanged" do
    assert R.map(R.error(:gone), &(&1 * 3)) == {:error, :gone}
  end

  test "map_error/2 transforms the error reason" do
    assert R.map_error(R.error("oops"), &String.upcase/1) == {:error, "OOPS"}
  end

  test "map_error/2 passes through ok unchanged" do
    assert R.map_error(R.ok(99), &String.upcase/1) == {:ok, 99}
  end

  # ── flat_map ──────────────────────────────────────────────────────────────────

  test "flat_map/2 chains successful computations" do
    parse = fn s ->
      case Integer.parse(s) do
        {n, ""} -> R.ok(n)
        _ -> R.error({:parse_error, s})
      end
    end

    result =
      R.ok("21")
      |> R.flat_map(parse)
      |> R.map(&(&1 * 2))

    assert result == {:ok, 42}
  end

  test "flat_map/2 short-circuits on error" do
    called = :counters.new(1, [])

    R.error(:stop)
    |> R.flat_map(fn _ ->
      :counters.add(called, 1, 1)
      R.ok(:never)
    end)

    assert :counters.get(called, 1) == 0
  end

  # ── unwrapping ───────────────────────────────────────────────────────────────

  test "unwrap!/1 extracts ok value" do
    assert R.unwrap!(R.ok(:hello)) == :hello
  end

  test "unwrap!/1 raises on error" do
    assert_raise RuntimeError, fn -> R.unwrap!(R.error(:bad)) end
  end

  test "unwrap_or/2 returns default on error" do
    assert R.unwrap_or(R.error(:miss), 0) == 0
    assert R.unwrap_or(R.ok(5), 0) == 5
  end

  test "unwrap_or_else/2 calls fallback on error" do
    assert R.unwrap_or_else(R.error(:x), fn _ -> 99 end) == 99
    assert R.unwrap_or_else(R.ok(7), fn _ -> 99 end) == 7
  end

  # ── conversion ───────────────────────────────────────────────────────────────

  test "from_nilable/2 wraps non-nil" do
    assert R.from_nilable("hello", :missing) == {:ok, "hello"}
  end

  test "from_nilable/2 errors on nil" do
    assert R.from_nilable(nil, :missing) == {:error, :missing}
  end

  test "try/1 catches raises" do
    assert R.try(fn -> 1 + 1 end) == {:ok, 2}
    assert {:error, %ArithmeticError{}} = R.try(fn -> 1 / 0 end)
  end

  # ── exhaustiveness demo ───────────────────────────────────────────────────────
  # Uncomment the clause below to see what the type checker infers when you
  # leave out the :error branch. With 1.17+ it warns; Dialyzer historically
  # wouldn't.
  #
  def demo do
    x = :hello
    x + 1
  end
end
