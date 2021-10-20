#-----------------------------------------------------------------------------
## DATA LOADING

student <- read_csv("4. scripts/1. data/StudentsPerformance.csv")
set.seed(1)
student
table(duplicated(student))  

#-----------------------------------------------------------------------------
## GENEREL DATA SET INFO

glimpse(student)
skim(student)

#-----------------------------------------------------------------------------
## NAN'S VALUES IN DATA SET

naniar::gg_miss_upset(student)  
map(student, ~mean(is.na(.)))
