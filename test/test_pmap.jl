

@everywhere function test_function(n, progress=nothing)
    ProgressMeter.@setup progress @sprintf("%2u  ", n)*"  " n
    ProgressMeter.@info "Startin the stuff..."
    for i in 1:n
        ProgressMeter.@progress progress i
        sleep(0.1)
    end
    ProgressMeter.@info "Done with the stuff..."
end

println("Testing pmap progress *without* pmap")
test_function(15)

println("Testing pmap progress")
ProgressMeter.pmap(test_function, [25, 5, 10, 15, 15, 20])