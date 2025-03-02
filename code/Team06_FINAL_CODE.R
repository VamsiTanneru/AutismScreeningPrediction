rm(list=ls()); gc()
# Load necessary libraries
library(tidyverse)
library(Amelia)
library(caret)
library(ROSE)
library(ggplot2)
library(corrplot)
library(reshape2)
library(fastDummies)
library(rpart)
library(rpart.plot)
library(FNN)

setwd("C:/Users/vamsi.tanneru/Documents/data")

# Load the CSV file
dat <- read.csv("autism_screening.csv", stringsAsFactors = TRUE, header = TRUE)

# View the first few rows of the dataset
head(dat)

# Drop the 'age_desc', 'ID'
dat <- dat[, !(colnames(dat) %in% c("age_desc", "ID"))]

summary(dat)

# Define numeric and categorical variables
numeric_vars <- c("A1_Score", "A2_Score", "A3_Score", "A4_Score", "A5_Score", 
                  "A6_Score", "A7_Score", "A8_Score", "A9_Score", "A10_Score", "age", "result", "Class.ASD")
categorical_vars <- c("gender", "ethnicity", "jaundice", "austim", "used_app_before", "relation")

# Function to plot numeric variables using histograms
plot_numeric_vars <- function(data, vars) {
  for (var in vars) {
    p <- ggplot(data, aes(x = !!sym(var))) +
      geom_histogram(bins = 30, fill = "steelblue", color = "black") +
      labs(title = paste("Histogram of", var), x = var, y = "Count") +
      theme_minimal()
    print(p)
  }
}

# Function to plot categorical variables using bar charts
plot_categorical_vars <- function(data, vars) {
  for (var in vars) {
    p <- ggplot(data, aes(x = !!sym(var), fill = !!sym(var))) +
      geom_bar() +
      labs(title = paste("Bar Chart of", var), x = var, y = "Count") +
      theme_minimal() +
      theme(legend.position = "none")
    print(p)
  }
}

# Execute plotting functions
plot_numeric_vars(dat, numeric_vars)
plot_categorical_vars(dat, categorical_vars)

plot_large_category_variable <- function(data, var_name, threshold = 20) {
  # Count frequencies and lump categories with few observations into 'Other'
  freq <- data %>% 
    count(!!sym(var_name)) %>%
    mutate(category = ifelse(n < threshold, "Other", as.character(!!sym(var_name)))) %>%
    group_by(category) %>%
    summarise(count = sum(n), .groups = 'drop')
  
  # Plot with horizontal layout
  ggplot(freq, aes(x = reorder(category, count), y = count, fill = category)) +
    geom_bar(stat = "identity") +
    labs(title = paste("Distribution of", var_name), x = var_name, y = "Count") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1),  # Adjust text alignment if needed
          legend.position = "none") +
    coord_flip()  # Make it horizontal for better label readability
}

# Plotting 'contry_of_res' with adjustments
plot_large_category_variable(dat, "contry_of_res", threshold = 5)  # Adjust threshold based on your data

# Drop the 'used_app_before', 'contry_of_res' columns
dat <- dat[, !(colnames(dat) %in% c("used_app_before", "contry_of_res", "result"))]

# Handling missing and incorrect values ('relation' and 'ethnicity' have "?")
dat$relation[dat$relation == "?"] <- NA
dat$ethnicity[dat$ethnicity == "?"] <- NA

# Check missing values pattern by heatmap
matrix.na <- is.na(dat)
pmiss <- colMeans(matrix.na)
nmiss <- rowMeans(matrix.na)
plot(pmiss)
missmap(dat)

# Remove columns with more than 20% missing data
dat1 <- dat[, pmiss < 0.2]
dat2 <- na.omit(dat1)

# Check distribution of continuous variables ('age')
par(mfrow = c(1, 2))
hist(dat2$age)
boxplot(dat2$age)
par(mfrow = c(1, 1))

# Outlier handling
dat2 <- dat2[dat2$age <= quantile(dat2$age, 0.95), ]
dat3 <- dat2

cat_vars <- c('gender', 'ethnicity', 'jaundice', 'austim', 'relation')

# Add 'Other' to the levels of the factor
levels(dat2$ethnicity) <- c(levels(dat2$ethnicity), "Other")
levels(dat2$relation) <- c(levels(dat2$relation), "Other")

# Combine low obs categories 
dat2$ethnicity[dat2$ethnicity %in% c('Asian', 'Black', 'Hispanic', 'Latino', 'others', 'Pasifika', 'South Asian', 'Turkish')] <- 'Other'

# Combine low obs categories
dat2$relation[dat2$relation %in% c('Health care professional', 'others', 'Others')] <- 'Other'


# Create dummy variables for remaining categorical variables
for (var in cat_vars) {
  dat2 <- dummy_columns(dat2, select_columns = var, remove_most_frequent_dummy = TRUE, remove_selected_columns = TRUE)
}

# Identify columns with zero variance
zero_var_cols <- sapply(dat2, function(x) var(x, na.rm = TRUE) == 0)
zero_var_cols[zero_var_cols]  # Print columns with zero variance

# Remove zero variance columns from the dataset
dat2 <- dat2[, !zero_var_cols]

# Calculate the correlation matrix
cor_matrix <- cor(dat2[, sapply(dat2, is.numeric)])

# Find index of highly correlated pairs
high_cor_pairs <- which(abs(cor_matrix) > 0.8 & cor_matrix != 1, arr.ind = TRUE)

# Create a data frame to store pairs and their correlation coefficients
high_cor_data <- data.frame(
  Var1 = rownames(cor_matrix)[high_cor_pairs[, 1]],
  Var2 = colnames(cor_matrix)[high_cor_pairs[, 2]],
  Correlation = cor_matrix[high_cor_pairs]
)

# Print the highly correlated pairs
print(high_cor_data)

# Calculate correlation matrix
cor_matrix <- cor(dat2[, sapply(dat2, is.numeric)], use = "pairwise.complete.obs")

# Melt the correlation matrix
cor_melted <- melt(cor_matrix)

# Truncate column names for visualization
colnames(cor_matrix) <- abbreviate(colnames(cor_matrix), minlength = 4)

# Create the heatmap
ggplot(cor_melted, aes(Var1, Var2, fill = value)) +
  geom_tile(color = "white") +  # add white lines to separate the tiles
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", midpoint = 0, limit = c(-1,1), space = "Lab", name="Correlation") +
  theme_minimal() +  # clean theme
  theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1),  # rotate x axis labels for better visibility
        axis.title = element_blank(),  # remove axis titles
        legend.position = "bottom") +  # move legend to bottom
  coord_fixed()  # ensure the tiles are square

dat2$age <- (dat2$age - min(dat2$age)) / (max(dat2$age) - min(dat2$age))

# -------------------------------------------Logistic Regression--------------------------------------
# Forward selection
# take 70% of data randomly as training
set.seed(1) # set a seed so that people get the same 60% next time they run the same code
id.train1 = sample(1:nrow(dat2), nrow(dat2)*0.7) # ncol() gives number of columns
id.test1 = setdiff(1:nrow(dat2), id.train1) # setdiff gives the set difference
dat.train1 = dat2[id.train1,]
dat.test1 = dat2[id.test1,]

min.model = glm(Class.ASD ~ 1, data = dat.train1, family = 'binomial')
max.model = glm(Class.ASD ~ ., data = dat.train1, family = 'binomial')
max.formula = formula(max.model)

forward.model <- step(min.model, direction = "forward", scope = max.formula)

# summary
summary(forward.model)

# Function to predict and evaluate model at different cutoffs
evaluate_model <- function(model, data, cutoffs = c(0.5, 0.4, 0.3)) {
  predictions <- predict(model, newdata = data, type = "response")
  results <- lapply(cutoffs, function(cut) {
    predicted_classes <- as.numeric(predictions > cut)
    cm <- confusionMatrix(as.factor(predicted_classes), as.factor(data$Class.ASD))
    misclassification_rate = 1 - cm$overall['Accuracy']
    return(list(Cutoff = cut, MisclassificationRate = misclassification_rate, 
                Sensitivity = cm$byClass['Sensitivity'], 
                Specificity = cm$byClass['Specificity']))
  })
  return(results)
}

# Evaluate model
forward_eval <- evaluate_model(forward.model, dat.test1)

# Function to print evaluation results
print_evaluations <- function(evaluations, model_name) {
  cat("Evaluations for", model_name, ":\n")
  for (eval in evaluations) {
    cat("Cutoff:", eval$Cutoff, "\n")
    cat("Misclassification Rate:", format(eval$MisclassificationRate, digits=4), "\n")
    cat("Sensitivity:", format(eval$Sensitivity, digits=4), "\n")
    cat("Specificity:", format(eval$Specificity, digits=4), "\n")
    cat("\n")  # Add a newline for better readability
  }
}

# Print results for model's evaluation
print_evaluations(forward_eval, "Forward Model")

# Backward selection
# take 70% of data randomly as training
set.seed(2) # set a seed so that people get the same 60% next time they run the same code
id.train2 = sample(1:nrow(dat2), nrow(dat2)*0.7) # ncol() gives number of columns
id.test2 = setdiff(1:nrow(dat2), id.train2) # setdiff gives the set difference
dat.train2 = dat2[id.train2,]
dat.test2 = dat2[id.test2,]

min.model = glm(Class.ASD ~ 1, data = dat.train2, family = 'binomial')
max.model = glm(Class.ASD ~ ., data = dat.train2, family = 'binomial')
max.formula = formula(max.model)

backward.model <- step(max.model, direction = "backward")

# summary
summary(backward.model)

# Evaluate models
backward_eval <- evaluate_model(backward.model, dat.test2)

# Print results for each model's evaluation
print_evaluations(backward_eval, "Backward Model")

# Stepwise selection
# take 70% of data randomly as training
set.seed(3) # set a seed so that people get the same 60% next time they run the same code
id.train3 = sample(1:nrow(dat2), nrow(dat2)*0.7) # ncol() gives number of columns
id.test3 = setdiff(1:nrow(dat2), id.train3) # setdiff gives the set difference
dat.train3 = dat2[id.train3,]
dat.test3 = dat2[id.test3,]

min.model = glm(Class.ASD ~ 1, data = dat.train3, family = 'binomial')
max.model = glm(Class.ASD ~ ., data = dat.train3, family = 'binomial')
max.formula = formula(max.model)

stepwise.model <- step(min.model, direction = "both", scope = max.formula)

# summary
summary(stepwise.model)

# Evaluate model
stepwise_eval <- evaluate_model(stepwise.model, dat.test3)

# Print results for each model evaluation
print_evaluations(stepwise_eval, "Stepwise Model")
# -------------------------------------------KNN--------------------------------------
# Set seed for reproducibility
set.seed(2)

# Prepare training and testing indices
n.train <- floor(nrow(dat2) * 0.75)
ind.train <- sample(1:nrow(dat2), n.train)
ind.test <- setdiff(1:nrow(dat2), ind.train)

# Load required package for KNN
require(class)

# Select predictors and response variable appropriately
Xtrain <- dat2[ind.train, -12] # Exclude the Class.ASD column
Xtest <- dat2[ind.test, -12]
ytrain <- dat2[ind.train, 12]
ytest <- dat2[ind.test, 12]

# Run KNN with k=3 to include probability estimates
ypred_prob <- knn(Xtrain, Xtest, ytrain, k=3, prob=TRUE)
ypred_probs <- attr(ypred_prob, "prob")

# Adjust probabilities based on predicted class
ypred_probs <- ifelse(ypred_prob == "1", ypred_probs, 1 - ypred_probs)

# Function to find the best k value
knn.bestK <- function(train, test, y.train, y.test, k.grid = 1:20, ct = .5) {
  fun.tmp <- function(k) {
    y.tmp <- knn(train, test, y.train, k = k, prob=TRUE)
    prob <- ifelse(y.tmp == "1", attr(y.tmp, "prob"), 1 - attr(y.tmp, "prob"))
    y.hat <- as.numeric(prob > ct)
    return(sum(y.hat != as.numeric(y.test)))
  }
  error <- unlist(lapply(k.grid, fun.tmp))
  names(error) = paste0('k=', k.grid)
  out <- list(k.optimal = k.grid[which.min(error)],
              error.min = min(error) / length(y.test),
              error.all = error / length(y.test))
  return(out)
}

# Finding the optimal k
obj1 <- knn.bestK(Xtrain, Xtest, ytrain, ytest, seq(1, 18, 2), .5)
cat("Optimal k: ", obj1$k.optimal, "\n")

# Rerun KNN with the optimal k
ypred_final <- knn(Xtrain, Xtest, ytrain, k=obj1$k.optimal, prob=TRUE)
ypred_probs_final <- ifelse(ypred_final == "1", attr(ypred_final, "prob"), 1 - attr(ypred_final, "prob"))

# Performance metrics functions
sen <- function(ytest, ypred) { mean(ytest[which(ytest == 1)] == ypred[which(ytest == 1)]) }
spe <- function(ytest, ypred) { mean(ytest[which(ytest == 0)] == ypred[which(ytest == 0)]) }
fpr <- function(ytest, ypred) { 1 - spe(ytest, ypred) }
fnr <- function(ytest, ypred) { 1 - sen(ytest, ypred) }

# Performance evaluation at different cutoffs
evaluate_performance <- function(ytest, ypred_probs, cutoffs) {
  results <- list()
  for (cut in cutoffs) {
    ypred <- as.numeric(ypred_probs > cut)
    cm <- table(ytest, ypred)
    results[[paste0("Cutoff_", cut)]] <- c(Accuracy = mean(ytest == ypred),
                                           Sensitivity = sen(ytest, ypred),
                                           Specificity = spe(ytest, ypred),
                                           FPR = fpr(ytest, ypred),
                                           FNR = fnr(ytest, ypred))
  }
  return(results)
}

# Evaluate model at different cutoffs
cutoffs <- c(0.5, 0.4, 0.3)
performance_results <- evaluate_performance(ytest, ypred_probs_final, cutoffs)

# Print results for each cutoff
for (cutoff in names(performance_results)) {
  cat("\nPerformance Metrics at", cutoff, ":\n")
  metrics <- performance_results[[cutoff]]
  cat("Accuracy: ", metrics['Accuracy'], "\n")
  cat("Sensitivity: ", metrics['Sensitivity'], "\n")
  cat("Specificity: ", metrics['Specificity'], "\n")
  cat("False Positive Rate (FPR): ", metrics['FPR'], "\n")
  cat("False Negative Rate (FNR): ", metrics['FNR'], "\n")
}
# -------------------------------------------CART--------------------------------------
head(dat3)
set.seed(5)
train = round(nrow(dat3) * 0.7)
train = sample(nrow(dat3), train)
df_train = dat3[train, ]
df_test = dat3[-train, ]

K=10
fit = rpart(Class.ASD ~ ., method="class", data=df_train, minsplit=5, xval=K, cp=0.0001)

#Min-Error Tree
me = prune(fit, cp = fit$cptable[which.min(fit$cptable[,"xerror"]),"CP"])
rpart.plot(me, main = 'Min Error Tree')
printcp(x = me)

#Error on df_test Data
yhat = predict(me, df_test, type = "class")
err.me = mean(yhat != df_test$Class.ASD)
#err.me
cat("\nAccuraccy:",1-err.me)

#Best Pruned Tree
ind = which.min(fit$cptable[,"xerror"])
se1 = fit$cptable[ind,"xstd"]/sqrt(K)
xer1 = min(fit$cptable[,"xerror"]) + se1
ind0 = which.min(abs(fit$cptable[1:ind,"xerror"] - xer1))
bestpruned = prune(fit, cp = fit$cptable[ind0,"CP"])
rpart.plot(bestpruned, main = 'Best Pruned Tree')

printcp(x = bestpruned)

#Error on df_test Data
yhat = predict(bestpruned, df_test, type = "class")
err.bp = mean(yhat != df_test$Class.ASD)
#err.bp
cat("\nAccuraccy:",1-err.bp)

# --------------------------------Performance Metrics CART-------------------------------
cut_offs = c(0.5,0.4,0.3)

# Function to evaluate performance and setting cutoffs
performance = function(ytest, ypred, ct,method) {
  measures = c(
    Method=method,
    Cutoff = ct,
    ErrorRate = mean(ytest != ypred),
    Sensitivity = mean(ytest[ytest == 1] == ypred[ytest == 1]),
    Specificity = mean(ytest[ytest == 0] == ypred[ytest == 0]),
    Accuracy = mean(ytest == ypred)
  )
  
  return(measures)
}

performance_table_CART = function(cart_model ,cart_type){
  cart_table <- data.frame()
  for (cut_off in cut_offs) {
    prob1 = predict(cart_model, df_test, type = "prob")[,2]
    ypred = as.numeric(prob1 > cut_off)
    ytest = as.numeric(df_test$Class.ASD)
    performance_result = performance(ytest, ypred, cut_off,cart_type)
    # Combine results into a data frame
    result_row <- data.frame(t(performance_result))
    cart_table <- rbind(cart_table, result_row)
  }
  colnames(cart_table) <- c("Method", "Cutoff", "ErrorRate", "Sensitivity", "Specificity", "Accuracy")
  return(cart_table)
}

cart_me_table = performance_table_CART(me,"CART-ME Tree")
cart_bestpruned_table = performance_table_CART(bestpruned,"CART-BP Tree")
#CART results
cart_table = rbind(cart_me_table, cart_bestpruned_table)
cart_table


