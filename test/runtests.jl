using Base.Test
using TestSetExtensions

test_path = splitdir(realpath(@__FILE__))[1]
# test_path = pwd()
modules_path = joinpath(splitdir(test_path)[1], "src/")
push!(LOAD_PATH, modules_path)

import FoodRecom

my_tests = ["GetData_test.jl"]

println("Running tests:")
for my_test in my_tests
  include(my_test)
end
