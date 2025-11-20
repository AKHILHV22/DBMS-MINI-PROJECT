from flask import Flask, render_template, request, jsonify, flash, redirect, url_for, session
from database import execute_query, execute_procedure, test_connection, initialize_pool, authenticate_user
from config import APP_CONFIG
import json
from datetime import datetime, date

app = Flask(__name__)
app.config['SECRET_KEY'] = APP_CONFIG['SECRET_KEY']

# Initialize database pool on startup
initialize_pool()

# Custom JSON encoder for date/datetime objects
class DateEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, (date, datetime)):
            return obj.isoformat()
        return super().default(obj)

app.json_encoder = DateEncoder

# ======================== HOME & DASHBOARD ========================
@app.route('/')
def index():
    """Redirect to login page"""
    return redirect(url_for('login_page'))

# ======================== AUTHENTICATION ========================
@app.route('/login')
def login_page():
    """Login page"""
    return render_template('login.html')

@app.route('/api/login', methods=['POST'])
def login():
    """Authenticate user"""
    data = request.json
    username = data.get('username')
    password = data.get('password')
    role = data.get('role')
    
    # Authenticate using database
    result = authenticate_user(username, password, role)
    
    if result['success']:
        session['user'] = {
            'username': username,
            'role': role
        }
        return jsonify({
            'success': True,
            'user': session['user']
        })
    else:
        return jsonify({
            'success': False,
            'error': result.get('error', 'Invalid credentials')
        }), 401

@app.route('/admin-dashboard')
def admin_dashboard():
    """Admin dashboard"""
    return render_template('admin_dashboard.html')

@app.route('/user-dashboard')
def user_dashboard():
    """User/Passenger dashboard"""
    return render_template('user_dashboard.html')

@app.route('/api/user/schedules')
def user_schedules():
    """Get schedules for passengers (limited access)"""
    query = "SELECT * FROM SCHEDULE ORDER BY ScheduleID DESC LIMIT 20"
    result = execute_query(query)
    return jsonify(result)

@app.route('/api/user/tickets')
def user_tickets():
    """Get tickets for passengers"""
    query = "SELECT * FROM TICKET ORDER BY TicketNumber DESC LIMIT 20"
    result = execute_query(query)
    return jsonify(result)

@app.route('/api/user/book-ticket', methods=['POST'])
def user_book_ticket():
    """Book ticket for passenger (limited access)"""
    data = request.json
    import random
    ticket_code = f"TKT{random.randint(100000000, 999999999)}"
    seat_number = f"A{random.randint(1, 99):02d}"
    
    query = """
        INSERT INTO TICKET (TicketCode, SeatNumber, JourneyDate, Fare, PassengerID, 
                           ScheduleID, SourceStationID, DestStationID, TicketStatus)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, 'Booked')
    """
    params = (
        ticket_code, seat_number, data.get('journeyDate', data.get('startDate', '2024-01-29')),
        data['fare'], data['passengerId'], data['scheduleId'], 
        data['fromStation'], data['toStation']
    )
    result = execute_query(query, params, fetch=False)
    return jsonify(result)

# Passenger-specific pages
@app.route('/user/book-ticket')
def user_book_ticket_page():
    """Passenger ticket booking page"""
    return render_template('user_book_ticket.html')

@app.route('/user/get-pass')
def user_get_pass_page():
    """Passenger pass application page"""
    return render_template('user_get_pass.html')

@app.route('/user/file-complaint')
def user_file_complaint_page():
    """Passenger complaint page"""
    return render_template('user_file_complaint.html')

# API endpoints for passenger actions
@app.route('/api/user/passes')
def user_passes():
    """Get passes for passengers"""
    query = "SELECT * FROM PASS ORDER BY PassID DESC LIMIT 20"
    result = execute_query(query)
    return jsonify(result)

@app.route('/api/user/get-pass', methods=['POST'])
def user_get_pass():
    """Apply for pass (passenger)"""
    data = request.json
    import random
    pass_code = f"PASS{random.randint(100000000, 999999999)}"
    
    # Calculate end date based on pass type
    if data['passType'] == 'Daily':
        interval_days = 1
    elif data['passType'] == 'Weekly':
        interval_days = 7
    elif data['passType'] == 'Monthly' or data['passType'] == 'Student':
        interval_days = 30
    elif data['passType'] == 'Quarterly':
        interval_days = 90
    elif data['passType'] == 'Annual':
        interval_days = 365
    else:
        interval_days = 30
    
    query = """
        INSERT INTO PASS (PassCode, PassType, StartDate, EndDate, Price, PassengerID, PassStatus)
        VALUES (%s, %s, %s, DATE_ADD(%s, INTERVAL %s DAY), %s, %s, 'Active')
    """
    params = (
        pass_code, data['passType'], data['startDate'], data['startDate'], 
        interval_days, data['price'], data['passengerId']
    )
    result = execute_query(query, params, fetch=False)
    return jsonify(result)

@app.route('/api/user/complaints')
def user_complaints():
    """Get complaints for passengers"""
    query = "SELECT * FROM COMPLAINT ORDER BY ComplaintID DESC LIMIT 20"
    result = execute_query(query)
    return jsonify(result)

@app.route('/api/user/file-complaint', methods=['POST'])
def user_file_complaint():
    """File complaint (passenger)"""
    data = request.json
    import random
    complaint_code = f"COMP{random.randint(100000000, 999999999)}"
    
    query = """
        INSERT INTO COMPLAINT (ComplaintCode, Title, Description, PassengerID, 
                              Category, Priority, Status)
        VALUES (%s, %s, %s, %s, %s, 'Medium', 'Pending')
    """
    params = (
        complaint_code,
        data.get('subject', 'General Complaint'),
        data['description'],
        data['passengerId'],
        data.get('category', 'Other')
    )
    result = execute_query(query, params, fetch=False)
    return jsonify(result)

@app.route('/dashboard')
def dashboard():
    """Main dashboard with statistics"""
    stats = {}
    
    # Get total passengers
    result = execute_query("SELECT COUNT(*) as count FROM PASSENGER WHERE Status='Active'")
    stats['total_passengers'] = result['data'][0]['count'] if result['success'] else 0
    
    # Get total tickets
    result = execute_query("SELECT COUNT(*) as count FROM TICKET WHERE TicketStatus='Booked'")
    stats['total_tickets'] = result['data'][0]['count'] if result['success'] else 0
    
    # Get active passes
    result = execute_query("SELECT COUNT(*) as count FROM PASS WHERE PassStatus='Active'")
    stats['active_passes'] = result['data'][0]['count'] if result['success'] else 0
    
    # Get total revenue
    result = execute_query("SELECT COALESCE(SUM(Amount), 0) as revenue FROM PAYMENT WHERE Status='Completed'")
    stats['total_revenue'] = float(result['data'][0]['revenue']) if result['success'] else 0
    
    # Get pending complaints
    result = execute_query("SELECT COUNT(*) as count FROM COMPLAINT WHERE Status='Pending'")
    stats['pending_complaints'] = result['data'][0]['count'] if result['success'] else 0
    
    # Get active vehicles
    result = execute_query("SELECT COUNT(*) as count FROM VEHICLE WHERE Status='Active'")
    stats['active_vehicles'] = result['data'][0]['count'] if result['success'] else 0
    
    return render_template('dashboard.html', stats=stats)

# ======================== PASSENGER CRUD ========================
@app.route('/passengers')
def passengers():
    """View all passengers"""
    return render_template('passengers.html')

@app.route('/api/passengers', methods=['GET'])
def get_passengers():
    """Get all passengers"""
    query = """
        SELECT p.*, GROUP_CONCAT(pp.PhoneNumber SEPARATOR ', ') as PhoneNumbers
        FROM PASSENGER p
        LEFT JOIN PASSENGER_PHONE pp ON p.PassengerID = pp.PassengerID
        GROUP BY p.PassengerID
        ORDER BY p.PassengerID DESC
    """
    result = execute_query(query)
    return jsonify(result)

@app.route('/api/passengers/<int:id>', methods=['GET'])
def get_passenger(id):
    """Get single passenger"""
    query = "SELECT * FROM PASSENGER WHERE PassengerID = %s"
    result = execute_query(query, (id,))
    return jsonify(result)

@app.route('/api/passengers', methods=['POST'])
def create_passenger():
    """Create new passenger"""
    data = request.json
    query = """
        INSERT INTO PASSENGER (FirstName, LastName, Email, DateOfBirth, Address, City, Status)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
    """
    params = (
        data['firstName'], data['lastName'], data['email'], 
        data['dateOfBirth'], data.get('address', ''), 
        data.get('city', ''), data.get('status', 'Active')
    )
    result = execute_query(query, params, fetch=False)
    
    if result['success'] and 'phone' in data and data['phone']:
        passenger_id = result['lastrowid']
        phone_query = """
            INSERT INTO PASSENGER_PHONE (PassengerID, PhoneNumber, PhoneType, IsPrimary)
            VALUES (%s, %s, 'Mobile', TRUE)
        """
        execute_query(phone_query, (passenger_id, data['phone']), fetch=False)
    
    return jsonify(result)

@app.route('/api/passengers/<int:id>', methods=['PUT'])
def update_passenger(id):
    """Update passenger"""
    data = request.json
    query = """
        UPDATE PASSENGER 
        SET FirstName=%s, LastName=%s, Email=%s, DateOfBirth=%s, 
            Address=%s, City=%s, Status=%s
        WHERE PassengerID=%s
    """
    params = (
        data['firstName'], data['lastName'], data['email'],
        data['dateOfBirth'], data.get('address', ''),
        data.get('city', ''), data.get('status', 'Active'), id
    )
    result = execute_query(query, params, fetch=False)
    return jsonify(result)

@app.route('/api/passengers/<int:id>', methods=['DELETE'])
def delete_passenger(id):
    """Delete passenger"""
    query = "DELETE FROM PASSENGER WHERE PassengerID = %s"
    result = execute_query(query, (id,), fetch=False)
    return jsonify(result)

# ======================== STATION CRUD ========================
@app.route('/stations')
def stations():
    """View all stations"""
    return render_template('stations.html')

@app.route('/api/stations', methods=['GET'])
def get_stations():
    """Get all stations"""
    query = "SELECT * FROM STATION ORDER BY StationID DESC"
    result = execute_query(query)
    return jsonify(result)

@app.route('/api/stations', methods=['POST'])
def create_station():
    """Create new station"""
    data = request.json
    query = """
        INSERT INTO STATION (StationCode, Name, Location, Type, Capacity, Zone, Status)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
    """
    params = (
        data['stationCode'], data['name'], data['location'],
        data['type'], data.get('capacity', 0), 
        data.get('zone', ''), data.get('status', 'Operational')
    )
    result = execute_query(query, params, fetch=False)
    return jsonify(result)

@app.route('/api/stations/<int:id>', methods=['PUT'])
def update_station(id):
    """Update station"""
    data = request.json
    query = """
        UPDATE STATION 
        SET StationCode=%s, Name=%s, Location=%s, Type=%s, 
            Capacity=%s, Zone=%s, Status=%s
        WHERE StationID=%s
    """
    params = (
        data['stationCode'], data['name'], data['location'],
        data['type'], data.get('capacity', 0),
        data.get('zone', ''), data.get('status', 'Operational'), id
    )
    result = execute_query(query, params, fetch=False)
    return jsonify(result)

@app.route('/api/stations/<int:id>', methods=['DELETE'])
def delete_station(id):
    """Delete station"""
    query = "DELETE FROM STATION WHERE StationID = %s"
    result = execute_query(query, (id,), fetch=False)
    return jsonify(result)

# ======================== TICKET CRUD ========================
@app.route('/tickets')
def tickets():
    """View all tickets"""
    return render_template('tickets.html')

@app.route('/api/tickets', methods=['GET'])
def get_tickets():
    """Get all tickets"""
    query = """
        SELECT t.*, 
               CONCAT(p.FirstName, ' ', p.LastName) as PassengerName,
               s.ScheduleCode,
               src.Name as SourceStation,
               dest.Name as DestinationStation
        FROM TICKET t
        JOIN PASSENGER p ON t.PassengerID = p.PassengerID
        JOIN SCHEDULE s ON t.ScheduleID = s.ScheduleID
        JOIN STATION src ON t.SourceStationID = src.StationID
        JOIN STATION dest ON t.DestStationID = dest.StationID
        ORDER BY t.TicketNumber DESC
    """
    result = execute_query(query)
    return jsonify(result)

# ======================== VEHICLE CRUD ========================
@app.route('/vehicles')
def vehicles():
    """View all vehicles"""
    return render_template('vehicles.html')

@app.route('/api/vehicles', methods=['GET'])
def get_vehicles():
    """Get all vehicles"""
    query = "SELECT * FROM VEHICLE ORDER BY VehicleID DESC"
    result = execute_query(query)
    return jsonify(result)

@app.route('/api/vehicles', methods=['POST'])
def create_vehicle():
    """Create new vehicle"""
    data = request.json
    query = """
        INSERT INTO VEHICLE (VehicleNumber, Type, Model, Capacity, 
                           RegistrationNumber, FuelType, Status)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
    """
    params = (
        data['vehicleNumber'], data['type'], data.get('model', ''),
        data['capacity'], data['registrationNumber'],
        data.get('fuelType', 'Diesel'), data.get('status', 'Active')
    )
    result = execute_query(query, params, fetch=False)
    return jsonify(result)

@app.route('/api/vehicles/<int:id>', methods=['PUT'])
def update_vehicle(id):
    """Update vehicle"""
    data = request.json
    query = """
        UPDATE VEHICLE 
        SET VehicleNumber=%s, Type=%s, Model=%s, Capacity=%s,
            RegistrationNumber=%s, FuelType=%s, Status=%s
        WHERE VehicleID=%s
    """
    params = (
        data['vehicleNumber'], data['type'], data.get('model', ''),
        data['capacity'], data['registrationNumber'],
        data.get('fuelType', 'Diesel'), data.get('status', 'Active'), id
    )
    result = execute_query(query, params, fetch=False)
    return jsonify(result)

@app.route('/api/vehicles/<int:id>', methods=['DELETE'])
def delete_vehicle(id):
    """Delete vehicle"""
    query = "DELETE FROM VEHICLE WHERE VehicleID = %s"
    result = execute_query(query, (id,), fetch=False)
    return jsonify(result)

# ======================== PASS CRUD ========================
@app.route('/passes')
def passes():
    """View all passes"""
    return render_template('passes.html')

@app.route('/api/passes', methods=['GET'])
def get_passes():
    """Get all passes"""
    query = """
        SELECT p.*, CONCAT(ps.FirstName, ' ', ps.LastName) as PassengerName
        FROM PASS p
        JOIN PASSENGER ps ON p.PassengerID = ps.PassengerID
        ORDER BY p.PassID DESC
    """
    result = execute_query(query)
    return jsonify(result)

# ======================== COMPLAINT CRUD ========================
@app.route('/complaints')
def complaints():
    """View all complaints"""
    return render_template('complaints.html')

@app.route('/api/complaints', methods=['GET'])
def get_complaints():
    """Get all complaints"""
    query = """
        SELECT c.*, CONCAT(p.FirstName, ' ', p.LastName) as PassengerName
        FROM COMPLAINT c
        JOIN PASSENGER p ON c.PassengerID = p.PassengerID
        ORDER BY c.ComplaintID DESC
    """
    result = execute_query(query)
    return jsonify(result)

@app.route('/api/complaints/<int:id>/status', methods=['PUT'])
def update_complaint_status(id):
    """Update complaint status"""
    data = request.json
    query = """
        UPDATE COMPLAINT 
        SET Status=%s, Resolution=%s, ResolvedAt=NOW()
        WHERE ComplaintID=%s
    """
    params = (data['status'], data.get('resolution', ''), id)
    result = execute_query(query, params, fetch=False)
    return jsonify(result)

# ======================== TRIGGERS & PROCEDURES ========================
@app.route('/triggers')
def triggers():
    """View triggers page"""
    return render_template('triggers.html')

@app.route('/procedures')
def procedures():
    """View procedures page"""
    return render_template('procedures.html')

@app.route('/api/book-ticket', methods=['POST'])
def book_ticket():
    """Book ticket using stored procedure"""
    data = request.json
    try:
        result = execute_procedure('sp_book_ticket_with_payment', [
            data['passengerId'],
            data['scheduleId'],
            data['sourceStationId'],
            data['destStationId'],
            data['seatNumber'],
            data['journeyDate'],
            data['fare'],
            data['paymentMethod']
        ])
        return jsonify(result)
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/revenue-report', methods=['POST'])
def revenue_report():
    """Generate revenue report using stored procedure"""
    data = request.json
    try:
        result = execute_procedure('sp_generate_revenue_report', [
            data['startDate'],
            data['endDate']
        ])
        return jsonify(result)
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

# ======================== FUNCTIONS ========================
@app.route('/functions')
def functions():
    """View functions page"""
    return render_template('functions.html')

@app.route('/api/passenger-age/<int:passenger_id>', methods=['GET'])
def get_passenger_age(passenger_id):
    """Get passenger age using function"""
    query = "SELECT fn_calculate_passenger_age(%s) as age"
    result = execute_query(query, (passenger_id,))
    return jsonify(result)

@app.route('/api/check-seat', methods=['POST'])
def check_seat_availability():
    """Check seat availability using function"""
    data = request.json
    query = "SELECT fn_check_seat_availability(%s, %s, %s) as status"
    result = execute_query(query, (
        data['scheduleId'],
        data['journeyDate'],
        data['seatNumber']
    ))
    return jsonify(result)

# ======================== ADVANCED QUERIES ========================
@app.route('/queries')
def queries():
    """View advanced queries page"""
    return render_template('queries.html')

@app.route('/api/query/nested', methods=['GET'])
def nested_query():
    """Nested query: Passengers with above average ticket spending"""
    query = """
        SELECT p.PassengerID, CONCAT(p.FirstName, ' ', p.LastName) as Name,
               COUNT(t.TicketNumber) as TotalTickets,
               SUM(t.Fare) as TotalSpending
        FROM PASSENGER p
        JOIN TICKET t ON p.PassengerID = t.PassengerID
        GROUP BY p.PassengerID, p.FirstName, p.LastName
        HAVING SUM(t.Fare) > (
            SELECT AVG(TotalFare) 
            FROM (
                SELECT SUM(Fare) as TotalFare 
                FROM TICKET 
                GROUP BY PassengerID
            ) as AvgSpending
        )
        ORDER BY TotalSpending DESC
    """
    result = execute_query(query)
    return jsonify(result)

@app.route('/api/query/join', methods=['GET'])
def join_query():
    """Join query: Route details with stations"""
    query = """
        SELECT r.RouteCode, r.Name as RouteName, r.TotalDistance,
               GROUP_CONCAT(s.Name ORDER BY rs.SequenceNumber SEPARATOR ' → ') as Stations,
               COUNT(DISTINCT rs.StationID) as StationCount
        FROM ROUTE r
        JOIN ROUTE_STATION rs ON r.RouteID = rs.RouteID
        JOIN STATION s ON rs.StationID = s.StationID
        GROUP BY r.RouteID, r.RouteCode, r.Name, r.TotalDistance
        ORDER BY r.RouteID
    """
    result = execute_query(query)
    return jsonify(result)

@app.route('/api/query/aggregate', methods=['GET'])
def aggregate_query():
    """Aggregate query: Revenue by payment method"""
    query = """
        SELECT PaymentMethod,
               COUNT(*) as TransactionCount,
               SUM(Amount) as TotalRevenue,
               AVG(Amount) as AverageAmount,
               MIN(Amount) as MinAmount,
               MAX(Amount) as MaxAmount
        FROM PAYMENT
        WHERE Status = 'Completed'
        GROUP BY PaymentMethod
        ORDER BY TotalRevenue DESC
    """
    result = execute_query(query)
    return jsonify(result)

# ======================== REPORTS ========================
@app.route('/reports')
def reports():
    """View reports page"""
    return render_template('reports.html')

@app.route('/api/reports/daily-bookings', methods=['GET'])
def daily_bookings():
    """Daily booking statistics"""
    query = """
        SELECT DATE(BookingDateTime) as BookingDate,
               COUNT(*) as TotalBookings,
               SUM(Fare) as Revenue,
               COUNT(DISTINCT PassengerID) as UniquePassengers
        FROM TICKET
        WHERE BookingDateTime >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
        GROUP BY DATE(BookingDateTime)
        ORDER BY BookingDate DESC
    """
    result = execute_query(query)
    return jsonify(result)

@app.route('/api/reports/popular-routes', methods=['GET'])
def popular_routes():
    """Most popular routes"""
    query = """
        SELECT r.RouteCode, r.Name, COUNT(t.TicketNumber) as BookingCount,
               SUM(t.Fare) as TotalRevenue
        FROM ROUTE r
        JOIN SCHEDULE sch ON r.RouteID = sch.RouteID
        JOIN TICKET t ON sch.ScheduleID = t.ScheduleID
        GROUP BY r.RouteID, r.RouteCode, r.Name
        ORDER BY BookingCount DESC
        LIMIT 10
    """
    result = execute_query(query)
    return jsonify(result)

if __name__ == '__main__':
    print("\n" + "="*60)
    print("🚆 TranspoTrack DBMS - Starting Application")
    print("="*60)
    
    # Test database connection
    if test_connection():
        print("✅ Database connection successful")
        print(f"🌐 Server starting at http://localhost:{APP_CONFIG['PORT']}")
        print("="*60 + "\n")
        app.run(
            host=APP_CONFIG['HOST'],
            port=APP_CONFIG['PORT'],
            debug=APP_CONFIG['DEBUG']
        )
    else:
        print("❌ Database connection failed. Please check your configuration.")
        print("="*60 + "\n")
