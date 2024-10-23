--Question-7
--Create a trigger to updates the Stock (quantity) table whenever new order placed in orders tables--
CREATE TRIGGER trg_UpdateStockOnNewOrder
ON sales.order_items
AFTER INSERT
AS
BEGIN
    UPDATE production.stocks
    SET quantity = s.quantity - i.quantity
    FROM production.stocks s
    INNER JOIN inserted i ON s.product_id = i.product_id
    INNER JOIN sales.orders o ON o.order_id = i.order_id
    WHERE s.store_id = o.store_id;

    -- Raise an error if any stock goes below 0
    IF EXISTS (SELECT 1 FROM production.stocks WHERE quantity < 0)
    BEGIN
        RAISERROR('Stock level cannot be negative!', 16, 1);
    END
END;

INSERT INTO sales.orders (customer_id, order_status, order_date, required_date, shipped_date, store_id, staff_id)
VALUES (101, 3, '2024-10-15', '2024-10-25', '2024-10-12', 2, 10);

INSERT INTO sales.order_items (order_id, item_id, product_id, quantity, list_price, discount)
VALUES (SCOPE_IDENTITY(), 1, 101, 3, 2000.00, 0.05);



--Question-8
-- Create a trigger to that prevents deletion of a customer if they have existing orders.
CREATE TRIGGER trg_PreventCustomerDeletion
ON sales.customers
INSTEAD OF DELETE
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM deleted d
        INNER JOIN sales.orders o ON d.customer_id = o.customer_id
    )
    BEGIN
        RAISERROR('Cannot delete customer with existing orders.', 16, 1);
        RETURN;
    END

    DELETE FROM sales.customers
    WHERE customer_id IN (SELECT customer_id FROM deleted);
END;

-- Testing with a customer who has an order
DELETE FROM sales.customers WHERE customer_id = 101;

-- Testing with a customer without orders
DELETE FROM sales.customers WHERE customer_id = 58;

SELECT * FROM sales.orders;



--Question-9
--Create Employee,Employee_Audit  insert some test data
CREATE TABLE Employee2 (
    employee_id INT IDENTITY(1,1) PRIMARY KEY,
    first_name NVARCHAR(50),
    last_name NVARCHAR(50),
    department NVARCHAR(100),
    salary DECIMAL(10, 2)
);

CREATE TABLE Employee_Audit (
    audit_id INT IDENTITY(1,1) PRIMARY KEY,
    employee_id INT,
    first_name NVARCHAR(50),
    last_name NVARCHAR(50),
    department NVARCHAR(100),
    salary DECIMAL(10, 2),
    operation NVARCHAR(10),   -- INSERT, UPDATE, or DELETE
    change_date DATETIME DEFAULT GETDATE()
);

INSERT INTO Employee2 (first_name, last_name, department, salary)
VALUES
('Amit', 'Verma', 'IT', 70000),
('Priya', 'Sharma', 'HR', 62000),
('Rahul', 'Patel', 'Finance', 78000);

--b)Create a Trigger that logs changes to the Employee Table into an Employee_Audit Table
CREATE TRIGGER trg_EmployeeAudit
ON Employee2
FOR INSERT, UPDATE, DELETE
AS
BEGIN
    -- INSERT operation
    IF EXISTS (SELECT * FROM inserted)
    BEGIN
        INSERT INTO Employee_Audit (employee_id, first_name, last_name, department, salary, operation)
        SELECT i.employee_id, i.first_name, i.last_name, i.department, i.salary, 'INSERT'
        FROM inserted i;
    END

    -- DELETE operation
    IF EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO Employee_Audit (employee_id, first_name, last_name, department, salary, operation)
        SELECT d.employee_id, d.first_name, d.last_name, d.department, d.salary, 'DELETE'
        FROM deleted d;
    END

    -- UPDATE operation
    IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
    BEGIN
        INSERT INTO Employee_Audit (employee_id, first_name, last_name, department, salary, operation)
        SELECT i.employee_id, i.first_name, i.last_name, i.department, i.salary, 'UPDATE'
        FROM inserted i;
    END
END;

INSERT INTO Employee2 (first_name, last_name, department, salary)
VALUES ('Rohit', 'Mehra', 'Finance', 65000.00);

UPDATE Employee2
SET salary = 72000.00
WHERE employee_id = 2;

DELETE FROM Employee2
WHERE employee_id = 1;



--Question-10
/*create Room Table with below columns RoomID,RoomType,Availability create Bookins Table with below columns 
BookingID,RoomID,CustomerName,CheckInDate,CheckInDate Insert some test data with both the tables Ensure both 
the tables are having Entity relationship Write a transaction that books a room for a customer, ensuring the
room is marked as unavailable.*/
CREATE TABLE Room (
    RoomID INT IDENTITY(1,1) PRIMARY KEY,
    RoomType NVARCHAR(50),
    Availability BIT -- 1 for Available, 0 for Unavailable
);

CREATE TABLE Bookings (
    BookingID INT IDENTITY(1,1) PRIMARY KEY,
    RoomID INT, 
    CustomerName NVARCHAR(100),
    CheckInDate DATE,
    CheckOutDate DATE,
    FOREIGN KEY (RoomID) REFERENCES Room(RoomID)
);

INSERT INTO Room (RoomType, Availability)
VALUES 
('Luxury Suite', 1), 
('Deluxe', 1), 
('Presidential', 1);

INSERT INTO Bookings (RoomID, CustomerName, CheckInDate, CheckOutDate)
VALUES 
(1, 'Ravi Sharma', '2024-10-15', '2024-10-18'),
(2, 'Meena Rao', '2024-10-16', '2024-10-19');

-- Transaction to book a room
BEGIN TRANSACTION;
IF EXISTS (SELECT 1 FROM Room WHERE RoomID = 3 AND Availability = 1)
BEGIN
    INSERT INTO Bookings (RoomID, CustomerName, CheckInDate, CheckOutDate)
    VALUES (3, 'Anil Kumar', '2024-10-20', '2024-10-25');

    UPDATE Room
    SET Availability = 0
    WHERE RoomID = 3;

    COMMIT;
    PRINT 'Room booked successfully and marked as unavailable';
END
ELSE
BEGIN
    ROLLBACK;
    PRINT 'The room is not available for booking.';
END;
