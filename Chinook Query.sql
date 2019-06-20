/* Query 1 - query used to define the customers that will get invited for the concert based on their
				value spent. If they spent above the average, they get invited.*/ 

with t1 as (SELECT a.artistid ArtistId, a.name nome, COUNT(t.trackid)
			FROM artist a
			JOIN album ab
			ON a.artistid = ab.artistid
			JOIN track t
			ON t.albumid = ab.albumid
			JOIN genre g
			ON t.genreid = g.genreid
			WHERE g.name = "Rock"
			GROUP BY 1, 2
			ORDER BY 3 DESC
			LIMIT 10),
			
	t2 as (SELECT strftime('%Y-%m', i.InvoiceDate) data_venda, SUM(il.UnitPrice) soma_mes
			FROM Invoice i
			JOIN InvoiceLine il
			ON il.InvoiceId = i.InvoiceId
			JOIN track t
			ON t.TrackId = il.TrackId
			JOIN album ab
			ON t.AlbumId = ab.AlbumId
			JOIN artist a
			ON a.ArtistId = ab.ArtistId
			JOIN t1
			ON t1.ArtistId = a.ArtistId
			WHERE a.name = t1.nome
			GROUP BY 1
			ORDER BY 1, 2 DESC),
			
	t3 as (SELECT CAST(data_venda AS DATE) ano, AVG(soma_mes) media_anual
			FROM t2
			GROUP BY 1)

SELECT strftime('%Y', i.InvoiceDate) ano_compra, (c.FirstName||' '|| c.LastName) as Name, SUM(il.UnitPrice) total_spent, t3.media_anual avg_year,
		CASE WHEN (SUM(il.UnitPrice)-t3.media_anual) > 0 THEN 'Yes' ELSE 'No' END as invite
FROM Customer c
JOIN Invoice i
ON c.CustomerId = i.CustomerId
JOIN t3
ON t3.ano = ano_compra
JOIN InvoiceLine il
ON il.InvoiceId = i.InvoiceId
JOIN track t
ON t.TrackId = il.TrackId
JOIN album ab
ON ab.AlbumId = t.AlbumId
JOIN artist a
ON a.artistid = ab.artistid
JOIN t1
ON t1.ArtistId = a.ArtistId
WHERE (a.name = t1.nome)
GROUP BY 1, 2
HAVING invite = 'Yes'
ORDER BY 1, 3 DESC

/* Query 2 - query used to define the most profitable serie based on the earning by episode*/ 
				
SELECT CASE WHEN a.name LIKE 'Battle%' THEN 'Science Fiction'
		WHEN a.name IN ('Heroes', 'Lost') THEN 'Drama' 
		WHEN a.name = 'The Office' THEN 'Comedy'
		ELSE 'Not Series' END AS genre_edit,
		SUM(il.unitprice) total_sold,
		count(DISTINCT t.trackid) num_episodes,
		SUM(il.unitprice)/count(DISTINCT t.trackid) AVG_per_episode
FROM Track t
JOIN MediaType mt
ON t.MediaTypeId = mt.MediaTypeId
JOIN Album al
ON al.AlbumId = t.AlbumId
JOIN Artist a
ON a.ArtistId = al.ArtistId
JOIN Genre g
ON g.GenreId = t.GenreId
LEFT JOIN InvoiceLine il
ON il.TrackId = t.TrackId
WHERE (mt.name IN ('Protected MPEG-4 video file')) AND
	  (genre_edit NOT IN ('Not Series'))
GROUP BY 1

/* Query 3 - query used to list the customers that will get the "miss you" discount.
				These customers did not made any purchase on 2013. */ 

select (e.firstname||' '||e.lastname) AS sales_rep, (c.firstname||' '||c.lastname) AS customer_name, c.email email,  strftime('%Y-%m-%d', MAX(i.Invoicedate)) last_order
from Customer c
JOIN Invoice i
ON c.customerid = i.customerid
JOIN Employee e
ON e.Employeeid = c.supportrepid
GROUP BY 1, 2, 3
having last_order < '2013-01-01'
ORDER BY 1

/* Query 4 - query used to define the day that the discount will be valid, which will be the day with wost total spent,
				and the minimum value that has to be purchased, based on the average by country. */ 

WITH avg_by_country AS (select billingcountry, AVG(total) avg_order
		from Invoice
		WHERE strftime('%Y', invoicedate) = '2013'
		GROUP BY 1),

         avg_total AS (SELECT AVG(total)
	            FROM invoice
	            WHERE strftime('%Y', invoicedate) = '2013'),
					
         customers AS (select (c.firstname||' '||c.lastname) AS customer_name, c.country country, strftime('%Y', MAX(i.Invoicedate)) last_order
	               from Customer c
	               JOIN Invoice I
	               ON c.customerid = i.customerid
	               GROUP BY 1, 2
	               HAVING last_order < '2013'
 	               ORDER BY 2)

SELECT c.customer_name, c.country,
             coalesce(abc.avg_order, (SELECT AVG(total)
		      FROM invoice
		      WHERE strftime('%Y', invoicedate) = '2013')) AS avg_order
FROM customers c
LEFT JOIN avg_by_country abc
ON c.country = abc.billingcountry
ORDER BY 2

SELECT strftime('%m', invoicedate) dow, SUM(total) total_sold
FROM Invoice
WHERE strftime('%Y', invoicedate) = '2013'
GROUP BY 1
