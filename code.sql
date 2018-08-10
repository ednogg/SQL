--1. Take a look at the first 100 rows of data in the subscriptions table. How many different segments do you see?///There appear to be only two segments, which is confirmed by the segment group by query.--
SELECT *
FROM subscriptions
LIMIT 100;

SELECT DISTINCT segment
FROM subscriptions;

--2.Determine the range of months of data provided. Which months will you be able to calculate churn for?///The first month in the data is December 2016 and the last month is March 2017. Since a user cannot end his/her subscription in the same month, I can only calculate churn for months beginning in January 2017.--
SELECT MIN(subscription_start) AS first_month,   		MAX(subscription_end) AS last_month
FROM subscriptions;

--3. Create temporary table of months--
WITH months AS
  (SELECT
    '2017-01-01' AS first_day,
    '2017-01-31' AS last_day
  UNION
  SELECT 
    '2017-02-01' AS first_day,
    '2017-02-28' AS last_day
  UNION
  SELECT
    '2017-03-01' AS first_day,
    '2017-03-31' AS last_day),
--4. Create cross_join table.--
cross_join AS
  (SELECT *
  FROM subscriptions
  CROSS JOIN months),
--5 and 6 Create status table. Include both active and canceled dummy variables--
status AS 
  (SELECT id, 
   first_day as month,
   CASE
    WHEN(subscription_start < first_day) AND 
      (subscription_end > first_day OR 		
       subscription_end IS NULL) AND 
      (segment = 87) THEN 1
    ELSE 0
   END AS is_active_87,
   CASE
    WHEN(subscription_start < first_day) AND 
      (subscription_end > first_day OR 
       subscription_end IS NULL) AND
      (segment = 30) THEN 1
    ELSE 0
   END AS is_active_30,
   CASE 
    WHEN (subscription_end BETWEEN first_day AND last_day) AND 
      (segment = 87) THEN 1
    ELSE 0
   END as is_canceled_87,
   CASE 
    WHEN (subscription_end BETWEEN first_day AND last_day) AND 	
      (segment = 30) THEN 1
    ELSE 0
   END as is_canceled_30
  FROM cross_join),
--7. Sum the data to identify total options for churn rate.--
status_aggregate AS 
  (SELECT status.month, 
    SUM(is_active_87) AS sum_active_87, 
    SUM(is_active_30) AS sum_active_30, 
    SUM(is_canceled_87) AS sum_canceled_87, 
    SUM(is_canceled_30) AS sum_canceled_30
  FROM status
  GROUP BY status.month)
--8. Calculate churn rates.--
SELECT month,
  1.0 *(sum_canceled_87+sum_canceled_30)/(sum_active_87+sum_active_30) AS churn_rate_overall,
  1.0 * sum_canceled_87/sum_active_87 AS churn_rate_87, 
  1.0 * sum_canceled_30/sum_active_30 AS churn_rate_30
FROM status_aggregate;