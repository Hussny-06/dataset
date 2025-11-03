import pandas as pd
import matplotlib.pyplot as plt


# reading the database
data = pd.read_csv("1/exp5/tips.csv")

# Scatter plot with day against tip
plt.plot(data['tip'], label='Tip', color='tab:blue')
plt.plot(data['total_bill'], label='Total Bill', color='tab:green')

# Adding Title to the Plot
plt.title("Line Chart")

# Setting the X and Y labels
plt.xlabel('Total Bill')
plt.ylabel('Tip')


# Show legend that maps colors to series
plt.legend(loc='best')

plt.show()