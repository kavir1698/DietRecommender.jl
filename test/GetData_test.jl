
@testset "GetData functions tests" begin

datadir = "./sr28/"


@testset "getfooddes Tests" begin
  @test isdefined(FoodRecom, :getfooddes) == true
  fooddes = FoodRecom.getfooddes(datadir)
  @inferred FoodRecom.getfooddes(datadir)
  @test size(fooddes) ==  (8789, 5)
  colnames = [:food, :group, :longdes, :shortdes, :othernames]
  @test names(fooddes) == colnames
end

@testset "getnutdata Tests" begin
  @test isdefined(FoodRecom, :getnutdata) == true
  nutdata = FoodRecom.getnutdata(datadir)
  @inferred FoodRecom.getnutdata(datadir)
  @test size(nutdata) == (100500, 4)
  colnames = [:food, :nut, :amount, :stderr]
  @test names(nutdata) == colnames
end

@testset "getnutrdef Tests" begin
  @test isdefined(FoodRecom, :getnutrdef) == true
  nutrdef = FoodRecom.getnutrdef(datadir)
  @inferred FoodRecom.getnutrdef(datadir)
  @test size(nutrdef) == (150, 4)
  colnames = [:nut, :unit, :nuttag, :nutname]
  @test names(nutrdef) == colnames
  @test nutr_def[31, 2] == "ug"  # successfully converted UTF-8 values
end

@testset "allnutdata Tests" begin
  @test isdefined(FoodRecom, :allnutdata) == true
  nutrdef = FoodRecom.allnutdata(data_folder=datadir)
  @inferred FoodRecom.allnutdata(data_folder=datadir)
  @test size(nutrdef) == (100500, 11)
end


end
