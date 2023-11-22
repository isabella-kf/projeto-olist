-- Faturamento por mês:
-- Combinar as colunas 'orders' e 'order_payments'.
WITH delivered AS (
	SELECT order_payments.payment_value, 
		orders.order_status, 
		orders.order_purchase_timestamp 
	FROM order_payments
	JOIN orders
	ON order_payments.order_id = orders.order_id
	)
-- Extrair ano e mês da coluna order_purchase_timestamp e somar faturamento por mês.
SELECT
	DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS 'ano_mês', 
	ROUND(SUM(payment_value), 2) AS 'faturamento_total'
FROM delivered
WHERE order_status LIKE 'delivered' -- Apenas pedidos que foram entregues.
GROUP BY 1
ORDER BY 1 ASC;


-- Diferença de faturamento por mês:
-- Tabela temporária unindo as tabelas 'order_payments' e 'orders'.
WITH temp1 AS (
	SELECT order_payments.payment_value, 
		orders.order_status, 
		orders.order_purchase_timestamp 
	FROM order_payments
	JOIN orders
	ON order_payments.order_id = orders.order_id
),
-- Tabela temporária com faturamento total por ano/mês.
temp2 AS (
SELECT 
	DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS 'ano_mês', 
	ROUND(SUM(payment_value), 2) AS 'faturamento_total'
FROM temp1
WHERE order_status LIKE 'delivered' -- Apenas pedidos que foram entregues.
GROUP BY 1
)
-- Calcular diferença entre o faturamento de um mês e o faturamento do mês anterior.
SELECT 
    ano_mês,
    faturamento_total - lag(faturamento_total, 1) OVER (order by ano_mês) AS 'diferença_faturamento'
FROM temp2;
	

-- Top 5 meses por faturamento:
-- Tabela temporário unindo as tabelas 'order_payments' e 'orders'.
WITH temp AS (
	SELECT order_payments.payment_value, 
		orders.order_status, 
		orders.order_purchase_timestamp 
	FROM order_payments
	JOIN orders
	ON order_payments.order_id = orders.order_id
	)
-- Extrair ano e mês da coluna order_purchase_timestamp e somar faturamento por mês.
SELECT
	DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS 'ano_mês', 
	ROUND(SUM(payment_value), 2) AS 'faturamento_total'
FROM temp
WHERE order_status LIKE 'delivered' -- Apenas pedidos que foram entregues.
GROUP BY 1
ORDER BY 2 desc
LIMIT 5; -- Exibir apenas os 5 meses com maior faturamento.


-- Faturamento por ano:
-- Tabela temporário unindo as tabelas 'order_payments' e 'orders'.
WITH delivered AS (
	SELECT order_payments.payment_value, 
		orders.order_status, 
		orders.order_purchase_timestamp 
	FROM order_payments
	JOIN orders
	ON order_payments.order_id = orders.order_id
	)
-- Extrair ano da coluna order_purchase_timestamp e somar faturamento por ano.
SELECT
	DATE_FORMAT(order_purchase_timestamp, '%Y') AS 'ano', 
	ROUND(SUM(payment_value), 2) AS 'faturamento_total'
FROM delivered
WHERE order_status LIKE 'delivered' -- Apenas pedidos que foram entregues.
GROUP BY 1
ORDER BY 1 ASC;


-- Top 5 categorias por faturamento:
-- Tabela temporária unindo as tabelas 'products' e 'order_items'.
WITH temp1 AS (
    SELECT products.product_category_name, order_items.order_id
    FROM products
    JOIN order_items 
    ON products.product_id = order_items.product_id
),
-- Tabela temporária unindo a tabela anterior e 'orders'.
temp2 AS (
    SELECT temp1.product_category_name, orders.order_id
    FROM temp1
    JOIN orders 
    ON temp1.order_id = orders.order_id
),
-- Tabela temporária unindo a tabela anterior e 'order_payments'.
temp3 AS (
    SELECT temp2.product_category_name, temp2.order_id, order_payments.payment_value
    FROM temp2
    JOIN order_payments 
    ON temp2.order_id = order_payments.order_id 
)
-- Somar faturamento por categoria.
SELECT 
	product_category_name AS 'categoria', 
	ROUND(SUM(payment_value), 2) AS 'faturamento_total'
FROM temp3
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;


-- Top 5 categorias com média de avaliações mais alta:
-- Tabela temporária unindo as tabelas 'products' e 'orders'.
WITH temp1 AS (
    SELECT products.product_category_name, order_items.order_id
    FROM products
    JOIN order_items 
    ON products.product_id = order_items.product_id
),
-- Tabela temporária unindo a tabela anterior e 'reviews'.
temp2 AS (
	SELECT temp1.product_category_name, order_reviews.review_score
	FROM temp1
	JOIN order_reviews
	ON temp1.order_id = order_reviews.order_id
)
-- Média de avaliação por categoria.
SELECT
	product_category_name AS 'categoria',
	ROUND(AVG(review_score), 1) AS 'méd_avaliações'
FROM temp2
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;


-- Período do dia em que ocorrem mais compras:
-- Contar número de pedidos...
SELECT 
	COUNT(order_id) AS 'num_pedidos',
-- ... de acordo com o período do dia.
	CASE
		WHEN DATE_FORMAT(order_purchase_timestamp, '%H') >= 0 AND DATE_FORMAT(order_purchase_timestamp, '%H') < 6 THEN 'Madrugada'
		WHEN DATE_FORMAT(order_purchase_timestamp, '%H') >= 6  AND DATE_FORMAT(order_purchase_timestamp, '%H') < 12 THEN 'Manhã'
		WHEN DATE_FORMAT(order_purchase_timestamp, '%H') >= 12 AND DATE_FORMAT(order_purchase_timestamp, '%H') < 18 THEN 'Tarde'
		ELSE 'Noite'
	END AS 'período'
FROM orders
GROUP BY 2
ORDER BY 1 DESC;


-- Dias da semana em que ocorrem mais compras:
SELECT
-- Contar número de pedidos...
	COUNT(order_id) AS 'num_pedidos',
-- ... de acordo com o dia da semana.
	CASE
		WHEN DAYOFWEEK(order_purchase_timestamp) = 1 THEN 'Domingo'
		WHEN DAYOFWEEK(order_purchase_timestamp) = 2 THEN 'Segunda'
		WHEN DAYOFWEEK(order_purchase_timestamp) = 3 THEN 'Terça'
		WHEN DAYOFWEEK(order_purchase_timestamp) = 4 THEN 'Quarta'
		WHEN DAYOFWEEK(order_purchase_timestamp) = 5 THEN 'Quinta'
		WHEN DAYOFWEEK(order_purchase_timestamp) = 6 THEN 'Sexta'
		ELSE 'Sábado'
	END AS 'dia_da_semana'
FROM orders
GROUP BY 2
ORDER BY 1 DESC;


-- Valor médio por pedido:
-- Tabela temporária unindo 'orders' e 'payment_value'
WITH temp AS (
	SELECT orders.order_id, order_payments.payment_value
	FROM orders
	JOIN order_payments
	ON orders.order_id = order_payments.order_id
)
-- Média por pedido.
SELECT ROUND(AVG(payment_value), 2) AS 'valor_méd_pedido'
FROM temp;


-- Valor médio por pedido por categoria:
-- Tabela temporária unindo 'products' e a tabela 'order_items'
WITH temp1 AS (
    SELECT products.product_category_name, order_items.order_id
    FROM products
    JOIN order_items 
    ON products.product_id = order_items.product_id
),
-- Tabela temporária unindo a tabela anterior e a tabela 'order_payments'.
temp2 AS (
    SELECT temp1.product_category_name, temp1.order_id, order_payments.payment_value
    FROM temp1
    JOIN order_payments 
    ON temp1.order_id = order_payments.order_id 
)
-- Valor médio por pedido por categoria.
SELECT
	product_category_name AS 'categoria', 
	ROUND(AVG(payment_value), 2) AS 'valor_méd_pedido'
FROM temp2
GROUP BY 1
ORDER BY 2 DESC;


-- Valor médio por pedido por forma de pagamento:
SELECT 
	payment_type AS 'forma_pagamento', 
	ROUND(AVG(payment_value), 2) as 'valor_méd_pedido'
FROM order_payments
GROUP BY 1
ORDER BY 2 DESC;


-- Estados com maior faturamento:
-- Tabela temporária unindo a tabela 'customers' e a tabela 'orders'.
WITH temp1 AS (
    SELECT customers.customer_state, orders.order_id 
    FROM customers
    JOIN orders 
    ON customers.customer_id = orders.customer_id
),
-- Tabela temporária unindo a tabela anterior e a tabela 'order_payments'.
temp2 AS (
    SELECT temp1.customer_state, order_payments.payment_value
    FROM temp1
    JOIN order_payments 
    ON temp1.order_id = order_payments.order_id
)
-- Somar faturamento total por estado.
SELECT
	customer_state AS 'estado', 
	ROUND(SUM(payment_value), 2) AS 'faturamento_total'
FROM temp2
GROUP BY 1
ORDER BY 2 DESC;


-- Estados com maior número de pedidos:
-- Tabela temporária unindo a tabela 'customers' e tabela 'orders'.
WITH temp1 AS (
    SELECT customers.customer_state, orders.order_id 
    FROM customers
    JOIN orders 
    ON customers.customer_id = orders.customer_id
)
-- Contar número de pedidos por estado.
SELECT
	customer_state AS 'estado', 
	count(order_id) AS 'num_pedidos'
FROM temp1
GROUP BY 1
ORDER BY 2 DESC;


-- Meses com o maior número de novos consumidores:
-- Tabela temporária unindo a tabela 'customers' e a tabela 'orders'.
WITH temp AS (
	SELECT customers.customer_unique_id, orders.order_purchase_timestamp
	FROM customers
	JOIN orders
	ON customers.customer_id = orders.customer_id
)
-- Contar número de novos consumidores por mês.
SELECT
	DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS 'ano_mês',
	COUNT(DISTINCT customer_unique_id) AS 'num_novos_consumidores'
FROM temp
GROUP BY 1
ORDER BY 2 DESC;


-- Taxa de rotatividade:
-- Contar consumidores que compraram apenas uma vez.
SELECT COUNT(freq)
FROM freq_customers
WHERE freq = 1; -- 93.099

-- Contar total de consumidores.
SELECT COUNT(freq)
FROM freq_customers; -- 96.096

-- Calcular taxa de rotatividade: (consumidores que compraram apenas uma vez / total de consumidores) * 100
SELECT ROUND(((93.099/96.096) * 100), 2) AS 'taxa_rotatividade'


-- Top 5 vendedores por faturamento:
-- Tabela temporária unindo a tabela 'sellers' e a tabela 'orders'.
WITH temp1 AS (
	SELECT sellers.seller_id, order_items.order_id
	FROM sellers
	JOIN order_items
	ON sellers.seller_id = order_items.seller_id
),
-- Tabela temporária unindo a tabela anterior e a tabela 'order_payments'.
temp2 AS (
	SELECT temp1.seller_id, temp1.order_id, order_payments.payment_value
	FROM temp1
	JOIN order_payments
	ON temp1.order_id = order_payments.order_id
)
-- Somar faturamento por vendedor.
SELECT 
	seller_id AS 'id_vendedor',
	SUM(payment_value) AS 'faturamento_total'
FROM temp2
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;


-- Top 5 vendedores por número de pedidos:
-- Tabela temporária unindo a tabela 'sellers' e a tabela 'order_items'.
WITH temp AS (
	SELECT sellers.seller_id, order_items.order_id
	FROM sellers
	JOIN order_items
	ON sellers.seller_id = order_items.seller_id
)
-- Contar número de pedidos por vendedor.
SELECT 
	seller_id AS 'id_vendedor',
	COUNT(order_id) AS 'num_pedidos'
FROM temp
GROUP BY 1
ORDER BY 2 DESC
LIMIT 5;


-- Número de vendedores por estado:
SELECT 
	seller_state as 'estado',
	COUNT(seller_id) AS 'num_vendedores'
FROM sellers
GROUP BY 1
ORDER BY 2 DESC;


-- Diferença média entre tempo estimado de entrega e tempo factual de entrega:
SELECT
	AVG(DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date)) AS 'dif_média'
FROM orders
WHERE order_status = 'delivered';


-- Diferença média entre tempo estimado de entrega e tempo factual de entrega por estado:
-- Tabela temporária unindo a tabela 'customers' e a tabela 'orders'.
WITH temp AS (
	SELECT customers.customer_state, orders.order_estimated_delivery_date, orders.order_delivered_customer_date, orders.order_status
	FROM customers
	JOIN orders
	ON customers.customer_id = orders.customer_id
)
-- Calcular diferença média entre tempo estimado de entrega e tempo factual de entrega por estado.
SELECT 
	customer_state AS 'estado', 
	AVG(DATEDIFF(order_estimated_delivery_date, order_delivered_customer_date)) AS 'dif_média'
FROM temp
WHERE order_status = 'delivered'
GROUP BY 1
ORDER BY 2 DESC; -- Estados com maior diferença (ou seja, entrega mais rápida em comparação ao estimado) primeiro.


-- Forma de pagamento mais utilizada:
SELECT 
	payment_type AS 'forma_de_pagamento',
	COUNT(payment_type) AS 'num_pedidos'
FROM order_payments
GROUP BY 1
ORDER BY 2 DESC;


-- Faturamento por forma de pagamento:
SELECT 
	payment_type AS 'forma_de_pagamento',
	ROUND(SUM(payment_value), 2) AS 'faturamento_total'
FROM order_payments
GROUP BY 1
ORDER BY 2 DESC;


-- Média de número de parcelas:
SELECT
	ROUND(AVG(payment_installments)) AS 'média_núm_parcelas'
FROM order_payments;