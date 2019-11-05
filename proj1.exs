defmodule Proj1 do
  def main do
    args = System.argv # taking input from commandline
    #:observer.start() #inspects the code
    [num1|num2] = args

    #converts the input numbers into a list of numbers
    input_list = Enum.to_list(String.to_integer(num1)..String.to_integer(Enum.join(num2)))

    #chunks the input_list into a list of 20 numbers each
    partitioned_list = Enum.chunk_every(input_list, 20)
    #Each worker i.e.VampSpawn module is given a list of 20 numbers to process at a time
    children = Enum.map(partitioned_list, fn list -> Supervisor.child_spec({VampSpawn, [list]}, id: Enum.at(list,0), restart: :permanent) end)

    opts = [strategy: :one_for_one, name: Vampire.Supervisor]
    Supervisor.start_link(children,opts) # starts the supervisor

    result = Supervisor.which_children(Vampire.Supervisor)
      |> Enum.map(fn {_,pid,:worker,_} -> pid end)
      |> Enum.map(fn pid -> GenServer.call(pid, :view) end)

      res = (List.flatten(result) |> Enum.filter(fn n -> n != nil end)) #formatting the result list for printing correctly
      for line <- res do
        IO.puts line# prints the vampire number along with its fangs
      end
  end
end

defmodule VampSpawn do #worker module
  use GenServer

  def start_link(list) do
    {:ok,pid} = GenServer.start_link(__MODULE__,nil) #calls the init method of the worker VampSpawn
    GenServer.cast(pid, {:calculate,list}) #calls handle_cast method having {:calculate,list}
    {:ok,pid}
  end

  def init(args) do
    {:ok, args}
  end

  def handle_cast({:calculate,list}, _state) do #stores the vampire numbers and its fangs in state variable
    flat_list = List.flatten(list)
    state = for num <- flat_list do # processing each number in the list
      process(num)
     end
    {:noreply, state}
  end

  def handle_call(:view, _from, state) do # returns the updated state to the Supervisor
    {:reply, state, nil}
  end

  def process(num) do # it takes a single number num and returns the number along with its fangs if it is a vampire number
    fangs = findVampNum(num) |> Enum.filter(&(&1 != nil))
    ans = [num] ++ List.flatten(fangs)
    if length(ans) > 1 do
      Enum.join(ans, " ") # takes a list and return its equivalent string
    end
  end

  @spec findVampNum(any) :: [any]
  def findVampNum(n) do
      length = String.length(to_string(n))
      if Integer.mod(length,2) == 0 do
        lowerBound = n / :math.pow(10, div(length, 2)) |> trunc() #calculating smallest factor of number n having length (n/2)
        upperBound = :math.sqrt(n) |> round() #calculating largest factor of number n having length (n/2)
        factList = findFactors(lowerBound, upperBound, n)
        findFangs(factList, n)
      else
        []
      end
  end

  def findFactors(lowerBound,upperBound,n) do # returns all the factors of number n within range lowerBound and upperBound
    (for i <- lowerBound..upperBound, rem(n,i)==0, do: i) ++ []
  end

  def findFangs(factList,n) do # checks for fangs within the list of factors of number n
    for i <- factList do
       if Enum.sort(String.codepoints(Integer.to_string(i)<>Integer.to_string((n/i)|> round()))) == Enum.sort(String.codepoints(Integer.to_string(n))) and
       (!(String.ends_with?(Integer.to_string(i),"0")) or !(String.ends_with?(Integer.to_string((n/i)|> round()),"0"))) do

        [[i,(n/i)|> round()]]

      end
    end
  end
end

Proj1.main # running the main method of Proj1 module
