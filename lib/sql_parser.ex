defmodule SqlParser do
  def run() do
    input = "SeLect 
          foo_1
      ,
      
        bar_2,bar_3   from some_table
      "
    IO.puts("input: #{inspect(input)}\n")
    parse(input)
  end

  defp parse(input) do
    parser = select_statement()
    parser.(input)
  end

  defp select_statement() do
    sequence([
      keyword(:select),
      columns(),
      keyword(:from),
      token(identifier())
    ])
    |> map(fn [_, columns, _, table] ->
      %{
        statement: :select,
        columns: columns,
        from: table
      }
    end)
  end

  defp keyword(expected) do
    identifier()
    |> token()
    |> satisfy(fn identifier ->
      String.upcase(identifier) == String.upcase(to_string(expected))
    end)
    |> map(fn _ -> expected end)
  end

  defp columns(), do: separated_list(token(identifier()), token(char(?,)))

  defp separated_list(element_parser, separator_parser) do
    sequence([
      element_parser,
      many(sequence([separator_parser, element_parser]))
    ])
    |> map(fn [first_element, rest] ->
      other_elements = Enum.map(rest, fn [_, element] -> element end)
      [first_element | other_elements]
    end)
  end

  defp token(parser) do
    # Some whitespace chars are missing here.
    whitespace = many(choice([char(?\s), char(?\r), char(?\n)]))

    sequence([whitespace, parser, whitespace])
    |> map(fn [_leading_whitespace, term, _trailing_whitespace] -> term end)
  end

  defp sequence(parsers) do
    fn input ->
      case parsers do
        [] ->
          {:ok, [], input}

        [first_parser | other_parsers] ->
          with {:ok, first_term, rest} <- first_parser.(input),
               {:ok, other_terms, rest} <- sequence(other_parsers).(rest),
               do: {:ok, [first_term | other_terms], rest}
      end
    end
  end

  defp map(parser, mapper) do
    fn input ->
      with {:ok, term, rest} <- parser.(input),
           do: {:ok, mapper.(term), rest}
    end
  end

  defp identifier() do
    many(identifier_char())
    # If we've failed to parse an identifier, return :error case.
    |> satisfy(fn chars -> chars != [] end)
    |> map(fn chars -> to_string(chars) end)
  end

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
