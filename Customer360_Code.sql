USE kacheamp_db;

-- Step 1: Create schema if not exists
CREATE SCHEMA IF NOT EXISTS customer360;

-- Step 2: Static Customer Conversion Data
WITH CustomerConversionData AS (
    SELECT
        c.customer_id,
        c.first_name,
        c.last_name,
        conv.conversion_id,
        ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY conv.conversion_date) AS conversion_number,
        conv.conversion_type,
        conv.conversion_date,
        dd.week AS conversion_week,
        LEAD(dd.week) OVER (PARTITION BY c.customer_id ORDER BY conv.conversion_date) AS next_conversion_week,
        conv.conversion_channel
    FROM
        dimensions.customer_dimension c
    INNER JOIN fact_tables.conversions conv
        ON c.customer_id = conv.customer_id
    INNER JOIN dimensions.date_dimension dd
        ON dd.date = conv.conversion_date
),

-- Step 3: First Order Placed Data
FirstOrderPlaced AS (
    SELECT DISTINCT
        conv.customer_id,
        conv.conversion_id,
        MIN(dd.week) AS first_order_week,
        FIRST_VALUE(o.total_paid) OVER (
            PARTITION BY conv.customer_id, conv.conversion_id ORDER BY dd.week
        ) AS first_order_total_paid
    FROM
        CustomerConversionData conv
    LEFT JOIN fact_tables.orders o
        ON conv.customer_id = o.customer_id
    INNER JOIN dimensions.date_dimension dd
        ON dd.date = o.order_date
    WHERE dd.week >= conv.conversion_week AND 
          (dd.week < conv.next_conversion_week OR conv.next_conversion_week IS NULL)
    GROUP BY
        conv.customer_id, conv.conversion_id
),

-- Step 4: Order History 
OrderHistory AS (
    SELECT
        conv.customer_id,
        conv.conversion_id,
        dd.week AS order_week,
        CASE WHEN o.order_id IS NOT NULL THEN 1 ELSE 0 END AS orders_placed,
        COALESCE(SUM(o.total_before_discounts), 0) AS total_before_discounts,
        COALESCE(SUM(o.total_discounts), 0) AS total_discounts,
        COALESCE(SUM(o.total_paid), 0) AS total_paid_in_week
    FROM
        CustomerConversionData conv
    CROSS JOIN dimensions.date_dimension dd
    LEFT JOIN fact_tables.orders o
        ON conv.customer_id = o.customer_id AND dd.date = o.order_date
    WHERE dd.week >= conv.conversion_week AND 
          (dd.week < conv.next_conversion_week OR conv.next_conversion_week IS NULL)
    GROUP BY
        conv.customer_id, conv.conversion_id, dd.week, o.order_id
),

-- Step 5: Final Customer360 View
Customer360_CTE AS (
    SELECT
        conv.*,
        oh.order_week,
        oh.orders_placed,
        oh.total_before_discounts,
        oh.total_discounts,
        oh.total_paid_in_week,
        SUM(oh.total_paid_in_week) OVER (
            PARTITION BY conv.customer_id, conv.conversion_id ORDER BY oh.order_week
        ) AS conversion_cumulative_revenue,
        SUM(oh.total_paid_in_week) OVER (
            PARTITION BY conv.customer_id ORDER BY oh.order_week
        ) AS lifetime_cumulative_revenue
    FROM
        CustomerConversionData conv
    LEFT JOIN OrderHistory oh
        ON conv.customer_id = oh.customer_id AND conv.conversion_id = oh.conversion_id
)

-- Step 6: Create Final Table
SELECT * INTO customer360.Customer360_View
FROM Customer360_CTE
ORDER BY customer_id, conversion_number, order_week;
