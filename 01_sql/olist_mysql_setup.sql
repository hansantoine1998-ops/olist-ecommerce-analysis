-- =====================================================
-- PROYECTO 1: OLIST E-COMMERCE - Creación e importación
-- =====================================================
-- ANTES DE EJECUTAR:
-- 1) Activa local_infile en el servidor:  SET GLOBAL local_infile = 1;
-- 2) En Workbench: edita tu conexión -> pestaña Advanced -> en "Others" escribe:  OPT_LOCAL_INFILE=1
--    (cierra y vuelve a abrir la conexión)
-- 3) Las rutas usan "/" en vez de "\" (obligatorio en MySQL). Ajusta si cambias de carpeta.
-- =====================================================

DROP DATABASE IF EXISTS olist;
CREATE DATABASE olist CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE olist;

-- ---------- 1. CREAR TABLAS ----------

CREATE TABLE customers (
    customer_id              VARCHAR(32) NOT NULL,
    customer_unique_id       VARCHAR(32),
    customer_zip_code_prefix VARCHAR(5),
    customer_city            VARCHAR(100),
    customer_state           CHAR(2),
    PRIMARY KEY (customer_id)
);

CREATE TABLE geolocation (
    geolocation_zip_code_prefix VARCHAR(5),
    geolocation_lat             DECIMAL(18,15),
    geolocation_lng             DECIMAL(18,15),
    geolocation_city            VARCHAR(100),
    geolocation_state           CHAR(2)
);

CREATE TABLE sellers (
    seller_id              VARCHAR(32) NOT NULL,
    seller_zip_code_prefix VARCHAR(5),
    seller_city            VARCHAR(100),
    seller_state           CHAR(2),
    PRIMARY KEY (seller_id)
);

CREATE TABLE products (
    product_id                 VARCHAR(32) NOT NULL,
    product_category_name      VARCHAR(100),
    product_name_lenght        INT,
    product_description_lenght INT,
    product_photos_qty         INT,
    product_weight_g           INT,
    product_length_cm          INT,
    product_height_cm          INT,
    product_width_cm           INT,
    PRIMARY KEY (product_id)
);

CREATE TABLE category_translation (
    product_category_name         VARCHAR(100) NOT NULL,
    product_category_name_english VARCHAR(100),
    PRIMARY KEY (product_category_name)
);

CREATE TABLE orders (
    order_id                      VARCHAR(32) NOT NULL,
    customer_id                   VARCHAR(32) NOT NULL,
    order_status                  VARCHAR(20),
    order_purchase_timestamp      DATETIME,
    order_approved_at             DATETIME,
    order_delivered_carrier_date  DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME,
    PRIMARY KEY (order_id)
);

CREATE TABLE order_items (
    order_id            VARCHAR(32) NOT NULL,
    order_item_id       INT NOT NULL,
    product_id          VARCHAR(32),
    seller_id           VARCHAR(32),
    shipping_limit_date DATETIME,
    price               DECIMAL(10,2),
    freight_value       DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE order_payments (
    order_id             VARCHAR(32) NOT NULL,
    payment_sequential   INT NOT NULL,
    payment_type         VARCHAR(20),
    payment_installments INT,
    payment_value        DECIMAL(10,2),
    PRIMARY KEY (order_id, payment_sequential)
);

-- review_id y order_id se repiten en este dataset, por eso no lleva clave primaria
CREATE TABLE order_reviews (
    review_id               VARCHAR(32),
    order_id                VARCHAR(32),
    review_score            TINYINT,
    review_comment_title    VARCHAR(255),
    review_comment_message  TEXT,
    review_creation_date    DATETIME,
    review_answer_timestamp DATETIME
);

-- ---------- 2. IMPORTAR CSV ----------
-- Si al final de cada fila queda un salto raro (\r), cambia '\n' por '\r\n'.

LOAD DATA LOCAL INFILE 'C:/Users/Ashly/Desktop/PORTAFOLIO/Proyecto 1/archivos_BBDD/olist_customers_dataset.csv'
INTO TABLE customers CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/Ashly/Desktop/PORTAFOLIO/Proyecto 1/archivos_BBDD/olist_sellers_dataset.csv'
INTO TABLE sellers CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/Ashly/Desktop/PORTAFOLIO/Proyecto 1/archivos_BBDD/product_category_name_translation.csv'
INTO TABLE category_translation CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

-- products: hay celdas vacías, se convierten a NULL
LOAD DATA LOCAL INFILE 'C:/Users/Ashly/Desktop/PORTAFOLIO/Proyecto 1/archivos_BBDD/olist_products_dataset.csv'
INTO TABLE products CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(product_id, @cat, @a, @b, @c, @d, @e, @f, @g)
SET product_category_name      = NULLIF(@cat,''),
    product_name_lenght        = NULLIF(@a,''),
    product_description_lenght = NULLIF(@b,''),
    product_photos_qty         = NULLIF(@c,''),
    product_weight_g           = NULLIF(@d,''),
    product_length_cm          = NULLIF(@e,''),
    product_height_cm          = NULLIF(@f,''),
    product_width_cm           = NULLIF(@g,'');

-- orders: fechas vacías -> NULL
LOAD DATA LOCAL INFILE 'C:/Users/Ashly/Desktop/PORTAFOLIO/Proyecto 1/archivos_BBDD/olist_orders_dataset.csv'
INTO TABLE orders CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(order_id, customer_id, order_status, @p, @ap, @ca, @cu, @es)
SET order_purchase_timestamp      = NULLIF(@p,''),
    order_approved_at             = NULLIF(@ap,''),
    order_delivered_carrier_date  = NULLIF(@ca,''),
    order_delivered_customer_date = NULLIF(@cu,''),
    order_estimated_delivery_date = NULLIF(@es,'');

LOAD DATA LOCAL INFILE 'C:/Users/Ashly/Desktop/PORTAFOLIO/Proyecto 1/archivos_BBDD/olist_order_items_dataset.csv'
INTO TABLE order_items CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/Users/Ashly/Desktop/PORTAFOLIO/Proyecto 1/archivos_BBDD/olist_order_payments_dataset.csv'
INTO TABLE order_payments CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

-- reviews: los comentarios traen saltos de línea y comillas dentro del texto
LOAD DATA LOCAL INFILE 'C:/Users/Ashly/Desktop/PORTAFOLIO/Proyecto 1/archivos_BBDD/olist_order_reviews_dataset.csv'
INTO TABLE order_reviews CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(review_id, order_id, review_score, @t, @m, @cr, @an)
SET review_comment_title    = NULLIF(@t,''),
    review_comment_message  = NULLIF(@m,''),
    review_creation_date    = NULLIF(@cr,''),
    review_answer_timestamp = NULLIF(@an,'');

-- geolocation (~1 millón de filas, puede tardar 1-2 minutos)
LOAD DATA LOCAL INFILE 'C:/Users/Ashly/Desktop/PORTAFOLIO/Proyecto 1/archivos_BBDD/olist_geolocation_dataset.csv'
INTO TABLE geolocation CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

-- ---------- 3. ÍNDICES PARA CONSULTAS RÁPIDAS ----------
CREATE INDEX idx_orders_customer  ON orders(customer_id);
CREATE INDEX idx_orders_status    ON orders(order_status);
CREATE INDEX idx_items_product    ON order_items(product_id);
CREATE INDEX idx_items_seller     ON order_items(seller_id);
CREATE INDEX idx_reviews_order    ON order_reviews(order_id);

-- ---------- 4. VALIDACIÓN (comparar con tu hoja "Validacion" de Excel) ----------
SELECT 'orders'          AS tabla, COUNT(*) AS filas FROM orders          UNION ALL  -- 99441
SELECT 'order_items',              COUNT(*)          FROM order_items     UNION ALL  -- 112650
SELECT 'order_reviews',            COUNT(*)          FROM order_reviews   UNION ALL  -- 99224
SELECT 'order_payments',           COUNT(*)          FROM order_payments  UNION ALL  -- 103886
SELECT 'customers',                COUNT(*)          FROM customers       UNION ALL  -- 99441
SELECT 'products',                 COUNT(*)          FROM products        UNION ALL  -- 32951
SELECT 'sellers',                  COUNT(*)          FROM sellers         UNION ALL  -- 3095
SELECT 'category_translation',     COUNT(*)          FROM category_translation UNION ALL  -- 71
SELECT 'geolocation',              COUNT(*)          FROM geolocation;                -- ~1000163

SELECT COUNT(*)                                        AS entregados,        -- 96478
       (SELECT SUM(price)         FROM order_items)    AS ventas_price,      -- 13591643.70
       (SELECT SUM(freight_value) FROM order_items)    AS flete_total,       -- 2251909.54
       (SELECT AVG(review_score)  FROM order_reviews)  AS puntaje_promedio   -- ~4.0864
FROM orders WHERE order_status = 'delivered';
