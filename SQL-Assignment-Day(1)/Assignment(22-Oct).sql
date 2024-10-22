--Assignment-1
--stored procedure that retrieves a list of customers who have purchased a specified product:
CREATE PROCEDURE GetCustomersByProduct  @ProductID INT
AS
BEGIN
    SELECT 
        c.customer_id AS CustomerID,
        c.first_name + ' ' + c.last_name AS CustomerName,
        o.order_date AS PurchaseDate
    FROM 
        sales.orders o
    JOIN 
        sales.order_items oi ON o.order_id = oi.order_id
    JOIN 
        sales.customers c ON o.customer_id = c.customer_id
    JOIN 
        production.products p ON oi.product_id = p.product_id
    WHERE 
        p.product_id = @ProductID;
END;
GO
--calling procedure(1)
EXEC GetCustomersByProduct @ProductID = 3;



--Assignment - 2
--Creating Department Table
CREATE TABLE Department (
    ID INT PRIMARY KEY,
    Name VARCHAR(100)
);

INSERT INTO Department (ID, Name)
VALUES
    (1, 'HR'),
    (2, 'IT'),
    (3, 'Finance'),
    (4, 'Marketing');


--Creating Employee Table
CREATE TABLE Employee (
    ID INT PRIMARY KEY,
    Name VARCHAR(100),
    Gender VARCHAR(10),
    DOB DATE,
    DeptId INT,
    FOREIGN KEY (DeptId) REFERENCES Department(ID)
);

INSERT INTO Employee (ID, Name, Gender, DOB, DeptId)
VALUES
    (1, 'Amit Sharma', 'Male', '1990-01-15', 1),
    (2, 'Sakshi Patel', 'Female', '1992-05-23', 2),
    (3, 'Rahul Verma', 'Male', '1988-08-30', 3),
    (4, 'Neha Singh', 'Female', '1991-11-12', 4);


--a) Procedure to Update Employee Details Based on Employee ID
CREATE PROCEDURE UpdateEmployeeDetails
    @EmpID INT,
    @Name VARCHAR(100),
    @Gender VARCHAR(10),
    @DOB DATE,
    @DeptId INT
AS
BEGIN
    UPDATE Employee
    SET 
        Name = @Name,
        Gender = @Gender,
        DOB = @DOB,
        DeptId = @DeptId
    WHERE 
        ID = @EmpID;
END;
GO

--b) Procedure to Get Employee Info by Gender and Department ID
CREATE PROCEDURE GetEmployeeInfoByGenderAndDept
    @Gender VARCHAR(10),
    @DeptId INT
AS
BEGIN
    SELECT 
        e.ID,
        e.Name,
        e.Gender,
        e.DOB,
        d.Name AS Department
    FROM 
        Employee e
    JOIN 
        Department d ON e.DeptId = d.ID
    WHERE 
        e.Gender = @Gender
        AND e.DeptId = @DeptId;
END;
GO


--c) Procedure to Get Employee Info by Gender and Department ID
CREATE PROCEDURE GetEmployeeCountByGender
    @Gender VARCHAR(10)
AS
BEGIN
    SELECT 
        COUNT(*) AS EmployeeCount
    FROM 
        Employee
    WHERE 
        Gender = @Gender;
END;
GO

--Calling Procedure (a)
EXEC UpdateEmployeeDetails 
    @EmpID = 1, 
    @Name = 'Amit Kumar', 
    @Gender = 'Male', 
    @DOB = '1990-01-15', 
    @DeptId = 2;

--Calling Procedure (b)
EXEC GetEmployeeInfoByGenderAndDept 
    @Gender = 'Female', 
    @DeptId = 2;

--Calling Procedure (c)
EXEC GetEmployeeCountByGender 
    @Gender = 'Male';



--Assignment-3
--Create a user Defined function to calculate the TotalPrice based on productid and Quantity Products Table
CREATE FUNCTION CalculateTotalPrice (
    @ProductID INT,
    @Quantity INT
)
RETURNS DECIMAL(10, 2)
AS
BEGIN
    DECLARE @TotalPrice DECIMAL(10, 2);

    SELECT @TotalPrice = list_price * @Quantity 
    FROM production.products 
    WHERE product_id = @ProductID;

    RETURN @TotalPrice;
END;

SELECT dbo.CalculateTotalPrice(1, 5) as TotalPrice;



--Assignment-4
--Create a function that returns all orders for a specific customer, including details such as OrderID, OrderDate, and the total amount of each order.
CREATE FUNCTION GetCustomerOrders (
    @CustomerID INT
)
RETURNS TABLE
AS
RETURN 
(
    SELECT 
        sales.orders.order_id,
        sales.orders.order_date,
        SUM(sales.order_items.quantity * sales.order_items.list_price * (1 - sales.order_items.discount / 100)) AS TotalAmount
    FROM sales.orders 
    JOIN sales.order_items ON sales.orders.order_id = sales.order_items.order_id
    WHERE sales.orders.customer_id = @CustomerID
    GROUP BY sales.orders.order_id, sales.orders.order_date
);
--calling procedure(4)
SELECT * FROM GetCustomerOrders(12); 



--Assignment-5 
--Create a Multistatement table valued function that calculates the total sales for each product, considering quantity and price.
CREATE FUNCTION dbo.CalculateTotalSalesForProducts()
RETURNS @ProductSales TABLE
(
    ProductID INT,
    ProductName VARCHAR(255),
    TotalSales DECIMAL(18, 2)
)
AS
BEGIN
    -- Insert the calculated total sales into the return table
    INSERT INTO @ProductSales (ProductID, ProductName, TotalSales)
    SELECT 
        p.product_id AS ProductID,
        p.product_name AS ProductName,
        SUM(oi.quantity * oi.list_price) AS TotalSales
    FROM 
        production.products p
    JOIN 
        sales.order_items oi ON p.product_id = oi.product_id
    GROUP BY 
        p.product_id, p.product_name;

    RETURN;
END;
GO
--calling procedure(5)
SELECT * FROM dbo.CalculateTotalSalesForProducts();



----Assignment-6
--Create a  multi-statement table-valued function that lists all customers along with the total amount they have spent on orders.
CREATE FUNCTION sales.fn_CustomerTotalSpent()
RETURNS @CustomerTotalSpent TABLE
(
    customer_id INT,
    customer_name VARCHAR(255),
    total_spent DECIMAL(10, 2)
)
AS
BEGIN
    -- Insert into the table variable the total spent by each customer
    INSERT INTO @CustomerTotalSpent (customer_id, customer_name, total_spent)
    SELECT 
        c.customer_id,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        ISNULL(SUM(oi.quantity * oi.list_price * (1 - oi.discount / 100)), 0) AS total_spent
    FROM 
        sales.customers c
    LEFT JOIN 
        sales.orders o ON c.customer_id = o.customer_id
    LEFT JOIN 
        sales.order_items oi ON o.order_id = oi.order_id
    GROUP BY 
        c.customer_id, c.first_name, c.last_name;

    RETURN;
END;
GO
--calling procedure(6)
SELECT * FROM sales.fn_CustomerTotalSpent();
