
"""
optimize(mins::Array, maxs::Array, nutamounts::Array, calories::Array)

This is also called the Stigler's Diet Problem

# Parameters

* mins: minimum allowed intake of nutrients for a given age and sex per day
* maxs: maximum allowed intake of nutrients for a given age and sex per day
* nutamounts: A nested list where each food (the outer list) has a combination of different nutrients (the inner list)
* calories: A list of amount of energy (kcal) in each food
"""
function optimize(mins, maxs, nutamounts, calories, dri_ids, nfoods, exclude_indices)

	nl_solver = optimizer_with_attributes(Ipopt.Optimizer, "print_level"=>0)
	minlp_solver = optimizer_with_attributes(Juniper.Optimizer, "nl_solver"=>nl_solver)
	m = Model(minlp_solver)

	nnutrients = length(dri_ids)

	@variable(m, a[i=1:nfoods,j=1:nnutrients] == nutamounts[i][j]);  # amount of nutrient Nj in one unit of food Fi.
	@variable(m, y[1:nfoods]) # amount of food i per day. the amounts are per 100 grams per day
	@variable(m, cc[c=1:nfoods] == calories[c]); # calorie of each food

	
	@constraint(m, y[[i for i in 1:nfoods if !in(i, exclude_indices)]] .>= 0)  # all food amounts except those in the exclude_indices can have a value more than 0.
	@constraint(m, y[exclude_indices] .== 0.0)  # set those foods that are excluded to 0
	for nn in 1:nnutrients
		@constraint(m, mins[nn] <= sum(a[i,nn]*y[i] for i=1:nfoods) <= maxs[nn])
	end

	@objective(m, Min, sum(cc[i]*y[i] for i=1:nfoods));
	
	optimize!(m)
	status = termination_status(m)
	primal_status(m)
	dual_status(m)
	objval = JuMP.objective_value(m)
	# JuMP.value.(a)
	yval = JuMP.value.(y);

	return m, status, objval, yval
end
