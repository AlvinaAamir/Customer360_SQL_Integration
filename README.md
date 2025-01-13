# Customer360 Project

## Overview
The Customer360 Project aims to create a unified view of customer activity for an online retailer. This view integrates data from multiple tables, providing comprehensive insights into customer conversions, order history, and cumulative revenue. These insights can be used to understand customer behavior better and support data-driven business decisions.

## Objectives
- Integrate data from various fact and dimension tables.
- Create a detailed Customer360 view containing specified attributes such as customer conversion details, first order data, and order history.
- Ensure data accuracy, eliminate overlaps, and provide actionable insights through SQL.

## Features
The resulting Customer360 table includes:

### **Static Customer/Conversion Data**
- **customer_id:** Unique identifier for the customer.
- **first_name, last_name:** Customer's name.
- **conversion_id:** Unique identifier for each conversion.
- **conversion_number:** Sequential conversion count for each customer.
- **conversion_type:** Type of conversion (activation or reactivation).
- **conversion_date and conversion_week:** Date and week of conversion.
- **next_conversion_week:** Week of the next conversion or `NULL` if none exists.
- **conversion_channel:** Channel through which the conversion occurred.

### **First Order Data**
- **first_order_week:** Week of the first order associated with the conversion.
- **first_order_total_paid:** Total paid for the first order.

### **Order History**
- **week_counter:** Sequence of weeks starting from the conversion week.
- **order_week:** Specific week of the order.
- **orders_placed:** Binary indicator (1/0) of whether an order was placed.
- **total_before_discounts:** Total order value before discounts for a given week.
- **total_discounts:** Discounts applied in a given week.
- **total_paid_in_week:** Total paid after discounts in a given week.
- **conversion_cumulative_revenue:** Cumulative revenue during the conversion period.
- **lifetime_cumulative_revenue:** Cumulative revenue since the customer's first activation.

## Data Sources
The project utilizes the following tables from the `mmai_db` database:
- **fact_tables.orders**
- **fact_tables.conversions**
- **dimensions.date_dimension**
- **dimensions.product_dimension**
- **dimensions.customer_dimension**

## Steps Taken
1. **Schema Creation:**
   - Created a schema named `customer360` to store the final view and intermediate data.

2. **Static Customer Data:**
   - Captured customer conversion details using SQL functions like `ROW_NUMBER()` and `LEAD()`.

3. **First Order Data:**
   - Used `FIRST_VALUE()` to retrieve details of the first order per conversion, ensuring accuracy.

4. **Order History:**
   - Aggregated weekly data with key metrics, ensuring all weeks are covered, including those with no orders.
   - Avoided overlaps in conversion periods using conditions like `order_week < next_conversion_week OR next_conversion_week IS NULL`.

5. **Cumulative Revenue:**
   - Calculated revenue metrics using SQL window functions for both the conversion period and lifetime revenue.

6. **Final Table:**
   - Combined all data into the final Customer360 view, logically ordered for analysis.

## Challenges Addressed
- Ensuring accurate joins between fact and dimension tables.
- Handling weeks with no orders while maintaining data integrity.
- Avoiding overlaps in conversion periods.
- Optimizing SQL queries for large datasets.

## Deliverables
- **SQL Script:** Contains the SQL queries used to generate the Customer360 view.
- **Project Report:** A detailed explanation of the methodology, challenges, and results.

## How to Use
1. Clone this repository.
2. Run the SQL script (`Customer360_Code.sql`) on the provided database schema.
3. The `customer360.Customer360_View` table will be created in your database.
4. Refer to the project report (`Customer360 Project Report.pdf`) for detailed documentation.
