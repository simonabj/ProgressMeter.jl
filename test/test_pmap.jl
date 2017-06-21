

@everywhere function test_function1(n, p=nothing)
    ProgressMeter.@info "Starting the stuff..."
    ProgressMeter.@parallelprogress p for i in 1:n
        sleep(0.1)
    end
    ProgressMeter.@info "Done with the stuff..."
end

println("Testing pmap progress *without* pmap")
test_function1(15)

println("Testing pmap progress")
ProgressMeter.pmap(test_function1, [25, 5, 10, 15, 15, 20])



@everywhere function test_function2(n, p=nothing)
    ProgressMeter.@info "Starting the stuff..."
    ProgressMeter.@parallelprogress p "LABEL HERE!!!  " for i in 1:n
        sleep(0.1)
    end
    ProgressMeter.@info "Done with the stuff..."
end

println("Testing pmap progress *without* pmap and with label")
test_function2(15)

println("Testing pmap progress with label")
ProgressMeter.pmap(test_function2, [25, 5, 10, 15, 15, 20])