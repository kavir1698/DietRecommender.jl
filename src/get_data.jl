
"""
#Column descriptions:

* 1st: 5-digit Nutrient Databank number that uniquely identifies a food item. If this field is defined as numeric, the leading zero will be lost
* 2nd: 4-digit code indicating food group to which a food item belongs. (for details see FD_GROUP.txt).
* 3rd: long description. 200-character description of food item
* 4th: short description
* 5th: Other names commonly used to describe a food, including local or regional names for various foods, for example, “soda” or “pop” for “carbonated beverages.

For more info and description of other fields, see p. 30 of sr28_doc.pdf
"""
function getfooddes(data_folder; filename="FOOD_DES.txt")
  food_des_file = joinpath(data_folder, filename)

  food_des = CSV.read(food_des_file, DataFrame, header=0, delim='^', quotechar='~');
  food_des = food_des[:, 1:5];  # only the columns that I need
  colnames = [:food, :group, :longdes, :shortdes, :othernames]
  for cn in 1:size(food_des)[2]
    rename!(food_des, names(food_des)[cn] => colnames[cn])
  end
  return food_des
end

"""
The Nutrient Data file contains mean nutrient values per 100 g of the edible portion of food, along with fields to further describe the mean value.

#  Column descriptions:

* 1st: 5-digit Nutrient Databank number that uniquely identifies a food item.
* 2nd: Unique 3-digit identifier code for a nutrient
* 3rd: Amount in 100 grams, edible portion
* 4th:
* 5th: Standard error of the mean.

For more info and description of other fields, see p. 32 of sr28_doc.pdf
"""
function getnutdata(data_folder; filename="NUT_DATA.txt")
  nut_data_file = joinpath(data_folder, filename)
  nut_data = CSV.read(nut_data_file, DataFrame, header=0, delim='^', quotechar='~');
  nut_data = nut_data[:, [1,2,3,5]];
  colnames = [:food, :nut, :amount, :stderr]
  for cn in 1:size(nut_data)[2]
    rename!(nut_data, names(nut_data)[cn] => colnames[cn])
  end
  return nut_data
end

"""
This file (Table 9) is a support file to the Nutrient Data file. It provides the 3-digit nutrient code, unit of measure, INFOODS tagname, and description.

# Column descriptions:

* 1st: Unique 3-digit identifier code for a nutrient.
* 2nd: Units of measure (mg, g, μg, and so on).

For more info and description of other fields, see p. 34 of sr28_doc.pdf
"""
function getnutrdef(data_folder; filename="NUTR_DEF.txt")
  nutr_def_file = joinpath(data_folder, filename)

  nutr_def = CSV.read(nutr_def_file, DataFrame, header=0, delim='^', quotechar='~');
  nutr_def = nutr_def[:, 1:4];
  # convert values same as  nutr_def[31, 2] to ug (i.e. micrograms)
  udefvar = nutr_def[31, 2]
  udefrows = findall(a -> a == udefvar, nutr_def[:, 2])
  nutr_def[udefrows, 2] .= "ug"

  colnames = [:nut, :unit, :nuttag, :nutname]
  for cn in 1:size(nutr_def)[2]
    rename!(nutr_def, names(nutr_def)[cn] => colnames[cn])
  end
  return nutr_def
end

function get_food_groups(data_folder)
  group_file = joinpath(data_folder, "FD_GROUP.txt")
  groups = CSV.read(group_file, DataFrame, header=0, delim='^', quotechar='~');
  return groups
end

"""
applies the updates to the data files.
"""
function apply_updates(food_des, nut_data, updatedir)
  # add new data
  newfood = getfooddes(updatedir, filename="ADD_FOOD.txt")
  newnut = getnutdata(updatedir, filename="ADD_NUTR.txt")
  food_des = vcat(food_des, newfood)
  nut_data = vcat(nut_data, newnut)

  # apply changes to the data
  foodc = getfooddes(updatedir, filename="CHG_FOOD.txt")
  nutc = getnutdata(updatedir, filename="CHG_NUTR.txt")

  for rr in 1:size(foodc)[1]
    food_des[.&(food_des[!, 1] .== foodc[rr, 1], food_des[!, 2] .== foodc[rr, 2]), 3:end] = DataFrame(foodc[rr, 3:end])
  end

  for rr in 1:size(nutc)[1]
    nut_data[.&(nut_data[!, 1] .== nutc[rr, 1], nut_data[!, 2] .== nutc[rr, 2]), 3:end] = DataFrame(nutc[rr, 3:end])
  end

  # remove deleted entries in the update
  # foodd = getfooddes(updatedir, filename="DEL_FOOD.txt")
  nutd_file = joinpath(updatedir, "DEL_NUTR.txt")
  nutd = CSV.read(nutd_file, DataFrame, header=0, delim='^', quotechar='~');
  for rr in 1:size(nutd)[1]
    nut_data = nut_data[.~.&(nut_data[!, 1] .== nutd[rr, 1], nut_data[!, 2] .== nutd[rr, 2]), :]
  end

  # TODO: update weights too
  "ADD_WGT.txt"
  "CHG_WGT.txt"
  "DEL_WGT.txt"

  return food_des, nut_data
end

function fix_DRI_table(;dritable::String="dri.csv", data_folder::String="sr28asc")
  counter = 0
  newfields = []
  for line in eachline(open(dritable))
    counter += 1
    if counter > 1
      fields = split(line, ",")
      dri = fields[5]
      if endswith(dri, "*") || ismatch(r"\d+\D", dri)
        dri = dri[1:end-1]
      end
      entry = vcat(fields[1:4], [dri], fields[6:end])
      push!(newfields, entry)
    end
  end

  outfile = "dri_new.csv"
  j = open(outfile, "w")
  println(j, readline(open(dritable)))
  close(j)
  open(outfile, "a") do ff
    for item in newfields
      println(ff, join(item, ","))
    end
  end
  dd = CSV.read("dri_new.csv", DataFrame, header=1, delim=',')

  nutr_def = getnutrdef(data_folder);
  dd = CSV.read("dri_new.csv", DataFrame, header=1, delim=',');
  availables = Dict()
  notavailables = Set()
  nuts = levels(dd[!, :Nutrient])
  for rr in 1:size(nuts)[1]
    item = nuts[rr]
    found = false
    for r2 in 1:size(nutr_def)[1]
      if contains(lowercase(nutr_def[r2, :nutname]), lowercase(item))
        if haskey(availables, item)
          push!(availables[item], nutr_def[r2, :nut])
        else
          availables[item] = [nutr_def[r2, :nut]]
          found = true
        end
      end
    end
    if ~found
      push!(notavailables, item)
    end
  end
  
end

"""
Load the cleaned and read dri table
"""
function load_dri(;filepath="dri_new.csv")
  dri = CSV.read(filepath, DataFrame, header=1, delim=',', missingstring="NA")
  return dri
end

"""
getnutdata(data_folder)

Return `nutrs` (a dataframe of the data), `dri` (a dataframe of recommended dosages), and `groups` (food groups).

Extracts data from SR28 database (https://www.ars.usda.gov/northeast-area/beltsville-md/beltsville-human-nutrition-research-center/nutrient-data-laboratory/docs/sr28-download-files/)

The four principal database files are the Food Description file, Nutrient Data file, Gram Weight file, and Footnote file.
"""
function allnutdata(;data_folder::String="./data/sr28asc", dri_file::String="./data/dri_new.csv", updatedir::String="")
  if ~isdir(data_folder)
    throw("Data directory does not exist.")
  end

  data_folder = abspath(data_folder)

  food_des = getfooddes(data_folder);
  nut_data = getnutdata(data_folder);
  nutr_def = getnutrdef(data_folder);
  # Option: get data from Weight File (file name = WEIGHT). This file (Table 12) contains the weight in grams of a number of common measures for each food item (p. 36)

  # apply updates
  if length(updatedir) > 0
    food_des, nut_data = apply_updates(food_des, nut_data, updatedir)
  end

  df1 = innerjoin(food_des, nut_data, on=:food);
  nutrs = innerjoin(df1, nutr_def, on=:nut);

  dri = load_dri(filepath=dri_file);
  groups = get_food_groups(data_folder);

  # convert all units to grams
  dri = convert_units_to_g(dri, Symbol("Unit(/d)"), [:DRI, :Upper_intake]);
  nutrs = convert_units_to_g(nutrs, :unit, [:amount]);

  return nutrs, dri, groups
end

"""
Returns lists of min and max required nutrients and lists of foods and their nutrients.

# Parameters:

* weight: in kg.
"""
function get_min_max(dri; age=22, sex="male", weight=70)
  if sex == "male" || sex == "m" || sex == "M"
    sex = "Male"
  elseif sex == "female" || sex == "f" || sex == "F"
    sex = "Female"
  end

  select_dri = @from i in dri begin
    @where getproperty(i, Symbol("AgeMin(year)")) <= age
    @where getproperty(i, Symbol("AgeMax(year)")) > age
    # @where typeof(i.id) <: Number
    @where i.Sex == sex || i.Sex == "Neutral"  # TODO: add pregnancy and lactation
    @select i #{i.DRI, i.Unit_d_, i.Upper_intake, i.id}
    @collect DataFrame
  end

  select_dri = select_dri[.~ismissing.(select_dri[!, :id]), :];

  minlist = select_dri[!, :DRI]
  maxlist = select_dri[!, :Upper_intake]
  dri_ids = select_dri[!, :id]

  # Remove the upper levels where the refernce intakes (minlist) are more than the upper levels (max list). This is from the data. In these cases, the upper intake is for intaking from supplements not from food. So it is safe to remove the upper intake in those cases.
  for rr in 1:length(minlist)
    if !ismissing(minlist[rr]) && !ismissing(maxlist[rr]) && minlist[rr] > maxlist[rr]
      maxlist[rr] = missing
    end
  end

  # fill the missing values
  mins_refilled = Float64[]
	for mm in minlist
		if ismissing(mm)
			push!(mins_refilled, 0.0)
		else
			push!(mins_refilled, mm)
		end
	end
	maxs_refilled = Float64[]
	for mm in maxlist
		if ismissing(mm)
			push!(maxs_refilled, 1e8)
		else
			push!(maxs_refilled, mm)
		end
  end

  # adjust those nutrients whose unit is g/kg to the body weight.
  for index in 1:length(mins_refilled)
    if select_dri[index, Symbol("Unit(/d)")] == "g/kg"
      if mins_refilled[index] != 0
        mins_refilled[index] = weight * mins_refilled[index]
      end
      if maxs_refilled[index] != 1e8
        maxs_refilled[index] = weight * maxs_refilled[index]
      end
    end
  end

  return dri_ids, mins_refilled, maxs_refilled
end

function pushtolist!(list::T, topush::Y, index::Z) where {T<:AbstractArray, Y<:AbstractArray, Z<:Integer}
  if length(topush) >0
    push!(list[index], topush[1])
  else
    push!(list[index], 0.0)
  end
end

"Returns a list of lists, where each inner list is the amount of nutrients in a food"
function getnutamounts(nfoods, foodids, dri_ids, nutrs)
  nutamounts = [Float64[] for i in 1:nfoods]
  prog = ProgressMeter.Progress(nfoods)
  for index in 1:nfoods
    foodid = foodids[index]
    for nutid in dri_ids
      nutamount = nutrs[.&(nutrs[!, :food] .== foodid, nutrs[!, :nut] .== nutid), :amount]
      pushtolist!(nutamounts, nutamount, index)
      # if length(nutamount) > 1
      #   warn("More than one nutrient ($nutid) for food ($foodid)")
      # end
    end
    next!(prog)
  end
  return nutamounts
end

"""
    loaddata(your_age, your_sex, your_weight; only_groups=[])

Return `nutrs`, `dri`, `groups`, `foodids`, `foodnames`, `nfoods`, `nutamounts`, `calories`, `dri_ids`, `mins`, `maxs`. They containt the following information:

* `nutrs:` list of foods. A table with the following columns: food (name of food), group (food group), longdes (long food description), shortdes (short food description), othernames, nut (id of a nutrition in the food), amount (amount of the nutrition in 100 g of edible food), stderr (standard error of the amount of the nutrition), unit (unit of the amount of the nutrition), nuttag (nutrition id), nutname (nutrition name).
* `dri:` recommended range of nutritions for various groups. A tale with the following columns: sex, AgeMin(year), AgeMax(year), Nutrient (nutrient name), DRI (recommended amound), Unit(/d)(unit of the recommended amount per day), DRI available (whether there is strong evidence for DRI), Upper intake (maximum amount before it's dangerous), id (nutrition id)
* `groups:` A list of food groups (second column) and their ids (first column).
* `foodids:` A list of all food IDs.
* `foodnames:` A list of all food names, with the same order as `foodids`.
* `nutamounts:` A list of lists, where each inner list has all the nutrient amounts per food. It has the same order as `foodids`.
* `calories:` calories in each food.
* `dri_ids:` A list of nutrient IDs.
* `mins:` The minimum recommended amount for each nutrient in grams per day. It has the same order as `dri_ids`.
* `maxs:` The maximum recommended amount for each nutrient in grams per day. It has the same order as `dri_ids`.
"""
function loaddata(your_age, your_sex, your_weight; only_groups=[])
  # mkpath("../data")
  if !isfile("all_opt_inputs_$(your_age)_$(your_sex).serialized")
    nutrs, dri, groups = allnutdata(data_folder="./data/sr28asc", dri_file="./data/dri_new.csv", updatedir="./data/SR28upd0516");
    foodids = unique(nutrs[!, :food]);
    foodnames = unique(nutrs[!, :shortdes]);
    nfoods = length(foodids)
    dri_ids, mins, maxs = get_min_max(dri, age=your_age, sex=your_sex, weight=your_weight);

    if length(only_groups) > 0
      select_rows = Array{Int64}(undef, 0)
      for rr in 1:size(nutrs)[1]
          if in(nutrs[rr, :group], only_groups) && (in(nutrs[rr, :nut], dri_ids) || nutrs[rr, :nut] .== 208)
          push!(select_rows, rr)
        end
      end
    
      foodids_org = deepcopy(nutrs[!, :food]);
      nutrs = nutrs[select_rows, :];
      foodids = unique(nutrs[!, :food]);
      foodnames = unique(nutrs[!, :shortdes]);
      nfoods = length(foodids);

      calories = Float64[] # calories in each food
      for index in 1:nfoods
        foodid = foodids[index]
        calorie = nutrs[.&(nutrs[!, :food] .== foodid, nutrs[!, :nut] .== 208), :amount]
        push!(calories, calorie[1])
      end
      nutamounts = getnutamounts(nfoods, foodids, dri_ids, nutrs);
    else
      nutamounts = getnutamounts(nfoods, foodids, dri_ids, nutrs)
      calories = Float64[] # calories in each food
      for index in 1:nfoods
        foodid = foodids[index]
        calorie = nutrs[.&(nutrs[!, :food] .== foodid, nutrs[!, :nut] .== 208), :amount]
        push!(calories, calorie[1])
      end
    end

    serialize("all_opt_inputs_$(your_age)_$(your_sex).serialized", [nutrs, dri, groups, foodids, foodnames, nfoods, nutamounts, calories, dri_ids, mins, maxs])
  else
    nutrs, dri, groups, foodids, foodnames, nfoods, nutamounts, calories, dri_ids, mins, maxs = deserialize("all_opt_inputs_$(your_age)_$(your_sex).serialized");
  end

  return nutrs, dri, groups, foodids, foodnames, nfoods, nutamounts, calories, dri_ids, mins, maxs
end

"Converts mg to g"
function mg_to_g(value::T) where T<:Real
  return value/T(1000)
end

"Converts ug to g"
function ug_to_g(value::T) where T<:Real
  return value/T(1000_000)
end

"Converts kg to g"
function kg_to_g(value::T) where T<:Real
  return value*T(1000)
end

"Converts mg to g"
function mg_to_g!(dd::AbstractDataFrame, unitcolumn::Symbol, columns::AbstractArray{Symbol, 1}, unit::AbstractString)
  for col in columns
    dd[dd[!, unitcolumn] .== unit, col] = mg_to_g.(dd[dd[!, unitcolumn] .== unit, col])
  end
end

"Converts ug to g"
function ug_to_g!(dd::AbstractDataFrame, unitcolumn::Symbol, columns::AbstractArray{Symbol, 1}, unit::AbstractString)
  for col in columns
    dd[dd[!, unitcolumn] .== unit, col] = ug_to_g.(dd[dd[!, unitcolumn] .== unit, col])
  end
end

"Converts kg to g"
function kg_to_g!(dd::AbstractDataFrame, unitcolumn::Symbol, columns::AbstractArray{Symbol, 1}, unit::AbstractString)
  for col in columns
    dd[dd[!, unitcolumn] .== unit, col] = kg_to_g.(dd[dd[!, unitcolumn] .== unit, col])
  end
end

"Converts mg to g"
function mg_to_g(value::Missing)
  return value
end

"Converts ug to g"
function ug_to_g(value::Missing)
  return value
end

"Converts kg to g"
function kg_to_g(value::Missing)
  return value
end

"""
    convert_units_to_g!(d::AbstractDataFrame, unitcolumn::Symbol, columns::AbstractArray{Symbol, 1})

Converts the values in columns `columns` to g or ml.
"""
function convert_units_to_g(d::AbstractDataFrame, unitcolumn::Symbol, columns::AbstractArray{Symbol, 1})
  current_values = unique(d[!, unitcolumn])
  d = DataFrame(d);
  for vvs in current_values
    if vvs == "g"
      continue
    end
    if vvs == "\xb5g"
      vv = "ug"
    else
      vv = lowercase(vvs)
    end
    
    if vv == "kg" || vv == "l"
      kg_to_g!(d, unitcolumn, columns, vvs)
      d[d[!, unitcolumn] .== vvs, unitcolumn] .= "g"
    elseif vv == "ug"
      ug_to_g!(d, unitcolumn, columns, vvs)
      d[d[!, unitcolumn] .== vvs, unitcolumn] .= "g"
    elseif vv == "mg" || vv == "mg/kg"
      mg_to_g!(d, unitcolumn, columns, vvs)
      if vv == "mg/kg"
        d[d[!, unitcolumn] .== vvs, unitcolumn] .= "g/kg"
      else
        d[d[!, unitcolumn] .== vvs, unitcolumn] .= "g"
      end
    end
  end
  return d
end


"""
    return_excluded_food_indices(nutrs, exclude_list, foodids)

Return a list of `indices` and `ids` of foods in which the words in `exclude_list` exist.
Use this list to set their amount to zero in the optimization process.
"""
function return_excluded_food_indices(nutrs, exclude_list, foodids)
  ids = Set{Int64}()
  for ex in exclude_list
    for row in 1:size(nutrs, 1)
      if occursin(ex, lowercase(nutrs[row, :longdes]))
        push!(ids, nutrs[row, :food])
      end
    end
  end
  ids = sort(collect(ids))
  indices = Int64[]
  for (index, id) in enumerate(foodids)
    if in(id, ids)
      push!(indices, index)
    end
  end
  return indices, ids
end

"""
Returns foods' `longdes` given their ids
"""
function find_longdes(nutrs, foodids)
  foodlongnames = AbstractString[]
  for id in foodids
    longdes = nutrs[nutrs[!, :food] .== id, :longdes][1]
    push!(foodlongnames, longdes)
  end
  return foodlongnames
end

"""
Returns foods groups given their ids
"""
function find_groups(nutrs, foodids)
  foodgroup = Int64[]
  for id in foodids
    groupid = nutrs[nutrs[!, :food] .== id, :group][1]
    push!(foodgroup, groupid)
  end
  return foodgroup
end

function constraints(dri, dri_ids, mins, maxs)
  nutrient_name_ids = [findfirst(x -> .&(!ismissing(dri.id[x]), dri.id[x] == id), 1:size(dri, 1)) for id in dri_ids]
  nutrient_names = dri[nutrient_name_ids, :Nutrient]
  return DataFrame(:nutrient => nutrient_names, :nutrient_id => dri_ids, Symbol("min(g)") => mins, Symbol("max (g)") => maxs)
end

function exclude_nutrients(dri_ids, mins, maxs, nutamounts, exclude_ids)
  new_rows = findall(x-> !in(x, exclude_ids), dri_ids)
  dri_ids = dri_ids[new_rows]
  mins = mins[new_rows]
  maxs = maxs[new_rows]
  for food in 1:length(nutamounts)
    nutamounts[food] = nutamounts[food][new_rows]
  end
  return dri_ids, mins, maxs, nutamounts
end