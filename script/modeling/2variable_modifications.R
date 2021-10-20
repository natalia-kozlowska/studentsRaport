
#-----------------------------------------------------------------------------
## 1. VARIABLE MODIFICATION
### 1.1 CHANGE TYPE IN VALUES 

student <- student %>%
  mutate_if(is.character, as.factor)

#-----------------------------------------------------------------------------
## 1. VARIABLE MODIFICATION
### 1.2 RENAMING COLUMNS

student <- student %>% 
  rename(
    race = `race/ethnicity`,
    parental_education = `parental level of education`,
    test_preparation = `test preparation course`,
    math_score = `math score`,
    reading_score  = `reading score`,
    writing_score = `writing score`)

#-----------------------------------------------------------------------------
## 1. VARIABLE MODIFICATION
### 1.3 CREATE NEW COLUMN - AVERAGE OF ALL THREE EXAMS

student$exsams_avg = (student$math_score + student$reading_score + 
                        student$writing_score) / 3
