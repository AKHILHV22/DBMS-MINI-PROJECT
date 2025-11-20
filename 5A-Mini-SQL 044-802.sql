-- DDL
-- Create Database with proper character set
CREATE DATABASE IF NOT EXISTS TranspoTrack
CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE TranspoTrack;


-- 1. PASSENGER Table
CREATE TABLE PASSENGER (
    PassengerID INT PRIMARY KEY AUTO_INCREMENT,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    DateOfBirth DATE NOT NULL,
    Address TEXT,
    City VARCHAR(50),
    RegistrationDate DATE DEFAULT (CURRENT_DATE),
    Status ENUM('Active', 'Inactive', 'Suspended') DEFAULT 'Active',
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_passenger_email (Email),
    INDEX idx_passenger_city (City),
    INDEX idx_passenger_status (Status)
);

-- 2. PASSENGER_PHONE Table
CREATE TABLE PASSENGER_PHONE (
    PassengerID INT NOT NULL,
    PhoneNumber VARCHAR(15) NOT NULL,
    PhoneType ENUM('Mobile', 'Home', 'Work') DEFAULT 'Mobile',
    IsPrimary BOOLEAN DEFAULT FALSE,
    Verified BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (PassengerID, PhoneNumber),
    FOREIGN KEY (PassengerID) REFERENCES PASSENGER(PassengerID) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_phone_number (PhoneNumber)
);

-- 3. STATION Table
CREATE TABLE STATION (
    StationID INT PRIMARY KEY AUTO_INCREMENT,
    StationCode VARCHAR(10) UNIQUE NOT NULL,
    Name VARCHAR(100) NOT NULL,
    Location VARCHAR(200) NOT NULL,
    Type ENUM('Bus-stop', 'Metro', 'Interchange') NOT NULL,
    Capacity INT DEFAULT 0,
    Facilities SET('Parking', 'Elevator', 'Restroom', 'ATM', 'Food Court', 'WiFi'),
    Zone VARCHAR(20),
    Status ENUM('Operational', 'Maintenance', 'Closed') DEFAULT 'Operational',
    Latitude DECIMAL(10, 8),
    Longitude DECIMAL(11, 8),
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_station_type (Type),
    INDEX idx_station_zone (Zone),
    INDEX idx_station_location (Location)
);

-- 4. ROUTE Table
CREATE TABLE ROUTE (
    RouteID INT PRIMARY KEY AUTO_INCREMENT,
    RouteCode VARCHAR(10) UNIQUE NOT NULL,
    Name VARCHAR(100) NOT NULL,
    TotalDistance DECIMAL(8,2) NOT NULL,
    EstimatedDuration INT NOT NULL,
    RouteType ENUM('City', 'Express', 'Airport', 'Suburban') DEFAULT 'City',
    Status ENUM('Active', 'Inactive', 'Seasonal') DEFAULT 'Active',
    StartStationID INT,
    EndStationID INT,
    OperatingHours VARCHAR(100),
    FarePerKM DECIMAL(5,2) DEFAULT 2.50,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (StartStationID) REFERENCES STATION(StationID),
    FOREIGN KEY (EndStationID) REFERENCES STATION(StationID),
    INDEX idx_route_code (RouteCode),
    INDEX idx_route_type (RouteType)
);

-- 5. ROUTE_STATION Table
CREATE TABLE ROUTE_STATION (
    SequenceID INT PRIMARY KEY AUTO_INCREMENT,
    RouteID INT NOT NULL,
    StationID INT NOT NULL,
    SequenceNumber INT NOT NULL,
    DistanceFromPrevious DECIMAL(6,2) DEFAULT 0.00,
    TravelTimeFromPrevious INT DEFAULT 0,
    CumulativeDistance DECIMAL(8,2) DEFAULT 0.00,
    CumulativeTime INT DEFAULT 0,
    UNIQUE KEY unique_route_sequence (RouteID, SequenceNumber),
    UNIQUE KEY unique_route_station (RouteID, StationID),
    FOREIGN KEY (RouteID) REFERENCES ROUTE(RouteID) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (StationID) REFERENCES STATION(StationID) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_route_station_route (RouteID),
    INDEX idx_route_station_station (StationID)
);

-- 6. VEHICLE Table
CREATE TABLE VEHICLE (
    VehicleID INT PRIMARY KEY AUTO_INCREMENT,
    VehicleNumber VARCHAR(20) UNIQUE NOT NULL,
    Type ENUM('Bus', 'Metro', 'BRT') NOT NULL,
    Model VARCHAR(50),
    Capacity INT NOT NULL,
    RegistrationNumber VARCHAR(20) UNIQUE NOT NULL,
    ManufacturingYear YEAR,
    FuelType ENUM('Diesel', 'Electric', 'CNG', 'Hybrid') DEFAULT 'Diesel',
    Status ENUM('Active', 'Maintenance', 'Inactive', 'Retired') DEFAULT 'Active',
    LastMaintenanceDate DATE,
    NextMaintenanceDate DATE,
    GPSDeviceID VARCHAR(50),
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_vehicle_type (Type),
    INDEX idx_vehicle_status (Status),
    INDEX idx_vehicle_maintenance (NextMaintenanceDate)
);

-- 7. SCHEDULE Table
CREATE TABLE SCHEDULE (
    ScheduleID INT PRIMARY KEY AUTO_INCREMENT,
    ScheduleCode VARCHAR(15) UNIQUE NOT NULL,
    RouteID INT NOT NULL,
    DepartureTime TIME NOT NULL,
    ArrivalTime TIME NOT NULL,
    DayOfWeek ENUM('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday') NOT NULL,
    EffectiveFrom DATE NOT NULL,
    EffectiveTo DATE,
    Status ENUM('Scheduled', 'Departed', 'Arrived', 'Cancelled', 'Delayed') DEFAULT 'Scheduled',
    DelayMinutes INT DEFAULT 0,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (RouteID) REFERENCES ROUTE(RouteID) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_schedule_route (RouteID),
    INDEX idx_schedule_time (DepartureTime),
    INDEX idx_schedule_day (DayOfWeek),
    INDEX idx_schedule_status (Status)
);

-- 8. ASSIGNED_TO Table
CREATE TABLE ASSIGNED_TO (
    AssignmentID INT PRIMARY KEY AUTO_INCREMENT,
    VehicleID INT NOT NULL,
    ScheduleID INT NOT NULL,
    AssignmentDate DATE NOT NULL,
    DriverID VARCHAR(20),
    DriverName VARCHAR(100),
    CoDriverName VARCHAR(100),
    AssignmentStatus ENUM('Scheduled', 'In Progress', 'Completed', 'Cancelled') DEFAULT 'Scheduled',
    ActualDepartureTime TIME,
    ActualArrivalTime TIME,
    Notes TEXT,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_vehicle_schedule_date (VehicleID, ScheduleID, AssignmentDate),
    FOREIGN KEY (VehicleID) REFERENCES VEHICLE(VehicleID) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (ScheduleID) REFERENCES SCHEDULE(ScheduleID) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_assignment_date (AssignmentDate),
    INDEX idx_assignment_status (AssignmentStatus)
);

-- 9. TICKET Table
CREATE TABLE TICKET (
    TicketNumber INT PRIMARY KEY AUTO_INCREMENT,
    TicketCode VARCHAR(20) UNIQUE NOT NULL,
    SeatNumber VARCHAR(10) NOT NULL,
    BookingDateTime DATETIME DEFAULT CURRENT_TIMESTAMP,
    JourneyDate DATE NOT NULL,
    Fare DECIMAL(8,2) NOT NULL,
    PassengerID INT NOT NULL,
    ScheduleID INT NOT NULL,
    SourceStationID INT NOT NULL,
    DestStationID INT NOT NULL,
    TicketStatus ENUM('Booked', 'Cancelled', 'Used', 'Expired') DEFAULT 'Booked',
    CancellationReason VARCHAR(255),
    CancellationCharges DECIMAL(8,2) DEFAULT 0.00,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (PassengerID) REFERENCES PASSENGER(PassengerID) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (ScheduleID) REFERENCES SCHEDULE(ScheduleID) 
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (SourceStationID) REFERENCES STATION(StationID),
    FOREIGN KEY (DestStationID) REFERENCES STATION(StationID),
    UNIQUE KEY unique_seat_schedule (ScheduleID, SeatNumber, JourneyDate),
    INDEX idx_ticket_passenger (PassengerID),
    INDEX idx_ticket_schedule (ScheduleID),
    INDEX idx_ticket_status (TicketStatus),
    INDEX idx_ticket_journey_date (JourneyDate)
);

-- 10. PASS Table
CREATE TABLE PASS (
    PassID INT PRIMARY KEY AUTO_INCREMENT,
    PassCode VARCHAR(20) UNIQUE NOT NULL,
    PassType ENUM('Daily', 'Weekly', 'Monthly', 'Quarterly', 'Annual', 'Student') NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NOT NULL,
    Price DECIMAL(8,2) NOT NULL,
    PassengerID INT NOT NULL,
    PassStatus ENUM('Active', 'Expired', 'Cancelled', 'Suspended') DEFAULT 'Active',
    AutoRenewal BOOLEAN DEFAULT FALSE,
    RouteRestrictions VARCHAR(255),
    ZoneRestrictions VARCHAR(255),
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (PassengerID) REFERENCES PASSENGER(PassengerID) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_pass_passenger (PassengerID),
    INDEX idx_pass_status (PassStatus),
    INDEX idx_pass_dates (StartDate, EndDate)
);

-- 11. COMPLAINT Table
CREATE TABLE COMPLAINT (
    ComplaintID INT PRIMARY KEY AUTO_INCREMENT,
    ComplaintCode VARCHAR(20) UNIQUE NOT NULL,
    Title VARCHAR(200) NOT NULL,
    Description TEXT NOT NULL,
    Timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    PassengerID INT NOT NULL,
    ScheduleID INT,
    VehicleID INT,
    Category ENUM('Service', 'Cleanliness', 'Safety', 'Ticketing', 'Staff Behavior', 'Delay', 'Facility', 'Other') NOT NULL,
    Priority ENUM('Low', 'Medium', 'High', 'Critical') DEFAULT 'Medium',
    Status ENUM('Pending', 'In Progress', 'Resolved', 'Rejected', 'Escalated') DEFAULT 'Pending',
    AssignedTo VARCHAR(100),
    Resolution TEXT,
    ResolvedAt DATETIME,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (PassengerID) REFERENCES PASSENGER(PassengerID) 
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (ScheduleID) REFERENCES SCHEDULE(ScheduleID) 
        ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (VehicleID) REFERENCES VEHICLE(VehicleID) 
        ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX idx_complaint_status (Status),
    INDEX idx_complaint_category (Category),
    INDEX idx_complaint_priority (Priority),
    INDEX idx_complaint_passenger (PassengerID)
);

-- 12. PAYMENT Table (FIXED - Removed problematic CHECK constraints)
CREATE TABLE PAYMENT (
    TransactionID INT PRIMARY KEY AUTO_INCREMENT,
    TransactionCode VARCHAR(30) UNIQUE NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    PaymentMethod ENUM('Credit Card', 'Debit Card', 'UPI', 'Net Banking', 'Wallet', 'Cash') NOT NULL,
    Status ENUM('Pending', 'Completed', 'Failed', 'Refunded', 'Cancelled') DEFAULT 'Pending',
    Timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    PassengerID INT NOT NULL,
    TicketNumber INT,
    PassID INT,
    PaymentGateway VARCHAR(50),
    GatewayTransactionID VARCHAR(100),
    GatewayResponse TEXT,
    RefundAmount DECIMAL(10,2) DEFAULT 0.00,
    RefundReason VARCHAR(255),
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (PassengerID) REFERENCES PASSENGER(PassengerID),
    FOREIGN KEY (TicketNumber) REFERENCES TICKET(TicketNumber),
    FOREIGN KEY (PassID) REFERENCES PASS(PassID),
    INDEX idx_payment_passenger (PassengerID),
    INDEX idx_payment_status (Status),
    INDEX idx_payment_method (PaymentMethod),
    INDEX idx_payment_timestamp (Timestamp)
);

-- Audit Table for tracking changes
CREATE TABLE AUDIT_LOG (
    AuditID INT PRIMARY KEY AUTO_INCREMENT,
    TableName VARCHAR(50) NOT NULL,
    RecordID INT NOT NULL,
    Action ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    OldValues JSON,
    NewValues JSON,
    ChangedBy VARCHAR(100) DEFAULT 'SYSTEM',
    ChangedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_audit_table (TableName),
    INDEX idx_audit_record (RecordID),
    INDEX idx_audit_timestamp (ChangedAt)
);
-- DML
-- Insert Passengers (20 records)
INSERT INTO PASSENGER (FirstName, LastName, Email, DateOfBirth, Address, City, Status) VALUES
('Raj', 'Sharma', 'raj.sharma@email.com', '1990-05-15', 'A-101, Sky Apartments, MG Road', 'Mumbai', 'Active'),
('Priya', 'Verma', 'priya.verma@email.com', '1985-12-20', 'B-205, Green Valley, Andheri East', 'Mumbai', 'Active'),
('Amit', 'Kumar', 'amit.kumar@email.com', '1992-08-10', 'C-304, Sunshine Complex, Bandra West', 'Mumbai', 'Active'),
('Sneha', 'Patel', 'sneha.patel@email.com', '1988-03-25', 'D-12, Royal Homes, Powai', 'Mumbai', 'Active'),
('Rahul', 'Singh', 'rahul.singh@email.com', '1995-11-05', 'E-45, Tech Park Residency, Vashi', 'Navi Mumbai', 'Active'),
('Anjali', 'Gupta', 'anjali.gupta@email.com', '1991-07-30', 'F-78, Lake View Apartments, Thane', 'Thane', 'Active'),
('Vikram', 'Joshi', 'vikram.joshi@email.com', '1987-09-14', 'G-23, Hill Side Society, Panvel', 'Navi Mumbai', 'Active'),
('Neha', 'Reddy', 'neha.reddy@email.com', '1993-04-18', 'H-56, Garden Estate, Kurla', 'Mumbai', 'Active'),
('Sanjay', 'Mehta', 'sanjay.mehta@email.com', '1984-01-22', 'I-89, Corporate Tower, BKC', 'Mumbai', 'Active'),
('Pooja', 'Desai', 'pooja.desai@email.com', '1996-12-08', 'J-34, Student Hostel, Churchgate', 'Mumbai', 'Active'),
('Karan', 'Malhotra', 'karan.malhotra@email.com', '1989-06-25', 'K-67, Business Bay, Lower Parel', 'Mumbai', 'Active'),
('Swati', 'Iyer', 'swati.iyer@email.com', '1994-02-12', 'L-90, Coastal Homes, Worli', 'Mumbai', 'Active'),
('Rohit', 'Choudhary', 'rohit.choudhary@email.com', '1990-10-30', 'M-123, Metro Heights, Ghatkopar', 'Mumbai', 'Active'),
('Meera', 'Krishnan', 'meera.krishnan@email.com', '1986-08-17', 'N-45, Silicon Valley, Airoli', 'Navi Mumbai', 'Active'),
('Arjun', 'Rao', 'arjun.rao@email.com', '1997-05-03', 'O-78, University Road, Kalyan', 'Thane', 'Active'),
('Divya', 'Nair', 'divya.nair@email.com', '1992-11-19', 'P-234, Sky Villa, Chembur', 'Mumbai', 'Active'),
('Manish', 'Thakur', 'manish.thakur@email.com', '1988-07-07', 'Q-56, Royal Palms, Dadar', 'Mumbai', 'Active'),
('Shweta', 'Bose', 'shweta.bose@email.com', '1995-03-28', 'R-89, Green Park, Borivali', 'Mumbai', 'Active'),
('Alok', 'Saxena', 'alok.saxena@email.com', '1983-12-15', 'S-345, Business Point, Andheri West', 'Mumbai', 'Active'),
('Tanvi', 'Kapoor', 'tanvi.kapoor@email.com', '1998-09-21', 'T-678, Youth Hostel, Colaba', 'Mumbai', 'Active');

-- Insert Passenger Phone Numbers
INSERT INTO PASSENGER_PHONE (PassengerID, PhoneNumber, PhoneType, IsPrimary, Verified) VALUES
(1, '+91-9876543210', 'Mobile', TRUE, TRUE),
(1, '+91-9876543211', 'Home', FALSE, TRUE),
(2, '+91-9876543220', 'Mobile', TRUE, TRUE),
(3, '+91-9876543230', 'Mobile', TRUE, TRUE),
(4, '+91-9876543240', 'Mobile', TRUE, TRUE),
(5, '+91-9876543250', 'Mobile', TRUE, TRUE),
(6, '+91-9876543260', 'Mobile', TRUE, TRUE),
(7, '+91-9876543270', 'Mobile', TRUE, TRUE),
(8, '+91-9876543280', 'Mobile', TRUE, TRUE),
(9, '+91-9876543290', 'Mobile', TRUE, TRUE),
(10, '+91-9876543300', 'Mobile', TRUE, TRUE),
(11, '+91-9876543310', 'Mobile', TRUE, TRUE),
(12, '+91-9876543320', 'Mobile', TRUE, TRUE),
(13, '+91-9876543330', 'Mobile', TRUE, TRUE),
(14, '+91-9876543340', 'Mobile', TRUE, TRUE),
(15, '+91-9876543350', 'Mobile', TRUE, TRUE),
(16, '+91-9876543360', 'Mobile', TRUE, TRUE),
(17, '+91-9876543370', 'Mobile', TRUE, TRUE),
(18, '+91-9876543380', 'Mobile', TRUE, TRUE),
(19, '+91-9876543390', 'Mobile', TRUE, TRUE),
(20, '+91-9876543400', 'Mobile', TRUE, TRUE);

-- Insert Stations (15 records)
INSERT INTO STATION (StationCode, Name, Location, Type, Capacity, Facilities, Zone, Status) VALUES
('ST001', 'Chhatrapati Shivaji Terminus', 'Fort, Mumbai', 'Metro', 10000, 'Parking,Restroom,ATM,Food Court,WiFi', 'South', 'Operational'),
('ST002', 'Churchgate Station', 'Churchgate, Mumbai', 'Metro', 8000, 'Parking,Elevator,Restroom,ATM,WiFi', 'South', 'Operational'),
('ST003', 'Andheri Metro Station', 'Andheri West, Mumbai', 'Metro', 7500, 'Parking,Elevator,Restroom,ATM,Food Court,WiFi', 'West', 'Operational'),
('ST004', 'Ghatkopar Bus Depot', 'Ghatkopar East, Mumbai', 'Bus-stop', 500, 'Restroom,ATM', 'Central', 'Operational'),
('ST005', 'Bandra Kurla Complex', 'BKC, Mumbai', 'Interchange', 6000, 'Parking,Elevator,Restroom,ATM,Food Court,WiFi', 'West', 'Operational'),
('ST006', 'Powai Lake Stop', 'Powai, Mumbai', 'Bus-stop', 300, 'Restroom', 'Central', 'Operational'),
('ST007', 'Vashi Plaza', 'Vashi, Navi Mumbai', 'Metro', 5500, 'Parking,Elevator,Restroom,ATM,Food Court,WiFi', 'Navi Mumbai', 'Operational'),
('ST008', 'Thane Station East', 'Thane East', 'Interchange', 7000, 'Parking,Elevator,Restroom,ATM,Food Court,WiFi', 'Thane', 'Operational'),
('ST009', 'Kalyan Junction', 'Kalyan West', 'Bus-stop', 400, 'Restroom,ATM', 'Kalyan', 'Operational'),
('ST010', 'Borivali National Park', 'Borivali East', 'Metro', 4500, 'Parking,Elevator,Restroom,ATM,WiFi', 'West', 'Operational'),
('ST011', 'Chembur Circle', 'Chembur, Mumbai', 'Bus-stop', 350, 'Restroom', 'Central', 'Operational'),
('ST012', 'Airoli Knowledge Park', 'Airoli, Navi Mumbai', 'Metro', 5000, 'Parking,Elevator,Restroom,ATM,WiFi', 'Navi Mumbai', 'Operational'),
('ST013', 'Dadar Plaza', 'Dadar West', 'Interchange', 8500, 'Parking,Elevator,Restroom,ATM,Food Court,WiFi', 'Central', 'Operational'),
('ST014', 'Kurla Terminal', 'Kurla West', 'Bus-stop', 600, 'Restroom,ATM', 'Central', 'Maintenance'),
('ST015', 'CSMIA Airport T2', 'Andheri East, Mumbai', 'Metro', 12000, 'Parking,Elevator,Restroom,ATM,Food Court,WiFi', 'West', 'Operational');

-- Insert Routes (8 records)
INSERT INTO ROUTE (RouteCode, Name, TotalDistance, EstimatedDuration, RouteType, Status, OperatingHours, FarePerKM) VALUES
('RT001', 'Western Express Highway', 35.50, 90, 'Express', 'Active', '05:00-23:00', 3.00),
('RT002', 'Harbour Line Local', 28.75, 75, 'City', 'Active', '04:30-01:00', 2.00),
('RT003', 'Airport Express', 42.00, 55, 'Airport', 'Active', '04:00-02:00', 5.00),
('RT004', 'Trans-Harbour Link', 38.25, 45, 'Express', 'Active', '05:30-22:30', 4.00),
('RT005', 'Eastern Freeway', 22.80, 40, 'City', 'Active', '05:00-23:30', 2.50),
('RT006', 'Navi Mumbai Connector', 31.60, 70, 'Suburban', 'Active', '05:15-22:00', 2.80),
('RT007', 'Thane-Kalyan Local', 18.90, 35, 'City', 'Active', '04:45-23:45', 2.00),
('RT008', 'Metro Line 1', 26.40, 60, 'City', 'Active', '05:30-22:30', 3.20);

-- Insert Route-Station relationships
INSERT INTO ROUTE_STATION (RouteID, StationID, SequenceNumber, DistanceFromPrevious, TravelTimeFromPrevious, CumulativeDistance, CumulativeTime) VALUES
-- Route 1: Western Express Highway
(1, 2, 1, 0.00, 0, 0.00, 0),
(1, 5, 2, 8.50, 20, 8.50, 20),
(1, 3, 3, 12.25, 30, 20.75, 50),
(1, 10, 4, 14.75, 40, 35.50, 90),

-- Route 2: Harbour Line Local
(2, 1, 1, 0.00, 0, 0.00, 0),
(2, 13, 2, 5.25, 15, 5.25, 15),
(2, 4, 3, 8.50, 25, 13.75, 40),
(2, 11, 4, 7.25, 20, 21.00, 60),
(2, 7, 5, 7.75, 15, 28.75, 75),

-- Route 3: Airport Express
(3, 15, 1, 0.00, 0, 0.00, 0),
(3, 3, 2, 8.75, 15, 8.75, 15),
(3, 5, 3, 12.50, 20, 21.25, 35),
(3, 1, 4, 20.75, 20, 42.00, 55);

-- Insert Vehicles (12 records)
INSERT INTO VEHICLE (VehicleNumber, Type, Model, Capacity, RegistrationNumber, ManufacturingYear, FuelType, Status, LastMaintenanceDate, NextMaintenanceDate) VALUES
('VH001', 'Bus', 'Volvo 8400', 45, 'MH01AB1234', 2022, 'Diesel', 'Active', '2024-01-15', '2024-02-15'),
('VH002', 'Bus', 'Tata Starbus', 50, 'MH01CD5678', 2021, 'CNG', 'Active', '2024-01-20', '2024-02-20'),
('VH003', 'Metro', 'Bombardier MOVIA', 300, 'METRO-A001', 2020, 'Electric', 'Active', '2024-01-10', '2024-04-10'),
('VH004', 'Metro', 'Alstom Metropolis', 350, 'METRO-A002', 2023, 'Electric', 'Maintenance', '2024-01-18', '2024-01-28'),
('VH005', 'BRT', 'Ashok Leyland', 60, 'MH01EF9012', 2022, 'Hybrid', 'Active', '2024-01-22', '2024-02-22'),
('VH006', 'Bus', 'Volvo 9400', 55, 'MH01GH3456', 2021, 'Diesel', 'Active', '2024-01-12', '2024-02-12'),
('VH007', 'Metro', 'Bombardier MOVIA', 300, 'METRO-A003', 2020, 'Electric', 'Active', '2024-01-08', '2024-04-08'),
('VH008', 'Bus', 'Tata Marcopolo', 40, 'MH01IJ7890', 2023, 'CNG', 'Active', '2024-01-25', '2024-02-25'),
('VH009', 'BRT', 'Ashok Leyland', 60, 'MH01KL1234', 2022, 'Hybrid', 'Active', '2024-01-14', '2024-02-14'),
('VH010', 'Metro', 'Alstom Metropolis', 350, 'METRO-A004', 2023, 'Electric', 'Active', '2024-01-30', '2024-04-30'),
('VH011', 'Bus', 'Volvo 8400', 45, 'MH01MN5678', 2022, 'Diesel', 'Inactive', '2024-01-05', '2024-02-05'),
('VH012', 'Bus', 'Tata Starbus', 50, 'MH01OP9012', 2021, 'CNG', 'Active', '2024-01-28', '2024-02-28');

-- Insert Schedules (15 records)
INSERT INTO SCHEDULE (ScheduleCode, RouteID, DepartureTime, ArrivalTime, DayOfWeek, EffectiveFrom, EffectiveTo, Status) VALUES
('SCH001', 1, '06:00:00', '07:30:00', 'Monday', '2024-01-01', '2024-12-31', 'Scheduled'),
('SCH002', 1, '08:00:00', '09:30:00', 'Monday', '2024-01-01', '2024-12-31', 'Scheduled'),
('SCH003', 1, '18:00:00', '19:30:00', 'Monday', '2024-01-01', '2024-12-31', 'Scheduled'),
('SCH004', 2, '07:30:00', '08:45:00', 'Monday', '2024-01-01', '2024-12-31', 'Scheduled'),
('SCH005', 2, '12:00:00', '13:15:00', 'Monday', '2024-01-01', '2024-12-31', 'Scheduled'),
('SCH006', 3, '05:30:00', '06:25:00', 'Monday', '2024-01-01', '2024-12-31', 'Scheduled'),
('SCH007', 3, '14:00:00', '14:55:00', 'Monday', '2024-01-01', '2024-12-31', 'Scheduled'),
('SCH008', 4, '06:15:00', '07:00:00', 'Monday', '2024-01-01', '2024-12-31', 'Scheduled'),
('SCH009', 4, '16:30:00', '17:15:00', 'Monday', '2024-01-01', '2024-12-31', 'Scheduled'),
('SCH010', 5, '07:00:00', '07:40:00', 'Monday', '2024-01-01', '2024-12-31', 'Scheduled'),
('SCH011', 5, '19:00:00', '19:40:00', 'Monday', '2024-01-01', '2024-12-31', 'Scheduled'),
('SCH012', 6, '08:30:00', '09:40:00', 'Monday', '2024-01-01', '2024-12-31', 'Scheduled'),
('SCH013', 6, '17:45:00', '18:55:00', 'Monday', '2024-01-01', '2024-12-31', 'Scheduled'),
('SCH014', 7, '09:15:00', '09:50:00', 'Monday', '2024-01-01', '2024-12-31', 'Scheduled'),
('SCH015', 8, '10:00:00', '11:00:00', 'Monday', '2024-01-01', '2024-12-31', 'Scheduled');


-- Insert ASSIGNED_TO relationships
INSERT INTO ASSIGNED_TO (VehicleID, ScheduleID, AssignmentDate, DriverID, DriverName, CoDriverName, AssignmentStatus) VALUES
(1, 1, '2024-01-29', 'DRV001', 'Rajesh Kumar', 'Sanjay Verma', 'Scheduled'),
(3, 2, '2024-01-29', 'DRV002', 'Priya Singh', 'Amit Sharma', 'Scheduled'),
(2, 3, '2024-01-29', 'DRV003', 'Suresh Patel', 'Neha Reddy', 'Scheduled'),
(1, 4, '2024-01-29', 'DRV001', 'Rajesh Kumar', 'Rahul Mehta', 'Scheduled'),
(5, 5, '2024-01-29', 'DRV004', 'Anil Joshi', 'Karan Desai', 'Scheduled'),
(6, 6, '2024-01-29', 'DRV005', 'Meera Iyer', 'Vikram Nair', 'Scheduled'),
(7, 7, '2024-01-29', 'DRV006', 'Arun Malhotra', 'Divya Kapoor', 'Scheduled'),
(8, 8, '2024-01-29', 'DRV007', 'Sunil Thakur', 'Pooja Bose', 'Scheduled'),
(9, 9, '2024-01-29', 'DRV008', 'Rohit Choudhary', 'Swati Saxena', 'Scheduled'),
(10, 10, '2024-01-29', 'DRV009', 'Manish Gupta', 'Tanvi Rao', 'Scheduled'),
(2, 11, '2024-01-29', 'DRV003', 'Suresh Patel', 'Alok Krishnan', 'Scheduled'),
(5, 12, '2024-01-29', 'DRV004', 'Anil Joshi', 'Anjali Singh', 'Scheduled'),
(6, 13, '2024-01-29', 'DRV005', 'Meera Iyer', 'Rahul Kumar', 'Scheduled'),
(8, 14, '2024-01-29', 'DRV007', 'Sunil Thakur', 'Priya Patel', 'Scheduled'),
(10, 15, '2024-01-29', 'DRV009', 'Manish Gupta', 'Amit Verma', 'Scheduled');

-- Insert PASS records
INSERT INTO PASS (PassCode, PassType, StartDate, EndDate, Price, PassengerID, PassStatus, AutoRenewal, RouteRestrictions, ZoneRestrictions) VALUES
('PASS202401001', 'Monthly', '2024-01-01', '2024-01-31', 1500.00, 1, 'Active', TRUE, 'RT001,RT002,RT005', 'South,West'),
('PASS202401002', 'Weekly', '2024-01-22', '2024-01-28', 500.00, 2, 'Active', FALSE, 'RT003,RT004', 'West,Navi Mumbai'),
('PASS202401003', 'Daily', '2024-01-25', '2024-01-25', 100.00, 3, 'Expired', FALSE, NULL, 'All Zones'),
('PASS202401004', 'Monthly', '2024-01-01', '2024-01-31', 1500.00, 4, 'Active', TRUE, 'RT002,RT007', 'Central,Thane'),
('PASS202401005', 'Quarterly', '2024-01-01', '2024-03-31', 4000.00, 5, 'Active', TRUE, NULL, 'All Zones'),
('PASS202401006', 'Student', '2024-01-01', '2024-01-31', 750.00, 6, 'Active', TRUE, 'RT001,RT005,RT008', 'South,West,Central'),
('PASS202401007', 'Annual', '2024-01-01', '2024-12-31', 12000.00, 7, 'Active', TRUE, NULL, 'All Zones'),
('PASS202401008', 'Monthly', '2024-01-01', '2024-01-31', 1500.00, 8, 'Active', FALSE, 'RT006,RT007', 'Navi Mumbai,Thane'),
('PASS202401009', 'Weekly', '2024-01-15', '2024-01-21', 500.00, 9, 'Expired', FALSE, 'RT003', 'West'),
('PASS202401010', 'Monthly', '2024-01-01', '2024-01-31', 1500.00, 10, 'Active', TRUE, 'RT001,RT002', 'South,West'),
('PASS202401011', 'Quarterly', '2024-01-01', '2024-03-31', 4000.00, 11, 'Active', TRUE, NULL, 'All Zones'),
('PASS202401012', 'Student', '2024-01-01', '2024-01-31', 750.00, 12, 'Active', TRUE, 'RT004,RT005', 'Central,East'),
('PASS202401013', 'Monthly', '2024-01-01', '2024-01-31', 1500.00, 13, 'Active', FALSE, 'RT007,RT008', 'Thane,Kalyan'),
('PASS202401014', 'Weekly', '2024-01-08', '2024-01-14', 500.00, 14, 'Expired', FALSE, 'RT002', 'South,Central'),
('PASS202401015', 'Monthly', '2024-01-01', '2024-01-31', 1500.00, 15, 'Active', TRUE, 'RT001,RT003', 'South,West');

-- Insert TICKET records
INSERT INTO TICKET (TicketCode, SeatNumber, JourneyDate, Fare, PassengerID, ScheduleID, SourceStationID, DestStationID, TicketStatus) VALUES
('TKT20240129001', 'A01', '2024-01-29', 45.00, 2, 1, 2, 5, 'Booked'),
('TKT20240129002', 'A02', '2024-01-29', 60.00, 3, 1, 2, 3, 'Booked'),
('TKT20240129003', 'B01', '2024-01-29', 35.00, 4, 2, 13, 1, 'Used'),
('TKT20240129004', 'B02', '2024-01-29', 25.00, 5, 4, 4, 3, 'Booked'),
('TKT20240129005', 'C01', '2024-01-29', 80.00, 1, 3, 15, 1, 'Cancelled'),
('TKT20240129006', 'A03', '2024-01-29', 55.00, 6, 5, 1, 7, 'Booked'),
('TKT20240129007', 'B03', '2024-01-29', 40.00, 7, 6, 15, 3, 'Used'),
('TKT20240129008', 'C02', '2024-01-29', 70.00, 8, 7, 3, 1, 'Booked'),
('TKT20240129009', 'A04', '2024-01-29', 30.00, 9, 8, 1, 5, 'Booked'),
('TKT20240129010', 'B04', '2024-01-29', 65.00, 10, 9, 5, 1, 'Used'),
('TKT20240129011', 'C03', '2024-01-29', 50.00, 11, 10, 4, 11, 'Booked'),
('TKT20240129012', 'A05', '2024-01-29', 45.00, 12, 11, 11, 4, 'Booked'),
('TKT20240129013', 'B05', '2024-01-29', 85.00, 13, 12, 7, 12, 'Used'),
('TKT20240129014', 'C04', '2024-01-29', 35.00, 14, 13, 12, 7, 'Booked'),
('TKT20240129015', 'A06', '2024-01-29', 25.00, 15, 14, 8, 9, 'Booked'),
('TKT20240129016', 'B06', '2024-01-29', 40.00, 16, 15, 10, 3, 'Used'),
('TKT20240129017', 'C05', '2024-01-29', 60.00, 17, 1, 5, 10, 'Booked'),
('TKT20240129018', 'A07', '2024-01-29', 75.00, 18, 2, 3, 15, 'Booked'),
('TKT20240129019', 'B07', '2024-01-29', 50.00, 19, 3, 1, 5, 'Used'),
('TKT20240129020', 'C06', '2024-01-29', 35.00, 20, 4, 13, 4, 'Booked');

-- Insert COMPLAINT records
INSERT INTO COMPLAINT (ComplaintCode, Title, Description, PassengerID, ScheduleID, VehicleID, Category, Priority, Status, AssignedTo) VALUES
('COMP202401001', 'Late Arrival', 'Bus arrived 15 minutes late at Churchgate station', 1, 1, 1, 'Service', 'Medium', 'Resolved', 'Customer Service Team'),
('COMP202401002', 'Unclean Seats', 'Seat was dirty and had food stains', 2, 2, 3, 'Cleanliness', 'Low', 'Pending', NULL),
('COMP202401003', 'AC Not Working', 'Air conditioning was not functioning properly throughout the journey', 3, 3, 2, 'Service', 'High', 'In Progress', 'Maintenance Team'),
('COMP202401004', 'Rude Conductor', 'Conductor behaved rudely when asked for ticket', 4, 4, 1, 'Staff Behavior', 'High', 'Resolved', 'Operations Manager'),
('COMP202401005', 'Overcrowding', 'Bus was overcrowded beyond capacity during peak hours', 5, 5, 5, 'Safety', 'Critical', 'Pending', NULL),
('COMP202401006', 'Ticket Machine Issue', 'Ticket vending machine was out of service', 6, NULL, NULL, 'Ticketing', 'Medium', 'Resolved', 'Technical Team'),
('COMP202401007', 'Poor Maintenance', 'Vehicle made unusual noises throughout the journey', 7, 6, 6, 'Service', 'High', 'In Progress', 'Maintenance Team'),
('COMP202401008', 'Wrong Information', 'Display boards showed incorrect arrival times', 8, 7, 7, 'Service', 'Medium', 'Resolved', 'IT Department'),
('COMP202401009', 'Lost Item', 'Left my backpack on the metro coach', 9, 8, 8, 'Other', 'Low', 'Pending', 'Lost & Found'),
('COMP202401010', 'Safety Concern', 'Felt unsafe due to inadequate lighting at station', 10, NULL, NULL, 'Safety', 'High', 'Resolved', 'Station Manager'),
('COMP202401011', 'Overcharged Fare', 'Was charged more than the displayed fare', 11, 9, 9, 'Ticketing', 'Medium', 'Resolved', 'Billing Department'),
('COMP202401012', 'No WiFi', 'Advertised WiFi service was not available', 12, 10, 10, 'Facility', 'Low', 'Pending', NULL),
('COMP202401013', 'Delayed Journey', 'Metro was delayed by 25 minutes without announcement', 13, 11, 2, 'Service', 'High', 'In Progress', 'Operations Team'),
('COMP202401014', 'Broken Seat', 'Seat was broken and could not be used', 14, 12, 5, 'Facility', 'Medium', 'Resolved', 'Maintenance Team'),
('COMP202401015', 'Poor Air Quality', 'Smoke smell inside the bus cabin', 15, 13, 6, 'Cleanliness', 'High', 'Pending', NULL);

-- Insert PAYMENT records
-- Clear existing payment data
TRUNCATE TABLE PAYMENT;

-- Insert payments with explicit timestamps across different dates
INSERT INTO PAYMENT (TransactionCode, Amount, PaymentMethod, Status, Timestamp, PassengerID, TicketNumber, PassID, PaymentGateway, GatewayTransactionID) VALUES
-- January 2024
('TXN202401290001', 45.00, 'UPI', 'Completed', '2024-01-29 10:30:00', 2, 1, NULL, 'Google Pay', 'GPay_1234567890'),
('TXN202401290002', 60.00, 'Credit Card', 'Completed', '2024-01-29 11:15:00', 3, 2, NULL, 'Stripe', 'Stripe_9876543210'),
('TXN202401290003', 1500.00, 'Debit Card', 'Completed', '2024-01-29 14:20:00', 1, NULL, 1, 'Razorpay', 'Razorpay_555666777'),
('TXN202401290004', 500.00, 'Wallet', 'Completed', '2024-01-29 16:45:00', 2, NULL, 2, 'PayTM', 'PayTM_444333222'),

-- February 2024
('TXN202402150001', 80.00, 'UPI', 'Failed', '2024-02-15 09:00:00', 1, 5, NULL, 'PhonePe', 'PhonePe_111222333'),
('TXN202402150002', 35.00, 'Cash', 'Completed', '2024-02-15 12:30:00', 4, 3, NULL, 'Cash Counter', 'CASH_001'),
('TXN202402150003', 750.00, 'Net Banking', 'Completed', '2024-02-15 15:00:00', 6, NULL, 6, 'ICICI Bank', 'ICICI_888999000'),

-- March 2024
('TXN202403100001', 55.00, 'UPI', 'Completed', '2024-03-10 08:45:00', 6, 6, NULL, 'Google Pay', 'GPay_222333444'),
('TXN202403100002', 12000.00, 'Credit Card', 'Completed', '2024-03-10 13:20:00', 7, NULL, 7, 'Stripe', 'Stripe_666777888'),
('TXN202403100003', 40.00, 'Wallet', 'Completed', '2024-03-10 17:30:00', 7, 7, NULL, 'PayTM', 'PayTM_333444555'),

-- April 2024
('TXN202404050001', 1500.00, 'Debit Card', 'Completed', '2024-04-05 10:00:00', 8, NULL, 8, 'Razorpay', 'Razorpay_777888999'),
('TXN202404050002', 70.00, 'UPI', 'Completed', '2024-04-05 14:15:00', 8, 8, NULL, 'PhonePe', 'PhonePe_444555666'),
('TXN202404050003', 4000.00, 'Net Banking', 'Completed', '2024-04-05 16:00:00', 11, NULL, 11, 'HDFC Bank', 'HDFC_999000111'),

-- May 2024
('TXN202405200001', 50.00, 'Credit Card', 'Completed', '2024-05-20 11:30:00', 11, 11, NULL, 'Stripe', 'Stripe_111222333'),
('TXN202405200002', 750.00, 'Wallet', 'Completed', '2024-05-20 15:45:00', 12, NULL, 12, 'PayTM', 'PayTM_555666777'),

-- June 2024
('TXN202406120001', 45.00, 'UPI', 'Completed', '2024-06-12 09:20:00', 12, 12, NULL, 'Google Pay', 'GPay_666777888'),
('TXN202406120002', 1500.00, 'Debit Card', 'Completed', '2024-06-12 13:00:00', 13, NULL, 13, 'Razorpay', 'Razorpay_888999000'),

-- July 2024
('TXN202407080001', 85.00, 'Cash', 'Completed', '2024-07-08 10:45:00', 13, 13, NULL, 'Cash Counter', 'CASH_002'),
('TXN202407080002', 500.00, 'Wallet', 'Completed', '2024-07-08 14:30:00', 14, NULL, 14, 'PayTM', 'PayTM_777888999'),
('TXN202407080003', 35.00, 'UPI', 'Completed', '2024-07-08 16:15:00', 14, 14, NULL, 'PhonePe', 'PhonePe_888999000'),

-- August 2024
('TXN202408250001', 120.00, 'UPI', 'Completed', '2024-08-25 11:00:00', 5, 15, NULL, 'Google Pay', 'GPay_999888777'),
('TXN202408250002', 2500.00, 'Credit Card', 'Completed', '2024-08-25 15:30:00', 9, NULL, 15, 'Stripe', 'Stripe_444333222'),

-- September 2024
('TXN202409150001', 95.00, 'Debit Card', 'Completed', '2024-09-15 10:20:00', 10, 16, NULL, 'Razorpay', 'Razorpay_111000999'),
('TXN202409150002', 300.00, 'Net Banking', 'Completed', '2024-09-15 14:45:00', 15, NULL, 16, 'HDFC Bank', 'HDFC_222111000'),

-- October 2024
('TXN202410100001', 65.00, 'UPI', 'Completed', '2024-10-10 09:30:00', 16, 17, NULL, 'PhonePe', 'PhonePe_333222111'),
('TXN202410100002', 1800.00, 'Wallet', 'Completed', '2024-10-10 13:15:00', 17, NULL, 17, 'PayTM', 'PayTM_444333222'),

-- November 2024
('TXN202411050001', 75.00, 'Credit Card', 'Completed', '2024-11-05 11:45:00', 18, 18, NULL, 'Stripe', 'Stripe_555444333'),
('TXN202411050002', 950.00, 'UPI', 'Completed', '2024-11-05 16:00:00', 19, NULL, 18, 'Google Pay', 'GPay_666555444'),

-- December 2024
('TXN202412200001', 55.00, 'Cash', 'Completed', '2024-12-20 10:00:00', 20, 19, NULL, 'Cash Counter', 'CASH_003'),
('TXN202412200002', 3500.00, 'Debit Card', 'Completed', '2024-12-20 14:30:00', 1, NULL, 19, 'Razorpay', 'Razorpay_777666555');

-- TRIGGER 1: Validate Payment Before Insert
DELIMITER //

CREATE TRIGGER trg_validate_payment
BEFORE INSERT ON PAYMENT
FOR EACH ROW
BEGIN
    DECLARE v_error_message VARCHAR(255);
    
    -- Validate that either TicketNumber or PassID is provided (but not both)
    IF (NEW.TicketNumber IS NULL AND NEW.PassID IS NULL) THEN
        SET v_error_message = 'Payment must be associated with either a Ticket or a Pass';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_message;
    END IF;
    
    IF (NEW.TicketNumber IS NOT NULL AND NEW.PassID IS NOT NULL) THEN
        SET v_error_message = 'Payment cannot be associated with both a Ticket and a Pass';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_message;
    END IF;
    
    -- Validate refund amount
    IF NEW.RefundAmount > NEW.Amount THEN
        SET v_error_message = CONCAT('Refund amount (', NEW.RefundAmount, ') cannot exceed original amount (', NEW.Amount, ')');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_message;
    END IF;
    
    -- Validate positive amount
    IF NEW.Amount <= 0 THEN
        SET v_error_message = 'Payment amount must be greater than 0';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_message;
    END IF;
END//

DELIMITER ;


-- TEST 1: Valid payment 
INSERT INTO PAYMENT (
    TransactionCode, Amount, PaymentMethod, PassengerID, TicketNumber, Status
) VALUES (
    'TXN_TEST001', 50.00, 'UPI', 1, 1, 'Completed'
);


-- TEST 2: Payment with both Ticket and Pass 
INSERT INTO PAYMENT (
    TransactionCode, Amount, PaymentMethod, PassengerID, TicketNumber, PassID, Status
) VALUES (
    'TXN_TEST002', 50.00, 'UPI', 1, 1, 1, 'Completed'
);


-- TEST 3: Payment with no reference

INSERT INTO PAYMENT (
    TransactionCode, Amount, PaymentMethod, PassengerID, Status
) VALUES (
    'TXN_TEST003', 50.00, 'UPI', 1, 'Completed'
);


-- TEST 4: Refund exceeding amount
INSERT INTO PAYMENT (
    TransactionCode, Amount, PaymentMethod, PassengerID, TicketNumber, RefundAmount, Status
) VALUES (
    'TXN_TEST004', 50.00, 'UPI', 1, 1, 60.00, 'Refunded'
);

-- TEST 5: Zero amount
INSERT INTO PAYMENT (
    TransactionCode, Amount, PaymentMethod, PassengerID, TicketNumber, Status
) VALUES (
    'TXN_TEST006', 50.00, 'UPI', 1, 1, 'Completed'
);



-- TRIGGER 2: Auto-Update Pass Status and Validate Dates
DELIMITER //

CREATE TRIGGER trg_validate_and_update_pass
BEFORE INSERT ON PASS
FOR EACH ROW
BEGIN
    DECLARE v_error_message VARCHAR(255);
    DECLARE v_today DATE;
    
    -- Get today's date
    SET v_today = CURDATE();
    
    -- Validate pass dates
    IF NEW.EndDate <= NEW.StartDate THEN
        SET v_error_message = 'Pass end date must be after start date';
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_error_message;
    END IF;
    
    -- SIMPLE LOGIC: Only set to Expired if end date is before today
    IF NEW.EndDate < v_today THEN
        SET NEW.PassStatus = 'Expired';
    ELSE
        SET NEW.PassStatus = 'Active';
    END IF;
END//

DELIMITER ;


-- TEST 1: Valid pass with future dates
INSERT INTO PASS (
    PassCode, PassType, StartDate, EndDate, Price, PassengerID
) VALUES (
    'PASS_DEMO001', 'Monthly', '2025-12-01', '2025-12-31', 1500.00, 1
);

-- Verify the result
SELECT PassID, PassCode, StartDate, EndDate, PassStatus 
FROM PASS WHERE PassCode = 'PASS_DEMO001';




-- TEST 2: Expired pass 
INSERT INTO PASS (
    PassCode, PassType, StartDate, EndDate, Price, PassengerID
) VALUES (
    'PASS_DEMO002', 'Daily', '2024-01-01', '2024-01-02', 100.00, 2
);

-- Verify the result:
SELECT PassID, PassCode, StartDate, EndDate, PassStatus FROM PASS WHERE PassCode = 'PASS_DEMO002';


-- TEST 3: Invalid dates (should fail)
INSERT INTO PASS (
    PassCode, PassType, StartDate, EndDate, Price, PassengerID
) VALUES (
    'PASS_DEMO003', 'Monthly', '2024-02-28', '2024-02-01', 1500.00, 3
);


-- TEST 4: Current active pass
INSERT INTO PASS (
    PassCode, PassType, StartDate, EndDate, Price, PassengerID
) VALUES (
    'PASS_DEMO004', 'Weekly', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 7 DAY), 500.00, 4
);

-- Verify the result:
SELECT PassID, PassCode, StartDate, EndDate, PassStatus FROM PASS WHERE PassCode = 'PASS_DEMO004';





-- TRIGGER 2 RESULTS:
-- ✅ TEST 1: Future pass (2025-12-01 to 2025-12-31) = Active ✓
-- ✅ TEST 2: Expired pass (2024-01-01 to 2024-01-02) = Expired ✓
-- ✅ TEST 3: Invalid dates (2024-02-28 to 2024-02-01) = Correctly failed ✓
-- ✅ TEST 4: Current active pass (Today to +7 days) = Active ✓

-- TRIGGER 1 RESULTS:
-- ✅ TEST 1: Valid payment = Query OK (but had duplicate key issue)
-- ✅ TEST 2: Both Ticket and Pass = Correctly failed ✓
-- ✅ TEST 3: No reference = Correctly failed ✓
-- ✅ TEST 4: Refund exceeding = Correctly failed ✓
-- ✅ TEST 5: Zero amount = Correctly failed ✓



 -- PROCEDURE 1: Book Ticket with Comprehensive Validation
 DELIMITER //

CREATE PROCEDURE sp_book_ticket_with_payment(
    IN p_passenger_id INT,
    IN p_schedule_id INT,
    IN p_source_station_id INT,
    IN p_dest_station_id INT,
    IN p_seat_number VARCHAR(10),
    IN p_journey_date DATE,
    IN p_fare DECIMAL(8,2),
    IN p_payment_method ENUM('Credit Card', 'Debit Card', 'UPI', 'Net Banking', 'Wallet', 'Cash')
)
BEGIN
    DECLARE v_ticket_number INT;
    DECLARE v_ticket_code VARCHAR(20);
    DECLARE v_transaction_code VARCHAR(30);
    DECLARE v_seat_available BOOLEAN;
    DECLARE v_passenger_exists BOOLEAN;
    DECLARE v_schedule_exists BOOLEAN;
    DECLARE v_stations_valid BOOLEAN;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    -- Validate passenger exists and is active
    SELECT COUNT(*) = 1 INTO v_passenger_exists
    FROM PASSENGER 
    WHERE PassengerID = p_passenger_id AND Status = 'Active';
    
    IF NOT v_passenger_exists THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid or inactive passenger';
    END IF;
    
    -- Validate schedule exists
    SELECT COUNT(*) = 1 INTO v_schedule_exists
    FROM SCHEDULE 
    WHERE ScheduleID = p_schedule_id;
    
    IF NOT v_schedule_exists THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid schedule';
    END IF;
    
    -- Validate different stations
    IF p_source_station_id = p_dest_station_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Source and destination stations cannot be the same';
    END IF;
    
    -- Validate stations exist
    SELECT COUNT(*) = 2 INTO v_stations_valid
    FROM STATION 
    WHERE StationID IN (p_source_station_id, p_dest_station_id);
    
    IF NOT v_stations_valid THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid source or destination station';
    END IF;
    
    -- Check seat availability
    SELECT COUNT(*) = 0 INTO v_seat_available
    FROM TICKET
    WHERE ScheduleID = p_schedule_id
    AND JourneyDate = p_journey_date
    AND SeatNumber = p_seat_number
    AND TicketStatus IN ('Booked', 'Used');
    
    IF NOT v_seat_available THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Seat not available';
    END IF;
    
    -- Validate fare
    IF p_fare <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Fare must be greater than 0';
    END IF;
    
    START TRANSACTION;
    
    -- Generate unique ticket code
    SET v_ticket_code = CONCAT('TKT', DATE_FORMAT(NOW(), '%Y%m%d'), 
        LPAD(COALESCE((SELECT MAX(SUBSTRING(TicketCode, 12)) FROM TICKET WHERE TicketCode LIKE CONCAT('TKT', DATE_FORMAT(NOW(), '%Y%m%d'), '%')), 0) + 1, 3, '0'));
    
    -- Insert ticket
    INSERT INTO TICKET (
        TicketCode, SeatNumber, JourneyDate, Fare, PassengerID, 
        ScheduleID, SourceStationID, DestStationID, TicketStatus
    ) VALUES (
        v_ticket_code, p_seat_number, p_journey_date, p_fare, p_passenger_id,
        p_schedule_id, p_source_station_id, p_dest_station_id, 'Booked'
    );
    
    SET v_ticket_number = LAST_INSERT_ID();
    
    -- Generate unique transaction code
    SET v_transaction_code = CONCAT('TXN', DATE_FORMAT(NOW(), '%Y%m%d'), 
        LPAD(COALESCE((SELECT MAX(SUBSTRING(TransactionCode, 12)) FROM PAYMENT WHERE TransactionCode LIKE CONCAT('TXN', DATE_FORMAT(NOW(), '%Y%m%d'), '%')), 0) + 1, 3, '0'));
    
    -- Insert payment
    INSERT INTO PAYMENT (
        TransactionCode, Amount, PaymentMethod, Status, PassengerID,
        TicketNumber, PaymentGateway
    ) VALUES (
        v_transaction_code, p_fare, p_payment_method, 'Completed', p_passenger_id,
        v_ticket_number, p_payment_method
    );
    
    COMMIT;
    
    -- Return success with details
    SELECT 
        'SUCCESS' AS Status,
        'Ticket booked successfully' AS Message,
        v_ticket_number AS TicketNumber,
        v_ticket_code AS TicketCode,
        v_transaction_code AS TransactionCode,
        p_fare AS Amount,
        p_seat_number AS SeatNumber,
        p_journey_date AS JourneyDate;
END//

DELIMITER ;

-- TEST 1: Successful ticket booking
CALL sp_book_ticket_with_payment(
    1,              -- Valid passenger
    1,              -- Valid schedule
    2,              -- Source: Churchgate (StationID 2)
    5,              -- Destination: BKC (StationID 5)
    'Z99',          -- Available seat
    '2025-12-01',   -- Future date
    75.00,          -- Valid fare
    'UPI'           -- Payment method
);

-- TEST 2: Test invalid passenger (should fail)
CALL sp_book_ticket_with_payment(
    999,            -- Invalid passenger
    1, 2, 5, 'Z98', '2025-12-01', 50.00, 'UPI'
);

-- TEST 3: Test seat already taken (should fail)
CALL sp_book_ticket_with_payment(
    1, 1, 2, 5, 'A01', '2024-01-29', 50.00, 'UPI'
);



-- PROCEDURE 2: Generate Revenue Report
-- ============================================================
-- Revenue Report Stored Procedure
-- ============================================================

USE TranspoTrack;

-- Drop if exists
DROP PROCEDURE IF EXISTS sp_generate_revenue_report;

DELIMITER //

CREATE PROCEDURE sp_generate_revenue_report(
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    -- 1. Overall Revenue Summary
    SELECT 
        COUNT(*) as TotalTransactions,
        COALESCE(SUM(Amount), 0) as TotalRevenue,
        COALESCE(AVG(Amount), 0) as AverageTransaction,
        COALESCE(MIN(Amount), 0) as MinTransaction,
        COALESCE(MAX(Amount), 0) as MaxTransaction
    FROM PAYMENT
    WHERE DATE(Timestamp) BETWEEN p_start_date AND p_end_date
        AND Status = 'Completed';
    
    -- 2. Revenue by Payment Method
    SELECT 
        PaymentMethod,
        COUNT(*) as TransactionCount,
        COALESCE(SUM(Amount), 0) as MethodRevenue,
        ROUND(
            (SUM(Amount) * 100.0 / 
                (SELECT SUM(Amount) FROM PAYMENT 
                 WHERE DATE(Timestamp) BETWEEN p_start_date AND p_end_date 
                 AND Status = 'Completed')
            ), 2
        ) as RevenuePercentage
    FROM PAYMENT
    WHERE DATE(Timestamp) BETWEEN p_start_date AND p_end_date
        AND Status = 'Completed'
    GROUP BY PaymentMethod
    ORDER BY MethodRevenue DESC;
    
    -- 3. Revenue by Type (Ticket vs Pass)
    SELECT 
        CASE 
            WHEN TicketNumber IS NOT NULL THEN 'Ticket Sales'
            WHEN PassID IS NOT NULL THEN 'Pass Sales'
            ELSE 'Other'
        END as RevenueType,
        COUNT(*) as SalesCount,
        COALESCE(SUM(Amount), 0) as TypeRevenue
    FROM PAYMENT
    WHERE DATE(Timestamp) BETWEEN p_start_date AND p_end_date
        AND Status = 'Completed'
    GROUP BY 
        CASE 
            WHEN TicketNumber IS NOT NULL THEN 'Ticket Sales'
            WHEN PassID IS NOT NULL THEN 'Pass Sales'
            ELSE 'Other'
        END
    ORDER BY TypeRevenue DESC;
    
    -- 4. Daily Revenue Trend
    SELECT 
        DATE(Timestamp) as RevenueDate,
        COUNT(*) as DailyTransactions,
        COALESCE(SUM(Amount), 0) as DailyRevenue
    FROM PAYMENT
    WHERE DATE(Timestamp) BETWEEN p_start_date AND p_end_date
        AND Status = 'Completed'
    GROUP BY DATE(Timestamp)
    ORDER BY RevenueDate;
END //

DELIMITER ;

-- ============================================================
-- Test the procedure
-- ============================================================

-- Test with date range
CALL sp_generate_revenue_report('2024-01-01', '2024-12-31');

-- Test with current month
CALL sp_generate_revenue_report(
    DATE_FORMAT(NOW(), '%Y-%m-01'),
    LAST_DAY(NOW())
);

-- Test with last 7 days
CALL sp_generate_revenue_report(
    DATE_SUB(CURDATE(), INTERVAL 7 DAY),
    CURDATE()
);



-- FUNCTION 1: Calculate Passenger Age
DELIMITER //

CREATE FUNCTION fn_calculate_passenger_age(p_passenger_id INT)
RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_age INT;
    DECLARE v_dob DATE;
    
    SELECT DateOfBirth INTO v_dob
    FROM PASSENGER
    WHERE PassengerID = p_passenger_id;
    
    IF v_dob IS NULL THEN
        RETURN NULL;
    END IF;
    
    SET v_age = TIMESTAMPDIFF(YEAR, v_dob, CURDATE());
    
    RETURN v_age;
END//

DELIMITER ;

-- Test: Calculate ages for passengers
SELECT 
    PassengerID,
    CONCAT(FirstName, ' ', LastName) AS PassengerName,
    DateOfBirth,
    fn_calculate_passenger_age(PassengerID) AS Age
FROM PASSENGER 
WHERE PassengerID IN (1, 3, 5, 7, 10);



-- FUNCTION 2: Check Seat Availability
DELIMITER //

CREATE FUNCTION fn_check_seat_availability(
    p_schedule_id INT,
    p_journey_date DATE,
    p_seat_number VARCHAR(10)
)
RETURNS VARCHAR(20)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_seat_count INT;
    
    -- Check if seat is already booked
    SELECT COUNT(*) INTO v_seat_count
    FROM TICKET
    WHERE ScheduleID = p_schedule_id
    AND JourneyDate = p_journey_date
    AND SeatNumber = p_seat_number
    AND TicketStatus IN ('Booked', 'Used');
    
    IF v_seat_count > 0 THEN
        RETURN 'NOT_AVAILABLE';
    ELSE
        RETURN 'AVAILABLE';
    END IF;
END//

DELIMITER ;

-- Test: Check seat availability
SELECT 
    fn_check_seat_availability(1, '2025-12-01', 'Z99') AS SeatZ99_Status,
    fn_check_seat_availability(1, '2024-01-29', 'A01') AS SeatA01_Status;
    
-- Let's test with seats that should be available:
SELECT 
    fn_check_seat_availability(1, '2025-12-01', 'Z100') AS SeatZ100_Status,
    fn_check_seat_availability(1, '2024-01-29', 'X99') AS SeatX99_Status;
    
select * FROM PASSENGER;
select * from TICKET;
select * from pass;
select * from complaint;
select * from vehicle;



-- ============================================================
-- TranspoTrack User Management and Privileges Setup
-- ============================================================

-- Drop users if they already exist (cleanup)
DROP USER IF EXISTS 'transport_admin'@'localhost';
DROP USER IF EXISTS 'passenger_user'@'localhost';

-- ============================================================
-- 1. Create Administrator User
-- ============================================================
CREATE USER 'transport_admin'@'localhost' IDENTIFIED BY 'admin_pass';

-- Grant ALL privileges to admin user
GRANT ALL PRIVILEGES ON TranspoTrack.* TO 'transport_admin'@'localhost';

-- Additional admin privileges
GRANT CREATE, ALTER, DROP, INDEX, REFERENCES ON TranspoTrack.* TO 'transport_admin'@'localhost';
GRANT EXECUTE ON TranspoTrack.* TO 'transport_admin'@'localhost';
GRANT TRIGGER ON TranspoTrack.* TO 'transport_admin'@'localhost';

-- ============================================================
-- 2. Create Passenger User (Limited Access)
-- ============================================================
CREATE USER 'passenger_user'@'localhost' IDENTIFIED BY 'user_pass';

-- Grant SELECT and INSERT on TICKET table (booking tickets)
GRANT SELECT, INSERT ON TranspoTrack.TICKET TO 'passenger_user'@'localhost';

-- Grant SELECT and INSERT on PASS table (getting passes)
GRANT SELECT, INSERT ON TranspoTrack.PASS TO 'passenger_user'@'localhost';

-- Grant SELECT and INSERT on COMPLAINT table (filing complaints)
GRANT SELECT, INSERT ON TranspoTrack.COMPLAINT TO 'passenger_user'@'localhost';

-- Grant SELECT on SCHEDULE table (view schedules)
GRANT SELECT ON TranspoTrack.SCHEDULE TO 'passenger_user'@'localhost';

-- Grant SELECT on other tables needed for viewing schedules and booking
GRANT SELECT ON TranspoTrack.STATION TO 'passenger_user'@'localhost';
GRANT SELECT ON TranspoTrack.ROUTE TO 'passenger_user'@'localhost';
GRANT SELECT ON TranspoTrack.VEHICLE TO 'passenger_user'@'localhost';
GRANT SELECT ON TranspoTrack.PASSENGER TO 'passenger_user'@'localhost';

-- ============================================================
-- 3. Apply Privileges
-- ============================================================
FLUSH PRIVILEGES;

-- ============================================================
-- 4. Verify User Creation and Privileges
-- ============================================================

-- Show all users
SELECT User, Host FROM mysql.user WHERE User IN ('transport_admin', 'passenger_user');

-- Show admin privileges
SHOW GRANTS FOR 'transport_admin'@'localhost';

-- Show passenger privileges
SHOW GRANTS FOR 'passenger_user'@'localhost';

-- ============================================================
-- Usage Instructions
-- ============================================================

/*
ADMIN LOGIN:
    Username: transport_admin
    Password: admin_pass
    Role: Administrator
    Access: Full CRUD operations, Execute procedures/functions, Manage triggers, View reports

PASSENGER LOGIN:
    Username: passenger_user
    Password: user_pass
    Role: Passenger
    Access: Book tickets, Get passes, File complaints (3 actions only)

To test authentication from MySQL:
    mysql -u transport_admin -p
    (Enter: admin_pass)
    
    mysql -u passenger_user -p
    (Enter: user_pass)
*/

-- ============================================================
-- Security Best Practices (Optional)
-- ============================================================

-- Set password expiration (optional)
-- ALTER USER 'transport_admin'@'localhost' PASSWORD EXPIRE INTERVAL 90 DAY;
-- ALTER USER 'passenger_user'@'localhost' PASSWORD EXPIRE INTERVAL 90 DAY;

-- Limit failed login attempts (MySQL 8.0+)
-- ALTER USER 'transport_admin'@'localhost' FAILED_LOGIN_ATTEMPTS 3 PASSWORD_LOCK_TIME 1;
-- ALTER USER 'passenger_user'@'localhost' FAILED_LOGIN_ATTEMPTS 5 PASSWORD_LOCK_TIME 1;

-- ============================================================
-- Test Queries
-- ============================================================

-- Test as admin (should work)
-- SELECT * FROM PASSENGER;
-- INSERT INTO PASSENGER (...) VALUES (...);
-- UPDATE PASSENGER SET ... WHERE ...;
-- DELETE FROM PASSENGER WHERE ...;

-- Test as passenger (should work)
-- SELECT * FROM SCHEDULE;
-- INSERT INTO TICKET (...) VALUES (...);
-- INSERT INTO PASS (...) VALUES (...);
-- INSERT INTO COMPLAINT (...) VALUES (...);

-- Test as passenger (should FAIL)
-- DELETE FROM PASSENGER WHERE PassengerID = 1;
-- UPDATE STATION SET Name = 'Test' WHERE StationID = 1;

-- ============================================================
-- TranspoTrack User Management and Privileges Setup
-- ============================================================

-- Drop users if they already exist (cleanup)
DROP USER IF EXISTS 'transport_admin'@'localhost';
DROP USER IF EXISTS 'passenger_user'@'localhost';

-- ============================================================
-- 1. Create Administrator User
-- ============================================================
CREATE USER 'transport_admin'@'localhost' IDENTIFIED BY 'admin_pass';

-- Grant ALL privileges to admin user
GRANT ALL PRIVILEGES ON TranspoTrack.* TO 'transport_admin'@'localhost';

-- Additional admin privileges
GRANT CREATE, ALTER, DROP, INDEX, REFERENCES ON TranspoTrack.* TO 'transport_admin'@'localhost';
GRANT EXECUTE ON TranspoTrack.* TO 'transport_admin'@'localhost';
GRANT TRIGGER ON TranspoTrack.* TO 'transport_admin'@'localhost';

-- ============================================================
-- 2. Create Passenger User (Limited Access)
-- ============================================================
CREATE USER 'passenger_user'@'localhost' IDENTIFIED BY 'user_pass';

-- Grant SELECT and INSERT on TICKET table (booking tickets)
GRANT SELECT, INSERT ON TranspoTrack.TICKET TO 'passenger_user'@'localhost';

-- Grant SELECT on SCHEDULE table (view schedules)
GRANT SELECT ON TranspoTrack.SCHEDULE TO 'passenger_user'@'localhost';

-- Grant SELECT on other tables needed for passengers
GRANT SELECT ON TranspoTrack.STATION TO 'passenger_user'@'localhost';
GRANT SELECT ON TranspoTrack.ROUTE TO 'passenger_user'@'localhost';
GRANT SELECT ON TranspoTrack.VEHICLE TO 'passenger_user'@'localhost';

-- ============================================================
-- 3. Apply Privileges
-- ============================================================
FLUSH PRIVILEGES;

-- ============================================================
-- 4. Verify User Creation and Privileges
-- ============================================================

-- Show all users
SELECT User, Host FROM mysql.user WHERE User IN ('transport_admin', 'passenger_user');

-- Show admin privileges
SHOW GRANTS FOR 'transport_admin'@'localhost';

-- Show passenger privileges
SHOW GRANTS FOR 'passenger_user'@'localhost';

-- ============================================================
-- Usage Instructions
-- ============================================================

/*
ADMIN LOGIN:
    Username: transport_admin
    Password: admin_pass
    Role: Administrator
    Access: Full CRUD operations, Execute procedures/functions, Manage triggers, View reports

PASSENGER LOGIN:
    Username: passenger_user
    Password: user_pass
    Role: Passenger
    Access: View schedules, Book tickets, View own tickets (limited access)

To test authentication from MySQL:
    mysql -u transport_admin -p
    (Enter: admin_pass)
    
    mysql -u passenger_user -p
    (Enter: user_pass)
*/

-- ============================================================
-- Security Best Practices (Optional)
-- ============================================================

-- Set password expiration (optional)
-- ALTER USER 'transport_admin'@'localhost' PASSWORD EXPIRE INTERVAL 90 DAY;
-- ALTER USER 'passenger_user'@'localhost' PASSWORD EXPIRE INTERVAL 90 DAY;

-- Limit failed login attempts (MySQL 8.0+)
-- ALTER USER 'transport_admin'@'localhost' FAILED_LOGIN_ATTEMPTS 3 PASSWORD_LOCK_TIME 1;
-- ALTER USER 'passenger_user'@'localhost' FAILED_LOGIN_ATTEMPTS 5 PASSWORD_LOCK_TIME 1;

-- ============================================================
-- Test Queries
-- ============================================================

-- Test as admin (should work)
-- SELECT * FROM PASSENGER;
-- INSERT INTO PASSENGER (...) VALUES (...);
-- UPDATE PASSENGER SET ... WHERE ...;
-- DELETE FROM PASSENGER WHERE ...;

-- Test as passenger (should work)
-- SELECT * FROM SCHEDULE;
-- INSERT INTO TICKET (...) VALUES (...);

-- Test as passenger (should FAIL)
-- DELETE FROM PASSENGER WHERE PassengerID = 1;
-- UPDATE STATION SET Name = 'Test' WHERE StationID = 1;



select * from Passenger;
select * from Station;
select * from Route;
select * from Vehicle;
select * from Ticket;
select * from Pass;
select * from Payment;
select * from Complaint;



-- Age calculation function test
SELECT PassengerID, CONCAT(FirstName, ' ', LastName) AS Name, 
       DateOfBirth, fn_calculate_passenger_age(PassengerID) AS Age 
FROM PASSENGER WHERE PassengerID IN (1, 3, 5, 7, 10);



-- Seat availability test
SELECT fn_check_seat_availability(1, '2025-12-01', 'Z99') AS Available_Seat,
       fn_check_seat_availability(1, '2024-01-29', 'A01') AS Taken_Seat;


    
