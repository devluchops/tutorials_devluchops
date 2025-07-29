# Python Data Science Ecosystem Complete Guide

Master the essential Python libraries for data science including Pandas, NumPy, Matplotlib, Seaborn, and Scikit-learn with practical examples and real-world projects.

## What You'll Learn

- **NumPy** - Numerical computing and array operations
- **Pandas** - Data manipulation and analysis
- **Matplotlib & Seaborn** - Data visualization and plotting
- **Scikit-learn** - Machine learning algorithms and tools
- **Jupyter Notebooks** - Interactive data analysis environment
- **Data Processing Pipeline** - Complete workflow from raw data to insights

## Core Libraries Overview

### **🔢 NumPy - Numerical Computing**
```python
import numpy as np

# Array creation and basic operations
arr = np.array([1, 2, 3, 4, 5])
matrix = np.array([[1, 2], [3, 4]])

# Mathematical operations
result = np.sqrt(arr)
mean_val = np.mean(arr)
std_val = np.std(arr)

# Array indexing and slicing
subset = arr[1:4]
condition_filter = arr[arr > 3]
```

### **🐼 Pandas - Data Manipulation**
```python
import pandas as pd

# DataFrame creation and basic operations
df = pd.DataFrame({
    'Name': ['Alice', 'Bob', 'Charlie'],
    'Age': [25, 30, 35],
    'City': ['NY', 'LA', 'Chicago']
})

# Data exploration
df.head()
df.info()
df.describe()

# Data filtering and grouping
young_people = df[df['Age'] < 30]
city_groups = df.groupby('City').mean()
```

### **📊 Matplotlib & Seaborn - Visualization**
```python
import matplotlib.pyplot as plt
import seaborn as sns

# Basic plotting
plt.figure(figsize=(10, 6))
plt.plot(x_data, y_data, label='Line Plot')
plt.scatter(x_data, y_data, label='Scatter Plot')
plt.xlabel('X Label')
plt.ylabel('Y Label')
plt.legend()
plt.show()

# Statistical plots with Seaborn
sns.boxplot(data=df, x='City', y='Age')
sns.heatmap(correlation_matrix, annot=True)
```

### **🤖 Scikit-learn - Machine Learning**
```python
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_squared_error

# Model training and evaluation
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)
model = LinearRegression()
model.fit(X_train, y_train)
predictions = model.predict(X_test)
mse = mean_squared_error(y_test, predictions)
```

## Practical Data Science Projects

### **📈 Project 1: Sales Data Analysis**
```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime, timedelta

# Generate sample sales data
np.random.seed(42)
dates = pd.date_range(start='2023-01-01', end='2023-12-31', freq='D')
n_days = len(dates)

# Create realistic sales data with seasonality
base_sales = 1000
seasonal_factor = 1 + 0.3 * np.sin(2 * np.pi * np.arange(n_days) / 365.25)
trend_factor = 1 + 0.5 * np.arange(n_days) / n_days
noise = np.random.normal(0, 0.1, n_days)
sales = base_sales * seasonal_factor * trend_factor * (1 + noise)

# Create DataFrame
sales_data = pd.DataFrame({
    'date': dates,
    'sales': sales,
    'day_of_week': dates.day_name(),
    'month': dates.month,
    'quarter': dates.quarter
})

# Add product categories
products = ['Electronics', 'Clothing', 'Home', 'Books', 'Sports']
sales_data['product_category'] = np.random.choice(products, n_days)
sales_data['units_sold'] = np.random.poisson(sales_data['sales'] / 50)

print("Sales Data Overview:")
print(sales_data.head())
print(f"\nDataset shape: {sales_data.shape}")
print(f"\nData types:\n{sales_data.dtypes}")

# Data Analysis
print("\n" + "="*50)
print("SALES DATA ANALYSIS")
print("="*50)

# 1. Basic statistics
print("\nBasic Statistics:")
print(sales_data['sales'].describe())

# 2. Monthly sales analysis
monthly_sales = sales_data.groupby('month')['sales'].agg(['sum', 'mean', 'count'])
print("\nMonthly Sales Summary:")
print(monthly_sales)

# 3. Day of week analysis
dow_sales = sales_data.groupby('day_of_week')['sales'].mean().reindex([
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
])
print("\nAverage Sales by Day of Week:")
print(dow_sales)

# 4. Product category analysis
category_sales = sales_data.groupby('product_category')['sales'].agg(['sum', 'mean', 'count'])
print("\nSales by Product Category:")
print(category_sales)

# Data Visualization
fig, axes = plt.subplots(2, 2, figsize=(15, 12))
fig.suptitle('Sales Data Analysis Dashboard', fontsize=16, fontweight='bold')

# 1. Time series plot
axes[0, 0].plot(sales_data['date'], sales_data['sales'], alpha=0.7, linewidth=1)
axes[0, 0].set_title('Daily Sales Over Time')
axes[0, 0].set_xlabel('Date')
axes[0, 0].set_ylabel('Sales ($)')
axes[0, 0].tick_params(axis='x', rotation=45)

# 2. Monthly sales trend
monthly_sales['mean'].plot(kind='bar', ax=axes[0, 1], color='steelblue')
axes[0, 1].set_title('Average Monthly Sales')
axes[0, 1].set_xlabel('Month')
axes[0, 1].set_ylabel('Average Sales ($)')
axes[0, 1].tick_params(axis='x', rotation=0)

# 3. Day of week analysis
dow_sales.plot(kind='bar', ax=axes[1, 0], color='lightcoral')
axes[1, 0].set_title('Average Sales by Day of Week')
axes[1, 0].set_xlabel('Day of Week')
axes[1, 0].set_ylabel('Average Sales ($)')
axes[1, 0].tick_params(axis='x', rotation=45)

# 4. Product category distribution
category_sales['sum'].plot(kind='pie', ax=axes[1, 1], autopct='%1.1f%%')
axes[1, 1].set_title('Total Sales by Product Category')
axes[1, 1].set_ylabel('')

plt.tight_layout()
plt.show()

# Advanced Analysis: Correlation and Trends
print("\n" + "="*50)
print("ADVANCED ANALYSIS")
print("="*50)

# Create additional features for analysis
sales_data['sales_ma_7'] = sales_data['sales'].rolling(window=7).mean()
sales_data['sales_ma_30'] = sales_data['sales'].rolling(window=30).mean()
sales_data['day_of_year'] = sales_data['date'].dt.dayofyear

# Correlation analysis
numeric_columns = ['sales', 'month', 'quarter', 'units_sold', 'day_of_year']
correlation_matrix = sales_data[numeric_columns].corr()

plt.figure(figsize=(10, 8))
sns.heatmap(correlation_matrix, annot=True, cmap='coolwarm', center=0,
            square=True, cbar_kws={'shrink': 0.8})
plt.title('Feature Correlation Matrix')
plt.tight_layout()
plt.show()

# Trend analysis with moving averages
plt.figure(figsize=(15, 8))
plt.plot(sales_data['date'], sales_data['sales'], alpha=0.3, label='Daily Sales', color='gray')
plt.plot(sales_data['date'], sales_data['sales_ma_7'], label='7-day Moving Average', color='blue')
plt.plot(sales_data['date'], sales_data['sales_ma_30'], label='30-day Moving Average', color='red')
plt.title('Sales Trends with Moving Averages')
plt.xlabel('Date')
plt.ylabel('Sales ($)')
plt.legend()
plt.grid(True, alpha=0.3)
plt.tight_layout()
plt.show()

# Export results
print("\nExporting results...")
summary_stats = {
    'total_sales': sales_data['sales'].sum(),
    'average_daily_sales': sales_data['sales'].mean(),
    'best_selling_day': dow_sales.idxmax(),
    'best_selling_month': monthly_sales['sum'].idxmax(),
    'top_product_category': category_sales['sum'].idxmax()
}

print("\nKey Insights:")
for key, value in summary_stats.items():
    print(f"- {key.replace('_', ' ').title()}: {value}")

# Save processed data
sales_data.to_csv('sales_analysis_results.csv', index=False)
print("\nData saved to 'sales_analysis_results.csv'")
```

### **🏠 Project 2: Real Estate Price Prediction**
```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.linear_model import LinearRegression, Ridge, Lasso
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.metrics import mean_squared_error, r2_score, mean_absolute_error
import warnings
warnings.filterwarnings('ignore')

# Generate synthetic real estate data
np.random.seed(42)
n_samples = 1000

# Generate features
square_feet = np.random.normal(2000, 500, n_samples)
square_feet = np.clip(square_feet, 800, 5000)

bedrooms = np.random.choice([1, 2, 3, 4, 5], n_samples, p=[0.1, 0.2, 0.4, 0.25, 0.05])
bathrooms = bedrooms + np.random.choice([-1, 0, 1, 2], n_samples, p=[0.1, 0.4, 0.4, 0.1])
bathrooms = np.clip(bathrooms, 1, 6)

age = np.random.exponential(15, n_samples)
age = np.clip(age, 0, 100)

neighborhoods = ['Downtown', 'Suburbs', 'Waterfront', 'Hills', 'Historic']
neighborhood = np.random.choice(neighborhoods, n_samples, p=[0.2, 0.4, 0.15, 0.15, 0.1])

# Generate price based on features (with realistic relationships)
base_price = 50000
price_per_sqft = 150 + np.random.normal(0, 20, n_samples)
bedroom_value = bedrooms * 15000
bathroom_value = bathrooms * 10000
age_depreciation = -age * 500
neighborhood_premium = {
    'Downtown': 50000, 'Waterfront': 100000, 'Hills': 30000, 
    'Historic': 20000, 'Suburbs': 0
}
neighborhood_adj = [neighborhood_premium[n] for n in neighborhood]

# Calculate price with some noise
price = (base_price + 
         square_feet * price_per_sqft + 
         bedroom_value + 
         bathroom_value + 
         age_depreciation + 
         neighborhood_adj +
         np.random.normal(0, 20000, n_samples))

price = np.clip(price, 100000, 2000000)  # Realistic price range

# Create DataFrame
real_estate_data = pd.DataFrame({
    'square_feet': square_feet,
    'bedrooms': bedrooms,
    'bathrooms': bathrooms,
    'age': age,
    'neighborhood': neighborhood,
    'price': price
})

print("Real Estate Dataset Overview:")
print(real_estate_data.head())
print(f"\nDataset shape: {real_estate_data.shape}")
print(f"\nData types:\n{real_estate_data.dtypes}")
print(f"\nBasic statistics:\n{real_estate_data.describe()}")

# Exploratory Data Analysis
print("\n" + "="*50)
print("EXPLORATORY DATA ANALYSIS")
print("="*50)

# Price distribution
plt.figure(figsize=(15, 12))

# 1. Price distribution
plt.subplot(3, 3, 1)
plt.hist(real_estate_data['price'], bins=30, alpha=0.7, color='skyblue', edgecolor='black')
plt.title('Price Distribution')
plt.xlabel('Price ($)')
plt.ylabel('Frequency')

# 2. Price vs Square Feet
plt.subplot(3, 3, 2)
plt.scatter(real_estate_data['square_feet'], real_estate_data['price'], alpha=0.6)
plt.title('Price vs Square Feet')
plt.xlabel('Square Feet')
plt.ylabel('Price ($)')

# 3. Price by Bedrooms
plt.subplot(3, 3, 3)
real_estate_data.boxplot(column='price', by='bedrooms', ax=plt.gca())
plt.title('Price by Number of Bedrooms')
plt.suptitle('')  # Remove automatic title

# 4. Price by Neighborhood
plt.subplot(3, 3, 4)
real_estate_data.boxplot(column='price', by='neighborhood', ax=plt.gca())
plt.title('Price by Neighborhood')
plt.xticks(rotation=45)
plt.suptitle('')

# 5. Age vs Price
plt.subplot(3, 3, 5)
plt.scatter(real_estate_data['age'], real_estate_data['price'], alpha=0.6, color='orange')
plt.title('Age vs Price')
plt.xlabel('Age (years)')
plt.ylabel('Price ($)')

# 6. Correlation heatmap
plt.subplot(3, 3, 6)
numeric_cols = ['square_feet', 'bedrooms', 'bathrooms', 'age', 'price']
correlation_matrix = real_estate_data[numeric_cols].corr()
sns.heatmap(correlation_matrix, annot=True, cmap='coolwarm', center=0, square=True)
plt.title('Feature Correlation Matrix')

# 7. Price per square foot distribution
plt.subplot(3, 3, 7)
price_per_sqft = real_estate_data['price'] / real_estate_data['square_feet']
plt.hist(price_per_sqft, bins=30, alpha=0.7, color='lightgreen', edgecolor='black')
plt.title('Price per Square Foot Distribution')
plt.xlabel('Price per Sq Ft ($)')
plt.ylabel('Frequency')

# 8. Bathrooms vs Price
plt.subplot(3, 3, 8)
real_estate_data.boxplot(column='price', by='bathrooms', ax=plt.gca())
plt.title('Price by Number of Bathrooms')
plt.suptitle('')

# 9. Average price by neighborhood
plt.subplot(3, 3, 9)
avg_price_by_neighborhood = real_estate_data.groupby('neighborhood')['price'].mean().sort_values(ascending=False)
avg_price_by_neighborhood.plot(kind='bar', color='coral')
plt.title('Average Price by Neighborhood')
plt.xlabel('Neighborhood')
plt.ylabel('Average Price ($)')
plt.xticks(rotation=45)

plt.tight_layout()
plt.show()

# Data Preprocessing for Machine Learning
print("\n" + "="*50)
print("DATA PREPROCESSING & MACHINE LEARNING")
print("="*50)

# Prepare features
X = real_estate_data.drop('price', axis=1).copy()
y = real_estate_data['price'].copy()

# Encode categorical variables
le = LabelEncoder()
X['neighborhood_encoded'] = le.fit_transform(X['neighborhood'])
X_encoded = X.drop('neighborhood', axis=1)

print("Features after encoding:")
print(X_encoded.head())

# Split the data
X_train, X_test, y_train, y_test = train_test_split(
    X_encoded, y, test_size=0.2, random_state=42
)

# Scale features
scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)

print(f"\nTraining set size: {X_train.shape}")
print(f"Test set size: {X_test.shape}")

# Model Training and Evaluation
models = {
    'Linear Regression': LinearRegression(),
    'Ridge Regression': Ridge(alpha=1.0),
    'Lasso Regression': Lasso(alpha=1.0),
    'Random Forest': RandomForestRegressor(n_estimators=100, random_state=42)
}

results = {}

for name, model in models.items():
    print(f"\nTraining {name}...")
    
    if 'Regression' in name:
        # Use scaled features for linear models
        model.fit(X_train_scaled, y_train)
        y_pred = model.predict(X_test_scaled)
    else:
        # Use original features for tree-based models
        model.fit(X_train, y_train)
        y_pred = model.predict(X_test)
    
    # Calculate metrics
    mse = mean_squared_error(y_test, y_pred)
    rmse = np.sqrt(mse)
    mae = mean_absolute_error(y_test, y_pred)
    r2 = r2_score(y_test, y_pred)
    
    results[name] = {
        'MSE': mse,
        'RMSE': rmse,
        'MAE': mae,
        'R2': r2,
        'Model': model,
        'Predictions': y_pred
    }
    
    print(f"RMSE: ${rmse:,.2f}")
    print(f"MAE: ${mae:,.2f}")
    print(f"R2 Score: {r2:.4f}")

# Model Comparison
print("\n" + "="*50)
print("MODEL COMPARISON")
print("="*50)

comparison_df = pd.DataFrame({
    'Model': list(results.keys()),
    'RMSE': [results[model]['RMSE'] for model in results.keys()],
    'MAE': [results[model]['MAE'] for model in results.keys()],
    'R2': [results[model]['R2'] for model in results.keys()]
})

print(comparison_df.round(4))

# Visualize model performance
fig, axes = plt.subplots(2, 2, figsize=(15, 10))
fig.suptitle('Model Performance Comparison', fontsize=16)

# RMSE comparison
axes[0, 0].bar(comparison_df['Model'], comparison_df['RMSE'], color='skyblue')
axes[0, 0].set_title('RMSE Comparison')
axes[0, 0].set_ylabel('RMSE ($)')
axes[0, 0].tick_params(axis='x', rotation=45)

# R2 comparison
axes[0, 1].bar(comparison_df['Model'], comparison_df['R2'], color='lightgreen')
axes[0, 1].set_title('R² Score Comparison')
axes[0, 1].set_ylabel('R² Score')
axes[0, 1].tick_params(axis='x', rotation=45)

# Best model predictions vs actual
best_model_name = comparison_df.loc[comparison_df['R2'].idxmax(), 'Model']
best_predictions = results[best_model_name]['Predictions']

axes[1, 0].scatter(y_test, best_predictions, alpha=0.6)
axes[1, 0].plot([y_test.min(), y_test.max()], [y_test.min(), y_test.max()], 'r--', lw=2)
axes[1, 0].set_xlabel('Actual Price ($)')
axes[1, 0].set_ylabel('Predicted Price ($)')
axes[1, 0].set_title(f'Actual vs Predicted ({best_model_name})')

# Residuals plot
residuals = y_test - best_predictions
axes[1, 1].scatter(best_predictions, residuals, alpha=0.6)
axes[1, 1].axhline(y=0, color='r', linestyle='--')
axes[1, 1].set_xlabel('Predicted Price ($)')
axes[1, 1].set_ylabel('Residuals ($)')
axes[1, 1].set_title(f'Residuals Plot ({best_model_name})')

plt.tight_layout()
plt.show()

# Feature Importance (for Random Forest)
if 'Random Forest' in results:
    rf_model = results['Random Forest']['Model']
    feature_importance = pd.DataFrame({
        'feature': X_encoded.columns,
        'importance': rf_model.feature_importances_
    }).sort_values('importance', ascending=False)
    
    plt.figure(figsize=(10, 6))
    plt.barh(feature_importance['feature'], feature_importance['importance'])
    plt.title('Feature Importance (Random Forest)')
    plt.xlabel('Importance')
    plt.gca().invert_yaxis()
    plt.tight_layout()
    plt.show()
    
    print("\nFeature Importance:")
    print(feature_importance)

# Summary
print("\n" + "="*50)
print("SUMMARY")
print("="*50)

print(f"Best performing model: {best_model_name}")
print(f"Best R² Score: {results[best_model_name]['R2']:.4f}")
print(f"Best RMSE: ${results[best_model_name]['RMSE']:,.2f}")

print("\nKey Insights:")
print("- Square footage is typically the most important feature")
print("- Neighborhood significantly affects property values")
print("- Age of property generally decreases value")
print("- Number of bedrooms and bathrooms add value")

# Save results
real_estate_data.to_csv('real_estate_analysis.csv', index=False)
comparison_df.to_csv('model_comparison.csv', index=False)
print("\nResults saved to CSV files")
```

### **📊 Project 3: Customer Segmentation Analysis**
```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA
from sklearn.metrics import silhouette_score
import warnings
warnings.filterwarnings('ignore')

# Generate synthetic customer data
np.random.seed(42)
n_customers = 1000

# Customer demographics
ages = np.random.normal(40, 15, n_customers)
ages = np.clip(ages, 18, 80).astype(int)

# Income based on age (with some noise)
base_income = 30000 + (ages - 18) * 1000 + np.random.normal(0, 15000, n_customers)
income = np.clip(base_income, 20000, 150000)

# Spending behavior
spending_score = np.random.beta(2, 5, n_customers) * 100  # 0-100 scale

# Annual spending based on income and spending score
annual_spending = (income * 0.3) * (spending_score / 100) + np.random.normal(0, 5000, n_customers)
annual_spending = np.clip(annual_spending, 1000, 50000)

# Purchase frequency
purchase_frequency = np.random.poisson(spending_score / 10, n_customers)
purchase_frequency = np.clip(purchase_frequency, 1, 50)

# Customer lifetime (months)
customer_lifetime = np.random.exponential(24, n_customers)
customer_lifetime = np.clip(customer_lifetime, 3, 120)

# Gender
gender = np.random.choice(['Male', 'Female'], n_customers, p=[0.48, 0.52])

# Create customer DataFrame
customer_data = pd.DataFrame({
    'customer_id': range(1, n_customers + 1),
    'age': ages,
    'gender': gender,
    'annual_income': income,
    'spending_score': spending_score,
    'annual_spending': annual_spending,
    'purchase_frequency': purchase_frequency,
    'customer_lifetime_months': customer_lifetime
})

# Calculate additional metrics
customer_data['avg_order_value'] = customer_data['annual_spending'] / customer_data['purchase_frequency']
customer_data['total_lifetime_value'] = (customer_data['annual_spending'] * 
                                       customer_data['customer_lifetime_months'] / 12)

print("Customer Data Overview:")
print(customer_data.head())
print(f"\nDataset shape: {customer_data.shape}")
print(f"\nBasic statistics:\n{customer_data.describe()}")

# Exploratory Data Analysis
print("\n" + "="*50)
print("CUSTOMER DATA ANALYSIS")
print("="*50)

fig, axes = plt.subplots(3, 3, figsize=(18, 15))
fig.suptitle('Customer Data Exploratory Analysis', fontsize=16, fontweight='bold')

# 1. Age distribution
axes[0, 0].hist(customer_data['age'], bins=20, alpha=0.7, color='skyblue', edgecolor='black')
axes[0, 0].set_title('Age Distribution')
axes[0, 0].set_xlabel('Age')
axes[0, 0].set_ylabel('Frequency')

# 2. Income distribution
axes[0, 1].hist(customer_data['annual_income'], bins=20, alpha=0.7, color='lightgreen', edgecolor='black')
axes[0, 1].set_title('Annual Income Distribution')
axes[0, 1].set_xlabel('Annual Income ($)')
axes[0, 1].set_ylabel('Frequency')

# 3. Spending score distribution
axes[0, 2].hist(customer_data['spending_score'], bins=20, alpha=0.7, color='coral', edgecolor='black')
axes[0, 2].set_title('Spending Score Distribution')
axes[0, 2].set_xlabel('Spending Score')
axes[0, 2].set_ylabel('Frequency')

# 4. Income vs Spending
axes[1, 0].scatter(customer_data['annual_income'], customer_data['annual_spending'], alpha=0.6)
axes[1, 0].set_title('Income vs Annual Spending')
axes[1, 0].set_xlabel('Annual Income ($)')
axes[1, 0].set_ylabel('Annual Spending ($)')

# 5. Age vs Spending Score
axes[1, 1].scatter(customer_data['age'], customer_data['spending_score'], alpha=0.6, color='orange')
axes[1, 1].set_title('Age vs Spending Score')
axes[1, 1].set_xlabel('Age')
axes[1, 1].set_ylabel('Spending Score')

# 6. Purchase frequency distribution
axes[1, 2].hist(customer_data['purchase_frequency'], bins=15, alpha=0.7, color='purple', edgecolor='black')
axes[1, 2].set_title('Purchase Frequency Distribution')
axes[1, 2].set_xlabel('Purchase Frequency')
axes[1, 2].set_ylabel('Frequency')

# 7. Gender distribution
gender_counts = customer_data['gender'].value_counts()
axes[2, 0].pie(gender_counts.values, labels=gender_counts.index, autopct='%1.1f%%')
axes[2, 0].set_title('Gender Distribution')

# 8. Average Order Value distribution
axes[2, 1].hist(customer_data['avg_order_value'], bins=20, alpha=0.7, color='brown', edgecolor='black')
axes[2, 1].set_title('Average Order Value Distribution')
axes[2, 1].set_xlabel('Average Order Value ($)')
axes[2, 1].set_ylabel('Frequency')

# 9. Customer Lifetime Value
axes[2, 2].hist(customer_data['total_lifetime_value'], bins=20, alpha=0.7, color='pink', edgecolor='black')
axes[2, 2].set_title('Customer Lifetime Value Distribution')
axes[2, 2].set_xlabel('Total Lifetime Value ($)')
axes[2, 2].set_ylabel('Frequency')

plt.tight_layout()
plt.show()

# Correlation Analysis
numeric_columns = ['age', 'annual_income', 'spending_score', 'annual_spending', 
                  'purchase_frequency', 'customer_lifetime_months', 'avg_order_value', 
                  'total_lifetime_value']

correlation_matrix = customer_data[numeric_columns].corr()

plt.figure(figsize=(12, 10))
sns.heatmap(correlation_matrix, annot=True, cmap='coolwarm', center=0, 
            square=True, cbar_kws={'shrink': 0.8})
plt.title('Customer Features Correlation Matrix')
plt.tight_layout()
plt.show()

# Customer Segmentation using K-Means Clustering
print("\n" + "="*50)
print("CUSTOMER SEGMENTATION ANALYSIS")
print("="*50)

# Select features for clustering
clustering_features = ['annual_income', 'spending_score', 'annual_spending', 
                      'purchase_frequency', 'avg_order_value']
X_cluster = customer_data[clustering_features].copy()

# Scale the features
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X_cluster)

# Determine optimal number of clusters using elbow method
inertias = []
silhouette_scores = []
k_range = range(2, 11)

for k in k_range:
    kmeans = KMeans(n_clusters=k, random_state=42, n_init=10)
    kmeans.fit(X_scaled)
    inertias.append(kmeans.inertia_)
    silhouette_scores.append(silhouette_score(X_scaled, kmeans.labels_))

# Plot elbow curve and silhouette scores
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 5))

ax1.plot(k_range, inertias, 'bo-')
ax1.set_title('Elbow Method for Optimal K')
ax1.set_xlabel('Number of Clusters (k)')
ax1.set_ylabel('Inertia')
ax1.grid(True)

ax2.plot(k_range, silhouette_scores, 'ro-')
ax2.set_title('Silhouette Score for Different K')
ax2.set_xlabel('Number of Clusters (k)')
ax2.set_ylabel('Silhouette Score')
ax2.grid(True)

plt.tight_layout()
plt.show()

# Choose optimal number of clusters (highest silhouette score)
optimal_k = k_range[np.argmax(silhouette_scores)]
print(f"Optimal number of clusters: {optimal_k}")

# Perform final clustering
kmeans_final = KMeans(n_clusters=optimal_k, random_state=42, n_init=10)
customer_data['cluster'] = kmeans_final.fit_predict(X_scaled)

print(f"Silhouette Score for {optimal_k} clusters: {silhouette_score(X_scaled, customer_data['cluster']):.3f}")

# Analyze clusters
cluster_analysis = customer_data.groupby('cluster')[clustering_features + ['age']].agg(['mean', 'std'])
print("\nCluster Analysis:")
print(cluster_analysis.round(2))

# Cluster distribution
cluster_counts = customer_data['cluster'].value_counts().sort_index()
print(f"\nCluster sizes:")
print(cluster_counts)

# Visualize clusters
fig, axes = plt.subplots(2, 3, figsize=(18, 12))
fig.suptitle('Customer Segmentation Analysis', fontsize=16, fontweight='bold')

# 1. Income vs Spending Score
scatter1 = axes[0, 0].scatter(customer_data['annual_income'], customer_data['spending_score'], 
                             c=customer_data['cluster'], cmap='viridis', alpha=0.7)
axes[0, 0].set_title('Clusters: Income vs Spending Score')
axes[0, 0].set_xlabel('Annual Income ($)')
axes[0, 0].set_ylabel('Spending Score')
plt.colorbar(scatter1, ax=axes[0, 0])

# 2. Age vs Annual Spending
scatter2 = axes[0, 1].scatter(customer_data['age'], customer_data['annual_spending'], 
                             c=customer_data['cluster'], cmap='viridis', alpha=0.7)
axes[0, 1].set_title('Clusters: Age vs Annual Spending')
axes[0, 1].set_xlabel('Age')
axes[0, 1].set_ylabel('Annual Spending ($)')
plt.colorbar(scatter2, ax=axes[0, 1])

# 3. Purchase Frequency vs Average Order Value
scatter3 = axes[0, 2].scatter(customer_data['purchase_frequency'], customer_data['avg_order_value'], 
                             c=customer_data['cluster'], cmap='viridis', alpha=0.7)
axes[0, 2].set_title('Clusters: Purchase Frequency vs AOV')
axes[0, 2].set_xlabel('Purchase Frequency')
axes[0, 2].set_ylabel('Average Order Value ($)')
plt.colorbar(scatter3, ax=axes[0, 2])

# 4. Cluster distribution
cluster_counts.plot(kind='bar', ax=axes[1, 0], color='steelblue')
axes[1, 0].set_title('Cluster Size Distribution')
axes[1, 0].set_xlabel('Cluster')
axes[1, 0].set_ylabel('Number of Customers')
axes[1, 0].tick_params(axis='x', rotation=0)

# 5. Average metrics by cluster
cluster_means = customer_data.groupby('cluster')[['annual_income', 'spending_score', 'annual_spending']].mean()
cluster_means.plot(kind='bar', ax=axes[1, 1])
axes[1, 1].set_title('Average Metrics by Cluster')
axes[1, 1].set_xlabel('Cluster')
axes[1, 1].set_ylabel('Value')
axes[1, 1].legend(bbox_to_anchor=(1.05, 1), loc='upper left')
axes[1, 1].tick_params(axis='x', rotation=0)

# 6. PCA visualization
pca = PCA(n_components=2)
X_pca = pca.fit_transform(X_scaled)
scatter4 = axes[1, 2].scatter(X_pca[:, 0], X_pca[:, 1], c=customer_data['cluster'], 
                             cmap='viridis', alpha=0.7)
axes[1, 2].set_title('PCA Visualization of Clusters')
axes[1, 2].set_xlabel(f'PC1 ({pca.explained_variance_ratio_[0]:.2%} variance)')
axes[1, 2].set_ylabel(f'PC2 ({pca.explained_variance_ratio_[1]:.2%} variance)')
plt.colorbar(scatter4, ax=axes[1, 2])

plt.tight_layout()
plt.show()

# Cluster Profiling
print("\n" + "="*50)
print("CLUSTER PROFILING")
print("="*50)

cluster_profiles = {}
for cluster_id in sorted(customer_data['cluster'].unique()):
    cluster_data = customer_data[customer_data['cluster'] == cluster_id]
    
    profile = {
        'size': len(cluster_data),
        'avg_age': cluster_data['age'].mean(),
        'avg_income': cluster_data['annual_income'].mean(),
        'avg_spending_score': cluster_data['spending_score'].mean(),
        'avg_annual_spending': cluster_data['annual_spending'].mean(),
        'avg_purchase_frequency': cluster_data['purchase_frequency'].mean(),
        'avg_order_value': cluster_data['avg_order_value'].mean(),
        'total_lifetime_value': cluster_data['total_lifetime_value'].mean(),
        'gender_distribution': cluster_data['gender'].value_counts(normalize=True).to_dict()
    }
    
    cluster_profiles[cluster_id] = profile

# Define cluster personas based on characteristics
cluster_names = {}
for cluster_id, profile in cluster_profiles.items():
    if profile['avg_income'] > 60000 and profile['avg_spending_score'] > 60:
        cluster_names[cluster_id] = "High-Value Customers"
    elif profile['avg_income'] < 40000 and profile['avg_spending_score'] < 40:
        cluster_names[cluster_id] = "Budget-Conscious Customers"
    elif profile['avg_spending_score'] > 70:
        cluster_names[cluster_id] = "High-Spenders"
    elif profile['avg_purchase_frequency'] > 15:
        cluster_names[cluster_id] = "Frequent Buyers"
    else:
        cluster_names[cluster_id] = f"Cluster {cluster_id}"

# Print detailed cluster analysis
for cluster_id, profile in cluster_profiles.items():
    print(f"\n{cluster_names[cluster_id]} (Cluster {cluster_id}):")
    print(f"  Size: {profile['size']} customers ({profile['size']/len(customer_data)*100:.1f}%)")
    print(f"  Average Age: {profile['avg_age']:.1f} years")
    print(f"  Average Income: ${profile['avg_income']:,.0f}")
    print(f"  Average Spending Score: {profile['avg_spending_score']:.1f}")
    print(f"  Average Annual Spending: ${profile['avg_annual_spending']:,.0f}")
    print(f"  Average Purchase Frequency: {profile['avg_purchase_frequency']:.1f}")
    print(f"  Average Order Value: ${profile['avg_order_value']:,.0f}")
    print(f"  Average Lifetime Value: ${profile['total_lifetime_value']:,.0f}")
    print(f"  Gender: {profile['gender_distribution']}")

# Business Recommendations
print("\n" + "="*50)
print("BUSINESS RECOMMENDATIONS")
print("="*50)

print("Marketing Strategy Recommendations:")
for cluster_id, profile in cluster_profiles.items():
    cluster_name = cluster_names[cluster_id]
    print(f"\n{cluster_name}:")
    
    if "High-Value" in cluster_name:
        print("  - Focus on premium products and personalized service")
        print("  - Implement VIP loyalty programs")
        print("  - Offer exclusive early access to new products")
    elif "Budget-Conscious" in cluster_name:
        print("  - Emphasize value propositions and discounts")
        print("  - Promote budget-friendly product lines")
        print("  - Use price-based marketing campaigns")
    elif "High-Spenders" in cluster_name:
        print("  - Target with premium product recommendations")
        print("  - Focus on upselling and cross-selling")
        print("  - Implement cashback or rewards programs")
    elif "Frequent" in cluster_name:
        print("  - Optimize inventory for quick restocking")
        print("  - Implement subscription services")
        print("  - Focus on customer retention programs")
    else:
        print("  - Develop targeted campaigns based on specific needs")
        print("  - A/B test different marketing approaches")

# Save results
customer_data['cluster_name'] = customer_data['cluster'].map(cluster_names)
customer_data.to_csv('customer_segmentation_results.csv', index=False)

cluster_summary = pd.DataFrame(cluster_profiles).T
cluster_summary.to_csv('cluster_analysis_summary.csv')

print("\nResults saved to CSV files:")
print("- customer_segmentation_results.csv")
print("- cluster_analysis_summary.csv")
```

## Environment Setup & Requirements

### **📋 Requirements File**
```bash
# requirements.txt
numpy>=1.21.0
pandas>=1.3.0
matplotlib>=3.4.0
seaborn>=0.11.0
scikit-learn>=1.0.0
jupyter>=1.0.0
ipython>=7.0.0
plotly>=5.0.0
statsmodels>=0.12.0
scipy>=1.7.0
```

### **🚀 Installation & Setup**
```bash
# Create virtual environment
python -m venv data_science_env
source data_science_env/bin/activate  # On Windows: data_science_env\Scripts\activate

# Install packages
pip install -r requirements.txt

# Launch Jupyter Notebook
jupyter notebook

# Or use Jupyter Lab
pip install jupyterlab
jupyter lab
```

## Useful Links

- [NumPy Documentation](https://numpy.org/doc/)
- [Pandas Documentation](https://pandas.pydata.org/docs/)
- [Matplotlib Gallery](https://matplotlib.org/stable/gallery/)
- [Seaborn Tutorial](https://seaborn.pydata.org/tutorial.html)
- [Scikit-learn Documentation](https://scikit-learn.org/stable/)
- [Jupyter Documentation](https://jupyter.org/documentation)
