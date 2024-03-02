defmodule SqlParser do
  def run() do
    input = "select foo from bar"
    IO.puts("input: #{inspect(input)}\n")
    parse(input)
  end

  defp parse(input) do
    parser = satisfy(char(), fn char -> char in ?0..?9 end)
    parser.(input)
  end

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
  defp char() do
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
