defmodule FibSolver do
  def fib(scheduler) do
    send scheduler, {:ready, self() }
    receive do
      { :fib, n, client } ->
        send client, { :answer, n, fib_calc(n), self() }
        fib(scheduler)
        { :shoutdown } ->
          exit(:normal)
    end
  end
  defp fib_calc(0), do: 0
  defp fib_calc(1), do: 1
  defp fib_calc(n), do: fib_calc(n-1) + fib_calc(n-2)
  defmodule Scheduler do
    def run(num_processes, module, func, to_calculate) do
      (1..num_processes)
      |> Enum.map(fn(_) -> spawn(module, func, [self()]) end)
      |> schedule_processes(to_calculate, [])
    end
    defp schedule_processes(processes, queue, results) do
      receive do
        {:ready, pid} when queue != [] ->
          [ next | tail ] = queue
          send pid, {:fib, next, self()}
          schedule_processes(processes, tail, results)

          {:ready, pid} ->
            send pid, {:shoutdown}
            if length(processes) > 1 do
              schedule_processes(List.delete(processes, pid), queue, results)
            else
              Enum.sort(results, fn {n1,_}, {n2,_} -> n1 <= n2 end)
            end
            {:answer, number, result, _pid} ->
              schedule_processes(processes, queue, [ {number, result} | result ])
      end
    end
    to_process = List.duplicate(31, 20)
    Enum.each 1..10, fn num_processes ->
      { time,result} =:timer.tc(
        Scheduler, :run,
        [num_processes, FibSolver, :fi, to_process]
      )
      if num_processes == 1 do
        IO.puts inspect result
        IO.puts "\n #   time (S)"
      end
      :io.format "~2B    ~.2f~n", [num_processes, time/1000000.0]
    end
  end

end
