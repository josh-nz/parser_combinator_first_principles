defmodule SqlParser do
  def run() do
    input = "foo_1 bar_2"
    IO.puts("input: #{inspect(input)}\n")
    parse(input)
  end

  defp parse(input) do
    parser = identifier()
    parser.(input)
  end

  # This implementation will stop on whitespace,
  # so will immediately stop returning :ok on input
  # such as " foo_1". Not ideal.
  defp identifier(), do: many(identifier_char())

  defp many(parser) do
    fn input ->
      case parser.(input) do
        {:error, _reason} ->
          {:ok, [], input}

        {:ok, first_term, rest} ->
          {:ok, other_terms, rest} = many(parser).(rest)
          {:ok, [first_term | other_terms], rest}
      end
    end
  end

  defp identifier_char(), do: choice([ascii_letter(), char(?_), digit()])

  # Sometimes called `one-of`.
  defp choice(parsers) do
    fn input ->
      case parsers do
        [] ->
          {:error, "No parser succeeded"}

        [first_parser | other_parsers] ->
          with {:error, _reason} <- first_parser.(input),
               do: choice(other_parsers).(input)
      end
    end
  end

  defp digit(), do: satisfy(read_char(), fn char -> char in ?0..?9 end)
  defp ascii_letter(), do: satisfy(read_char(), fn char -> char in ?A..?Z or char in ?a..?z end)
  defp char(expected), do: satisfy(read_char(), fn char -> char == expected end)

  # If a combinator takes parser/s, it must invoke
  # them whilst also returning a function. This sets
  # up the combinator function call chain eg 
  # foo(bar(baz(quax(read_char))))
  defp satisfy(parser, acceptor) do
    fn input ->
      with {:ok, term, rest} <- parser.(input) do
        if acceptor.(term),
          do: {:ok, term, rest},
          else: {:error, "Term rejected"}
      end
    end
  end

  # A combinator is a function that returns a parser
  # according to the parser contract, defined below.
  # This function char/0 is a combinator.
  defp read_char() do
    # This anonymous function is a parser.
    fn input ->
      case input do
        # Defines the parser contract; must return
        # either the :error or :ok tuple.
        "" -> {:error, "Unexpected end of input"}
        <<char::utf8, rest::binary>> -> {:ok, char, rest}
      end
    end
  end
end
