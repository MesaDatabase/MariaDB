#!/bin/bash

# Function to insert disk space information into MariaDB
insert_disk_space_info() {
    local directory="$1"
    local db_name="$2"
    
    # Run df command to get disk space information
    df_output=$(df -h "$directory")

    # Extract relevant information using awk
    size=$(echo "$df_output" | awk 'NR==2 {print $2}')
    used=$(echo "$df_output" | awk 'NR==2 {print $3}')
    avail=$(echo "$df_output" | awk 'NR==2 {print $4}')
    use_percent=$(echo "$df_output" | awk 'NR==2 {print $5}')
    mounted_on=$(echo "$df_output" | awk 'NR==2 {print $6}')

    # MariaDB connection parameters from option file
    mariadb_option_file="/etc/mysql/mariadb_client.cnf"

    # MariaDB query to insert data into the table
    query="INSERT INTO disk_space_info (size, used, avail, use_percent, mounted_on) VALUES ('$size', '$used', '$avail', '$use_percent', '$mounted_on');"

    # Run the query using the mariadb command-line tool with options from the option file
    echo "$query" | mariadb --defaults-extra-file=$mariadb_option_file $db_name
}

# Insert disk space information for /raid
insert_disk_space_info "/raid" "MariaMetrics"

# Insert disk space information for /backups
insert_disk_space_info "/backups" "MariaMetrics"
