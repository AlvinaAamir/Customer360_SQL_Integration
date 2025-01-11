# Customer360 SQL Integration Project

## Objective
The goal of this project was to create a Customer360 view for an online retailer by integrating data from multiple tables, providing insights into customer conversions, order history, and cumulative revenue.

---

## Methodology
1. **Data Integration**:
   - Utilized tables from `mban_db`:
     - `fact_tables.orders`
     - `fact_tables.conversions`
     - `dimensions.date_dimension`
     - `dimensions.product_dimension`
     - `dimensions.customer_dimension`
   - Created a `customer360` schema to store the integrated view.

2. **CTEs and Transformations**:
   - **CustomerConversionData**: Captured customer conversions, including type, date, week, and channel.
   - **FirstOrderPlaced**: Aggregated first order details for each conversion.
   - **OrderHistory**: Calculated weekly metrics (e.g., orders placed, revenue, discounts).
   - **AllWeeks**: Ensured inclusion of all possible weeks within conversion periods.
   - **customer360_cte**: Combined all CTEs for the final integrated view.

3. **Final View**:
   - Generated rows for each week from the conversion week to the next, including metrics like lifetime cumulative revenue.

---

## Challenges
- **Schema Creation**: Issues with creating the `customer360` schema, resolved using `SELECT INTO` commands.
- **Data Joins**: Ensured accurate joins between fact and dimension tables.
- **Next Conversion Week**: Used conditional functions (`ISNULL`) to handle missing data.
- **Performance**: Optimized SQL queries using window functions to handle complex aggregations efficiently.

---

## Files
1. **SQL Script**: [Customer360_Final.sql](./Customer360_Final.sql)
2. **Final Report**: [Customer360 Project Final Report.pdf](./Customer360%20Project%20Final%20Report.pdf)

---

## How to Use
1. Clone this repository:
   ```bash
   git clone https://github.com/YourUsername/Customer360_SQL_Integration.git

