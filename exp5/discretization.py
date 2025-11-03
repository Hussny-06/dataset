import pandas as pd


# reading the database
data = pd.read_csv("1/exp5/tips.csv")

# printing the top 10 rows
print(data.head(10))