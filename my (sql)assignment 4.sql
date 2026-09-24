/* =========================================================================
   JOIN PRACTICE -- built on the Sakila sample database.
   Before running any of the queries below, make sure you're pointed at
   the right schema by running:

       USE sakila;

   TYPES OF JOINS COVERED IN THIS FILE:

     - INNER JOIN
         Returns only the rows where a match exists on BOTH sides.
         If either table has no matching row, that row is left out
         entirely.

     - LEFT JOIN
         Keeps every row from the left (first-listed) table no matter
         what. If a matching row exists on the right table, its columns
         are filled in; if not, those columns simply come back as NULL
         instead of the row being dropped.

     - RIGHT JOIN
         The exact opposite of LEFT JOIN -- keeps every row from the
         right table instead, filling in NULLs on the left side when
         there's no match.

     - FULL OUTER JOIN
         Keeps every row from BOTH tables, matched where possible and
         NULL-filled where not. MySQL has no native FULL OUTER JOIN
         keyword, so it has to be simulated manually by combining a
         LEFT JOIN and a RIGHT JOIN together with UNION.
   ========================================================================= */



   /* ---------------------------------------------------------------------
   Q1. List all customers along with the films they have rented.
   -----------------------------------------------------------------
   This one requires linking FOUR tables together, because there's no
   direct connection between "customer" and "film" in the database
   design. The path looks like this:

       customer --> rental --> inventory --> film

   Each rental row tells you which customer rented which physical copy
   (inventory_id). Each inventory row tells you which film that
   specific copy belongs to. So you have to hop through both rental
   AND inventory just to connect a customer to a film title.

   INNER JOIN is the right call here, not LEFT JOIN, because the
   question only wants customers paired with films they've actually
   rented -- there's no reason to show a customer's name next to a
   blank/NULL film if they've never rented anything.
   --------------------------------------------------------------------- */
SELECT c.customer_id,
       c.first_name,
       c.last_name,
       f.title
FROM customer c
JOIN rental r ON c.customer_id = r.customer_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
ORDER BY c.customer_id;


/* ---------------------------------------------------------------------
   Q2. List all customers and show their rental count, INCLUDING those
       who haven't rented any films.
   -----------------------------------------------------------------
   The word "including" in the question is what forces LEFT JOIN
   instead of INNER JOIN. Picture what INNER JOIN would do: a customer
   with zero rentals has no row in the rental table to match against,
   so an INNER JOIN would just erase them from the results entirely.

   LEFT JOIN instead says "keep every single customer no matter what,"
   and for anyone with no matching rental rows, it just fills those
   columns in with NULL instead of dropping the customer.

   There's also a subtle trap here: COUNT(*) vs COUNT(r.rental_id).
   After a LEFT JOIN, a customer with no rentals still produces exactly
   one row (just with NULLs in it) -- so COUNT(*) would wrongly count
   that as "1 rental." COUNT(r.rental_id) is smarter: it only counts
   non-NULL values, so a customer with no rentals correctly shows 0.
   --------------------------------------------------------------------- */
SELECT c.customer_id,
       c.first_name,
       c.last_name,
       COUNT(r.rental_id) AS rental_count
FROM customer c
LEFT JOIN rental r ON c.customer_id = r.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY rental_count DESC;


/* ---------------------------------------------------------------------
   Q3. Show all films along with their category. Include films that
       don't have a category assigned.
   -----------------------------------------------------------------
   Same underlying idea as Q2, just applied to films/categories instead
   of customers/rentals. "Include films with no category" tells you
   immediately that INNER JOIN is off the table, since it would quietly
   remove any film missing a link in film_category.

   Also worth noting: film and category don't connect directly to each
   other at all. They're related through film_category, a bridge table
   that exists purely to link the two (this is the standard way SQL
   handles many-to-many relationships -- one film can have multiple
   categories, and one category has many films).
   --------------------------------------------------------------------- */
SELECT f.title,
       cat.name AS category_name
FROM film f
LEFT JOIN film_category fc ON f.film_id = fc.film_id
LEFT JOIN category cat ON fc.category_id = cat.category_id
ORDER BY f.title;


/* ---------------------------------------------------------------------
   Q4. Show all customers and staff emails from both customer and
       staff tables using a FULL OUTER JOIN (simulate using LEFT +
       RIGHT + UNION).
   -----------------------------------------------------------------
   A true FULL OUTER JOIN means: don't drop ANYONE from either table --
   show every customer, every staff member, matched up wherever
   possible, with NULLs filling in the gaps on whichever side doesn't
   have a match.

   The catch: MySQL simply doesn't offer a FULL OUTER JOIN keyword.
   So the workaround is to fake it by running two separate queries and
   gluing them together:
     - one LEFT JOIN (keeps every customer, matches staff where possible)
     - one RIGHT JOIN (keeps every staff member, matches customers where
       possible)
     - UNION merges both result sets into one, and automatically
       drops any exact duplicate rows (rows that would've matched in
       both directions get counted only once)

   Since customer and staff aren't directly related to each other, we
   join them on store_id -- the one column both tables happen to share
   (each records which store the person is tied to).
   --------------------------------------------------------------------- */
SELECT c.customer_id, c.email AS customer_email, s.staff_id, s.email AS staff_email
FROM customer c
LEFT JOIN staff s ON c.store_id = s.store_id

UNION

SELECT c.customer_id, c.email AS customer_email, s.staff_id, s.email AS staff_email
FROM customer c
RIGHT JOIN staff s ON c.store_id = s.store_id;


/* ---------------------------------------------------------------------
   Q5. Find all actors who acted in the film "ACADEMY DINOSAUR".
   -----------------------------------------------------------------
   This is a straightforward lookup, but it still requires passing
   through a bridge table, since actor and film have a many-to-many
   relationship (one actor is in many films, one film has many actors).
   That relationship lives in film_actor.

   So the chain is: actor -> film_actor -> film, and then WHERE narrows
   it down to just the one title you care about. Since we're filtering
   to a specific, guaranteed-to-exist title, INNER JOIN is fine -- there's
   no "include actors with no films" requirement here.
   --------------------------------------------------------------------- */
SELECT a.first_name,
       a.last_name
FROM actor a
JOIN film_actor fa ON a.actor_id = fa.actor_id
JOIN film f ON fa.film_id = f.film_id
WHERE f.title = 'ACADEMY DINOSAUR';


/* ---------------------------------------------------------------------
   Q6. List all stores and the total number of staff members working
       in each store, even if a store has no staff.
   -----------------------------------------------------------------
   "Even if a store has no staff" is another instance of the same LEFT
   JOIN signal you've seen in Q2 and Q3 -- except now store is the table
   we're protecting from being dropped, so it goes on the LEFT side of
   the JOIN (and in the FROM clause).

   Same COUNT() logic as Q2 applies too: COUNT(s.staff_id) only counts
   actual staff rows, so a store with zero staff correctly shows a
   count of 0 instead of 1.
   --------------------------------------------------------------------- */
SELECT st.store_id,
       COUNT(s.staff_id) AS staff_count
FROM store st
LEFT JOIN staff s ON st.store_id = s.store_id
GROUP BY st.store_id;


/* ---------------------------------------------------------------------
   Q7. List the customers who have rented films more than 5 times.
       Include their name and total rental count.
   -----------------------------------------------------------------
   Even though this question also involves counting rentals per
   customer (like Q2), it does NOT need a LEFT JOIN. Think about why:
   a customer with 0 rentals could never satisfy "more than 5" anyway,
   so whether they're included or excluded up front makes zero
   difference to the final result -- HAVING would filter them out
   either way.

   Since keeping zero-rental customers around would be pointless here,
   a plain INNER JOIN is simpler and works just as correctly.
   --------------------------------------------------------------------- */
SELECT c.customer_id,
       c.first_name,
       c.last_name,
       COUNT(r.rental_id) AS total_rentals
FROM customer c
JOIN rental r ON c.customer_id = r.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(r.rental_id) > 5
ORDER BY total_rentals DESC;