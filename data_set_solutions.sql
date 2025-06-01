-- SQL Commands

SELECT * FROM actor;
SELECT * FROM customer;
SELECT DISTINCT country FROM country;
SELECT * FROM customer WHERE active = 1;
SELECT rental_id FROM rental WHERE customer_id = 1;
SELECT * FROM film WHERE rental_duration > 5;
SELECT COUNT(*) FROM film WHERE replacement_cost > 15 AND replacement_cost < 20;
SELECT COUNT(DISTINCT first_name) FROM actor;
SELECT * FROM customer LIMIT 10;
SELECT * FROM customer WHERE LOWER(first_name) LIKE 'b%' LIMIT 3;
SELECT title FROM film WHERE rating = 'G' LIMIT 5;
SELECT * FROM customer WHERE LOWER(first_name) LIKE 'a%';
SELECT * FROM customer WHERE LOWER(first_name) LIKE '%a';
SELECT * FROM city WHERE LOWER(city) LIKE 'a%' AND LOWER(city) LIKE '%a' LIMIT 4;
SELECT * FROM customer WHERE UPPER(first_name) LIKE '%NI%';
SELECT * FROM customer WHERE LOWER(first_name) LIKE '_r%';
SELECT * FROM customer WHERE LOWER(first_name) LIKE 'a%' AND LENGTH(first_name) >= 5;
SELECT * FROM customer WHERE LOWER(first_name) LIKE 'a%' AND LOWER(first_name) LIKE '%o';
SELECT * FROM film WHERE rating IN ('PG', 'PG-13');
SELECT * FROM film WHERE length BETWEEN 50 AND 100;
SELECT * FROM actor LIMIT 50;
SELECT DISTINCT film_id FROM inventory;

-- Functions (Aggregate, String, Group By)

SELECT COUNT(*) AS total_rentals FROM rental;
SELECT AVG(rental_duration) AS avg_rental_duration FROM film;
SELECT UPPER(first_name), UPPER(last_name) FROM customer;
SELECT rental_id, MONTH(rental_date) AS rental_month FROM rental;
SELECT customer_id, COUNT(*) AS rental_count FROM rental GROUP BY customer_id;
SELECT store_id, SUM(amount) AS total_revenue FROM payment GROUP BY store_id;
SELECT fc.category_id, c.name, COUNT(*) AS total_rentals
FROM film_category fc
JOIN category c ON fc.category_id = c.category_id
JOIN inventory i ON fc.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY fc.category_id, c.name;
SELECT l.name, AVG(f.rental_rate)
FROM film f
JOIN language l ON f.language_id = l.language_id
GROUP BY l.name;

-- Joins

SELECT f.title, c.first_name, c.last_name
FROM film f
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
JOIN customer c ON r.customer_id = c.customer_id;

SELECT a.first_name, a.last_name
FROM actor a
JOIN film_actor fa ON a.actor_id = fa.actor_id
JOIN film f ON fa.film_id = f.film_id
WHERE f.title = 'Gone with the Wind';

SELECT c.first_name, c.last_name, SUM(p.amount) AS total_spent
FROM customer c
JOIN payment p ON c.customer_id = p.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name;

SELECT c.first_name, c.last_name, f.title
FROM customer c
JOIN address a ON c.address_id = a.address_id
JOIN city ci ON a.city_id = ci.city_id
JOIN rental r ON c.customer_id = r.customer_id
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
WHERE ci.city = 'London';

SELECT f.title, COUNT(r.rental_id) AS rental_count
FROM film f
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
GROUP BY f.film_id, f.title
ORDER BY rental_count DESC
LIMIT 5;

SELECT c.customer_id, c.first_name, c.last_name
FROM customer c
JOIN rental r ON c.customer_id = r.customer_id
JOIN inventory i ON r.inventory_id = i.inventory_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(DISTINCT i.store_id) = 2;


-- Window Functions

-- 1. Rank customers by total spending
SELECT customer_id, first_name, last_name, 
       SUM(amount) AS total_spent,
       RANK() OVER (ORDER BY SUM(amount) DESC) AS spending_rank
FROM customer
JOIN payment ON customer.customer_id = payment.customer_id
GROUP BY customer_id, first_name, last_name;

-- 2. Cumulative revenue by film over time
SELECT f.film_id, f.title, p.payment_date, SUM(p.amount) OVER (
    PARTITION BY f.film_id ORDER BY p.payment_date
) AS cumulative_revenue
FROM film f
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
JOIN payment p ON r.rental_id = p.rental_id;

-- 3. Average rental duration for films with similar lengths
SELECT film_id, title, length,
       AVG(rental_duration) OVER (PARTITION BY length) AS avg_rental_duration
FROM film;

-- 4. Top 3 films per category based on rental count
WITH film_rentals AS (
  SELECT fc.category_id, c.name AS category_name, f.film_id, f.title,
         COUNT(r.rental_id) AS rental_count
  FROM film f
  JOIN film_category fc ON f.film_id = fc.film_id
  JOIN category c ON fc.category_id = c.category_id
  JOIN inventory i ON f.film_id = i.film_id
  JOIN rental r ON i.inventory_id = r.inventory_id
  GROUP BY fc.category_id, c.name, f.film_id, f.title
)
SELECT *, 
       RANK() OVER (PARTITION BY category_id ORDER BY rental_count DESC) AS rank
FROM film_rentals
WHERE rank <= 3;

-- 5. Difference between customer's rentals and average
WITH rental_counts AS (
  SELECT customer_id, COUNT(*) AS rental_count
  FROM rental
  GROUP BY customer_id
)
SELECT customer_id, rental_count,
       rental_count - AVG(rental_count) OVER () AS diff_from_avg
FROM rental_counts;

-- 6. Monthly revenue trend
SELECT DATE_FORMAT(payment_date, '%Y-%m') AS month,
       SUM(amount) AS monthly_revenue
FROM payment
GROUP BY DATE_FORMAT(payment_date, '%Y-%m')
ORDER BY month;

-- 7. Top 20% spenders
WITH customer_spending AS (
  SELECT customer_id, SUM(amount) AS total_spent
  FROM payment
  GROUP BY customer_id
),
ranked AS (
  SELECT *, NTILE(5) OVER (ORDER BY total_spent DESC) AS quintile
  FROM customer_spending
)
SELECT * FROM ranked WHERE quintile = 1;

-- 8. Running total of rentals per category
WITH rental_counts AS (
  SELECT c.name AS category_name, COUNT(r.rental_id) AS rental_count
  FROM film f
  JOIN film_category fc ON f.film_id = fc.film_id
  JOIN category c ON fc.category_id = c.category_id
  JOIN inventory i ON f.film_id = i.film_id
  JOIN rental r ON i.inventory_id = r.inventory_id
  GROUP BY c.name
)
SELECT *, SUM(rental_count) OVER (ORDER BY category_name) AS running_total
FROM rental_counts;

-- 9. Films rented less than category average
WITH film_rentals AS (
  SELECT fc.category_id, f.film_id, f.title, COUNT(r.rental_id) AS rental_count
  FROM film f
  JOIN film_category fc ON f.film_id = fc.film_id
  JOIN inventory i ON f.film_id = i.film_id
  JOIN rental r ON i.inventory_id = r.inventory_id
  GROUP BY fc.category_id, f.film_id, f.title
),
category_avg AS (
  SELECT category_id, AVG(rental_count) AS avg_rentals
  FROM film_rentals
  GROUP BY category_id
)
SELECT fr.*
FROM film_rentals fr
JOIN category_avg ca ON fr.category_id = ca.category_id
WHERE fr.rental_count < ca.avg_rentals;

-- 10. Top 5 months by revenue
SELECT DATE_FORMAT(payment_date, '%Y-%m') AS month,
       SUM(amount) AS revenue
FROM payment
GROUP BY DATE_FORMAT(payment_date, '%Y-%m')
ORDER BY revenue DESC
LIMIT 5;

-- Normalization & CTEs

-- CTE: Actor name and film count
WITH actor_film_count AS (
  SELECT a.actor_id, a.first_name, a.last_name, COUNT(fa.film_id) AS film_count
  FROM actor a
  JOIN film_actor fa ON a.actor_id = fa.actor_id
  GROUP BY a.actor_id, a.first_name, a.last_name
)
SELECT * FROM actor_film_count;

-- CTE with film and language
WITH film_language AS (
  SELECT f.title, l.name AS language_name, f.rental_rate
  FROM film f
  JOIN language l ON f.language_id = l.language_id
)
SELECT * FROM film_language;

-- CTE for total revenue per customer
WITH customer_revenue AS (
  SELECT customer_id, SUM(amount) AS total_revenue
  FROM payment
  GROUP BY customer_id
)
SELECT * FROM customer_revenue;

-- CTE with window function – rank films by rental duration
WITH ranked_films AS (
  SELECT title, rental_duration,
         RANK() OVER (ORDER BY rental_duration DESC) AS duration_rank
  FROM film
)
SELECT * FROM ranked_films;

-- CTE for customers with >2 rentals
WITH frequent_customers AS (
  SELECT customer_id, COUNT(*) AS rental_count
  FROM rental
  GROUP BY customer_id
  HAVING COUNT(*) > 2
)
SELECT fc.*, c.first_name, c.last_name
FROM frequent_customers fc
JOIN customer c ON fc.customer_id = c.customer_id;

-- CTE: Rentals per month
WITH monthly_rentals AS (
  SELECT DATE_FORMAT(rental_date, '%Y-%m') AS month, COUNT(*) AS rentals
  FROM rental
  GROUP BY DATE_FORMAT(rental_date, '%Y-%m')
)
SELECT * FROM monthly_rentals;

-- CTE: Actor pairs in same film
WITH actor_pairs AS (
  SELECT fa1.film_id, fa1.actor_id AS actor1, fa2.actor_id AS actor2
  FROM film_actor fa1
  JOIN film_actor fa2 ON fa1.film_id = fa2.film_id
  WHERE fa1.actor_id < fa2.actor_id
)
SELECT * FROM actor_pairs;
-- Recursive CTE: Find employees reporting to a manager
WITH RECURSIVE subordinates AS (
  SELECT staff_id, first_name, last_name, reports_to
  FROM staff
  WHERE reports_to = 1

  UNION ALL

  SELECT s.staff_id, s.first_name, s.last_name, s.reports_to
  FROM staff s
  JOIN subordinates sub ON s.reports_to = sub.staff_id
)
SELECT * FROM subordinates;
