#!/usr/bin/env python3
"""
Ocean Hazard - Database Validation Script
Validates database schema, relationships, and data integrity
"""

import sqlite3
import os
import json
from datetime import datetime

class DatabaseValidator:
    def __init__(self, db_path="backend/database/ocean_hazard.db"):
        self.db_path = db_path
        self.issues = []
        
    def log_issue(self, category, issue, severity="INFO"):
        """Log database issues"""
        self.issues.append({
            "category": category,
            "issue": issue,
            "severity": severity,
            "timestamp": datetime.now().isoformat()
        })
        
        icon = "🔴" if severity == "ERROR" else "🟡" if severity == "WARNING" else "🔵"
        print(f"{icon} [{category}] {issue}")
    
    def validate_database_exists(self):
        """Check if database file exists"""
        if not os.path.exists(self.db_path):
            self.log_issue("Database", f"Database file not found: {self.db_path}", "ERROR")
            return False
        
        self.log_issue("Database", f"Database file found: {self.db_path}", "INFO")
        return True
    
    def validate_schema(self):
        """Validate database schema"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Get all tables
            cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
            tables = [row[0] for row in cursor.fetchall()]
            
            required_tables = ['users', 'incidents']
            
            for table in required_tables:
                if table not in tables:
                    self.log_issue("Schema", f"Missing required table: {table}", "ERROR")
                else:
                    self.log_issue("Schema", f"Table exists: {table}", "INFO")
            
            # Validate users table structure
            if 'users' in tables:
                cursor.execute("PRAGMA table_info(users)")
                user_columns = {row[1]: row[2] for row in cursor.fetchall()}
                
                required_user_columns = {
                    'id': 'INTEGER',
                    'username': 'VARCHAR',
                    'email': 'VARCHAR',
                    'hashed_password': 'VARCHAR',
                    'first_name': 'VARCHAR',
                    'last_name': 'VARCHAR'
                }
                
                for col, col_type in required_user_columns.items():
                    if col not in user_columns:
                        self.log_issue("Schema", f"Missing column in users table: {col}", "ERROR")
                    else:
                        self.log_issue("Schema", f"Users table column OK: {col}", "INFO")
            
            # Validate incidents table structure
            if 'incidents' in tables:
                cursor.execute("PRAGMA table_info(incidents)")
                incident_columns = {row[1]: row[2] for row in cursor.fetchall()}
                
                required_incident_columns = {
                    'id': 'INTEGER',
                    'reference_id': 'VARCHAR',
                    'hazard_type': 'VARCHAR',
                    'location': 'VARCHAR',
                    'description': 'TEXT',
                    'urgency': 'VARCHAR',
                    'status': 'VARCHAR',
                    'reporter_id': 'INTEGER'
                }
                
                for col, col_type in required_incident_columns.items():
                    if col not in incident_columns:
                        self.log_issue("Schema", f"Missing column in incidents table: {col}", "ERROR")
                    else:
                        self.log_issue("Schema", f"Incidents table column OK: {col}", "INFO")
            
            conn.close()
            return True
            
        except Exception as e:
            self.log_issue("Schema", f"Error validating schema: {str(e)}", "ERROR")
            return False
    
    def validate_data_integrity(self):
        """Validate data integrity and relationships"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Check user data
            cursor.execute("SELECT COUNT(*) FROM users")
            user_count = cursor.fetchone()[0]
            self.log_issue("Data", f"Total users: {user_count}", "INFO")
            
            # Check for duplicate usernames
            cursor.execute("SELECT username, COUNT(*) FROM users GROUP BY username HAVING COUNT(*) > 1")
            duplicates = cursor.fetchall()
            if duplicates:
                for username, count in duplicates:
                    self.log_issue("Data", f"Duplicate username: {username} ({count} times)", "WARNING")
            
            # Check for duplicate emails
            cursor.execute("SELECT email, COUNT(*) FROM users GROUP BY email HAVING COUNT(*) > 1")
            duplicates = cursor.fetchall()
            if duplicates:
                for email, count in duplicates:
                    self.log_issue("Data", f"Duplicate email: {email} ({count} times)", "WARNING")
            
            # Check incident data
            cursor.execute("SELECT COUNT(*) FROM incidents")
            incident_count = cursor.fetchone()[0]
            self.log_issue("Data", f"Total incidents: {incident_count}", "INFO")
            
            # Check for orphaned incidents (incidents without valid reporter)
            cursor.execute("""
                SELECT i.id, i.reference_id, i.reporter_id 
                FROM incidents i 
                LEFT JOIN users u ON i.reporter_id = u.id 
                WHERE u.id IS NULL
            """)
            orphaned = cursor.fetchall()
            if orphaned:
                for incident_id, ref_id, reporter_id in orphaned:
                    self.log_issue("Data", f"Orphaned incident: {ref_id} (reporter_id: {reporter_id})", "ERROR")
            
            # Check incident status values
            cursor.execute("SELECT DISTINCT status FROM incidents")
            statuses = [row[0] for row in cursor.fetchall()]
            valid_statuses = ['pending', 'verified', 'in_progress', 'resolved', 'false_alarm']
            
            for status in statuses:
                if status not in valid_statuses:
                    self.log_issue("Data", f"Invalid incident status: {status}", "WARNING")
            
            # Check hazard types
            cursor.execute("SELECT DISTINCT hazard_type FROM incidents")
            hazard_types = [row[0] for row in cursor.fetchall()]
            valid_hazards = ['high-waves', 'flooding', 'tsunami', 'lost-vessel', 'debris', 'oil-spill', 'other']
            
            for hazard in hazard_types:
                if hazard not in valid_hazards:
                    self.log_issue("Data", f"Invalid hazard type: {hazard}", "WARNING")
            
            conn.close()
            return True
            
        except Exception as e:
            self.log_issue("Data", f"Error validating data integrity: {str(e)}", "ERROR")
            return False
    
    def generate_sample_data(self):
        """Generate sample data for testing"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Check if we need sample data
            cursor.execute("SELECT COUNT(*) FROM users WHERE username LIKE 'test_%'")
            test_users = cursor.fetchone()[0]
            
            if test_users == 0:
                # Create test users
                test_users_data = [
                    ('test_citizen', 'citizen@test.com', 'hashed_password', 'Test', 'Citizen', '9876543210', 'Test City', 'public'),
                    ('test_admin', 'admin@test.com', 'hashed_password', 'Test', 'Admin', '9876543211', 'Test City', 'admin')
                ]
                
                for username, email, password, fname, lname, phone, location, role in test_users_data:
                    cursor.execute("""
                        INSERT INTO users (username, email, hashed_password, first_name, last_name, phone, location, role, is_active, is_verified)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, 1)
                    """, (username, email, password, fname, lname, phone, location, role))
                
                conn.commit()
                self.log_issue("Sample Data", "Created test users", "INFO")
            
            # Check if we need sample incidents
            cursor.execute("SELECT COUNT(*) FROM incidents WHERE reference_id LIKE 'TEST-%'")
            test_incidents = cursor.fetchone()[0]
            
            if test_incidents == 0:
                # Get test user ID
                cursor.execute("SELECT id FROM users WHERE username = 'test_citizen'")
                user_result = cursor.fetchone()
                
                if user_result:
                    user_id = user_result[0]
                    
                    # Create test incidents
                    test_incidents_data = [
                        ('TEST-001', 'high-waves', 'Test Beach', 'Test high waves incident', 'medium', 'pending', user_id),
                        ('TEST-002', 'debris', 'Test Coast', 'Test debris incident', 'low', 'verified', user_id)
                    ]
                    
                    for ref_id, hazard, location, desc, urgency, status, reporter in test_incidents_data:
                        cursor.execute("""
                            INSERT INTO incidents (reference_id, hazard_type, location, description, urgency, status, reporter_id, contact_info)
                            VALUES (?, ?, ?, ?, ?, ?, ?, 'test@example.com')
                        """, (ref_id, hazard, location, desc, urgency, status, reporter))
                    
                    conn.commit()
                    self.log_issue("Sample Data", "Created test incidents", "INFO")
            
            conn.close()
            return True
            
        except Exception as e:
            self.log_issue("Sample Data", f"Error creating sample data: {str(e)}", "ERROR")
            return False
    
    def run_validation(self):
        """Run complete database validation"""
        print("🌊 Ocean Hazard - Database Validation")
        print("=" * 40)
        
        # Step 1: Check database exists
        if not self.validate_database_exists():
            return False
        
        # Step 2: Validate schema
        self.validate_schema()
        
        # Step 3: Validate data integrity
        self.validate_data_integrity()
        
        # Step 4: Generate sample data if needed
        self.generate_sample_data()
        
        # Generate report
        self.generate_report()
        
        return True
    
    def generate_report(self):
        """Generate validation report"""
        print("\n" + "=" * 40)
        print("📊 VALIDATION SUMMARY")
        print("=" * 40)
        
        errors = [issue for issue in self.issues if issue['severity'] == 'ERROR']
        warnings = [issue for issue in self.issues if issue['severity'] == 'WARNING']
        info = [issue for issue in self.issues if issue['severity'] == 'INFO']
        
        print(f"🔴 Errors: {len(errors)}")
        print(f"🟡 Warnings: {len(warnings)}")
        print(f"🔵 Info: {len(info)}")
        
        if errors:
            print("\n🔴 ERRORS FOUND:")
            for error in errors:
                print(f"  • [{error['category']}] {error['issue']}")
        
        if warnings:
            print("\n🟡 WARNINGS:")
            for warning in warnings:
                print(f"  • [{warning['category']}] {warning['issue']}")
        
        # Save report
        report_file = f"py_test/tests/db_validation_{int(datetime.now().timestamp())}.json"
        os.makedirs(os.path.dirname(report_file), exist_ok=True)
        
        with open(report_file, 'w') as f:
            json.dump(self.issues, f, indent=2)
        
        print(f"\n📄 Full report saved to: {report_file}")
        
        if len(errors) == 0:
            print("\n✅ Database validation passed!")
        else:
            print(f"\n❌ Database validation failed with {len(errors)} errors")

def main():
    """Main validation execution"""
    validator = DatabaseValidator()
    
    # Check if we're in the right directory
    if not os.path.exists("backend"):
        print("❌ Please run this script from the Ocean-Hazard root directory")
        return
    
    try:
        validator.run_validation()
    except Exception as e:
        print(f"\n❌ Unexpected error: {str(e)}")

if __name__ == "__main__":
    main()