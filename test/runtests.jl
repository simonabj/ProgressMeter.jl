addprocs(2)

import ProgressMeter
import Base.Test.@test
import Base.Test.@test_throws

using Compat

srand(123)

include("test.jl")
include("test_showvalues.jl")
include("test_pmap.jl")

println("")
println("All tests complete")