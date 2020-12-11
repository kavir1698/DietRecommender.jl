# DietRecommender.jl

Create a diet with minimum energies while fulfilling all recommended micro- and macro-nutrition elements. Using USDA's food composition database and linear programming, it finds a personalized diet given your age, sex and weight with which you fulfill all recommended daily micro- and macro-nutritional doses and take the minimum calories.

## Example

```julia
using DietRecommeder

your_age = 22
your_sex = "male"
your_weight = 70

diet_ids, diet_names, diet_amounts = get_diet(your_age, your_sex, your_weight)
```

```md
Optimization status: LOCALLY_SOLVED 

Calorie intake: 5279.957465715046 

Your recommended diet per day:


1. Raisins, seedless: 1489.284 grams
2. Asparagus, cooked, boiled, drained: 324.472 grams
3. Beans, snap, green, raw: 463.388 grams
4. Butterbur, cooked, boiled, drained, without salt: 2126.634 grams
5. Cucumber, peeled, raw: 101.094 grams
6. Asparagus, cooked, boiled, drained, with salt: 85.661 grams
7. Butterbur, cooked, boiled, drained, with salt: 11.372 grams
8. Carrots, cooked, boiled, drained, with salt: 298.302 grams
9. Waxgourd, (chinese preserving melon), cooked, boiled, drained, with salt: 71.164 grams
10. Mushrooms, portabella, exposed to ultraviolet light, raw: 52.429 grams
11. Beef, variety meats and by-products, brain, cooked, simmered: 4.443 grams
12. Crustaceans, shrimp, mixed species, cooked, breaded and fried: 100.296 grams
13. Mollusks, oyster, eastern, wild, raw: 72.081 grams
```

## Installation

Type the following in a Julia REPL.

```julia
] add https://github.com/kavir1698/DietRecommender.jl
```
