USE kacheamp_db;

-- create schema if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'customer360')
BEGIN
    EXEC('CREATE SCHEMA customer360');
END
;


-- Code to build the Customer 360 table
WITH CustomerConversionData AS (
    -- extract static customer and conversion data
    SELECT
        cd.customer_id,
        cd.first_name,
        cd.last_name,
        cv.conversion_id,
        -- calculate conversion number for each customer
        ROW_NUMBER() OVER (PARTITION BY cd.customer_id ORDER BY cv.conversion_date) AS conversion_number,
        cv.conversion_type,
        cv.conversion_date,
        dd.year_week AS conversion_week,
        -- Determine the next conversion week
        LEAD(dd.year_week) OVER (PARTITION BY cd.customer_id ORDER BY cv.conversion_date) AS next_conversion_week,
        cv.conversion_channel
    FROM mban_db.fact_tables.conversions AS cv
    JOIN mban_db.dimensions.customer_dimension AS cd ON cv.fk_customer = cd.sk_customer
    JOIN mban_db.dimensions.date_dimension AS dd ON cv.fk_conversion_date = dd.sk_date
),

-- CTE for first order placed data
FirstOrderPlaced AS (
    -- gather data related to the first order placed by the customer
    SELECT
        cd.customer_id,
        cv.conversion_id,
        -- calculate the earliest order week
        MIN(dd.year_week) AS first_order_week,
        -- Calculate the total price paid for the first order
        MIN(o.price_paid) AS first_order_total_paid,
        pd.product_name AS first_order_product
    FROM mban_db.fact_tables.orders AS o
    JOIN mban_db.fact_tables.conversions AS cv ON o.order_number = cv.order_number
    JOIN mban_db.dimensions.date_dimension AS dd ON o.fk_order_date = dd.sk_date
    JOIN mban_db.dimensions.customer_dimension AS cd ON o.fk_customer = cd.sk_customer
    JOIN mban_db.dimensions.product_dimension AS pd ON o.fk_product = pd.sk_product
    GROUP BY cd.customer_id, cv.conversion_id, pd.product_name
),

-- CTE for order history
OrderHistory AS (
    -- compile customer's order history
    SELECT
        cd.customer_id,
        dd.year_week AS order_week,
        -- count the orders placed
        COUNT(o.order_id) AS orders_placed,
        -- sum up the total price before discounts
        SUM(o.unit_price) AS total_before_discounts,
        -- sum up the total discounts
        SUM(o.discount_value) AS total_discounts,
        -- sum up the total price paid in the week
        SUM(o.price_paid) AS total_paid_in_week
    FROM mban_db.fact_tables.orders AS o
    JOIN mban_db.dimensions.date_dimension AS dd ON o.fk_order_date = dd.sk_date
    JOIN mban_db.dimensions.customer_dimension AS cd ON o.fk_customer = cd.sk_customer
    GROUP BY cd.customer_id, dd.year_week
),

-- CTE to generate all possible weeks for each customer within conversion periods
AllWeeks AS (
    -- generate all possible weeks for each customer within conversion periods
    SELECT
        DISTINCT cd.customer_id,
        dd.year_week
    FROM mban_db.dimensions.date_dimension AS dd
    CROSS JOIN mban_db.dimensions.customer_dimension AS cd
),

-- CTE to aggregate customer 360 data
customer360_cte AS (
    -- generate comprehensive data for each customer conversion
    SELECT
        cc.customer_id,
        cc.first_name,
        cc.last_name,
        cc.conversion_id,
        cc.conversion_number,
        cc.conversion_type,
        cc.conversion_date,
        cc.conversion_week,
        cc.next_conversion_week,
        cc.conversion_channel,
        fo.first_order_week,
        fo.first_order_total_paid,
        fo.first_order_product,
        aw.year_week AS order_week,
        -- calculate week counter for each conversion
        ROW_NUMBER() OVER (PARTITION BY cc.customer_id, cc.conversion_id ORDER BY aw.year_week) AS week_counter,
        -- handle null values and set default to 0
        ISNULL(oh.orders_placed, 0) AS order_placed,
        ISNULL(oh.total_before_discounts, 0) AS total_before_discounts,
        ISNULL(oh.total_discounts, 0) AS total_discounts,
        ISNULL(oh.total_paid_in_week, 0) AS total_paid,
        -- calculate conversion cumulative revenue
        SUM(ISNULL(oh.total_paid_in_week, 0)) OVER (PARTITION BY cc.customer_id, cc.conversion_id ORDER BY aw.year_week) AS conversion_cumulative_revenue,
        -- calculate lifetime cumulative revenue
        SUM(ISNULL(oh.total_paid_in_week, 0)) OVER (PARTITION BY cc.customer_id ORDER BY aw.year_week ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS lifetime_cumulative_revenue
    FROM CustomerConversionData AS cc
    LEFT JOIN FirstOrderPlaced fo ON cc.customer_id = fo.customer_id AND cc.conversion_id = fo.conversion_id
    LEFT JOIN AllWeeks aw ON cc.customer_id = aw.customer_id AND aw.year_week BETWEEN cc.conversion_week AND ISNULL(cc.next_conversion_week, aw.year_week)
    LEFT JOIN OrderHistory oh ON cc.customer_id = oh.customer_id AND aw.year_week = oh.order_week
)

-- select from the final customer360_cte and create the final table and insert into customer360 schema
SELECT *
INTO customer360.customer360_table
FROM customer360_cte
ORDER BY customer_id, conversion_number, week_counter;