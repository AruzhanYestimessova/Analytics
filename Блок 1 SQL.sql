CREATE DATABASE my_database;
USE my_database;
CREATE TABLE transactions_info (
    date_new DATE,
    Id_check INT,
    ID_client INT,
    Count_products INT,
    Sum_payment DECIMAL(10, 2)
);

CREATE TABLE customer_info (
    Id_client INT PRIMARY KEY,
    Total_amount DECIMAL(10, 2),
    Gender VARCHAR(10),
    Age VARCHAR(10),
    Count_city INT,
    Response_communication VARCHAR(50),
    Communication_3month VARCHAR(50),
    Tenure INT
);

LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\TRANSACTIONS (2).csv"
INTO TABLE transactions_info
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(date_new, Id_check, ID_client, Count_products, Sum_payment);

SHOW VARIABLES LIKE 'secure_file_priv';

LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\customer_info.xlsx - QUERY_FOR_ABT_CUSTOMERINFO_0002 (3).csv"
INTO TABLE customer_info
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(Id_client, Total_amount, Gender, Age, Count_city, Response_communication, Communication_3month, Tenure);

SHOW VARIABLES LIKE 'secure_file_priv';
SELECT * FROM customers;
UPDATE customers SET Gender = NULL WHERE Gender ='';
UPDATE customers SET Age = NULL WHERE Age ='';
ALTER TABLE Customers MODIFY AGE INT NULL;

#Список клиентов с непрерывной историей за год /(01.06.2015 по 01.06.2016)
WITH MonthlyTransactions AS (
    SELECT 
        ID_client, 
        EXTRACT(MONTH FROM date_new) AS month,
        EXTRACT(YEAR FROM date_new) AS year
    FROM transactions_info
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY ID_client, EXTRACT(MONTH FROM date_new), EXTRACT(YEAR FROM date_new)
),
ClientMonths AS (
    SELECT ID_client, COUNT(DISTINCT month) AS months_active
    FROM MonthlyTransactions
    GROUP BY ID_client
    HAVING months_active = 12
)
SELECT c.ID_client, c.Total_amount, c.Gender, c.Age, c.Count_city, c.Response_communication, c.Communication_3month, c.Tenure
FROM customer_info c
JOIN ClientMonths cm ON c.ID_client = cm.ID_client;

# Средний чек за период с 01.06.2015 по 01.06.2016
SELECT 
    ID_client, 
    AVG(Sum_payment) AS average_check
FROM transactions_info
WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY ID_client;

#Средняя сумма покупок за месяц и количество всех операций по клиенту
WITH MonthlyPayments AS (
    SELECT 
        ID_client, 
        EXTRACT(MONTH FROM date_new) AS month,
        SUM(Sum_payment) AS monthly_sum,
        COUNT(*) AS monthly_transactions
    FROM transactions_info
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY ID_client, EXTRACT(MONTH FROM date_new)
)
SELECT 
    ID_client,
    AVG(monthly_sum) AS avg_monthly_spending,
    AVG(monthly_transactions) AS avg_monthly_transactions
FROM MonthlyPayments
GROUP BY ID_client;

#Пункт для себя #Информация по месяцам (общие продажи, общие операций и доля)
SELECT 
    EXTRACT(MONTH FROM date_new) AS month,  -- Извлекаем месяц из даты
    SUM(Sum_payment) AS total_monthly_sales,  -- Сумма всех продаж за месяц
    COUNT(*) AS total_monthly_operations,  -- Общее количество операций за месяц
    COUNT(DISTINCT ID_client) AS active_clients  -- Количество уникальных клиентов за месяц
FROM transactions_info
WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'  -- Учитываем данные в нужном периоде
GROUP BY EXTRACT(MONTH FROM date_new);  -- Группируем по месяцу

SELECT 
    SUM(Sum_payment) AS total_sales,  -- Общая сумма всех продаж
    COUNT(*) AS total_operations  -- Общее количество операций
FROM transactions_info
WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01';  -- Период с 01.06.2015 по 01.06.2016

WITH MonthlyStats AS (
    SELECT 
        EXTRACT(MONTH FROM date_new) AS month,
        SUM(Sum_payment) AS total_monthly_sales,
        COUNT(*) AS total_monthly_operations,
        COUNT(DISTINCT ID_client) AS active_clients
    FROM transactions_info
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY EXTRACT(MONTH FROM date_new)
),
TotalStats AS (
    SELECT 
        SUM(Sum_payment) AS total_sales,
        COUNT(*) AS total_operations
    FROM transactions_info
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
)
SELECT 
    ms.month,
    ms.total_monthly_sales,
    ms.total_monthly_operations,
    ms.active_clients,
    (ms.total_monthly_operations / ts.total_operations) * 100 AS operation_share,
    (ms.total_monthly_sales / ts.total_sales) * 100 AS sales_share
FROM MonthlyStats ms
JOIN TotalStats ts;

#Средняя сумма чека в месяц
WITH MonthlyStats AS (

    SELECT 
        EXTRACT(MONTH FROM date_new) AS month,  -- Извлекаем месяц из даты
        SUM(Sum_payment) AS total_monthly_sales,  -- Сумма всех продаж за месяц
        COUNT(*) AS total_monthly_operations  -- Общее количество операций за месяц
    FROM transactions_info
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'  -- Период с 01.06.2015 по 01.06.2016
    GROUP BY EXTRACT(MONTH FROM date_new)  -- Группируем по месяцу
)
SELECT 
    month, 
    total_monthly_sales / total_monthly_operations AS avg_check_per_month  -- Средняя сумма чека
FROM MonthlyStats;

#Среднее количество операций в месяц
WITH MonthlyOperations AS (
    SELECT 
        EXTRACT(MONTH FROM date_new) AS month,  -- Извлекаем месяц
        COUNT(*) AS total_monthly_operations  -- Общее количество операций за месяц
    FROM transactions_info
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'  -- Период с 01.06.2015 по 01.06.2016
    GROUP BY EXTRACT(MONTH FROM date_new)  -- Группируем по месяцу
)
SELECT 
    SUM(total_monthly_operations) / 12 AS avg_operations_per_month  -- Среднее количество операций за месяц
FROM MonthlyOperations;

SELECT 
    EXTRACT(MONTH FROM date_new) AS month,  -- Извлекаем месяц
    COUNT(*) AS total_monthly_operations  -- Общее количество операций за месяц
FROM transactions_info
WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'  -- Период с 01.06.2015 по 01.06.2016
GROUP BY EXTRACT(MONTH FROM date_new)  -- Группируем по месяцу
ORDER BY month;

# Среднее количество клиентов которые совершали операции
WITH MonthlyStats AS (
    SELECT 
        EXTRACT(MONTH FROM date_new) AS month,  -- Извлекаем месяц из даты
        COUNT(DISTINCT ID_client) AS active_clients  -- Количество уникальных клиентов за месяц
    FROM transactions_info
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'  -- Период с 01.06.2015 по 01.06.2016
    GROUP BY EXTRACT(MONTH FROM date_new)  -- Группируем по месяцу
)
SELECT 
    AVG(active_clients) AS avg_clients_per_month  -- Среднее количество клиентов
FROM MonthlyStats;

# Доля общего количества операций за год
WITH MonthlyStats AS (
    SELECT 
        EXTRACT(MONTH FROM date_new) AS month,  -- Извлекаем месяц из даты
        COUNT(*) AS total_monthly_operations  -- Общее количество операций за месяц
    FROM transactions_info
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'  -- Период с 01.06.2015 по 01.06.2016
    GROUP BY EXTRACT(MONTH FROM date_new)  -- Группируем по месяцу
),
TotalStats AS (
    SELECT 
        COUNT(*) AS total_operations  -- Общее количество операций за год
    FROM transactions_info
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'  -- Период с 01.06.2015 по 01.06.2016
)
SELECT 
    ms.month,
    (ms.total_monthly_operations / ts.total_operations) * 100 AS operation_share  -- Доля операций за месяц
FROM MonthlyStats ms
JOIN TotalStats ts;

# Доля в месяц от общей суммы операций
WITH MonthlyStats AS (
    SELECT 
        EXTRACT(MONTH FROM date_new) AS month,  -- Извлекаем месяц из даты
        SUM(Sum_payment) AS total_monthly_sales  -- Сумма всех продаж за месяц
    FROM transactions_info
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'  -- Период с 01.06.2015 по 01.06.2016
    GROUP BY EXTRACT(MONTH FROM date_new)  -- Группируем по месяцу
),
TotalStats AS (
    SELECT 
        SUM(Sum_payment) AS total_sales  -- Общая сумма всех продаж за год
    FROM transactions_info
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'  -- Период с 01.06.2015 по 01.06.2016
)
SELECT 
    ms.month,
    (ms.total_monthly_sales / ts.total_sales) * 100 AS sales_share  -- Доля продаж за месяц
FROM MonthlyStats ms
JOIN TotalStats ts;

# % соотношение M/F/NA в каждом месяца с их долей затрат
WITH MonthlyGenderStats AS (
    SELECT 
        EXTRACT(MONTH FROM t.date_new) AS month,
        c.Gender,
        SUM(t.Sum_payment) AS total_spent
    FROM transactions_info t
    JOIN customer_info c ON t.ID_client = c.ID_client
    WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY EXTRACT(MONTH FROM t.date_new), c.Gender
),
MonthlyTotalSales AS (
    SELECT 
        EXTRACT(MONTH FROM date_new) AS month,
        SUM(Sum_payment) AS total_sales
    FROM transactions_info
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY EXTRACT(MONTH FROM date_new)
)
SELECT 
    mgs.month,
    mgs.Gender,
    SUM(mgs.total_spent) AS total_spent_by_gender,
    (SUM(mgs.total_spent) / mts.total_sales) * 100 AS gender_spending_share
FROM MonthlyGenderStats mgs
JOIN MonthlyTotalSales mts ON mgs.month = mts.month
GROUP BY mgs.month, mgs.Gender, mts.total_sales;

#Для возрастных групп за весь период
WITH AgeGroupStats AS (
    SELECT 
        CASE 
            WHEN Age BETWEEN 0 AND 9 THEN '0-9'
            WHEN Age BETWEEN 10 AND 19 THEN '10-19'
            WHEN Age BETWEEN 20 AND 29 THEN '20-29'
            WHEN Age BETWEEN 30 AND 39 THEN '30-39'
            WHEN Age BETWEEN 40 AND 49 THEN '40-49'
            WHEN Age BETWEEN 50 AND 59 THEN '50-59'
            WHEN Age BETWEEN 60 AND 69 THEN '60-69'
            WHEN Age BETWEEN 70 AND 79 THEN '70-79'
            WHEN Age BETWEEN 80 AND 89 THEN '80-89'
            WHEN Age >= 90 THEN '90+'
            WHEN Age IS NULL OR Age ='' THEN 'UNKNOWN'  -- Если возраст не указан
        END AS age_group,
        COUNT(*) AS total_operations,  -- Количество операций в каждой возрастной группе
        SUM(Sum_payment) AS total_spent  -- Сумма операций в каждой возрастной группе
    FROM transactions_info t
    JOIN customer_info c ON t.ID_client = c.ID_client
    GROUP BY age_group
)
SELECT 
    age_group,
    total_operations,
    total_spent,
    AVG(total_operations) OVER() AS avg_operations,  -- Среднее количество операций
    AVG(total_spent) OVER() AS avg_spent,  -- Средняя сумма операций
    (total_operations / (SELECT SUM(total_operations) FROM AgeGroupStats)) * 100 AS operation_percentage,  -- Процент от общего количества операций
    (total_spent / (SELECT SUM(total_spent) FROM AgeGroupStats)) * 100 AS spent_percentage  -- Процент от общей суммы операций
FROM AgeGroupStats;

#Для возрастных групп поквартально
WITH QuarterlyStats AS (
    SELECT 
        EXTRACT(YEAR FROM date_new) AS year,  -- Извлекаем год
        EXTRACT(QUARTER FROM date_new) AS quarter,  -- Извлекаем квартал
        CASE 
            WHEN Age BETWEEN 0 AND 9 THEN '0-9'
            WHEN Age BETWEEN 10 AND 19 THEN '10-19'
            WHEN Age BETWEEN 20 AND 29 THEN '20-29'
            WHEN Age BETWEEN 30 AND 39 THEN '30-39'
            WHEN Age BETWEEN 40 AND 49 THEN '40-49'
            WHEN Age BETWEEN 50 AND 59 THEN '50-59'
            WHEN Age BETWEEN 60 AND 69 THEN '60-69'
            WHEN Age BETWEEN 70 AND 79 THEN '70-79'
            WHEN Age BETWEEN 80 AND 89 THEN '80-89'
            WHEN Age >= 90 THEN '90+'
            WHEN Age IS NULL THEN 'Unknown'  -- Если возраст не указан (NULL)
        END AS age_group,
        COUNT(*) AS total_operations,  -- Количество операций в квартале
        SUM(Sum_payment) AS total_spent  -- Сумма операций в квартале
    FROM transactions_info t
    JOIN customer_info c ON t.ID_client = c.ID_client
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'  -- Период с 01.06.2015 по 01.06.2016
    GROUP BY year, quarter, age_group  -- Группируем по году, кварталу и возрастной группе
),
TotalStats AS (
    SELECT 
        SUM(total_operations) AS total_operations_all,  -- Общее количество операций за весь период
        SUM(total_spent) AS total_spent_all  -- Общая сумма всех операций за весь период
    FROM QuarterlyStats
)
SELECT 
    year,
    quarter,
    age_group,
    total_operations,
    total_spent,
    AVG(total_operations) OVER(PARTITION BY year, quarter) AS avg_operations,  -- Среднее количество операций по кварталу
    AVG(total_spent) OVER(PARTITION BY year, quarter) AS avg_spent,  -- Средняя сумма операций по кварталу
    (total_operations / (SELECT total_operations_all FROM TotalStats)) * 100 AS operation_percentage,  -- Процент от общего количества операций
    (total_spent / (SELECT total_spent_all FROM TotalStats)) * 100 AS spent_percentage  -- Процент от общей суммы операций
FROM QuarterlyStats
ORDER BY year, quarter, age_group;

#Для тех у кого нет информации (за весь период)
SELECT
    'Unknown' AS age_group,
    COUNT(*) AS total_operations,
    SUM(t.Sum_payment) AS total_spent,
    AVG(t.Sum_payment) AS avg_check,
    COUNT(*) / COUNT(DISTINCT DATE(t.date_new)) AS avg_operations,
    COUNT(DISTINCT t.ID_client) AS total_clients,
    COUNT(DISTINCT t.ID_client) / COUNT(DISTINCT DATE(t.date_new)) AS avg_clients,
    COUNT(*) * 100 / (
        SELECT COUNT(*)
        FROM transactions_info
        WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
    ) AS operation_percentage,
    SUM(t.Sum_payment) * 100 / (
        SELECT SUM(Sum_payment)
        FROM transactions_info
        WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
    ) AS spent_percentage
FROM transactions_info t
JOIN customer_info c
ON t.ID_client = c.ID_client
WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
AND (c.Age IS NULL OR c.Age ='');

#Для тех у кого нет информации (поквартально)
SELECT
    EXTRACT(YEAR FROM t.date_new) AS year,
    EXTRACT(QUARTER FROM t.date_new) AS quarter,
    COUNT(*) AS unknown_operations,
    SUM(t.Sum_payment) AS unknown_spent,
    AVG(t.Sum_payment) AS avg_check_unknown,
    COUNT(*) / COUNT(DISTINCT DATE(t.date_new)) AS avg_operations_unknown,
    COUNT(DISTINCT t.ID_client) AS unknown_clients
FROM transactions_info t
JOIN customer_info c
ON t.ID_client = c.ID_client
WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
AND (c.Age IS NULL OR c.Age = '')
GROUP BY year, quarter
ORDER BY year, quarter;

SELECT
    EXTRACT(YEAR FROM date_new) AS year,
    EXTRACT(QUARTER FROM date_new) AS quarter,
    COUNT(*) AS total_operations,
    SUM(Sum_payment) AS total_spent
FROM transactions_info
WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
GROUP BY year, quarter
ORDER BY year, quarter;

WITH UnknownQuarterly AS (
    SELECT
        EXTRACT(YEAR FROM t.date_new) AS year,
        EXTRACT(QUARTER FROM t.date_new) AS quarter,
        COUNT(*) AS unknown_operations,
        SUM(t.Sum_payment) AS unknown_spent,
        AVG(t.Sum_payment) AS avg_check_unknown,
        COUNT(*) / COUNT(DISTINCT DATE(t.date_new)) AS avg_operations_unknown,
        COUNT(DISTINCT t.ID_client) AS unknown_clients
    FROM transactions_info t
    JOIN customer_info c
    ON t.ID_client = c.ID_client
    WHERE t.date_new BETWEEN '2015-06-01' AND '2016-06-01'
    AND (c.Age IS NULL OR c.Age = '')
    GROUP BY year, quarter
),

TotalQuarterly AS (
    SELECT
        EXTRACT(YEAR FROM date_new) AS year,
        EXTRACT(QUARTER FROM date_new) AS quarter,
        COUNT(*) AS total_operations,
        SUM(Sum_payment) AS total_spent
    FROM transactions_info
    WHERE date_new BETWEEN '2015-06-01' AND '2016-06-01'
    GROUP BY year, quarter
)

SELECT
    u.year,
    u.quarter,
    'Unknown' AS age_group,
    u.unknown_operations,
    u.unknown_spent,
    u.avg_check_unknown,
    u.avg_operations_unknown,
    u.unknown_clients,
    u.unknown_operations * 100 / tq.total_operations AS operation_percentage,
    u.unknown_spent * 100 / tq.total_spent AS spent_percentage
FROM UnknownQuarterly u
JOIN TotalQuarterly tq
ON u.year = tq.year
AND u.quarter = tq.quarter
ORDER BY u.year, u.quarter;