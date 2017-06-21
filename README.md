# ProgressMeter.jl

This is a fork of Tim Holy's excellent progress meter package. It adds support for multiple progress meters from worker processes using a new `pmap` function.

## Usage

First, add some worker processes and define a work function:
```julia
addprocs(4)

@everywhere using ProgressMeter

@everywhere function test_function(x, p=nothing)
    @info("Running with value $x")

    @parallelprogress p "optional label " for i in 1:x
        sleep(0.1)
    end

    @info("Done")
    return x
end
```

Now we can run this locally on the master process, and it will print out the helpful diagnostic info:
```julia
julia> test_function(100)
INFO: Running with value 100
optional label 100%|████████████████████████████████████| Time: 0:00:10
INFO: Done
100
```

Or, we can run several copies of `test_function` on the worker processes and see the progress of each one:
```julia
julia> ProgressMeter.pmap(test_function, [50, 50, 100, 25, 10, 50])
2 tasks remaining to start
-------------------------------
optional label  40%|██████████████                      |  ETA: 0:00:04
optional label  80%|█████████████████████████████       |  ETA: 0:00:01
optional label  40%|██████████████                      |  ETA: 0:00:04
optional label  20%|███████                             |  ETA: 0:00:10
```
