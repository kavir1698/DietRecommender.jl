module DietRecommender

using ProgressMeter
using Serialization
using DataFrames
using CSV
using Query
using JuMP
using Ipopt
using Cbc
using Juniper
using StatsBase: sample
include("get_data.jl")
include("optimize.jl")
include("return_diet.jl")


end # module
