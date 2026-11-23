CREATE DATABASE IF NOT EXISTS food_delivery_analysis;
USE food_delivery_analysis;
CREATE TABLE orders_raw (
    order_id VARCHAR(100), customer_id VARCHAR(100), restaurant_id VARCHAR(100), driver_id VARCHAR(100),
    order_timestamp VARCHAR(100), order_date VARCHAR(100), order_hour VARCHAR(100), day_of_week VARCHAR(100),
    is_weekend VARCHAR(100), city VARCHAR(100), delivery_area VARCHAR(100), customer_age VARCHAR(100),
    customer_type VARCHAR(100), restaurant_type VARCHAR(100), restaurant_primary_category VARCHAR(100),
    restaurant_rating VARCHAR(100), items_count VARCHAR(100), subtotal VARCHAR(100), discount_percent VARCHAR(100),
    tax_amount VARCHAR(100), service_fee VARCHAR(100), delivery_fee VARCHAR(100), order_total VARCHAR(100),
    payment_method VARCHAR(100), tip_amount VARCHAR(100), distance_km VARCHAR(100), weather VARCHAR(100),
    traffic_level VARCHAR(100), delivery_partner_experience_months VARCHAR(100), delivery_partner_rating VARCHAR(100),
    restaurant_preparation_time_minutes VARCHAR(100), estimated_delivery_time_minutes VARCHAR(100),
    actual_delivery_time_minutes VARCHAR(100), late_delivery VARCHAR(100), order_status VARCHAR(100),
    cancellation_reason VARCHAR(100), customer_rating VARCHAR(100), discount_amount VARCHAR(100),
    net_food_value VARCHAR(100), total_fees VARCHAR(100), calculated_total VARCHAR(100), total_with_tip VARCHAR(100),
    delay_minutes VARCHAR(100), is_delayed VARCHAR(100), delay_category VARCHAR(100), time_of_day VARCHAR(100),
    age_group VARCHAR(100), experience_band VARCHAR(100), distance_band VARCHAR(100), prep_time_band VARCHAR(100)
);

SHOW TABLES;
SELECT COUNT(*) FROM orders_raw;
CREATE TABLE customers (
    customer_id   VARCHAR(20) PRIMARY KEY,
    customer_age  INT,
    customer_type VARCHAR(20)          -- Regular / Premium / New
);

CREATE TABLE restaurants (
    restaurant_id               VARCHAR(20) PRIMARY KEY,
    restaurant_type             VARCHAR(50),
    restaurant_primary_category VARCHAR(50),   -- Burger, Pizza, Asian...
    restaurant_rating           DECIMAL(3,2),
    city                        VARCHAR(20)
);

CREATE TABLE drivers (
    driver_id          VARCHAR(20) PRIMARY KEY,
    experience_months  DECIMAL(6,1),
    experience_band    VARCHAR(20),
    driver_rating      DECIMAL(3,2)
);

CREATE TABLE orders (
    order_id                    VARCHAR(20) PRIMARY KEY,
    customer_id                 VARCHAR(20) NOT NULL,
    restaurant_id               VARCHAR(20) NOT NULL,
    driver_id                   VARCHAR(20) NOT NULL,
    order_timestamp             DATETIME,
    city                        VARCHAR(20),
    delivery_area               VARCHAR(30),
    items_count                 INT,
    subtotal                    DECIMAL(10,2),
    discount_percent            INT,
    discount_amount             DECIMAL(10,2),
    tax_amount                  DECIMAL(10,2),
    service_fee                 DECIMAL(10,2),
    delivery_fee                DECIMAL(10,2),
    order_total                 DECIMAL(10,2),
    tip_amount                  DECIMAL(10,2),
    payment_method              VARCHAR(30),
    distance_km                 DECIMAL(6,2),
    weather                     VARCHAR(20),
    traffic_level               VARCHAR(20),
    prep_time_minutes           DECIMAL(6,1),
    estimated_delivery_minutes  DECIMAL(6,1),
    actual_delivery_minutes     DECIMAL(6,1),
    delay_minutes               DECIMAL(6,1),
    late_delivery               TINYINT,
    order_status                VARCHAR(20),
    cancellation_reason         VARCHAR(50),
    customer_rating             DECIMAL(3,1),
    FOREIGN KEY (customer_id)   REFERENCES customers(customer_id),
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id),
    FOREIGN KEY (driver_id)     REFERENCES drivers(driver_id)
);
INSERT INTO customers
SELECT customer_id, MAX(customer_age), MAX(customer_type)
FROM orders_raw
GROUP BY customer_id;

INSERT INTO restaurants
SELECT restaurant_id, MAX(restaurant_type), MAX(restaurant_primary_category),
       MAX(restaurant_rating), MAX(city)
FROM orders_raw
GROUP BY restaurant_id;

INSERT INTO drivers
SELECT driver_id, MAX(delivery_partner_experience_months), MAX(experience_band),
       MAX(delivery_partner_rating)
FROM orders_raw
GROUP BY driver_id;

INSERT INTO orders
SELECT order_id, customer_id, restaurant_id, driver_id,
       NULLIF(order_timestamp,''),
       city, delivery_area,
       CAST(NULLIF(items_count,'')       AS UNSIGNED),
       CAST(NULLIF(subtotal,'')          AS DECIMAL(10,2)),
       CAST(NULLIF(discount_percent,'')  AS UNSIGNED),
       CAST(NULLIF(discount_amount,'')   AS DECIMAL(10,2)),
       CAST(NULLIF(tax_amount,'')        AS DECIMAL(10,2)),
       CAST(NULLIF(service_fee,'')       AS DECIMAL(10,2)),
       CAST(NULLIF(delivery_fee,'')      AS DECIMAL(10,2)),
       CAST(NULLIF(order_total,'')       AS DECIMAL(10,2)),
       CAST(NULLIF(tip_amount,'')        AS DECIMAL(10,2)),
       NULLIF(payment_method,''),
       CAST(NULLIF(distance_km,'')       AS DECIMAL(6,2)),
       NULLIF(weather,''),
       NULLIF(traffic_level,''),
       CAST(NULLIF(restaurant_preparation_time_minutes,'') AS DECIMAL(6,1)),
       CAST(NULLIF(estimated_delivery_time_minutes,'')     AS DECIMAL(6,1)),
       CAST(NULLIF(actual_delivery_time_minutes,'')        AS DECIMAL(6,1)),
       CAST(NULLIF(delay_minutes,'')     AS DECIMAL(6,1)),
       CAST(NULLIF(late_delivery,'')     AS DECIMAL(3,1)),
       NULLIF(order_status,''),
       NULLIF(cancellation_reason,''),
       CAST(NULLIF(customer_rating,'')   AS DECIMAL(3,1))
FROM orders_raw;
SELECT (SELECT COUNT(*) FROM customers)   AS customers,    -- 3030
       (SELECT COUNT(*) FROM restaurants) AS restaurants,  -- 250
       (SELECT COUNT(*) FROM drivers)     AS drivers,      -- 200
       (SELECT COUNT(*) FROM orders)      AS orders;       -- 18160
       
-- Total orders
SELECT COUNT(*) AS total_orders FROM orders;

-- Total customers
SELECT COUNT(*) AS total_customers FROM customers;

-- Orders by customer type (your "loyalty tier")
SELECT c.customer_type, COUNT(o.order_id) AS total_orders
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_type
ORDER BY total_orders DESC;

-- Top 10 customers by order value (completed orders only)
SELECT customer_id, SUM(order_total) AS total_order_value
FROM orders
WHERE order_status = 'Completed'
GROUP BY customer_id
ORDER BY total_order_value DESC
LIMIT 10;

-- Revenue by cuisine / category
SELECT r.restaurant_primary_category AS cuisine,
       SUM(o.order_total) AS revenue
FROM orders o
JOIN restaurants r ON o.restaurant_id = r.restaurant_id
WHERE o.order_status = 'Completed'
GROUP BY r.restaurant_primary_category
ORDER BY revenue DESC;

-- Average ETA and actual delivery time by traffic
SELECT traffic_level,
       AVG(estimated_delivery_minutes) AS average_eta,
       AVG(actual_delivery_minutes)    AS average_actual
FROM orders
WHERE order_status = 'Completed'
GROUP BY traffic_level
ORDER BY average_eta DESC;

-- Average ETA and actual delivery time by weather
SELECT weather,
       AVG(estimated_delivery_minutes) AS average_eta,
       AVG(actual_delivery_minutes)    AS average_actual
FROM orders
WHERE order_status = 'Completed'
GROUP BY weather
ORDER BY average_eta DESC;

-- Driver performance by experience band
SELECT d.experience_band,
       AVG(d.driver_rating)               AS avg_rating,
       AVG(o.estimated_delivery_minutes)  AS avg_eta,
       AVG(o.actual_delivery_minutes)     AS avg_actual,
       COUNT(o.order_id)                  AS total_orders
FROM drivers d
JOIN orders o ON d.driver_id = o.driver_id
WHERE o.order_status = 'Completed'
GROUP BY d.experience_band;

-- Restaurant performance
SELECT r.restaurant_id, r.restaurant_primary_category AS cuisine,
       r.restaurant_rating,
       AVG(o.estimated_delivery_minutes) AS average_eta,
       COUNT(o.order_id)                 AS total_orders
FROM restaurants r
JOIN orders o ON r.restaurant_id = o.restaurant_id
GROUP BY r.restaurant_id, r.restaurant_primary_category, r.restaurant_rating
ORDER BY average_eta DESC;