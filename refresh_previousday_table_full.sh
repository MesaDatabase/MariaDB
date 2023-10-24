#!/bin/bash

# Set error flag to 0 by default
error_flag=0

# Optional authentication settings for testing
# MySQL db credentials
# username="dbuser1"
# password=''

# Prompt for MySQL password
# echo -n "Enter MySQL password for user $username: "
# stty -echo  # Turn off echoing
# read password
# stty echo  # Turn echoing back on
# echo  # Add a newline after the password input

# Define the path to the MySQL option file - u, p
mariadb_option_file="/etc/mysql/mariadb_client.cnf"

# Define database & backup location
source_database="DB1"
# source_server="db"
source_server="10.0.00.00"
backup_dir="/backups/DB1"

# Get current / or previous date YYYMMDD - toggle comment 
# current_date=$(date +'%Y%m%d')
current_date=$(date -d "1 day ago" +'%Y%m%d')

# Get current month YYYY_mm
current_month=$(date +'%Y_%m')

# Define import database name - SCADA_YYYY_MM
import_db="${source_database}_${current_month}"

# Define table to be copied
copy_table="prefix_$current_date"

# Define the import file name
import_file_name="prefix_$current_date.sql"  # Updated file name

# Backup previous day table from SourceDB
if mysqldump --defaults-file="$mariadb_option_file" -h "$source_server" "$source_database" "$copy_table" > "$backup_dir/$import_file_name"; then
    echo "SourceDB - history table backed up"
else
    echo "Error: backup of history table failed"
    error_flag=1
fi

# Import the SQL file into the target database on TargetDB
if mysql --defaults-file="$mariadb_option_file" "$import_db" < "$backup_dir/$import_file_name"; then
    echo "TargetDB - Imported history table"
else
    echo "Error: Import history table failed"
    error_flag=1
fi

# Import the SQL file into the target database on SourceDB
if mysql --defaults-file="$mariadb_option_file" -h "$source_server" "$import_db" < "$backup_dir/$import_file_name"; then
    echo "SourceDB - Imported history table"
else
    echo "Error: Import history table failed"
    error_flag=1
fi

# Check if any errors occurred during the mysqldump commands
if [ $error_flag -eq 0 ]; then
    echo "historic data imports successful."
else
    echo "Error: historic data imports failed."
fi