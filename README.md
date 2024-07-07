# Autism Spectrum Disorder (ASD) Prediction

Welcome! This project is part of the ISDS 574 – Data Mining for Business Applications course. It aims to leverage machine learning techniques to analyze and predict Autism Spectrum Disorder using a comprehensive dataset.

## Table of Contents

- [Project Overview](#project-overview)
- [Dataset](#dataset)
- [Data Preprocessing](#data-preprocessing)
- [Modeling](#modeling)
- [Evaluation](#evaluation)
- [Results](#results)
- [Limitations and Future Work](#limitations-and-future-work)
- [Acknowledgments](#acknowledgments)
- [Setup](#setup)

## Project Overview

Autism Spectrum Disorder (ASD) is a complex developmental condition affecting communication, behavior, and social interactions. This project utilizes various machine learning models to predict ASD based on survey data. The goal is to enhance early detection and improve intervention strategies.

## Dataset

The dataset consists of 800 observations and 22 columns. Key variables include:

- **ID:** Unique identifier for each individual
- **A1_Score to A10_Score:** Survey responses related to autism screening
- **Age:** Age of the individual
- **Gender:** Gender of the individual
- **Ethnicity:** Ethnicity or racial background
- **Jaundice:** History of jaundice at birth
- **Autism:** Family history of autism
- **Result:** Autism screening assessment result
- **Age_desc:** Age group description
- **Relation:** Relationship of the individual to the person completing the survey
- **Class/ASD:** Binary indicator of ASD presence (1 = ASD, 0 = non-ASD)

## Data Preprocessing

Data preprocessing steps include:

- **Handling Missing Values:** Addressing incomplete data entries
- **Outlier Detection and Removal:** Identifying and handling outliers
- **Categorical Variable Encoding:** Converting categorical variables into numerical format
- **Normalization and Scaling:** Standardizing data to improve model performance

## Modeling

Several machine learning models and techniques were implemented:

1. **Forward Selection Model:** A stepwise selection method that starts with no variables and adds the most significant variables one by one.
2. **Backward Selection Model:** A stepwise selection method that starts with all variables and removes the least significant variables one by one.
3. **Stepwise Selection Model:** A combination of forward and backward selection methods to choose the best subset of variables.
4. **K-Nearest Neighbors (KNN):** A non-parametric method used for classification by finding the most common class among the k-nearest neighbors.
5. **Classification and Regression Tree (CART):** A decision tree algorithm used for classification tasks, splitting the data into subsets based on feature values.

## Evaluation

Models were evaluated based on:

- **Accuracy:** Proportion of correctly predicted instances
- **Sensitivity:** Ability to correctly identify positive cases
- **Specificity:** Ability to correctly identify negative cases
- **False Positive Rate (FPR):** Proportion of negative cases incorrectly classified as positive
- **False Negative Rate (FNR):** Proportion of positive cases incorrectly classified as negative

## Results

### Forward Model
- **Key Features:** A3_Score, A4_Score, A6_Score, ethnicity_Middle Eastern, A9_Score, A1_Score, A10_Score, A5_Score, ethnicity_White-European
- **Insights:** High importance on A3_Score, A4_Score, and A6_Score.

### Backward Model
- **Key Features:** A2_Score, A3_Score, A4_Score, A5_Score, A6_Score, A9_Score, A10_Score, ethnicity_Middle Eastern, jaundice_yes, autism_yes
- **Insights:** A3_Score and A9_Score are the most influential features.

### Stepwise Model
- **Key Features:** A3_Score, A9_Score, A10_Score, A6_Score, A4_Score, A5_Score, ethnicity_White-European, autism_yes, jaundice_yes, relation_Parent, A7_Score, age
- **Insights:** A3_Score, A10_Score, and A4_Score are the most significant features.

### KNN Model
- **Optimal K:** 5 neighbors
- **Performance:** Balanced trade-off between sensitivity and specificity at a cutoff value of 0.3.

### CART Model
- **Parameters:** Minsplit = 5, Xval = 10, Cp = 0.00001
- **Insights:** Decision tree splits based on significant features to classify ASD presence.

## Limitations and Future Work

### Limitations
- **Data Dependency:** Model performance varies with dataset characteristics.
- **Feature Engineering:** Limited by initial feature selection and engineering.
- **Sample Diversity:** Limited sample size and diversity affecting generalizability.
- **Evaluation Metrics:** Traditional metrics may not fully capture real-world effectiveness.

### Future Work
- **Additional Data Sources:** Incorporating more diverse populations.
- **Advanced Techniques:** Exploring sophisticated machine learning and deep learning approaches.
- **Longitudinal Analysis:** Using longitudinal data to assess long-term model accuracy.
- **Clinical Testing:** Pilot studies in real clinical settings to evaluate usability and impact.

## Acknowledgments

- **Thabtah’s Research on Machine Learning in ASD Screening:** [Link](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC10168184/)
- **Machine Learning Approach to Predict ASD:** [Link](https://ieeexplore.ieee.org/document/8679454)
- **Using ML for Motion Analysis to Detect ASD:** [Link](https://link.springer.com/article/10.1007/s40489-024-00435-4)
- **Feature Signature Discovery for Autism Detection:** [Link](https://www.hindawi.com/journals/cin/2023/6330002/)

## Setup

To set up the project locally, follow these steps:

### R Environment Setup:

1. **Ensure R is Installed:**
   - Download and install R from the official [CRAN](https://cran.r-project.org/) website.

2. **Install Required R Packages:**
   - Open your R console or RStudio and run the following command to install the necessary packages:
     ```R
     install.packages(c("dplyr", "ggplot2", "caret", "e1071", "rpart", "rpart.plot"))
     ```

3. **Clone the Repository**:
   - Clone this repository to your local machine using Git:
     ```bash
     git clone https://github.com/VamsiTanneru/AutismScreeningPrediction.git
     ```
     
4. **Run the Code**:
   - Open the R Script:
     Open Team06_FINAL_CODE.R in your R environment (e.g., RStudio).
   - Execute the Script:
     Run the script to perform the data analysis and modeling.
