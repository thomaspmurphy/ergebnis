defmodule Ergebnis do
  @moduledoc """
  A typed Result/Either type built on idiomatic `{:ok, a} | {:error, e}` tuples.

  Designed to exercise Elixir 1.17+'s set-theoretic type checker — the union
  type `t(a, e)` and pattern-matched clauses give the checker enough signal to
  infer return types and flag non-exhaustive matches.

  ## Basic usage

      iex> Ergebnis.ok(42) |> Ergebnis.map(& &1 * 2)
      {:ok, 84}

      iex> Ergebnis.error(:not_found) |> Ergebnis.map(& &1 * 2)
      {:error, :not_found}

  ## Chaining with flat_map

      iex> parse = fn s -> case Integer.parse(s) do
      ...>   {n, ""} -> Ergebnis.ok(n)
      ...>   _       -> Ergebnis.error({:parse_error, s})
      ...> end end
      iex> Ergebnis.ok("42") |> Ergebnis.flat_map(parse) |> Ergebnis.map(& &1 + 1)
      {:ok, 43}
  """

  @type ok(a) :: {:ok, a}
  @type error(e) :: {:error, e}

  # The core union: this is what the type checker sees when it infers through
  # pattern-matched functions below.
  @type t(a, e) :: ok(a) | error(e)

  # ── Constructors ─────────────────────────────────────────────────────────────

  @spec ok(a) :: ok(a) when a: var
  def ok(value), do: {:ok, value}

  @spec error(e) :: error(e) when e: var
  def error(reason), do: {:error, reason}

  # ── Predicates ───────────────────────────────────────────────────────────────

  @spec ok?(t(term(), term())) :: boolean()
  def ok?({:ok, _}), do: true
  def ok?({:error, _}), do: false

  @spec error?(t(term(), term())) :: boolean()
  def error?({:ok, _}), do: false
  def error?({:error, _}), do: true

  # ── Functor ──────────────────────────────────────────────────────────────────

  @spec map(t(a, e), (a -> b)) :: t(b, e) when a: var, b: var, e: var
  def map({:ok, v}, f), do: {:ok, f.(v)}
  def map({:error, _} = e, _f), do: e

  @spec map_error(t(a, e), (e -> f)) :: t(a, f) when a: var, e: var, f: var
  def map_error({:ok, _} = r, _f), do: r
  def map_error({:error, e}, f), do: {:error, f.(e)}

  # ── Monad ────────────────────────────────────────────────────────────────────

  @spec flat_map(t(a, e), (a -> t(b, e))) :: t(b, e) when a: var, b: var, e: var
  def flat_map({:ok, v}, f), do: f.(v)
  def flat_map({:error, _} = e, _f), do: e

  # ── Unwrapping ───────────────────────────────────────────────────────────────

  @spec unwrap!(ok(a)) :: a when a: var
  def unwrap!({:ok, v}), do: v
  def unwrap!({:error, e}), do: raise("unwrap! called on error: #{inspect(e)}")

  @spec unwrap_error!(error(e)) :: e when e: var
  def unwrap_error!({:error, e}), do: e
  def unwrap_error!({:ok, v}), do: raise("unwrap_error! called on ok: #{inspect(v)}")

  @spec unwrap_or(t(a, term()), a) :: a when a: var
  def unwrap_or({:ok, v}, _default), do: v
  def unwrap_or({:error, _}, default), do: default

  @spec unwrap_or_else(t(a, e), (e -> a)) :: a when a: var, e: var
  def unwrap_or_else({:ok, v}, _f), do: v
  def unwrap_or_else({:error, e}, f), do: f.(e)

  # ── Conversion ───────────────────────────────────────────────────────────────

  @doc "Lift a nullable value — nil becomes {:error, reason}, anything else {:ok, v}."
  @spec from_nilable(a | nil, e) :: t(a, e) when a: var, e: var
  def from_nilable(nil, reason), do: {:error, reason}
  def from_nilable(value, _reason), do: {:ok, value}

  @doc "Wrap a function that may raise into a Result."
  @spec try((-> a)) :: t(a, Exception.t()) when a: var
  def try(f) do
    {:ok, f.()}
  rescue
    e -> {:error, e}
  end

  # Exhaustiveness demo — uncomment to see the 1.17+ type checker in action.
  # Emits: "the following clause will never match: {:ok, v}"
  # because the checker infers val :: {:error, :oops} and can prove the arm is dead.
  # Note: only fires for locally-inferred types; cross-function checking requires
  # @spec enforcement, which is a planned future milestone.
  #
  # def type_check_demo do
  #   val = {:error, :oops}
  #   case val do
  #     {:ok, v} -> v * 2
  #   end
  # end
end
