-- =====================================================
-- OLIST: VISTAS Y KPIs
-- =====================================================
USE olist;

-- ---------- 1. Puntaje por pedido (evita duplicar ventas por reseñas repetidas) ----------
CREATE OR REPLACE VIEW v_reviews_pedido AS
SELECT order_id, AVG(review_score) AS review_score
FROM order_reviews
GROUP BY order_id;

-- ---------- 2. Vista consolidada: 1 fila por ítem vendido, solo pedidos entregados ----------
CREATE OR REPLACE VIEW v_ventas AS
SELECT
    o.order_id,
    i.order_item_id,
    DATE(o.order_purchase_timestamp)                         AS fecha_compra,
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')         AS anio_mes,
    o.order_delivered_customer_date                          AS fecha_entrega,
    o.order_estimated_delivery_date                          AS fecha_estimada,
    c.customer_unique_id,
    c.customer_state                                         AS estado,
    c.customer_city                                          AS ciudad,
    COALESCE(t.product_category_name_english,
             p.product_category_name, 'sin_categoria')       AS categoria,
    i.price,
    i.freight_value,
    r.review_score,
    DATEDIFF(o.order_delivered_customer_date,
             o.order_purchase_timestamp)                     AS dias_entrega,
    CASE WHEN o.order_delivered_customer_date IS NULL THEN NULL
         WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1
         ELSE 0 END                                          AS entrega_tardia
FROM orders o
JOIN order_items i               ON o.order_id = i.order_id
JOIN customers c                 ON o.customer_id = c.customer_id
LEFT JOIN products p             ON i.product_id = p.product_id
LEFT JOIN category_translation t ON p.product_category_name = t.product_category_name
LEFT JOIN v_reviews_pedido r     ON o.order_id = r.order_id
WHERE o.order_status = 'delivered';

-- Comprobación de la vista
SELECT COUNT(*)                  AS items,        -- ~110.197
       COUNT(DISTINCT order_id)  AS pedidos,      -- 96.478
       SUM(price)                AS ventas        -- ~13,2 millones
FROM v_ventas;

-- ---------- 3. KPIs globales ----------
SELECT
    ROUND(SUM(price), 2)                                   AS ventas_totales_gmv,
    COUNT(DISTINCT order_id)                               AS pedidos,
    ROUND(SUM(price) / COUNT(DISTINCT order_id), 2)        AS ticket_promedio,
    ROUND(AVG(dias_entrega), 1)                            AS dias_entrega_prom,
    ROUND(100 * AVG(entrega_tardia), 2)                    AS pct_entregas_tardias,
    ROUND(AVG(review_score), 2)                            AS satisfaccion_prom
FROM v_ventas;

-- ---------- 4. Ventas por mes + crecimiento mensual ----------
SELECT anio_mes,
       ROUND(SUM(price), 2)                 AS ventas,
       COUNT(DISTINCT order_id)             AS pedidos,
       ROUND(100 * (SUM(price) - LAG(SUM(price)) OVER (ORDER BY anio_mes))
             / LAG(SUM(price)) OVER (ORDER BY anio_mes), 1) AS crecimiento_pct
FROM v_ventas
WHERE anio_mes BETWEEN '2017-01' AND '2018-08'
GROUP BY anio_mes
ORDER BY anio_mes;

-- ---------- 5. Top 10 categorías por ventas ----------
SELECT categoria,
       ROUND(SUM(price), 2)       AS ventas,
       COUNT(DISTINCT order_id)   AS pedidos,
       ROUND(AVG(review_score),2) AS satisfaccion
FROM v_ventas
GROUP BY categoria
ORDER BY ventas DESC
LIMIT 10;

-- ---------- 6. Ventas y logística por estado ----------
SELECT estado,
       ROUND(SUM(price), 2)                AS ventas,
       COUNT(DISTINCT order_id)            AS pedidos,
       ROUND(AVG(dias_entrega), 1)         AS dias_entrega_prom,
       ROUND(100 * AVG(entrega_tardia), 1) AS pct_tardias,
       ROUND(AVG(review_score), 2)         AS satisfaccion
FROM v_ventas
GROUP BY estado
ORDER BY ventas DESC;

-- ---------- 7. Satisfacción según retraso (hipótesis: el retraso baja el puntaje) ----------
SELECT CASE WHEN entrega_tardia = 1 THEN 'Tardía' ELSE 'A tiempo' END AS entrega,
       COUNT(DISTINCT order_id)    AS pedidos,
       ROUND(AVG(review_score), 2) AS satisfaccion_prom
FROM v_ventas
WHERE entrega_tardia IS NOT NULL
GROUP BY entrega;
