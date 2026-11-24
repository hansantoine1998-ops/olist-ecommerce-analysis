# Dashboard web interactivo: Olist

Panel con 5 páginas (Resumen, Productos, Logística, Clientes y Verificación) y filtros por año, estado, categoría y segmento RFM.

**Abrir el panel:** https://hansantoine1998-ops.github.io/olist-ecommerce-analysis/03_dashboard_web/

## Cómo funciona
- Las cifras se calculan en el navegador a partir de `orders.csv` y `cats.csv`, derivados de las tablas procesadas de `06_datos_procesados/`.
- La página **Verificación** compara 23 cifras clave con los valores oficiales del dashboard de Power BI, el README y el reporte PDF.
- Los importes están en reales brasileños (R$), mostrados con el símbolo «$».

## Archivos
| Archivo | Contenido |
|---|---|
| `index.html` | Página y lógica del panel |
| `orders.csv` | Datos agregados por pedido |
| `cats.csv` | Datos por categoría |
| `meta.json` | Parámetros del panel |
