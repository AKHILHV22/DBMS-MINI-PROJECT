import mysql.connector
from mysql.connector import Error, pooling
from config import DB_CONFIG
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Connection Pool
connection_pool = None

def initialize_pool():
    """Initialize database connection pool"""
    global connection_pool
    try:
        connection_pool = pooling.MySQLConnectionPool(
            pool_name="transpotrack_pool",
            pool_size=5,
            pool_reset_session=True,
            **DB_CONFIG
        )
        logger.info("Database connection pool initialized successfully")
        return True
    except Error as e:
        logger.error(f"Error creating connection pool: {e}")
        return False

def get_connection():
    """Get connection from pool"""
    try:
        if connection_pool is None:
            initialize_pool()
        return connection_pool.get_connection()
    except Error as e:
        logger.error(f"Error getting connection from pool: {e}")
        return None

def execute_query(query, params=None, fetch=True):
    """Execute a query and return results"""
    connection = None
    cursor = None
    try:
        connection = get_connection()
        if connection is None:
            return {'success': False, 'error': 'Could not establish database connection'}
        
        cursor = connection.cursor(dictionary=True)
        cursor.execute(query, params or ())
        
        if fetch:
            if cursor.description:
                results = cursor.fetchall()
                # Convert any set objects to lists for JSON serialization
                for row in results:
                    for key, value in row.items():
                        if isinstance(value, set):
                            row[key] = list(value)
                return {'success': True, 'data': results}
            else:
                connection.commit()
                return {'success': True, 'affected_rows': cursor.rowcount}
        else:
            connection.commit()
            return {'success': True, 'affected_rows': cursor.rowcount, 'lastrowid': cursor.lastrowid}
            
    except Error as e:
        if connection:
            connection.rollback()
        logger.error(f"Database error: {e}")
        return {'success': False, 'error': str(e)}
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

def execute_procedure(proc_name, params=None):
    """Execute a stored procedure"""
    connection = None
    cursor = None
    try:
        connection = get_connection()
        if connection is None:
            return {'success': False, 'error': 'Could not establish database connection'}
        
        cursor = connection.cursor(dictionary=True)
        cursor.callproc(proc_name, params or ())
        
        results = []
        for result in cursor.stored_results():
            results.append(result.fetchall())
        
        connection.commit()
        return {'success': True, 'data': results}
        
    except Error as e:
        if connection:
            connection.rollback()
        logger.error(f"Procedure error: {e}")
        return {'success': False, 'error': str(e)}
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

def test_connection():
    """Test database connection"""
    try:
        conn = get_connection()
        if conn and conn.is_connected():
            cursor = conn.cursor()
            cursor.execute("SELECT DATABASE();")
            db = cursor.fetchone()
            cursor.close()
            conn.close()
            logger.info(f"Connected to database: {db[0]}")
            return True
        return False
    except Error as e:
        logger.error(f"Connection test failed: {e}")
        return False

def authenticate_user(username, password, role):
    """Authenticate user with database credentials"""
    connection = None
    try:
        # Create connection with user credentials
        db_config = {
            'host': DB_CONFIG['host'],
            'database': DB_CONFIG['database'],
            'user': username,
            'password': password
        }
        
        connection = mysql.connector.connect(**db_config)
        
        if connection.is_connected():
            # Verify role-based access
            cursor = connection.cursor()
            
            if role == 'admin':
                # Admin should have all privileges
                cursor.execute("SHOW GRANTS FOR CURRENT_USER()")
                grants = cursor.fetchall()
                has_all_privileges = any('ALL PRIVILEGES' in str(grant) for grant in grants)
                
                if has_all_privileges:
                    cursor.close()
                    connection.close()
                    return {'success': True, 'role': 'admin'}
                else:
                    cursor.close()
                    connection.close()
                    return {'success': False, 'error': 'User does not have admin privileges'}
            
            elif role == 'user':
                # Passenger should have limited access
                cursor.execute("SHOW GRANTS FOR CURRENT_USER()")
                grants = cursor.fetchall()
                
                cursor.close()
                connection.close()
                return {'success': True, 'role': 'user'}
            
            else:
                connection.close()
                return {'success': False, 'error': 'Invalid role'}
        
        return {'success': False, 'error': 'Authentication failed'}
        
    except Error as e:
        logger.error(f"Authentication error: {e}")
        if connection:
            connection.close()
        return {'success': False, 'error': 'Invalid username or password'}
