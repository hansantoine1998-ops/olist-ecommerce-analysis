# Análisis de ventas, logística y clientes: Olist (E-commerce Brasil)

> **English summary:** End-to-end data analysis of the public Olist Brazilian e-commerce dataset (96,478 delivered orders, 2016–2018). Stack: **MySQL** (data load, views, KPIs) · **Python** (profiling, delivery delay vs. satisfaction, RFM segmentation, PDF report) · **Power BI** (DAX, 4-page dashboard) · **Excel** (pivot tables for validation). Key finding: late deliveries of 4+ days drop the average review from 4.2 to 2.3, and 30 % of customers (two high-value segments) generate 58 % of sales.

Proyecto de análisis de datos de punta a punta sobre el dataset público de Olist (Kaggle): base de datos, análisis en Python, dashboard en Power BI, Excel de apoyo y reporte ejecutivo en PDF para gerencia.

**Período analizado:** septiembre 2016 a agosto 2018 · **Pedidos entregados:** 96.478

## Entregables

| Entregable | Qué es | Dónde |
|---|---|---|
| Dashboard Power BI | 4 páginas: Resumen, Productos, Logística y Clientes | Carpeta [`04_powerbi/`](04_powerbi/) |
| Reporte ejecutivo | PDF de 6 páginas para gerencia | Carpeta [`05_reporte/`](05_reporte/) |
| Análisis en Python | Perfilado, retraso vs. satisfacción y RFM; generador del reporte PDF (Colab) | Carpeta [`02_python/`](02_python/) |
| Excel de apoyo | Validación de cifras y tablas dinámicas (53 MB) | [Descargar desde Releases](https://github.com/hansantoine1998-ops/olist-ecommerce-analysis/releases/tag/v1.0) |
| SQL | Carga de datos, vistas y KPIs | Carpeta [`01_sql/`](01_sql/) |
| Datos procesados | CSV generados por el análisis (los usa Power BI) | Carpeta [`06_datos_procesados/`](06_datos_procesados/) |

> **Cómo abrir cada uno:** entra a la carpeta, haz clic en el archivo y luego en **Download** (arriba a la derecha). Los `.pbix` se abren con Power BI Desktop y los `.ipynb` con Google Colab.
>
> **Excel:** pesa 53 MB, por eso está en [Releases](https://github.com/hansantoine1998-ops/olist-ecommerce-analysis/releases/tag/v1.0) y no en una carpeta. En esa página, haz clic en el archivo `.xlsx` de la sección *Assets* para descargarlo y ábrelo en Microsoft Excel para ver las tablas dinámicas y los gráficos.

## Objetivo
Entender qué impulsa las ventas, cómo afectan los retrasos de entrega a la satisfacción del cliente y qué segmentos de clientes concentran el valor, para apoyar decisiones de la gerencia.

## Herramientas
| Herramienta | Uso |
|---|---|
| MySQL | Carga de datos, vistas (v_ventas, v_pedidos, retraso_pedidos, rfm_clientes) y KPIs por pedido. |
| Python (pandas, matplotlib, reportlab) | Perfilado de datos, análisis retraso vs. satisfacción, segmentación RFM y generación del reporte PDF |
| Power BI (DAX) | Modelo de datos, medidas y dashboard de 4 páginas |
| Excel (tablas dinámicas) | Validación de cifras y tablas dinámicas de apoyo |

## Indicadores principales
Pedidos entregados, calculados por pedido:

| KPI | Valor |
|---|---|
| Ventas totales (sin flete) | $13.221.498 |
| Pedidos | 96.478 |
| Ticket promedio | $137,04 |
| Días de entrega (promedio) | 12,5 |
| Entregas tardías | 8,11 % |
| Satisfacción (1-5) | 4,16 |
| Clientes únicos | 93.358 |
| Clientes que repiten | 3,0 % |

## Hallazgos destacados
- **Concentración geográfica:** SP concentra el 38 % de las ventas; SP, RJ y MG suman el 63 %.
- **Retraso y satisfacción:** la nota baja de 4,2 (entrega a tiempo) a 2,3 con 4 a 7 días de retraso y a 1,7 con más de una semana. Llegar antes casi no mejora la nota. Es una asociación, no prueba causalidad.
- **Nordeste:** AL, MA, PI, CE, SE y BA tienen las mayores tasas de entregas tardías.
- **Clientes:** los dos segmentos de alto valor son el 30 % de los clientes y generan el 58 % de las ventas. 13.784 clientes «En riesgo de alto valor» llevan unos 395 días sin comprar.
- **Recompra baja:** solo el 3 % de los clientes compró más de una vez.

## Recomendaciones para gerencia
1. **Priorizar la logística del Nordeste.** Revisar transportistas y rutas en AL, MA, PI, CE, SE y BA, donde se concentran las entregas tardías.
2. **Prometer plazos realistas.** Adelantarse casi no mejora la nota, pero retrasarse 4 días o más la hunde. Conviene agregar margen al plazo estimado en las zonas con más retrasos antes que acelerar entregas ya rápidas.
3. **Reactivar a los clientes de alto valor en riesgo.** Una campaña dirigida a los 13.784 clientes inactivos (cerca de $3,8 M históricos) tiene más potencial que captar clientes de bajo valor.
4. **Fomentar la recompra.** Con solo 3 % de recompra, programas de fidelización o cupones post-compra son una oportunidad.

## Estructura del repositorio
```
├── 01_sql/                Scripts de MySQL (carga de datos, vistas y KPIs)
├── 02_python/             Análisis en Colab (RFM, retraso) y generador del reporte PDF
├── 04_powerbi/            Dashboard (.pbix)
├── 05_reporte/            Reporte ejecutivo para gerencia (PDF)
├── 06_datos_procesados/   CSV generados por el análisis y usados por Power BI
└── imagenes/              Capturas del dashboard
```
El Excel de apoyo se descarga desde la sección [Releases](https://github.com/hansantoine1998-ops/olist-ecommerce-analysis/releases/tag/v1.0).

## Vista previa del dashboard
![Resumen](imagenes/dashboard_resumen.png)
![Productos](imagenes/dashboard_productos.png)
![Logística](imagenes/dashboard_logistica.png)
![Clientes](imagenes/dashboard_clientes.png)

## Cómo reproducirlo
1. Descarga el dataset original en Kaggle: *Brazilian E-Commerce Public Dataset by Olist* (los CSV originales no se incluyen en este repositorio).
2. **MySQL:** ejecuta los scripts de `01_sql/` (primero `olist_mysql_setup.sql`, ajustando la ruta de tus CSV, y luego `olist_vistas_kpis.sql`).
3. **Python:** sube los CSV originales a una carpeta de Google Drive, abre el cuaderno `Analisis_Olist_Colab.ipynb` (carpeta `02_python/`) en Colab y ejecuta todo. El cuaderno valida los KPIs y genera los 4 CSV de `06_datos_procesados/`.
4. **Power BI:** abre el archivo `.pbix` de la carpeta `04_powerbi/`. Si necesitas actualizar los datos, en *Transformar datos → Configuración de origen de datos* apunta cada tabla a los CSV de `06_datos_procesados/`.
5. **Reporte PDF:** abre el cuaderno `Reporte_Olist_Colab_ejecutivo.ipynb` (carpeta `02_python/`) en Colab y ejecuta todo para generar el PDF.
6. **Excel:** descarga el archivo de apoyo desde la sección [Releases](https://github.com/hansantoine1998-ops/olist-ecommerce-analysis/releases/tag/v1.0).

## Notas metodológicas
- Los indicadores consideran solo pedidos entregados. La satisfacción es el promedio por pedido (4,16); por ítem es 4,08 y sobre todas las reseñas es 4,09.
- El Excel de apoyo excluye sep-dic 2016 en sus gráficos mensuales (267 pedidos y $40.471); los totales completos coinciden con el dashboard.
- **RFM:** recencia y monto en quintiles; frecuencia 1 pedido = 1, 2 pedidos = 3, 3 o más = 5. Se calculó sobre todo el período y depende de que los datos terminan en agosto de 2018.
- Si se eliminan o se agregan datos, los resultados cambian y el reporte debe actualizarse.

## Fuente de datos
Olist Brazilian E-Commerce Public Dataset (Kaggle). Revisa la licencia del dataset en Kaggle antes de redistribuir los datos originales. Esta carpeta `06_datos_procesados/` contiene solo tablas derivadas del análisis.

## Autor
Hans Velásquez Leres · www.linkedin.com/in/hans-navor-velásquez-leres-425b452a8 · hansnavor@gmail.com
