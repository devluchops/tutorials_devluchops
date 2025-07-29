import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime, timedelta

def generate_sales_data(start_date='2023-01-01', end_date='2023-12-31', base_sales=1000):
    """
    Generate realistic sales data with seasonality and trends
    
    Parameters:
    start_date (str): Start date for data generation
    end_date (str): End date for data generation
    base_sales (int): Base sales amount
    
    Returns:
    pd.DataFrame: Generated sales data
    """
    # Set random seed for reproducibility
    np.random.seed(42)
    
    # Generate date range
    dates = pd.date_range(start=start_date, end=end_date, freq='D')
    n_days = len(dates)
    
    # Create realistic sales data with seasonality
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
    
    return sales_data

def analyze_sales_data(sales_data):
    """
    Perform comprehensive sales data analysis
    
    Parameters:
    sales_data (pd.DataFrame): Sales data to analyze
    
    Returns:
    dict: Analysis results
    """
    print("Sales Data Overview:")
    print(sales_data.head())
    print(f"\nDataset shape: {sales_data.shape}")
    print(f"\nData types:\n{sales_data.dtypes}")

    # Basic statistics
    print("\nBasic Statistics:")
    print(sales_data['sales'].describe())

    # Monthly sales analysis
    monthly_sales = sales_data.groupby('month')['sales'].agg(['sum', 'mean', 'count'])
    print("\nMonthly Sales Summary:")
    print(monthly_sales)

    # Day of week analysis
    dow_sales = sales_data.groupby('day_of_week')['sales'].mean().reindex([
        'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ])
    print("\nAverage Sales by Day of Week:")
    print(dow_sales)

    # Product category analysis
    category_sales = sales_data.groupby('product_category')['sales'].agg(['sum', 'mean', 'count'])
    print("\nSales by Product Category:")
    print(category_sales)
    
    return {
        'monthly_sales': monthly_sales,
        'dow_sales': dow_sales,
        'category_sales': category_sales
    }

def create_sales_dashboard(sales_data, analysis_results):
    """
    Create comprehensive sales analysis dashboard
    
    Parameters:
    sales_data (pd.DataFrame): Sales data
    analysis_results (dict): Analysis results from analyze_sales_data
    """
    fig, axes = plt.subplots(2, 2, figsize=(15, 12))
    fig.suptitle('Sales Data Analysis Dashboard', fontsize=16, fontweight='bold')

    # 1. Time series plot
    axes[0, 0].plot(sales_data['date'], sales_data['sales'], alpha=0.7, linewidth=1)
    axes[0, 0].set_title('Daily Sales Over Time')
    axes[0, 0].set_xlabel('Date')
    axes[0, 0].set_ylabel('Sales ($)')
    axes[0, 0].tick_params(axis='x', rotation=45)

    # 2. Monthly sales trend
    analysis_results['monthly_sales']['mean'].plot(kind='bar', ax=axes[0, 1], color='steelblue')
    axes[0, 1].set_title('Average Monthly Sales')
    axes[0, 1].set_xlabel('Month')
    axes[0, 1].set_ylabel('Average Sales ($)')
    axes[0, 1].tick_params(axis='x', rotation=0)

    # 3. Day of week analysis
    analysis_results['dow_sales'].plot(kind='bar', ax=axes[1, 0], color='lightcoral')
    axes[1, 0].set_title('Average Sales by Day of Week')
    axes[1, 0].set_xlabel('Day of Week')
    axes[1, 0].set_ylabel('Average Sales ($)')
    axes[1, 0].tick_params(axis='x', rotation=45)

    # 4. Product category distribution
    analysis_results['category_sales']['sum'].plot(kind='pie', ax=axes[1, 1], autopct='%1.1f%%')
    axes[1, 1].set_title('Total Sales by Product Category')
    axes[1, 1].set_ylabel('')

    plt.tight_layout()
    plt.show()

def advanced_sales_analysis(sales_data):
    """
    Perform advanced sales analysis with correlations and trends
    
    Parameters:
    sales_data (pd.DataFrame): Sales data to analyze
    """
    print("\n" + "="*50)
    print("ADVANCED ANALYSIS")
    print("="*50)

    # Create additional features for analysis
    sales_data_copy = sales_data.copy()
    sales_data_copy['sales_ma_7'] = sales_data_copy['sales'].rolling(window=7).mean()
    sales_data_copy['sales_ma_30'] = sales_data_copy['sales'].rolling(window=30).mean()
    sales_data_copy['day_of_year'] = sales_data_copy['date'].dt.dayofyear

    # Correlation analysis
    numeric_columns = ['sales', 'month', 'quarter', 'units_sold', 'day_of_year']
    correlation_matrix = sales_data_copy[numeric_columns].corr()

    plt.figure(figsize=(10, 8))
    sns.heatmap(correlation_matrix, annot=True, cmap='coolwarm', center=0,
                square=True, cbar_kws={'shrink': 0.8})
    plt.title('Feature Correlation Matrix')
    plt.tight_layout()
    plt.show()

    # Trend analysis with moving averages
    plt.figure(figsize=(15, 8))
    plt.plot(sales_data_copy['date'], sales_data_copy['sales'], alpha=0.3, label='Daily Sales', color='gray')
    plt.plot(sales_data_copy['date'], sales_data_copy['sales_ma_7'], label='7-day Moving Average', color='blue')
    plt.plot(sales_data_copy['date'], sales_data_copy['sales_ma_30'], label='30-day Moving Average', color='red')
    plt.title('Sales Trends with Moving Averages')
    plt.xlabel('Date')
    plt.ylabel('Sales ($)')
    plt.legend()
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.show()

    return sales_data_copy

def generate_summary_insights(sales_data, analysis_results):
    """
    Generate key business insights from the analysis
    
    Parameters:
    sales_data (pd.DataFrame): Sales data
    analysis_results (dict): Analysis results
    
    Returns:
    dict: Summary insights
    """
    summary_stats = {
        'total_sales': sales_data['sales'].sum(),
        'average_daily_sales': sales_data['sales'].mean(),
        'best_selling_day': analysis_results['dow_sales'].idxmax(),
        'best_selling_month': analysis_results['monthly_sales']['sum'].idxmax(),
        'top_product_category': analysis_results['category_sales']['sum'].idxmax()
    }

    print("\nKey Insights:")
    for key, value in summary_stats.items():
        print(f"- {key.replace('_', ' ').title()}: {value}")
    
    return summary_stats

def main():
    """
    Main function to run the complete sales data analysis
    """
    print("="*60)
    print("SALES DATA ANALYSIS PROJECT")
    print("="*60)
    
    # Generate sample data
    sales_data = generate_sales_data()
    
    # Perform analysis
    analysis_results = analyze_sales_data(sales_data)
    
    # Create dashboard
    create_sales_dashboard(sales_data, analysis_results)
    
    # Advanced analysis
    enhanced_data = advanced_sales_analysis(sales_data)
    
    # Generate insights
    insights = generate_summary_insights(sales_data, analysis_results)
    
    # Save results
    print("\nExporting results...")
    sales_data.to_csv('sales_analysis_results.csv', index=False)
    enhanced_data.to_csv('enhanced_sales_data.csv', index=False)
    print("Data saved to CSV files")
    
    return sales_data, analysis_results, insights

if __name__ == "__main__":
    sales_data, analysis_results, insights = main()
