#!/bin/bash

# Set error flag to 0 by default
error_flag=0

# Optional authentication settings for testing
# MySQL database credentials
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

# Get the current date in YYYYMMDD format
# yesterday - current_date=$(date -d "1 day ago" +'%Y%m%d')
current_date=$(date +'%Y%m%d')

# Set source server for db
source_server="10.0.0.00"

# First database - DB1 config
database1="DB1"
backup_dir1="/backups/DB1"  # Change this to the directory of the first backup file

# Second database - DB2 config
database2="DB2"
backup_dir2="/backups/DB2"  # Change this to the directory of the second backup file

# Third database - DB3 config
database3="DB3"
backup_dir3="/backups/DB3_Essentials"
exclude_prefix="prefix_" # Filter out historic data for DB3_Essentials
# Get a list of table names excluding those with the specified prefix
table_list=$(mysql --defaults-file="$mariadb_option_file" -h "$source_server" "$database3" -e "SHOW TABLES LIKE '$exclude_prefix%';" --skip-column-names)
# Construct the list of tables to exclude
exclude_tables=""
for table in $table_list; do
  exclude_tables+="--ignore-table=${database3}.${table} "
done
# End DB3 Essentials config

# Backup & refresh DB1
if mysqldump --defaults-file="$mariadb_option_file" -h "$source_server" "$database1" > "$backup_dir1/${database1}_${current_date}.sql"; then
    echo "SourceDB - Exported database: ${database1}"
else
    echo "Error: backup of DB1 failed"
    error_flag=1
fi

if mysql --defaults-file="$mariadb_option_file" "$database1" < "$backup_dir1/${database1}_${current_date}.sql"; then
    echo "TargetDB - Refreshed database: ${database1}"
else
    echo "Error: refresh of DB1 failed"
    error_flag=1
fi

# Backup & refresh DB2
if mysqldump --defaults-file="$mariadb_option_file" -h "$source_server" "$database2" > "$backup_dir2/${database2}_${current_date}.sql"; then
    echo "SourceDB - Exported database: ${database2}"
else
    echo "Error: backup of DB2 failed"
    error_flag=1
fi

if mysql --defaults-file="$mariadb_option_file" "$database2" < "$backup_dir2/${database2}_${current_date}.sql"; then
    echo "TargetDB - Refreshed database: ${database2}"
else
    echo "Error: refresh of DB2 failed"
    error_flag=1
fi


# Backup & refresh DB3_Essentials
if mysqldump --defaults-file="$mariadb_option_file" -h "$source_server" "$database3" $exclude_tables > "$backup_dir3/${database3}_${current_date}.sql"; then
    echo "SourceDB - Exported DB3_Essentials"
else
    echo "Error: backup of DB3_Essentials failed"
    error_flag=1
fi

if mysql --defaults-file="$mariadb_option_file" "$database3" < "$backup_dir3/${database3}_${current_date}.sql"; then
    echo "TargetDB - Refreshed DB3_Essentials"
else
    echo "Error: refresh of DB3_Essentials failed"
    error_flag=1
fi

# Check if any errors occurred during the mysqldump commands
if [ $error_flag -eq 0 ]; then
    echo "Databases refreshed successfully."
else
    echo "Errors with database backups and/or refresh."
fi