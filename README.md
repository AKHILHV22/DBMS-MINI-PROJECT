🚆 TranspoTrack DBMS - Complete GUI Application
Project Overview
TranspoTrack is a comprehensive Database Management System for Public Transport & Metro Ticketing. This project includes a complete web-based GUI built with Python Flask backend and modern HTML/CSS/JavaScript frontend.

Domain
Public Transport & Metro Ticketing System

Problem Statement
In cities, public transport systems like buses and metros face issues with ticketing, seat availability, pass management, and passenger complaints. Manual ticketing and fragmented databases result in revenue loss, delays, and poor passenger experience.

Solution
TranspoTrack DBMS is a centralized system that manages:

Passenger records and ticketing
Real-time seat/ticket availability
Digital pass renewal with auto fine calculation
Complaint/feedback tracking
Comprehensive reports on route demand, revenue, and service usage
🛠️ Technology Stack
Backend: Python 3.x, Flask Framework
Database: MySQL 8.0+
Frontend: HTML5, CSS3, JavaScript (Vanilla)
Libraries: mysql-connector-python, Flask
📋 Features Implemented
✅ Database Design
Complete ER Diagram with 8 entities
Normalized Relational Schema
12+ tables with proper constraints
✅ CRUD Operations (All Tables)
Passengers - Full CRUD with phone management
Stations - Add, Edit, Delete, View
Tickets - View booking details
Vehicles - Complete fleet management
Passes - Season pass management
Complaints - Complaint tracking and resolution
Routes - Route management
Schedules - Schedule management
✅ Triggers (2)
Payment Validation Trigger - Validates payment data before insertion
Pass Status Update Trigger - Auto-updates pass status based on dates
✅ Stored Procedures (2)
Book Ticket with Payment - Complete booking workflow with validations
Generate Revenue Report - Comprehensive revenue analysis
✅ Functions (2)
Calculate Passenger Age - Returns age from date of birth
Check Seat Availability - Real-time seat availability check
✅ Advanced Queries (3)
Nested Query - High-value passengers above average spending
Join Query - Route details with station sequences
Aggregate Query - Revenue analysis by payment method
✅ Reports & Analytics
Daily booking statistics
Popular routes analysis
Payment method distribution
Revenue trends
🚀 Installation & Setup
Prerequisites
Python 3.8 or higher
MySQL 8.0 or higher
pip (Python package manager)
