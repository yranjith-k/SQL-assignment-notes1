/* 
   A. Subqueries */
/* 1a. Scalar Subquery */

/* Find all films priced higher than the average rental rate. */

SELECT title, rental_rate
FROM film
WHERE rental_rate > (SELECT AVG(rental_rate) FROM film);

/*  
   Explanation: The inner query (SELECT AVG(rental_rate) FROM film) runs once and 
   returns a single number (the average). The outer query then compares every film's
   rental_rate against that one fixed value. This is called a "scalar" subquery because it
   returns exactly one value (one row, one column).
*/

/* 
   2a. Multi-row Subquery (IN) 
*/


/* Find customers who have made more than 5 payments. */


SELECT customer_id, first_name, last_name
FROM customer
WHERE customer_id IN (
    SELECT customer_id
    FROM payment
    GROUP BY customer_id
    HAVING COUNT(*) > 5
);

/* 
   Explanation: The inner query returns a list of customer_ids (everyone with more than 5 payments)
   rather than a single value. The outer query then uses IN to keep any customer
   whose ID appears anywhere in that list — like checking membership in a set.
*/

/* 3a. Correlated Subquery */

/* 
   Find films priced higher than the average rental rate for their own rating category (PG films compared
   only to other PG films, R films only to other R films, etc.)
*/

SELECT f.title, f.rating, f.rental_rate
FROM film f
WHERE f.rental_rate > (
    SELECT AVG(f2.rental_rate)
    FROM film f2
    WHERE f2.rating = f.rating
);

/* 
    Explanation: The inner query references f.rating from the outer query — so it can't run just
    once like A1 did. Instead, it re-runs separately for every row in the outer query, using that row's 
    own rating each time. This dependency on the outer row is what makes it "correlated" 
    (as opposed to A1's "uncorrelated" scalar subquery, which only needed to run once total).
*/


/* 
   Part 2 — CTEs (Common Table Expressions)
   a. Basic CTE
   Find customers who have spent more than $100 in total.

*/

WITH customer_spending AS (
    SELECT customer_id, SUM(amount) AS total_spent
    FROM payment
    GROUP BY customer_id
)
SELECT customer_id, total_spent
FROM customer_spending
WHERE total_spent > 100
ORDER BY total_spent DESC;
/* 
   Explanation: WITH ... AS (...) names a query up front — here, customer_spending. The final SELECT below then treats that name exactly like a real table. This achieves the same result as writing a subquery inside the FROM clause, but it's written top-to-bottom instead of nested, which is much easier to read and reuse.
   b. Multiple Chained CTEs
*/   



/*   Find the names of customers who are "big spenders" (>$100), showing their total spent amount too.
*/

WITH customer_spending AS (
    SELECT customer_id, SUM(amount) AS total_spent
    FROM payment
    GROUP BY customer_id
),
big_spenders AS (
    SELECT customer_id, total_spent
    FROM customer_spending
    WHERE total_spent > 100
)
SELECT c.customer_id, c.first_name, c.last_name, bs.total_spent
FROM customer c
JOIN big_spenders bs ON c.customer_id = bs.customer_id
ORDER BY bs.total_spent DESC;


/* 
    Explanation: You can stack CTEs one after another, separated by commas — each later CTE can reference the ones defined before it. Here, big_spenders is built directly on top of customer_spending. Trying to do this with nested subqueries instead would get messy fast (subquery inside a subquery inside a subquery) — this readability is the main reason CTEs exist.
    B3. Recursive CTE
    Generate a simple sequence of numbers from 1 to 10.
*/

WITH RECURSIVE number_sequence AS (
    SELECT 1 AS n
    UNION ALL
    SELECT n + 1
    FROM number_sequence
    WHERE n < 10
)
SELECT n
FROM number_sequence;


/*  
    Explanation: A recursive CTE refers to itself. It has two parts joined by UNION ALL:
    Anchor: the starting row (n = 1)
    Recursive part: builds the next row from the previous one (n + 1), repeating until the 
    WHERE condition stops it.
*/

/*
    Trace it like a loop: n=1 → produces n=2 → produces n=3 → ... → stops once n is no longer less 
    than 10. This pattern is commonly used for generating sequences, traversing hierarchies
     (like org charts), or walking through date ranges.
*/


/* 
    Part C — Views
    C1. Simple View
    Save "customer total spending" as a reusable view.
*/

DROP VIEW IF EXISTS customer_spending_view;

CREATE VIEW customer_spending_view AS
SELECT c.customer_id,
       c.first_name,
       c.last_name,
       SUM(p.amount) AS total_spent
FROM customer c
JOIN payment p ON c.customer_id = p.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name;


-- Using it afterward is just like querying a table:
SELECT *
FROM customer_spending_view
WHERE total_spent > 100
ORDER BY total_spent DESC;

-- Using it afterward is just like querying a table:
SELECT *
FROM customer_spending_view
WHERE total_spent > 100
ORDER BY total_spent DESC;


/*
   Using it afterward  */

SELECT *
FROM customer_spending_view
WHERE total_spent > 100
ORDER BY total_spent DESC;

/* 
    Explanation: A view is a saved query that behaves like a virtual table. Once created, 
    you (or anyone else with access) can SELECT from it exactly like a real table, without 
    retyping the underlying JOIN/GROUP BY logic every time. Unlike a temp table, a view doesn't
     store data — it re-runs the underlying query live every time you query it.

*/


/*    C2. View Built on a JOIN
    Save a simplified "film catalog" view showing title, category, and rental rate together
     (normally spread across 3 tables: film, film_category, category).
*/

CREATE VIEW film_catalog_view AS
SELECT f.film_id,
       f.title,
       cat.name AS category_name,
       f.rental_rate
FROM film f
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category cat ON fc.category_id = cat.category_id;

-- Now anyone can get "title + category + price" in one simple query,
-- without needing to remember the underlying 3-table JOIN:

SELECT *
FROM film_catalog_view
WHERE category_name = 'Action'
ORDER BY rental_rate DESC;


/* 
    Explanation: This demonstrates a common real-world use of views: hiding complexity. The category name isn't
    stored directly on the film table — it requires joining through film_category (a junction table) to category.
    By wrapping that JOIN logic in a view once, anyone can query film_catalog_view directly without needing to know
    or repeat that 3-table relationship.
*/


/*   C3. View with Aggregation
   Save a "films per category count" view.
*/

CREATE VIEW films_per_category_view AS
SELECT cat.name AS category_name,
       COUNT(*) AS film_count
FROM film_category fc
JOIN category cat ON fc.category_id = cat.category_id
GROUP BY cat.name;

-- Use it directly:
SELECT *
FROM films_per_category_view
ORDER BY film_count DESC;


/* 
   Explanation: Views aren't limited to simple SELECTs — they can contain full aggregation logic too (GROUP BY, COUNT, etc.). This view precomputes "how many films exist per category" as a reusable, queryable object, so nobody has to rewrite that GROUP BY logic each time they need it.
    Part D — Temporary Tables
     D1. Temporary Table
*/

-- Step 1: create the temp table from a query (runs once, stores results)
CREATE TEMPORARY TABLE temp_customer_spending AS
SELECT customer_id, SUM(amount) AS total_spent
FROM payment
GROUP BY customer_id;

-- Step 2: now query it like any normal table, as many times as you like
SELECT *
FROM temp_customer_spending
WHERE total_spent > 100
ORDER BY total_spent DESC;

-- You can run other, completely different queries against the same
-- snapshot without recalculating anything:

SELECT AVG(total_spent) AS avg_spending
FROM temp_customer_spending;

-- To remove it manually before your session ends (optional -- it
-- disappears automatically once you disconnect anyway):

DROP TEMPORARY TABLE temp_customer_spending;

/* 
    Explanation: A temp table is different from a view: it actually stores a real copy of the data 
    (a frozen snapshot at the moment of creation), but only for the duration of your current 
    session/connection. Once you disconnect (or close Workbench), it automatically disappears.
*/

/* 
   Why use one instead of a CTE or view?
*/
/*  
    CTEs only live for a single query, then vanish.
   - Views never store data -- they always recalculate live.
   - Temp tables store data ONCE and let you reuse/query/index that
     snapshot repeatedly within your session, which can be faster if
     you need to run several different queries against the same
     intermediate result.
*/


/*   
    Explanation of each point:
    CTEs vanish after one query — if you write a WITH ... AS (...) CTE, it only exists for 
    the single SELECT statement immediately after it. If you want to reuse that same logic
    in a completely separate query below it, you'd have to retype the entire WITH block 
     again from scratch.

    Views always recalculate live — a view never stores actual data. Every single time you
     SELECT from a view, the database re-runs the underlying query behind the scenes, from 
     scratch, against the current live data. This is great for staying up-to-date, but wasteful 
    if you're going to query the same result many times in a row and the underlying data isn't changing.
    Temp tables store a snapshot — unlike CTEs and views, a temp table actually calculates the result
    once and physically holds onto it (in temporary storage) for the rest of your session. This means 
    any query you run against it afterward is instant — it's just reading stored data, not recalculating anything.

*/

/*
   Create the temp table. */


CREATE TEMPORARY TABLE temp_customer_spending AS
SELECT customer_id, SUM(amount) AS total_spent
FROM payment
GROUP BY customer_id;

/* 
    Explanation:
    CREATE TEMPORARY TABLE table_name AS (a SELECT query) — this runs the SELECT once, and instead 
    of just displaying the results, it saves them into a brand-new table called temp_customer_spending.
    This table behaves exactly like a normal table (you can add indexes, filter it, join it to other tables) —
     the only difference is it's automatically deleted once your session/connection ends.
     The calculation (SUM(amount) GROUP BY customer_id) only happens this one time, right now, when the table is created.
*/




  