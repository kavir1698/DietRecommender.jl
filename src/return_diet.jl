export get_diet

"""
    get_diet(your_age, your_sex, your_weight; kwargs)

## kwargs:

* `only_groups`: Array with list of food group IDs. Only include foods in in these categories. Defaults to `[100, 500, 900, 1000, 1100, 1200, 1300, 1500, 1600, 1700, 2000]`. Here is a list of all IDs and their corresponding food category:
  * 0100: Dairy and Egg Products
  * 0200: Spices and Herbs 
  * 0300: Baby Foods 
  * 0400: Fats and Oils 
  * 0500: Poultry Products 
  * 0600: Soups, Sauces, and Gravies 
  * 0700: Sausages and Luncheon Meats 
  * 0800: Breakfast Cereals 
  * 0900: Fruits and Fruit Juices 
  * 1000: Pork Products 
  * 1100: Vegetables and Vegetable Products 
  * 1200: Nut and Seed Products 
  * 1300: Beef Products 
  * 1400: Beverages 
  * 1500: Finfish and Shellfish Products 
  * 1600: Legumes and Legume Products 
  * 1700: Lamb, Veal, and Game Products 
  * 1800: Baked Products 
  * 1900: Sweets 
  * 2000: Cereal Grains and Pasta 
  * 2100: Fast Foods 
  * 2200: Meals, Entrees, and Side Dishes 
  * 2500: Snacks 
  * 3500: American Indian/Alaska Native Foods 
  * 3600: Restaurant Foods 
* `exclude_food`: Array with list of keywords. Exclude foods that have the such words in their description. Defaults to `["pickle", "pickled", "w/ added", "with added", "sweetened", "canned", "with artificial", "w/ artificial"]`.
"""
function get_diet(your_age, your_sex, your_weight, only_groups=[100, 500, 900, 1000, 1100, 1200, 1300, 1500, 1600, 1700, 2000], exclude_food = ["pickle", "pickled", "w/ added", "with added", "sweetened", "canned", "with artificial", "w/ artificial"])

	println("\nQuerying the database...\n")
	nutrs, dri, groups, foodids, foodnames, nfoods, nutamounts, calories, dri_ids, mins, maxs = loaddata(your_age, your_sex, your_weight; only_groups=only_groups);

  exclude_indices, exclude_ids = return_excluded_food_indices(nutrs, exclude_food, foodids)

	println("\nOptimizing...\n")
  m, status, objval, yval = optimize(mins, maxs, nutamounts, calories, dri_ids, nfoods, exclude_indices);
  
  println("\nOptimization status: $status \n")
  println("Calorie intake: $(round(Int, objval)) \n")
  
  println("\n\nYour recommended diet per day:\n")

	toeatindices = findall(a-> a>0, yval);
	toeatnames = foodnames[toeatindices];
	toeatids = foodids[toeatindices];
	toeactamounts = yval[toeatindices];
	foodlongname = find_longdes(nutrs, foodids);
  toeatlongnames = foodlongname[toeatindices];
  diet_ids = Int[]
  diet_names = String[]
  diet_amounts = Float64[]
  for (index, nameamount) in enumerate(zip(toeatnames, toeactamounts, toeatlongnames))
    # amounts are in 100 grams. So the * 100 here converts the recommended amounts to grams
    amountingrams = round(nameamount[2] * 100, digits=3)
    if amountingrams > 1
      push!(diet_ids, toeatids[index])
      push!(diet_names, nameamount[3])
      push!(diet_amounts, amountingrams)
    end
  end

  print_diet(diet_names, diet_amounts)

  return diet_ids, diet_names, diet_amounts
end

function print_diet(diet_names, diet_amounts)
  println("")
  for i in 1:length(diet_ids)
    println(i, ". ", diet_names[i], ": ", diet_amounts[i], " grams")
  end
end