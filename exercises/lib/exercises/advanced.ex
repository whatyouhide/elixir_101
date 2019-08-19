defmodule Exercises.Advanced do
  @doc """
  Return the average value of all numbers in the list.
  """
  def average([head | tail]) do
    do_average(tail, head, 1)
  end

  defp do_average(_list, _sum, _count) do
    raise "not implemented yet"
  end

  @doc """
  Returns a two element tuple with the odd and even numbers of the list.
  """
  def odds_and_evens(list) do
    do_odds_and_evens(list, [], [])
  end

  defp do_odds_and_evens(_list, _odds, _evens) do
    raise "not implemented yet"
  end

  @doc """
  Returns the three largest numbers of the list
  """
  def three_largest(_list) do
    raise "not implemented yet"
  end

  @doc """
  Capitalize all words in the given string.

  TIP: Use the functions `String.split/2`, `String.capitalize/1`, and `Enum.join/1`.
  """
  def capitalize_all(_string) do
    raise "not implemented yet"
  end
end
