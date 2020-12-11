export get_diet

"""
    get_diet(your_age, your_sex, your_weight; kwargs)

Return a personalized list of foods and their recommended intake amount in grams per day to fulfill all your nutritional requirements with minimum calories. `your_age` is in years, `your_sex` can be `male` or `female`, `your_weight` is in kilograms.

## kwargs:

* `only_groups`: Array with list of food group IDs. Only include foods in in these categories. Defaults to `[100, 500, 900, 1000, 1100, 1200, 1300, 1500, 1600, 1700, 2000]`. Here is a list of all IDs and their corresponding food category:
  1. 0100: Dairy and Egg Products
  1. 0200: Spices and Herbs 
  1. 0300: Baby Foods 
  1. 0400: Fats and Oils 
  1. 0500: Poultry Products 
  1. 0600: Soups, Sauces, and Gravies 
  1. 0700: Sausages and Luncheon Meats 
  1. 0800: Breakfast Cereals 
  1. 0900: Fruits and Fruit Juices 
  1. 1000: Pork Products 
  1. 1100: Vegetables and Vegetable Products 
  1. 1200: Nut and Seed Products 
  1. 1300: Beef Products 
  1. 1400: Beverages 
  1. 1500: Finfish and Shellfish Products 
  1. 1600: Legumes and Legume Products 
  1. 1700: Lamb, Veal, and Game Products 
  1. 1800: Baked Products 
  1. 1900: Sweets 
  1. 2000: Cereal Grains and Pasta 
  1. 2100: Fast Foods 
  1. 2200: Meals, Entrees, and Side Dishes 
  1. 2500: Snacks 
  1. 3500: American Indian/Alaska Native Foods 
  1. 3600: Restaurant Foods 
* `exclude_food`: Array with list of keywords. Exclude foods that have the such words in their description. Defaults to `["pickle", "pickled", "w/ added", "with added", "sweetened", "canned", "with artificial", "w/ artificial"]`.
* 'excluded_nutrients'=[]: Provide a list of IDs of nutrients not to be considered as a constraint to be fulfilled. By default the list is empty, and the following nutrients and their minimum and maximum recommened daily intakes are taken as constrains.
    * nutrient                : nutrient id 
    1. Calcium                : 301         
    1. Carbohydrate           : 205         
    1. Choline                : 421         
    1. Copper                 : 312         
    1. Fluoride               : 313         
    1. Folate                 : 417         
    1. Histidine              : 512         
    1. Iron                   : 303         
    1. Isoleucine             : 503         
    1. Leucine                : 504         
    1. Lysine                 : 505         
    1. Magnesium              : 304         
    1. Manganese              : 315         
    1. Methionine+cysteine    : 506         
    1. Niacin                 : 406         
    1. Pantothenic Acid       : 410         
    1. Phenylalanine+tyrosine : 508         
    1. Phosphorus             : 305         
    1. Potassium              : 306         
    1. Protein                : 203         
    1. Riboflavin             : 405         
    1. Selenium               : 317         
    1. Sodium                 : 307         
    1. Thiamin                : 404         
    1. Threonine              : 502         
    1. Total Fiber            : 291         
    1. Tryptophan             : 501         
    1. Valine                 : 510         
    1. Vitamin A              : 320         
    1. Vitamin B12            : 418         
    1. Vitamin B6             : 415         
    1. Vitamin C              : 401         
    1. Vitamin D              : 328         
    1. Vitamin E              : 323         
    1. Vitamin K              : 430         
    1. Zinc                   : 309         
"""
function get_diet(your_age, your_sex, your_weight; only_groups=[100, 500, 900, 1000, 1100, 1200, 1300, 1500, 1600, 1700, 2000], exclude_food = ["pickle", "pickled", "w/ added", "with added", "sweetened", "canned", "with artificial", "w/ artificial"], excluded_nutrients=[])

	println("\nQuerying the database...\n")
	nutrs, dri, groups, foodids, foodnames, nfoods, nutamounts, calories, dri_ids, mins, maxs = loaddata(your_age, your_sex, your_weight; only_groups=only_groups);

  exclude_indices, exclude_ids = return_excluded_food_indices(nutrs, exclude_food, foodids)
  dri_ids, mins, maxs = exclude_nutrients(dri_ids, mins, maxs, [255, 204])
  dri_ids, mins, maxs = exclude_nutrients(dri_ids, mins, maxs, excluded_nutrients)

	println("\nOptimizing...\n")
  m, status, objval, yval = optimize(mins, maxs, nutamounts, calories, dri_ids, nfoods, exclude_indices);
  
  println("\nOptimization status: $status \n")
  if isnan(objval)
    return
  end
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
  for i in 1:length(diet_names)
    println(i, ". ", diet_names[i], ": ", diet_amounts[i], " grams")
  end
end