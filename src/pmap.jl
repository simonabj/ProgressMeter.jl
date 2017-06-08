function pmap(pool::WorkerPool, f, c; output::IO=STDERR)
    meters = Array{Progress}(nworkers(pool))
    channels = [RemoteChannel(() -> Channel{Any}(16), w) for w in 1:nworkers()]
    remaining = length(c)

    g(x) = f(x, channels[myid() - 1])
    g = remote(pool, g)

    h(x) = (remaining -= 1; g(x))

    done = false
    lastPrint = time()
    dt = 0.1
    print(output, "\n"^(nworkers(pool) + 2))

    @async while true
        for (i, channel) in enumerate(channels)
            if isready(channel)
                update = take!(channel)

                if typeof(update) == Tuple{String, Int64}
                    meters[i] = Progress(update[2], desc=update[1], do_not_print=true)
                else
                    update!(meters[i], update)
                end
            end
        end

        t = time()
        if t > lastPrint + dt
            move_cursor_up_while_clearing_lines(output, nworkers() + 2)

            println(output, remaining, " tasks remaining to start")
            println(output, "-------------------------------")
            for i in 1:length(meters)
                if isassigned(meters, i)
                    printover(output, progress_meter_string(meters[i])*"\n", meters[i].color)
                else
                    println(output)
                end
            end

            lastPrint = t
        end

        yield()
        done && break
    end

    results = asyncmap(h, c, ntasks = () -> nworkers(pool))

    done = true
    sleep(0.1)

    return results
end
pmap(f, c) = pmap(default_worker_pool(), f, c)

macro setup(progress, str, n)
    if myid() == 1
        esc(:($progress = ProgressMeter.Progress($n, desc=$str)) )
    else
        esc(:(put!($progress, ($str, $n) )) )
    end
end

macro progress(progress, num)
    if myid() == 1          # progress is a ProgressMeter
        esc(:(ProgressMeter.update!($progress, $num)))
    else                    # progress is a RemoteChannel
        esc(:(put!($progress, $num)))
    end
end

macro info(str)
    if myid() == 1
        esc(:(Base.print_with_color(:green, "INFO:  ", $str, "\n")))
    end
end