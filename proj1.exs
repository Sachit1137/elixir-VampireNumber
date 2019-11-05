defmodule Proj1 do
  def main do
    # taking input from commandline
    args = System.argv()
    # :observer.start() #inspects the code
    [num1 | num2] = args

    # converts the input numbers into a list of numbers
    input_list = Enum.to_list(String.to_integer(num1)..String.to_integer(Enum.join(num2)))

    # chunks the input_list into a list of 20 numbers each
    partitioned_list = Enum.chunk_every(input_list, 20)
    # Each worker i.e.VampSpawn module is given a list of 20 numbers to process at a time
    children =
      Enum.map(partitioned_list, fn list ->
        Supervisor.child_spec({VampSpawn, [list]}, id: Enum.at(list, 0), restart: :permanent)
      end)

    opts = [strategy: :one_for_one, name: Vampire.Supervisor]
    # starts the supervisor
    Supervisor.start_link(children, opts)

    result =
      Supervisor.which_children(Vampire.Supervisor)
      |> Enum.map(fn {_, pid, :worker, _} -> pid end)
      |> Enum.map(fn pid -> GenServer.call(pid, :view) end)

    # formatting the result list for printing correctly
    res = List.flatten(result) |> Enum.filter(fn n -> n != nil end)

    for line <- res do
      # prints the vampire number along with its fangs
      IO.puts(line)
    end
  end
end

# worker module
defmodule VampSpawn do
  use GenServer

  def start_link(list) do
    # calls the init method of the worker VampSpawn
    {:ok, pid} = GenServer.start_link(__MODULE__, nil)
    # calls handle_cast method having {:calculate,list}
    GenServer.cast(pid, {:calculate, list})
    {:ok, pid}
  end

  def init(args) do
    {:ok, args}
  end

  # stores the vampire numbers and its fangs in state variable
  def handle_cast({:calculate, list}, _state) do
    flat_list = List.flatten(list)
    # processing each number in the list
    state =
      for num <- flat_list do
        process(num)
      end

    {:noreply, state}
  end

  # returns the updated state to the Supervisor
  def handle_call(:view, _from, state) do
    {:reply, state, nil}
  end

  # it takes a single number num and returns the number along with its fangs if it is a vampire number
  def process(num) do
    fangs = findVampNum(num) |> Enum.filter(&(&1 != nil))
    ans = [num] ++ List.flatten(fangs)

    if length(ans) > 1 do
      # takes a list and return its equivalent string
      Enum.join(ans, " ")
    end
  end

  @spec findVampNum(any) :: [any]
  def findVampNum(n) do
    length = String.length(to_string(n))

    if Integer.mod(length, 2) == 0 do
      # calculating smallest factor of number n having length (n/2)
      lowerBound = (n / :math.pow(10, div(length, 2))) |> trunc()
      # calculating largest factor of number n having length (n/2)
      upperBound = :math.sqrt(n) |> round()
      factList = findFactors(lowerBound, upperBound, n)
      findFangs(factList, n)
    else
      []
    end
  end

  # returns all the factors of number n within range lowerBound and upperBound
  def findFactors(lowerBound, upperBound, n) do
    for(i <- lowerBound..upperBound, rem(n, i) == 0, do: i) ++ []
  end

  # checks for fangs within the list of factors of number n
  def findFangs(factList, n) do
    for i <- factList do
      if Enum.sort(
           String.codepoints(Integer.to_string(i) <> Integer.to_string((n / i) |> round()))
         ) == Enum.sort(String.codepoints(Integer.to_string(n))) and
           (!String.ends_with?(Integer.to_string(i), "0") or
              !String.ends_with?(Integer.to_string((n / i) |> round()), "0")) do
        [[i, (n / i) |> round()]]
      end
    end
  end
end

# running the main method of Proj1 module
Proj1.main()
