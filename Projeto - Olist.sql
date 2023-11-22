-- Faturamento por mês:
-- Combinar as colunas 'orders' e 'order_payments'.
with delivered as (
	select order_payments.payment_value, 
		orders.order_status, 
		orders.order_purchase_timestamp 
	from order_payments
	join orders
	on order_payments.order_id = orders.order_id
	)
-- Extrair ano e mês da coluna order_purchase_timestamp e somar faturamento por mês.
select 
	date_format(order_purchase_timestamp, '%Y-%m') as 'ano_mês', 
	round(sum(payment_value), 2) as 'faturamento_total'
from delivered
where order_status like 'delivered' -- Apenas pedidos que foram entregues.
group by 1
order by 1 asc;


-- Diferença de faturamento por mês:
-- Tabela temporária unindo as tabelas 'order_payments' e 'orders'.
with temp1 as (
	select order_payments.payment_value, 
		orders.order_status, 
		orders.order_purchase_timestamp 
	from order_payments
	join orders
	on order_payments.order_id = orders.order_id
),
-- Tabela temporária com faturamento total por ano/mês.
temp2 as (
select 
	date_format(order_purchase_timestamp, '%Y-%m') as 'ano_mês', 
	round(sum(payment_value), 2) as 'faturamento_total'
from temp1
where order_status like 'delivered' -- Apenas pedidos que foram entregues.
group by 1
)
-- Calcular diferença entre o faturamento de um mês e o faturamento do mês anterior.
SELECT 
    ano_mês,
    faturamento_total - lag(faturamento_total, 1) OVER (order by ano_mês) AS 'diferença_faturamento'
FROM temp2;
	

-- Top 5 meses por faturamento:
-- Tabela temporário unindo as tabelas 'order_payments' e 'orders'.
with temp as (
	select order_payments.payment_value, 
		orders.order_status, 
		orders.order_purchase_timestamp 
	from order_payments
	join orders
	on order_payments.order_id = orders.order_id
	)
-- Extrair ano e mês da coluna order_purchase_timestamp e somar faturamento por mês.
select 
	date_format(order_purchase_timestamp, '%Y-%m') as 'ano_mês', 
	round(sum(payment_value), 2) as 'faturamento_total'
from temp
where order_status like 'delivered' -- Apenas pedidos que foram entregues.
group by 1
order by 2 desc
limit 5; -- Exibir apenas os 5 meses com maior faturamento.


-- Faturamento por ano:
-- Tabela temporário unindo as tabelas 'order_payments' e 'orders'.
with delivered as (
	select order_payments.payment_value, 
		orders.order_status, 
		orders.order_purchase_timestamp 
	from order_payments
	join orders
	on order_payments.order_id = orders.order_id
	)
-- Extrair ano da coluna order_purchase_timestamp e somar faturamento por ano.
select 
	date_format(order_purchase_timestamp, '%Y') as 'ano', 
	round(sum(payment_value), 2) as 'faturamento_total'
from delivered
where order_status like 'delivered' -- Apenas pedidos que foram entregues.
group by 1
order by 1 asc;


-- Top 5 categorias por faturamento:
-- Tabela temporária unindo as tabelas 'products' e 'order_items'.
with temp1 as (
    select products.product_category_name, order_items.order_id
    from products
    join order_items on products.product_id = order_items.product_id
),
-- Tabela temporária unindo a tabela anterior e 'orders'.
temp2 as (
    select temp1.product_category_name, orders.order_id
    from temp1
    join orders 
    on temp1.order_id = orders.order_id
),
-- Tabela temporária unindo a tabela anterior e 'order_payments'.
temp3 as (
    select temp2.product_category_name, temp2.order_id, order_payments.payment_value
    from temp2
    join order_payments 
    on temp2.order_id = order_payments.order_id 
)
-- Somar faturamento por categoria.
select 
	product_category_name as 'categoria', 
	round(sum(payment_value), 2) as 'faturamento_total'
from temp3
group by 1
order by 2 desc
limit 5;


-- Top 5 categorias com média de avaliações mais alta:
-- Tabela temporária unindo as tabelas 'products' e 'orders'.
with temp1 as (
    select products.product_category_name, order_items.order_id
    from products
    join order_items on products.product_id = order_items.product_id
),
-- Tabela temporária unindo a tabela anterior e 'reviews'.
temp2 as (
	select temp1.product_category_name, order_reviews.review_score
	from temp1
	join order_reviews
	on temp1.order_id = order_reviews.order_id
)
-- Média de avaliação por categoria.
select
	product_category_name,
	round(avg(review_score), 1)
from temp2
group by 1
order by 2 desc
limit 5;


-- Período do dia em que ocorrem mais compras:
-- Contar número de pedidos...
select 
	count(order_id) as 'num_pedidos',
-- ... de acordo com o período do dia.
	case
		when date_format(order_purchase_timestamp, '%H') >= 0 and date_format(order_purchase_timestamp, '%H') < 6 then 'Madrugada'
		when date_format(order_purchase_timestamp, '%H') >= 6  and date_format(order_purchase_timestamp, '%H') < 12 then 'Manhã'
		when date_format(order_purchase_timestamp, '%H') >= 12 and date_format(order_purchase_timestamp, '%H') < 18 then 'Tarde'
		else 'Noite'
	end as 'período'
from orders
group by 2
order by 1 desc;


-- Dias da semana em que ocorrem mais compras:
select
-- Contar número de pedidos...
	count(order_id) as 'num_pedidos',
-- ... de acordo com o dia da semana.
	case
		when dayofweek(order_purchase_timestamp) = 1 then 'Domingo'
		when dayofweek(order_purchase_timestamp) = 2 then 'Segunda'
		when dayofweek(order_purchase_timestamp) = 3 then 'Terça'
		when dayofweek(order_purchase_timestamp) = 4 then 'Quarta'
		when dayofweek(order_purchase_timestamp) = 5 then 'Quinta'
		when dayofweek(order_purchase_timestamp) = 6 then 'Sexta'
		else 'Sábado'
	end as 'dia_da_semana'
from orders
group by 1
order by 2 desc;


-- Valor médio por pedido:
-- Tabela temporária unindo 'orders' e 'payment_value'
with temp as (
	select orders.order_id, order_payments.payment_value
	from orders
	join order_payments
	on orders.order_id = order_payments.order_id
)
-- Média por pedido.
select round(avg(payment_value), 2)
from temp;


-- Valor médio por pedido por categoria:
-- Tabela temporária unindo 'products' e a tabela 'order_items'
with temp1 as (
    select products.product_category_name, order_items.order_id
    from products
    join order_items on products.product_id = order_items.product_id
),
-- Tabela temporária unindo a tabela anterior e a tabela 'order_payments'.
temp2 as (
    select temp1.product_category_name, temp1.order_id, order_payments.payment_value
    from temp1
    join order_payments on temp1.order_id = order_payments.order_id 
)
-- Valor médio por pedido por categoria.
select 
	product_category_name, 
	round(avg(payment_value), 2)
from temp2
group by 1
order by 2 desc;


-- Valor médio por pedido por forma de pagamento:
select 
	payment_type, 
	round(avg(payment_value), 2)
from order_payments
group by 1
order by 2 desc;


-- Estados com maior faturamento:
-- Tabela temporária unindo a tabela 'customers' e a tabela 'orders'.
with temp1 as (
    select customers.customer_state, orders.order_id 
    from customers
    join orders on customers.customer_id = orders.customer_id
),
-- Tabela temporária unindo a tabela anterior e a tabela 'order_payments'.
temp2 as (
    select temp1.customer_state, order_payments.payment_value
    from temp1
    join order_payments on temp1.order_id = order_payments.order_id
)
-- Somar faturamento total por estado.
select 
	customer_state as 'estado', 
	round(sum(payment_value), 2) as 'faturamento_total'
from temp2
group by 1
order by 2 desc;


-- Estados com maior número de pedidos:
-- Tabela temporária unindo a tabela 'customers' e tabela 'orders'.
with temp1 as (
    select customers.customer_state, orders.order_id 
    from customers
    join orders on customers.customer_id = orders.customer_id
)
-- Contar número de pedidos por estado.
select 
	customer_state as 'estado', 
	count(order_id) as 'num_pedidos'
from temp1
group by 1
order by 2 desc;


-- Meses com o maior número de novos consumidores:
-- Tabela temporária unindo a tabela 'customers' e a tabela 'orders'.
with temp as (
	select customers.customer_unique_id, orders.order_purchase_timestamp
	from customers
	join orders
	on customers.customer_id = orders.customer_id
)
-- Contar número de novos consumidores por mês.
select
	date_format(order_purchase_timestamp, '%Y-%m') as 'ano_mês',
	count(distinct customer_unique_id) as 'num_novos_consumidores'
from temp
group by 1
order by 2 desc;


-- Taxa de rotatividade:
-- Contar consumidores que compraram apenas uma vez.
select count(freq)
from freq_customers
where freq = 1; -- 93.099

-- Contar total de consumidores.
select count(freq)
from freq_customers; -- 96.096

-- Calcular taxa de rotatividade: (consumidores que compraram apenas uma vez / total de consumidores) * 100
select round(((93.099/96.096) * 100), 2)


-- Top 5 vendedores por faturamento:
-- Tabela temporária unindo a tabela 'sellers' e a tabela 'orders'.
with temp1 as (
	select sellers.seller_id, order_items.order_id
	from sellers
	join order_items
	on sellers.seller_id = order_items.seller_id
),
-- Tabela temporária unindo a tabela anterior e a tabela 'order_payments'.
temp2 as (
	select temp1.seller_id, temp1.order_id, order_payments.payment_value
	from temp1
	join order_payments
	on temp1.order_id = order_payments.order_id
)
-- Somar faturamento por vendedor.
select 
	seller_id as 'id_vendedor',
	sum(payment_value) as 'faturamento_total'
from temp2
group by 1
order by 2 desc
limit 5;


-- Top 5 vendedores por número de pedidos:
-- Tabela temporária unindo a tabela 'sellers' e a tabela 'order_items'.
with temp as (
	select sellers.seller_id, order_items.order_id
	from sellers
	join order_items
	on sellers.seller_id = order_items.seller_id
)
-- Contar número de pedidos por vendedor.
select 
	seller_id as 'id_vendedor',
	count(order_id) as 'num_pedidos'
from temp
group by 1
order by 2 desc
limit 5;


-- Número de vendedores por estado:
select 
	seller_state as 'estado',
	count(seller_id) as 'num_vendedores'
from sellers
group by 1
order by 2 desc;


-- Diferença média entre tempo estimado de entrega e tempo factual de entrega:
select
	avg(datediff(order_estimated_delivery_date, order_delivered_customer_date)) as 'dif_média'
from orders
where order_status = 'delivered';


-- Diferença média entre tempo estimado de entrega e tempo factual de entrega por estado:
-- Tabela temporária unindo a tabela 'customers' e a tabela 'orders'.
with temp as (
	select customers.customer_state, orders.order_estimated_delivery_date, orders.order_delivered_customer_date, orders.order_status
	from customers
	join orders
	on customers.customer_id = orders.customer_id
)
-- Calcular diferença média entre tempo estimado de entrega e tempo factual de entrega por estado.
select 
	customer_state as 'estado', 
	avg(datediff(order_estimated_delivery_date, order_delivered_customer_date)) as 'dif_média'
from temp
where order_status = 'delivered'
group by 1
order by 2 desc; -- Estados com maior diferença (ou seja, entrega mais rápida em comparação ao estimado) primeiro.


-- Forma de pagamento mais utilizada:
select 
	payment_type as 'forma_de_pagamento',
	count(payment_type) as 'num_pagamentos'
from order_payments
group by 1
order by 2 desc;


-- Faturamento por forma de pagamento:
select 
	payment_type as 'forma_de_pagamento',
	round(sum(payment_value), 2) as 'faturamento_total'
from order_payments
group by 1
order by 2 desc;


-- Média de número de parcelas:
select
	round(avg(payment_installments)) as 'média_núm_parcelas'
from order_payments;