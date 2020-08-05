source("R/tests/coverage.R")
source("R/tests/build_csv.R")
callTest<-function()
{
build_csv()
#do_consistency_test("chebi", 20)
}
