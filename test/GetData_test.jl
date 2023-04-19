
@testset "GetData functions tests" begin

datadir = "./sr28/"


@testset "getfooddes Tests" begin
  @test isdefined(DietRecommender, :getfooddes) == true
  fooddes = DietRecommender.getfooddes(datadir)
  @inferred DietRecommender.getfooddes(datadir)
  @test size(fooddes) ==  (8789, 5)
  colnames = ["food", "group", "longdes", "shortdes", "othernames"]
  @test names(fooddes) == colnames
end

@testset "getnutdata Tests" begin
  @test isdefined(DietRecommender, :getnutdata) == true
  nutdata = DietRecommender.getnutdata(datadir)
  @inferred DietRecommender.getnutdata(datadir)
  @test size(nutdata) == (100500, 4)
  colnames = ["food", "nut", "amount", "stderr"]
  @test names(nutdata) == colnames
end

@testset "getnutrdef Tests" begin
  @test isdefined(DietRecommender, :getnutrdef) == true
  nutrdef = DietRecommender.getnutrdef(datadir)
  @inferred DietRecommender.getnutrdef(datadir)
  @test size(nutrdef) == (150, 4)
  colnames = [:nut, :unit, :nuttag, :nutname]
  @test names(nutrdef) == String.(colnames)
  @test nutrdef[31, 2] == "ug"  # successfully converted UTF-8 values
end

end
