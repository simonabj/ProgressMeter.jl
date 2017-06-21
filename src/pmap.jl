function pmap(pool::WorkerPool, f, c; output::IO=STDERR, dt::Real=0.5)
    meters = Array{Progress}(nworkers(pool))
    channels = [RemoteChannel(() -> Channel{Any}(16), w) for w in 1:nworkers()]
    remaining = length(c)

    g(x) = f(x, channels[myid() - 1])
    g = remote(pool, g)

    h(x) = (remaining -= 1; g(x))

    done = false
    lastPrint = time()

    #clear space for the progress meters
    print(output, "\n"^(nworkers(pool) + 2))

    @async while true
        for (i, channel) in enumerate(channels)
            if isready(channel)
                update = take!(channel)

                if typeof(update) == Tuple{String, Int64}
                    meters[i] = Progress(update[2], desc=update[1], do_not_print=true)
                elseif update < 0
                    finish!(meters[i])
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

macro info(str)
    if myid() == 1
        esc(:(Base.print_with_color(:cyan, "INFO: ", $str, "\n")))
    end
end

macro parallelprogress(args...)
    if length(args) < 2
        throw(ArgumentError("@paralleprogress requires at least two arguments"))
    end
    metersym = args[1]
    progressargs = args[2:end-1]
    loop = args[end]

    if loop.head != :for
        throw(ArgumentError("@paralleprogress only works on for loops"))
    end

    progressString = "Progress: "
    if length(progressargs) > 0
        progressString = progressargs[1]
    end

    loopIttr = loop.args[1].args[2]
    loopVar = loop.args[1].args[1]
    loopBody = loop.args[2].args
    loopLength = :( length($loopIttr) )

    if myid() == 1
        setup = esc(:($metersym = ProgressMeter.Progress($loopLength, desc=$progressString) ))
        update = :(ProgressMeter.update!($metersym, $loopVar))
        finish = esc(:(ProgressMeter.finish!($metersym)))
    else
        setup = esc(:(put!($metersym, ($progressString, $loopLength)); lastUpdateTime = time() ))
        update = quote
                    t = time()
                    if t > lastUpdateTime + 0.5
                        @async put!($metersym, $loopVar)
                        lastUpdateTime = t
                    end

                    yield()
                end
        finish = esc(:(put!($metersym, -1)))
    end

    push!(loop.args[2].args, update)
    loop = esc(loop)

    return quote
        $setup
        $loop
        $finish
    end
end