#!/usr/bin/env python3
import sqlite3

# Check incidents count
conn = sqlite3.connect('backend/database/ocean_hazard.db')
cursor = conn.cursor()

cursor.execute('SELECT COUNT(*) FROM incidents')
count = cursor.fetchone()[0]
print(f'📊 Total incidents in database: {count}')

if count == 0:
    print('⚠️ No incidents found - this is why reports show "Failed to fetch"')
    print('🔧 Creating sample incidents...')
    
    sample_incidents = [
        ('OG-20250930-TEST001', 'TIDAL_SURGE', 'Mumbai Coast', 19.0760, 72.8777, 'High tide surge reported near Marine Drive', 'HIGH', 'PENDING', 'test@example.com'),
        ('OG-20250930-TEST002', 'ROUGH_SEAS', 'Chennai Marina', 13.0827, 80.2707, 'Rough sea conditions, fishing boats advised to return', 'MEDIUM', 'PENDING', 'chennai@example.com'),
        ('OG-20250930-TEST003', 'COASTAL_EROSION', 'Kochi Beach', 9.9312, 76.2673, 'Severe erosion observed along coastline', 'LOW', 'PENDING', 'kochi@example.com')
    ]
    
    for incident in sample_incidents:
        cursor.execute('''
            INSERT INTO incidents (
                reference_id, hazard_type, location, latitude, longitude, 
                description, urgency, status, contact_info, 
                reporter_id, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1, CURRENT_TIMESTAMP)
        ''', incident)
    
    conn.commit()
    print(f'✅ Created {len(sample_incidents)} sample incidents')
    
    cursor.execute('SELECT COUNT(*) FROM incidents')
    new_count = cursor.fetchone()[0]
    print(f'📊 New total: {new_count} incidents')
else:
    cursor.execute('SELECT id, reference_id, hazard_type, location, status FROM incidents LIMIT 3')
    incidents = cursor.fetchall()
    print('📋 Existing incidents:')
    for incident in incidents:
        print(f'   {incident[1]} | {incident[2]} | {incident[3]} | {incident[4]}')

conn.close()
print('✅ Database check complete')