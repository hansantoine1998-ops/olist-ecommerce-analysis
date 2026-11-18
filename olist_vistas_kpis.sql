-- =====================================================
-- OLIST: VISTAS Y KPIs (por pedido, igual que el dashboard de Power BI)
-- Ejecutar DESPUÉS de olist_mysql_setup.sql. Requiere MySQL 8.0+.
-- =====================================================
USE olist;

-- ---------- 1. Puntaje por pedido (evita duplicar ventas por reseñas repetidas) ----------
CREATE OR REPLACE VIEW v_reviews_pedido AS
SELECT order_id, AVG(review_score) AS review_score
FROM order_reviews
GROUP BY order_id;

-- ---------- 2. v_ventas: 1 fila por ítem vendido, solo pedidos entregados ----------
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

-- ---------- 3. v_pedidos: 1 fila por pedido (base de los KPIs oficiales) ----------
-- Los campos del pedido se repiten en cada ítem, por eso se usa MAX/MIN al agrupar.
CREATE OR REPLACE VIEW v_pedidos AS
SELECT
    order_id,
    MAX(customer_unique_id)  AS customer_unique_id,
    MIN(fecha_compra)        AS fecha_compra,
    MAX(estado)              AS estado,
    ROUND(SUM(price), 2)     AS ventas,
    ROUND(SUM(freight_value), 2) AS flete,
    COUNT(*)                 AS items,
    MAX(dias_entrega)        AS dias_entrega,
    MAX(entrega_tardia)      AS entrega_tardia,
    MAX(review_score)        AS review_score
FROM v_ventas
GROUP BY order_id;

-- Comprobación de las vistas
SELECT (SELECT COUNT(*) FROM v_ventas)   AS items,      -- 110197
       (SELECT COUNT(*) FROM v_pedidos)  AS pedidos,    -- 96478
       (SELECT ROUND(SUM(ventas), 2) FROM v_pedidos) AS ventas;  -- 13221498.11

-- ---------- 4. KPIs globales (por pedido: coinciden con Power BI, PDF y README) ----------
SELECT
    ROUND(SUM(ventas), 2)                      AS ventas_totales,         -- 13221498.11
    COUNT(*)                                   AS pedidos,                -- 96478
    ROUND(AVG(ventas), 2)                      AS ticket_promedio,        -- 137.04
    ROUND(AVG(dias_entrega), 1)                AS dias_entrega_prom,      -- 12.5
    ROUND(100 * AVG(entrega_tardia), 2)        AS pct_entregas_tardias,   -- 8.11
    ROUND(AVG(review_score), 2)                AS satisfaccion_prom,      -- 4.16
    COUNT(DISTINCT customer_unique_id)         AS clientes_unicos         -- 93358
FROM v_pedidos;

-- Clientes que repiten (2 o más pedidos)
SELECT ROUND(100 * AVG(n_pedidos >= 2), 1) AS pct_clientes_que_repiten     -- 3.0
FROM (SELECT customer_unique_id, COUNT(*) AS n_pedidos
      FROM v_pedidos GROUP BY customer_unique_id) c;

-- ---------- 5. Ventas por mes + crecimiento mensual ----------
SELECT anio_mes, ventas, pedidos,
       ROUND(100 * (ventas - LAG(ventas) OVER (ORDER BY anio_mes))
             / LAG(ventas) OVER (ORDER BY anio_mes), 1) AS crecimiento_pct
FROM (SELECT DATE_FORMAT(fecha_compra, '%Y-%m') AS anio_mes,
             ROUND(SUM(ventas), 2) AS ventas,
             COUNT(*) AS pedidos
      FROM v_pedidos
      GROUP BY DATE_FORMAT(fecha_compra, '%Y-%m')) m
WHERE anio_mes BETWEEN '2017-01' AND '2018-08'
ORDER BY anio_mes;                                 -- pico: 2017-11 con ~$987.765

-- ---------- 6. Top 10 categorías por ventas (nivel ítem: una categoría por ítem) ----------
SELECT categoria,
       ROUND(SUM(price), 2)       AS ventas,
       COUNT(DISTINCT order_id)   AS pedidos,
       ROUND(AVG(review_score),2) AS satisfaccion
FROM v_ventas
GROUP BY categoria
ORDER BY ventas DESC
LIMIT 10;

-- ---------- 7. Ventas y logística por estado ----------
SELECT estado,
       ROUND(SUM(ventas), 2)                AS ventas,
       COUNT(*)                             AS pedidos,
       ROUND(100 * SUM(ventas) / SUM(SUM(ventas)) OVER (), 1) AS pct_ventas,   -- SP ~38%
       ROUND(AVG(dias_entrega), 1)          AS dias_entrega_prom,
       ROUND(100 * AVG(entrega_tardia), 1)  AS pct_tardias,
       ROUND(AVG(review_score), 2)          AS satisfaccion
FROM v_pedidos
GROUP BY estado
ORDER BY ventas DESC;

-- ---------- 8. retraso_pedidos: días de retraso por pedido (negativo = llegó antes) ----------
-- Solo pedidos entregados con fecha de entrega y reseña (95.824 pedidos).
CREATE OR REPLACE VIEW retraso_pedidos AS
SELECT order_id, dias_retraso,
       CASE WHEN dias_retraso <= -8 THEN '8+ días antes'
            WHEN dias_retraso <=  0 THEN '0-7 días antes'
            WHEN dias_retraso <=  3 THEN '1-3 días tarde'
            WHEN dias_retraso <=  7 THEN '4-7 días tarde'
            WHEN dias_retraso <= 14 THEN '8-14 días tarde'
            ELSE '15+ días tarde' END AS grupo,
       CASE WHEN dias_retraso <= -8 THEN 1
            WHEN dias_retraso <=  0 THEN 2
            WHEN dias_retraso <=  3 THEN 3
            WHEN dias_retraso <=  7 THEN 4
            WHEN dias_retraso <= 14 THEN 5
            ELSE 6 END AS orden
FROM (SELECT o.order_id,
             TIMESTAMPDIFF(SECOND, o.order_estimated_delivery_date,
                                   o.order_delivered_customer_date) / 86400.0 AS dias_retraso
      FROM orders o
      JOIN v_reviews_pedido r ON o.order_id = r.order_id
      WHERE o.order_status = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL) t;

-- ---------- 9. Satisfacción según retraso (el retraso se asocia a notas más bajas) ----------
SELECT rp.orden, rp.grupo,
       COUNT(*)                    AS pedidos,
       ROUND(AVG(r.review_score), 2) AS nota_promedio
FROM retraso_pedidos rp
JOIN v_reviews_pedido r ON rp.order_id = r.order_id
GROUP BY rp.orden, rp.grupo
ORDER BY rp.orden;
-- Esperado: 4.32 · 4.21 · 3.77 · 2.32 · 1.75 · 1.71  (asociación, no prueba causalidad)

-- ---------- 10. rfm_clientes: segmentación RFM ----------
-- Recencia: días hasta el día siguiente a la última compra del dataset.
-- R y M en quintiles (5 = mejor). F: 1 pedido = 1, 2 pedidos = 3, 3 o más = 5.
-- Nota: los quintiles con empates pueden diferir en unos pocos clientes respecto al
-- notebook de Python (que es la fuente de los CSV usados en Power BI).
CREATE OR REPLACE VIEW rfm_clientes AS
WITH base AS (
    SELECT customer_unique_id,
           DATEDIFF((SELECT DATE_ADD(MAX(fecha_compra), INTERVAL 1 DAY) FROM v_pedidos),
                    MAX(fecha_compra))     AS recencia,
           COUNT(*)                        AS frecuencia,
           ROUND(SUM(ventas), 2)           AS monto
    FROM v_pedidos
    GROUP BY customer_unique_id
),
puntaje AS (
    SELECT customer_unique_id, recencia, frecuencia, monto,
           6 - NTILE(5) OVER (ORDER BY recencia, customer_unique_id) AS R,
           NTILE(5) OVER (ORDER BY monto, customer_unique_id)        AS M,
           CASE WHEN frecuencia >= 3 THEN 5
                WHEN frecuencia = 2  THEN 3
                ELSE 1 END                                           AS F
    FROM base
)
SELECT customer_unique_id, recencia, frecuencia, monto, R, M, F,
       CASE WHEN F >= 3 THEN 'Recurrentes'
            WHEN R <= 2 AND M >= 4 THEN 'En riesgo de alto valor'
            WHEN R <= 2 THEN 'Perdidos'
            WHEN R = 3  THEN 'Ocasionales'
            WHEN M >= 4 THEN 'Nuevos de alto valor'
            ELSE 'Nuevos' END AS segmento
FROM puntaje;

-- ---------- 11. Resumen por segmento ----------
SELECT segmento,
       COUNT(*)                                     AS clientes,
       ROUND(AVG(recencia), 0)                      AS recencia_prom,
       ROUND(SUM(monto), 2)                         AS ventas,
       ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_clientes,
       ROUND(100 * SUM(monto) / SUM(SUM(monto)) OVER (), 1) AS pct_ventas
FROM rfm_clientes
GROUP BY segmento
ORDER BY ventas DESC;
-- Esperado: En riesgo de alto valor ≈ 13.784 clientes (~395 días); los 2 segmentos de alto valor ≈ 30% clientes y 58% ventas
