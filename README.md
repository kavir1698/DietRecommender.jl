# DietRecommender.jl

Create a diet with minimum calorie intake while fulfilling all recommended micro- and macro-nutrients. Using USDA's food composition database and linear programming, it finds a personalized diet given your age, sex and weight with which you fulfill all recommended daily micro- and macro-nutrients with minimum calories.

The recommended diet is personalized on your age, sex, and weight, and also on your food preferences. You can exclude specific foods or complete food categories. It is also possible to exclude nutrients from constraints.

> Currently, the minimum calories of a diet that fulfills all recommended nutrients is much more than the recommended calorie intake. I am not sure why this happens. Possibly it is a result of recommended daily intake values, which cannot be fulfilled without taking too much calories. I welcome any comments about this issue.

## Example

```julia
using DietRecommender

your_age = 22
your_sex = "male"
your_weight = 70 # in kilograms

diet_ids, diet_names, diet_amounts, m, status, objval, yval = get_diet(your_age, your_sex, your_weight)
```

```md
Optimization status: LOCALLY_SOLVED 

Calorie intake: 5054 

Your recommended diet per day:


1. Egg, yolk, dried: 2.454 grams
2. Raisins, seedless: 1514.629 grams
3. Asparagus, cooked, boiled, drained: 232.107 grams
4. Spinach, cooked, boiled, drained, without salt: 109.184 grams
5. Asparagus, cooked, boiled, drained, with salt: 152.499 grams
6. Carrots, cooked, boiled, drained, with salt: 199.236 grams
7. Mushrooms, shiitake, cooked, with salt: 14.097 grams
8. Spinach, cooked, boiled, drained, with salt: 87.436 grams
9. Mushrooms, brown, italian, or crimini, exposed to ultraviolet light, raw: 45.555 grams
10. Crustaceans, shrimp, mixed species, cooked, breaded and fried: 104.196 grams
11. Mollusks, oyster, eastern, wild, cooked, dry heat: 49.396 grams
```

## Installation

Type the following in a Julia REPL.

```julia
] add https://github.com/kavir1698/DietRecommender.jl
```
