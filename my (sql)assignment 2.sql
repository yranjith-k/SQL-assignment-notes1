/* Q1.Identify duplicates in Customer table (without using customer_id).*/

SELECT first_name, last_name, email, COUNT(*) AS duplicate_count
FROM customer
GROUP BY first_name, last_name, email
HAVING COUNT(*) > 1;

/*

   Since we can't use customer_id (which is always unique by design), we group by the other identifying columns instead — here first_name, last_name, and email.
   GROUP BY collapses all rows with the same combination of these values into one group.
   COUNT(*) counts how many rows fall into each group.
   HAVING COUNT(*) > 1 keeps only the groups that appeared more than once — meaning the same name+email combination exists in multiple rows, which indicates a duplicate customer record.
   You can adjust which columns you group by depending on what "duplicate" means for your assignment (e.g., just email, or name + address)
*/

/* Q2. Number of times the letter 'a' is repeated in film descriptions
     .*/

     SELECT SUM(LENGTH(description) - LENGTH(REPLACE(LOWER(description), 'a', ''))) AS total_a_count
FROM film;


/*

   This uses a classic SQL trick since there's no built-in "count character occurrences" function.
   LENGTH(description) — gets the total character length of each description.
   REPLACE(LOWER(description), 'a', '') — makes the text lowercase (so it catches both 'A' and 'a'), then removes every occurrence of 'a' from the string.
   LENGTH(...) on that modified string — gets the new (shorter) length after removing all the 'a's.
   Subtracting the shortened length from the original length tells you exactly how many 'a' characters were removed — i.e., how many times 'a' appeared in that one description.
   SUM(...) adds this count across all rows in the film table, giving you a grand total

*/

/*

   Q3. Number of times EACH vowel is repeated in film descriptions 
*/
 SELECT 
  SUM(LENGTH(description) - LENGTH(REPLACE(LOWER(description), 'a', ''))) AS count_a,
  SUM(LENGTH(description) - LENGTH(REPLACE(LOWER(description), 'e', ''))) AS count_e,
  SUM(LENGTH(description) - LENGTH(REPLACE(LOWER(description), 'i', ''))) AS count_i,
  SUM(LENGTH(description) - LENGTH(REPLACE(LOWER(description), 'o', ''))) AS count_o,
  SUM(LENGTH(description) - LENGTH(REPLACE(LOWER(description), 'u', ''))) AS count_u
FROM film;

/* 
    Same exact logic as question 2, just repeated once for each vowel (a, e, i, o, u).
    Each SUM(...) calculation is independent — it removes only that one specific letter and measures the length difference.
    Result: one row with five columns, each showing the total count of that vowel across every film description in the table.
*/

/*
   Q4. Display the payments made by each customer:

*/
SELECT customer_id, 
       YEAR(payment_date) AS pay_year,
       MONTH(payment_date) AS pay_month,
       SUM(amount) AS total_paid
FROM payment
GROUP BY customer_id, YEAR(payment_date), MONTH(payment_date)
ORDER BY customer_id, pay_year, pay_month;

/* Week-wise:

SELECT customer_id, 
       YEAR(payment_date) AS pay_year,
       WEEK(payment_date) AS pay_week,
       SUM(amount) AS total_paid
FROM payment
GROUP BY customer_id, YEAR(payment_date), WEEK(payment_date)
ORDER BY customer_id, pay_year, pay_week;

/*
   YEAR(), MONTH(), and WEEK() are MySQL date functions that extract just that piece from a full date/timestamp.
   Month-wise: grouping by customer + year + month means each customer gets a separate row for every month they made payments in, with SUM(amount) totaling what they paid that month.
   Year-wise: simpler grouping — just customer + year, since month/week detail isn't needed.
   Week-wise: WEEK() returns a week number (0–53) within the year, so grouping by customer + year + week number breaks payments into weekly buckets.
   We include YEAR() alongside MONTH()/WEEK() in all of these because month numbers (1–12) and week numbers (0–53) repeat every year — without also grouping by year, payments from January 2023 and January 2024 would incorrectly get merged together.
*/

/* Q5. Check if any given year is a leap year or not.
       (Hardcoded date, no Sakila table involved.)
*/
SELECT 
  CASE 
    WHEN (2024 % 4 = 0 AND 2024 % 100 <> 0) OR (2024 % 400 = 0) 
    THEN 'Leap Year' 
    ELSE 'Not a Leap Year' 
  END AS leap_year_check;

  /* 
    This uses the real-world leap year rule: a year is a leap year if it's divisible by 4, unless it's also divisible by 100 — unless it's also divisible by 400 (then it IS a leap year after all). This is why 2000 was a leap year but 1900 was not.
    % is the modulus operator — year % 4 = 0 checks if there's no remainder when dividing by 4 (i.e., evenly divisible).
      CASE WHEN ... THEN ... ELSE ... END is SQL's version of an if/else statement — it evaluates the condition and returns one value or another based on whether it's true.
     Since no table is involved, you're just hardcoding the year (2024) directly into the logic — SQL can evaluate expressions and conditions even without pulling from any table, using SELECT on its own.

*/

/* To make it reusable for any year, you could write it with a variable-style hardcoded date instead: 
*/

SET @check_year = 2024;

SELECT 
  CASE 
    WHEN (@check_year % 4 = 0 AND @check_year % 100 <> 0) OR (@check_year % 400 = 0) 
    THEN 'Leap Year' 
    ELSE 'Not a Leap Year' 
  END AS leap_year_check;

  /* 
   Q6. Display number of days remaining in the current year from today.
   */

   SELECT DATEDIFF(
  CONCAT(YEAR(CURDATE()), '-12-31'), 
  CURDATE()
) AS days_remaining;

/* 
  CURDATE() — returns today's date automatically (no hardcoding needed).
  YEAR(CURDATE()) — extracts just the year from today's date (e.g., 2026).
  CONCAT(YEAR(CURDATE()), '-12-31') — builds a date string for December 31st of this year (e.g., '2026-12-31'), by joining the year with -12-31.
  DATEDIFF(date1, date2) — calculates the number of days between two dates (date1 minus date2).
   So this calculates: "December 31st of this year" minus "today" = how many days are left until the year ends.
*/


/* 
  Q7 Display quarter number (Q1, Q2, Q3, Q4) for payment dates
*/
SELECT payment_date, 
       CONCAT('Q', QUARTER(payment_date)) AS quarter_label
FROM payment;

/*
   QUARTER(date) is a built-in MySQL function that returns which quarter (1, 2, 3, or 4) a given date falls into. Jan–Mar = 1, Apr–Jun = 2, Jul–Sep = 3, Oct–Dec = 4.
   CONCAT('Q', QUARTER(payment_date)) — joins the letter "Q" with that number, so instead of showing just 1, 2, 3, 4, it displays Q1, Q2, Q3, Q4 — matching how quarters are usually labeled.
   Each row in the result shows the original payment date alongside which quarter it belongs to.
*/





