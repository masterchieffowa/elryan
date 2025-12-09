#!/usr/bin/env python3
"""
Excel Data Import Script for Laptop Repair Shop
Usage: python import_excel.py <excel_file.xlsx> <database_path>
"""

import sqlite3
import pandas as pd
import sys
from datetime import datetime
import uuid

def generate_serial_code():
    """Generate unique serial code for orders"""
    timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
    unique_id = str(uuid.uuid4())[:4].upper()
    return f"RPR{timestamp}{unique_id}"

def import_excel_to_db(excel_file, db_path):
    """Import Excel data into SQLite database"""
    
    # Read Excel file
    try:
        df = pd.read_excel(excel_file)
        print(f"✓ Loaded {len(df)} rows from Excel file")
    except Exception as e:
        print(f"✗ Error reading Excel file: {e}")
        return
    
    # Connect to database
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        print(f"✓ Connected to database: {db_path}")
    except Exception as e:
        print(f"✗ Error connecting to database: {e}")
        return
    
    # Process each row
    success_count = 0
    error_count = 0
    
    for index, row in df.iterrows():
        try:
            # Extract data from Excel columns
            customer_name = str(row.get('العميل', '')).strip()
            phone = str(row.get('رقم الهاتف', 'لا يوجد')).strip()
            laptop_model = str(row.get('الموديل', '')).strip()
            problem = str(row.get('صيانه', '')).strip()
            cost = float(row.get('التكلفه', 0) or 0)
            remaining = float(row.get('باقى حساب', 0) or 0)
            delivery_status = str(row.get('استلام', '')).strip()
            date_str = str(row.get('تاريخ الاسلام', '')).strip()
            
            # Skip empty rows
            if not customer_name or customer_name == 'nan':
                continue
            
            # Parse date
            try:
                if date_str and date_str != 'nan':
                    created_date = pd.to_datetime(date_str).strftime('%Y-%m-%d %H:%M:%S')
                else:
                    created_date = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            except:
                created_date = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            
            # Generate IDs
            customer_id = str(uuid.uuid4())
            order_id = str(uuid.uuid4())
            serial_code = generate_serial_code()
            
            # Calculate paid amount
            paid_amount = cost - remaining
            
            # Determine status
            if delivery_status == 'تم':
                status = 'delivered'
                completed_at = created_date
                delivered_at = created_date
            else:
                status = 'pending'
                completed_at = None
                delivered_at = None
            
            # Insert customer
            cursor.execute('''
                INSERT OR IGNORE INTO customers (id, name, phone, address, created_at)
                VALUES (?, ?, ?, NULL, ?)
            ''', (customer_id, customer_name, phone, created_date))
            
            # Get customer_id if already exists
            cursor.execute('SELECT id FROM customers WHERE name = ? AND phone = ?', 
                          (customer_name, phone))
            result = cursor.fetchone()
            if result:
                customer_id = result[0]
            
            # Insert repair order
            cursor.execute('''
                INSERT INTO repair_orders 
                (id, serial_code, customer_id, dealer_id, device_owner_name, 
                 laptop_type, problem_description, total_cost, paid_amount, 
                 status, created_at, completed_at, delivered_at, notes)
                VALUES (?, ?, ?, NULL, NULL, ?, ?, ?, ?, ?, ?, ?, ?, NULL)
            ''', (order_id, serial_code, customer_id, laptop_model, problem,
                  cost, paid_amount, status, created_date, completed_at, delivered_at))
            
            # Insert initial payment if paid
            if paid_amount > 0:
                payment_id = str(uuid.uuid4())
                cursor.execute('''
                    INSERT INTO payments (id, order_id, amount, payment_date, notes)
                    VALUES (?, ?, ?, ?, ?)
                ''', (payment_id, order_id, paid_amount, created_date, 'استيراد من Excel'))
            
            success_count += 1
            print(f"✓ Imported: {customer_name} - {laptop_model}")
            
        except Exception as e:
            error_count += 1
            print(f"✗ Error importing row {index + 1}: {e}")
            continue
    
    # Commit changes
    conn.commit()
    conn.close()
    
    print("\n" + "="*50)
    print(f"Import Summary:")
    print(f"  Successfully imported: {success_count} records")
    print(f"  Errors: {error_count} records")
    print("="*50)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python import_excel.py <excel_file.xlsx> <database_path>")
        print("\nExample:")
        print("  python import_excel.py old_data.xlsx ~/Documents/laptop_repair_shop/laptop_repair.db")
        sys.exit(1)
    
    excel_file = sys.argv[1]
    db_path = sys.argv[2]
    
    print("Starting Excel Import...")
    print(f"Excel File: {excel_file}")
    print(f"Database: {db_path}")
    print("-" * 50)
    
    import_excel_to_db(excel_file, db_path)