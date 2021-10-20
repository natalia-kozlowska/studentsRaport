
#-----------------------------------------------------------------------------
## LOANDING PACKAGES 

library("tidyverse")
library("skimr")
library("lubridate")
library("rpart") 
library("recipes")
library("caret")

library("naniar")
library("tidyverse")
library("caret")
library("skimr")
library("lubridate")
library("descr")
library("precrec")
library("lubridate")
library("readxl")
library("ggplot2movies")
library("data.table")
library("dplyr")
library("ggplot2")
library("gridExtra")
library("naniar")
library("mosaic") 
library("descr") 
library("viridis") 
library("scales") 
library("RColorBrewer")
library("randomForest")
library("partykit") # lepsze rysunki dla drzew regresyjnych

#-----------------------------------------------------------------------------
## LOANDING DATA

student <- read_csv("StudentsPerformance.csv")

set.seed(1)
student
table(duplicated(student)) 

#-------------------------------------------------------------------------------
## SPOJRZENIE NA ILOSC DANYCH 

glimpse(student)
skim(student)

#-----------------------------------------------------------------------------
## CREATING TRAIN / TEST 

student_gender <- createDataPartition(y = student$gender, 
                                      p = 0.7, list = FALSE)

train.student <- dplyr::slice(student, student_gender)
dim(train.student) 

test.student <- dplyr::slice(student, -student_gender)
dim(test.student) 

#----------------------------------------------------------------------------
## MODELING
### Cross validation

controls_student <- trainControl(
  method = "repeatedcv", number = 5, repeats = 3,
  verboseIter = TRUE,
  summaryFunction = twoClassSummary, classProbs = TRUE
)

prep <- preProcess(train.student, method = c("center", "scale", "medianImpute"))
train.student <- predict(prep, train.student)

#----------------------------------------------------------------------------
## MODELING
### 1. LOGISTIC REGRESSION

(student_glm <- train(gender ~ . -exsams_avg, train.student, method = "glm", 
                      family = "binomial",
                      trControl = controls_student, metric = "ROC"))

summary(student_glm$finalModel) 
car::vif(student_glm$finalModel) 
confusionMatrix(student_glm) 

varImp(student_glm) 

p_est2 <- predict(student_glm, type = 'prob')$male
y_est2 <- ifelse(p_est2 > 0.5, 'male', 'female')             
mean(y_est2 == train.student$gender)

eval_student2 <- evalmod(scores = p_est2, labels = train.student$gender, 
                         posclass = NULL)
autoplot(eval_student2)

descr::crosstab(y_est2, train.student$gender) 

#write_rds(m_glm, "models/m_glm.rds") # 900 MB
# m_glm <- read_rds("models/m_glm.rds")

#----------------------------------------------------------------------------
## MODELING
### 2. RPART

y <- select(train.student, gender) %>% pull() #dummy
X <- select(train.student, -gender) %>% as.data.frame()
(student_rpart <- train(X, y, method = "rpart", 
                        trControl = controls_student, metric = "ROC",
                        tuneGrid = data.frame(cp = c(0.001, 0.009, 0.0001))))

varImp(student_rpart)
student_rpart$finalModel %>% rpart::prune(cp = 0.009) %>% 
  rpart.plot::rpart.plot(cex = 0.5)

#----------------------------------------------------------------------------
## MODELING
### 3. KNN

(student_knn <- train(gender ~ math_score + writing_score + 
                    reading_score, train.student, method = "knn", 
                    trControl = controls_student, metric = "ROC",
                    tuneGrid = data.frame(k = c(25,35))))

#y <- select(train.student, gender) %>% pull()
#X_dummy <- train.student %>%
 #  select(-gender) %>%
  # fastDummies::dummy_cols() %>% #2.
   #select_if(is.numeric) %>%
   # as.data.frame()

# (student_knn <- train(X_dummy, y, method = "knn",
#                       trControl = controls_student, metric = "ROC",
#                       tuneGrid = data.frame(k = c(25,30, 35))))

varImp(student_knn)

#------------------------------------------------------------------------------
## MODELING
### 4. RANDOM FOREST 

(student_forest2 <- train(X,y, method = "rf", 
               trControl = trainControl(
                  method = "repeatedcv", number = 5, repeats = 1,
                  verboseIter = TRUE,
                  summaryFunction = twoClassSummary, classProbs = TRUE,
               ), metric = "ROC", tuneGrid = data.frame(mtry = c(2,4,6,8))
))


student_forest2$results

partial(student_forest2, pred.var = c("math_score"), plot = TRUE, rug = TRUE,
        prob = TRUE, which.class = 2)

#------------------------------------------------------------------------------
## MODELING
### 5. GBOOSTING

(student_gbm <- train(gender ~ ., train.student, method = "gbm", verbose = FALSE,
                      trControl = trainControl(
                         method = "repeatedcv", number = 5, repeats = 1,
                         verboseIter = TRUE,
                         summaryFunction = twoClassSummary, classProbs = TRUE,
                      ), metric = "ROC",))

#------------------------------------------------------------------------------
## MODELING
### 6. XGBOOST

(student_xgb <- train(gender ~ ., train.student, method = "xgbTree",
                      trControl = trainControl(
                         method = "repeatedcv", number = 5, repeats = 1,
                         verboseIter = TRUE,
                         summaryFunction = twoClassSummary, classProbs = TRUE,
                      ), metric = "ROC",))

student_xgb$results %>% slice_max(ROC, n =5)

#-----------------------------------------------------------------------------
#4.

test.student <- predict(prep, test.student)

#5.
results <- tibble(
   glm = predict(student_glm, test.student, type = "prob")$male,
   knn = predict(student_knn, test.student, type = "prob")$male,
   rpart = predict(student_rpart, test.student, type = "prob")$male,
   rforest = predict(student_forest2, test.student, type = "prob")$male,
   gboosting = predict(student_gbm, test.student, type = "prob")$male,
   xgboosting = predict(student_xgb, test.student, type = "prob")$male,
   gender = test.student$gender
)

# map(select(results, -gender), postResample, obs = results$gender)

# map(results %>% select(-gender), postResample, obs = results$gender)
# 
# results %>% 
#    select(-gender) %>% 
#    map(postResample, obs = results$gender)


auc <- evalmod(
   scores = list(results$glm, results$rpart, results$knn, results$rforest, 
                 results$gboosting, results$xgboosting),
   labels = results$gender
)
autoplot(auc)
auc
ggplot(results, aes(glm, fill = gender)) + geom_density(alpha = 0.5)
ggplot(results, aes(knn, fill = gender)) + geom_density(alpha = 0.5)
ggplot(results, aes(rpart, fill = gender)) + geom_density(alpha = 0.5)
ggplot(results, aes(rforest, fill = gender)) + geom_density(alpha = 0.5)
ggplot(results, aes(gboosting, fill = gender)) + geom_density(alpha = 0.5)
ggplot(results, aes(xgboosting, fill = gender)) + geom_density(alpha = 0.5)


results %>% 
   gather(key = "model", value = "prob", 1:5) %>% #6.
   filter(gender == "male") %>% 
   ggplot(aes(prob, fill = model)) + geom_density(alpha = 0.5)

