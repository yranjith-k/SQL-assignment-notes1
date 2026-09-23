USE sakila;
SELECT * FROM customer
WHERE first_name LIKE 'J%' AND active = 1;

/* 
   Explanation: LIKE 'J%' uses % as a wildcard meaning "any characters after."
   active = 1 filters to only currently active customers.
   AND requires both conditions to be true.
*/


SELECT * FROM film
WHERE title LIKE '%ACTION%' OR description LIKE '%WAR%';


/*  

 %ACTION% — wildcards on both sides mean "ACTION" can appear anywhere in the string (beginning, middle, end).
OR — a row is returned if either condition is true (doesn't need both)
*/

SELECT * FROM customer
WHERE last_name <> 'SMITH' AND first_name LIKE '%a';


/*  

 <> means "not equal to" (some databases also accept !=).
'%a' — wildcard before 'a' only, meaning the string must end in "a" (Maria, Anna, Lisa...

*/



SELECT * FROM film
WHERE rental_rate > 3.0 AND replacement_cost IS NOT NULL;

/*  

 > 3.0 — standard numeric comparison.
IS NOT NULL — you can't use = NULL in SQL because NULL means "unknown," not a comparable value. You must use the special IS NULL / IS NOT NULL operators.


*/



SELECT store_id, COUNT(*) AS active_customers
FROM customer
WHERE active = 1
GROUP BY store_id;

/*  

 WHERE active = 1 filters rows before grouping — only active customers are counted at all.
GROUP BY store_id — buckets the remaining rows by store, so COUNT(*) counts rows within each store rather than the whole table.
AS active_customers — just renames the output column (an "alias") for readability.


*/


SELECT DISTINCT rating FROM film;

/*  

DISTINCT removes duplicate values from the result — so if 500 films are rated 'PG', it shows 'PG' only once


*/

SELECT rental_duration, COUNT(*) AS film_count, AVG(length) AS avg_length
FROM film
GROUP BY rental_duration
HAVING AVG(length) > 100;

/*  

GROUP BY rental_duration groups all films by their duration value (e.g., all 3-day rentals together, all 5-day together).
AVG(length) calculates the average film length within each group.
Key concept: HAVING vs WHERE — WHERE filters individual rows before grouping happens, but you can't use aggregate functions like AVG() in WHERE. HAVING filters groups after aggregation, so it's the only place you can say "average > 100."



*/



SELECT DATE(payment_date) AS pay_date,
       SUM(amount) AS total_amount,
       COUNT(*) AS num_payments
FROM payment
GROUP BY DATE(payment_date)
HAVING COUNT(*) > 100;

/* 
   payment_date likely includes a timestamp (date + time). DATE() strips the time portion so all payments on the same calendar day group together, instead of being split by exact second.
SUM(amount) totals the dollar amount per day; COUNT(*) counts how many payment rows fall on that day.
HAVING COUNT(*) > 100 — again, filtering on an aggregate, so it must be HAVING, not WHERE.

*/




SELECT * FROM customer
WHERE email IS NULL OR email LIKE '%.org';

/*
   IS NULL catches missing/blank email fields.
   LIKE '%.org' — wildcard before, nothing after, meaning the string must end with ".org".

*/


SELECT * FROM film
WHERE rating IN ('PG', 'G')
ORDER BY rental_rate DESC;

/*
    IN ('PG', 'G') is shorthand for rating = 'PG' OR rating = 'G' — cleaner when checking against multiple specific values.
    ORDER BY rental_rate DESC — sorts results from highest to lowest rental rate. (ASC would be lowest to highest, and is the default if you omit it.)

*/


SELECT length, COUNT(*) AS film_count
FROM film
WHERE title LIKE 'T%'
GROUP BY length
HAVING COUNT(*) > 5;

/*
    WHERE title LIKE 'T%' filters to only "T" films before grouping.
    GROUP BY length then buckets those T-films by their length value.
    HAVING COUNT(*) > 5 keeps only length-groups that have more than 5 films in them.
    This shows WHERE and HAVING working together: WHERE restricts rows first, HAVING restricts the resulting groups second.

*/



SELECT a.actor_id, a.first_name, a.last_name, COUNT(fa.film_id) AS film_count
FROM actor a
JOIN film_actor fa ON a.actor_id = fa.actor_id
GROUP BY a.actor_id, a.first_name, a.last_name
HAVING COUNT(fa.film_id) > 10;

/*
    Actor and film are related through a junction table film_actor (since one actor can be in many films, and one film can have many actors — a many-to-many relationship).
    JOIN ... ON a.actor_id = fa.actor_id connects each actor to their rows in the junction table.
    GROUP BY on the actor's ID/name groups all their film appearances together, and COUNT(fa.film_id) counts how many films that adds up to.
    HAVING COUNT(...) > 10 keeps only actors above that threshold.
    Note: all non-aggregated selected columns (actor_id, first_name, last_name) must appear in GROUP BY — this is a SQL rule.
 
 */




SELECT title, rental_rate, length
FROM film
ORDER BY rental_rate DESC, length DESC
LIMIT 5;

/*
   ORDER BY rental_rate DESC, length DESC — sorts primarily by rental_rate; when two films tie on rental_rate, it breaks the tie using length (also descending).
   LIMIT 5 — returns only the first 5 rows after sorting.

*/


SELECT c.customer_id, c.first_name, c.last_name, COUNT(r.rental_id) AS total_rentals
FROM customer c
JOIN rental r ON c.customer_id = r.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_rentals DESC;

/*
   Similar pattern to #12: join customer to rental (one customer → many rentals), group by customer, count how many rental rows belong to each.
   ORDER BY total_rentals DESC — after aggregating, sort customers from most rentals to least.
   Note this uses JOIN (inner join), which means customers with zero rentals wouldn't appear at all — if you needed to include them (showing 0), you'd use LEFT JOIN instead.

*/

SELECT f.title
FROM film f
LEFT JOIN inventory i ON f.film_id = i.film_id
LEFT JOIN rental r ON i.inventory_id = r.inventory_id
WHERE r.rental_id IS NULL;

/*
    This is the trickiest one conceptually. In Sakila, film doesn't directly connect to rental — a film has physical copies in inventory, and rental records happen against a specific inventory copy. So the chain is: film → inventory → rental.
    LEFT JOIN keeps all rows from the left table (film), even if there's no match on the right side. A regular JOIN would drop films with no rentals entirely — the opposite of what we want.
    When a film has no matching rental, all the rental columns (including rental_id) come back as NULL in the joined result.
    WHERE r.rental_id IS NULL then filters to exactly those cases — films that made it through the LEFT JOIN with no corresponding rental row. This is the classic SQL pattern for "find records that exist in table A but have no match in table B."

*/
  
