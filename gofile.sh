#!/bin/bash

#Original: https://github.com/sethbang/gofile-cl
#Retofitted by The_SamminAter

# Default values
LOGGING_ENABLED=false
LOG_FILE="gofile_upload.log"
default_directory="./"
default_folderid=""
recursive=false
os_type=""
min_size=""
delete_after_upload=false
move_after_upload=false

# Function to handle logging
log() {
    if [ "$LOGGING_ENABLED" = true ]; then
        tee -a "$LOG_FILE"
    else
        cat
    fi
}

# Function to create or update the config file
update_config() {
    local token="$1"
    echo "auth_token=\"$token\"" > "$config_file"
    chmod 600 "$config_file"
    echo "Auth token updated in $config_file" | log
}

# Config file location
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    config_file="$USERPROFILE/.gofile_config"
else
    config_file="$HOME/.gofile_config"
fi

# Initialize auth_token
auth_token=""

# Check if config file exists, if so, source it
# shellcheck source=/dev/null
if [ -f "$config_file" ]; then
    source "$config_file"
fi

#Tricky tricky
if [[ $# == 0 ]]
then
    $0 --help
    exit 1
fi

# Parse command-line arguments
while getopts ":d:a:f:ro:u:s:Xml" opt; do
  case $opt in
    d) directory="$OPTARG" ;;
    a) auth_token="$OPTARG" ;;
    f) folderid="$OPTARG" ;;
    r) recursive=true ;;
    o) os_type="$OPTARG" ;;
    u) echo "Please enter your new GoFile auth token:" | log
       read -r new_token
       update_config "$new_token"
       exit 0 ;;
    s) min_size="$OPTARG" ;;
    X) delete_after_upload=true ;;
    m) move_after_upload=true ;;
    l) LOGGING_ENABLED=true ;;
    \?) echo "Invalid option -$OPTARG" >&2 | log
        echo "Usage: $0 [-d directory] [-a auth_token] [-f folderid] [-r] [-o os_type] [-u] [-s min_size] [-X] [-m] [-l]" | log
        echo "Alternative usage: $0 [file(s)/director(ies)]" | log
        exit 1 ;;
  esac
done

# Use defaults if not provided
directory="${directory:-$default_directory}"
folderid="${folderid:-$default_folderid}"

# Check if auth_token is set, if not, exit with an error
if [[ "$1" == "-a" &&  -z "$auth_token" ]]; then
    echo "Error: No auth token provided. Please set it in the config file or use the -a flag." | log
    exit 1
fi
#We can just leave auth_token as blank, and detect that later

# Confirmation for delete option
if [ "$delete_after_upload" = true ]; then
    echo "WARNING: The delete option (-X) will permanently remove files after successful upload." | log
    echo "To confirm, please type exactly: 'I understand and accept the risk of deleting files'" | log
    read -r confirmation
    if [ "$confirmation" != "I understand and accept the risk of deleting files" ]; then
        echo "Confirmation failed. Exiting without deleting files." | log
        exit 1
    fi
fi

# Confirmation for move option
if [ "$move_after_upload" = true ]; then
    echo "The move option (-m) will move files to a 'completed' folder after successful upload." | log
    echo "To confirm, please type exactly: 'I confirm the file movement'" | log
    read -r confirmation
    if [ "$confirmation" != "I confirm the file movement" ]; then
        echo "Confirmation failed. Exiting without moving files." | log
        exit 1
    fi
    # Create 'completed' folder if it doesn't exist
    mkdir -p "${directory}/completed"
fi

# Detect OS if not specified
if [ -z "$os_type" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        os_type="macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        os_type="linux"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        os_type="windows"
    else
        echo "Unsupported OS. Please specify using -o option (macos, linux, or windows)." | log
        exit 1
    fi
fi

# Function to get available 'na' server
#Why specifically na?
get_na_server() {
    local max_attempts=16
    local attempt=1
    local server_info
    local na_server

    while [ $attempt -le $max_attempts ]; do
        if ! server_info=$(curl -s -X GET 'https://api.gofile.io/servers'); then
            if [ $attempt -le 5 ]; then
                echo "Failed to fetch server info. Retrying in 60 seconds (attempt $attempt of $max_attempts)..." >&2 | log
                sleep_time=60
            else
                echo "Failed to fetch server info. Retrying in 300 seconds (attempt $attempt of $max_attempts)..." >&2 | log
                sleep_time=300
            fi
            echo "You can force quit the script with Ctrl+C if needed." >&2 | log
            sleep $sleep_time
            ((attempt++))
            continue
        fi

        na_server=$(echo "$server_info" | jq -r '.data.servers[] | select(.zone == "na") | .name' | head -n 1) #Not sure why we only use na?
        if [ -n "$na_server" ]; then
            echo "$na_server"
            return 0
        fi

        eu_server=$(echo "$server_info" | jq -r '.data.servers[] | select(.zone == "eu") | .name' | head -n 1) #Not sure why we only use na?
        if [ -n "$eu_server" ]; then
            echo "$eu_server"
            return 0
        fi

        if [ $attempt -le 5 ]; then
            echo "No 'na' or 'eu' servers available. Retrying in 60 seconds (attempt $attempt of $max_attempts)..." >&2 | log
            sleep_time=60
        else
            echo "No 'na' or 'eu' servers available. Retrying in 300 seconds (attempt $attempt of $max_attempts)..." >&2 | log
            sleep_time=300
        fi
        echo "You can force quit the script with Ctrl+C if needed." >&2 | log
        sleep $sleep_time
        ((attempt++))
    done

    echo "Failed to get an 'na' server after $max_attempts attempts. Exiting." >&2 | log
    exit 1
}

# Function to format time
format_time() {
    local seconds=$1
    printf "%02d:%02d:%02d" $((seconds/3600)) $((seconds%3600/60)) $((seconds%60))
}

# Function to format file size
format_size() {
    local size=$1
    if [ $size -ge 1073741824 ]; then
        awk -v size="$size" 'BEGIN {printf "%.2f GB", size/1073741824}'
    elif [ $size -ge 1048576 ]; then
        awk -v size="$size" 'BEGIN {printf "%.2f MB", size/1048576}'
    else
        echo "$size bytes"
    fi
}

# Function to convert size to bytes
convert_to_bytes() {
    local size="$1"
    local unit="${size: -2}"
    local value="${size%??}"

    case "$unit" in
        KB|kb) echo $((value * 1024)) ;;
        MB|mb) echo $((value * 1024 * 1024)) ;;
        *) echo "$size" ;;
    esac
}

# Set find options based on recursive flag, OS, and min_size
if [ -n "$min_size" ]; then
    min_size_bytes=$(convert_to_bytes "$min_size")
    size_option="-size +${min_size_bytes}c"
else
    size_option=""
fi

if [ "$recursive" = true ]; then
    find_opts="-type f $size_option ! -name '.*' ! -name 'SYNOINDEX_*'"
else
    find_opts="-maxdepth 1 -type f $size_option ! -name '.*' ! -name 'SYNOINDEX_*'"
fi

# Initialize counters
current_file=0
uploaded_size=0

# Create a temporary file to store sorted file list
temp_file=$(mktemp)
trap 'rm -f "$temp_file"' EXIT

# Sort files by size and save to temporary file
#My addition to allow for direct file uploading
individual=false

if [[ -f "$1" ]]
then
    individual=true
    if [[ -f "$2" ]]
    then
        for arg in "$@"
        do
            file="$arg"
            if [ "$os_type" = "macos" ]
            then
                file_size=$(stat -f%z "$file")
            else
                file_size=$(stat -c%s "$file")
            fi
            echo "$file_size $file"
        done | sort -n | cut -d' ' -f2- > "$temp_file"
    else
        file="$1"
        if [ "$os_type" = "macos" ]
        then
            file_size=$(stat -f%z "$file")
        else
            file_size=$(stat -c%s "$file")
        fi
        echo "$file_size $file" | cut -d' ' -f2- > "$temp_file"
    fi
else
    if [[ -d "$1" ]]
    then
        directory="$1"
        if [[ -d "$2" ]]
        then
            trap 'rm -f "$temp_file" && $0 "${@:2}"' EXIT #Yes, I know this is re-doing work that was already done, but this trap overrides the last one
        fi
    fi
    if [ "$os_type" = "macos" ]; then
        eval find "$directory" "$find_opts" -print0 | while IFS= read -r -d '' file; do
      file_size=$(stat -f%z "$file")
        echo "$file_size $file"
        done | sort -n | cut -d' ' -f2- > "$temp_file"
    else
        eval find "$directory" "$find_opts" -print0 | while IFS= read -r -d '' file; do
      file_size=$(stat -c%s "$file")
        echo "$file_size $file"
        done | sort -n | cut -d' ' -f2- > "$temp_file"
    fi
fi

# Get total number of files and size
#Until the else is my retrofitting
total_size=0
if [[ $individual = true ]]
then
    total_size=0
    for arg in "$@"
    do
        file="$arg"
        if [ "$os_type" = "macos" ]
        then
            ((total_size += $(stat -f%z "$file")))
        else
            ((total_size += $(stat -c%s "$file")))
        fi
    done
    total_files=$#
else
    if [ "$os_type" = "macos" ]; then
        total_files=$(eval find "$directory" "$find_opts" | wc -l)
        total_size=$(eval find "$directory" "$find_opts" -print0 | xargs -0 stat -f%z | awk '{sum+=$1} END {print sum}')
    else
        total_files=$(eval find "$directory" "$find_opts" | wc -l)
        total_size=$(eval find "$directory" "$find_opts" -print0 | xargs -0 stat -c%s | awk '{sum+=$1} END {print sum}')
    fi
fi

# Read from the temporary file and process each file
while read -r file; do
  if [ -f "$file" ]; then
    ((current_file++))
    file_name=$(basename "$file")
    if [ "$os_type" = "macos" ]; then
        file_size=$(stat -f%z "$file")
    else
        file_size=$(stat -c%s "$file")
    fi
    
    formatted_size=$(format_size "$file_size")
    echo "==========================================" | log
    echo "Uploading file $current_file of $total_files: $file_name ($formatted_size)" | log
    echo "Overall progress: $((uploaded_size * 100 / total_size))% completed" | log
    
    # Get the 'na' server for this upload
    storenum=$(get_na_server)
    echo "Using server: $storenum" | log
    
    # GoFile API endpoint
    url="https://$storenum.gofile.io/contents/uploadfile"
    
    start_time=$(date +%s)
    
    #Here's my add-on for anonymous uploads
    if [[ "${auth_token}" == "" ]]
    then
        curl_output=$(curl -X POST "$url" \
            -F "file=@$file" \
            --progress-bar)
        #echo "curl -X POST $url -F file=@$file --progress-bar"
    else
        curl_output=$(curl -X POST "$url" \
            -H "Authorization: Bearer $auth_token" \
            -F "file=@$file" \
            -F "folderId=$folderid" \
            --progress-bar)
    fi

    end_time=$(date +%s)
    duration=$((end_time - start_time))
    uploaded_size=$((uploaded_size + file_size))
    
    upload_status=$(echo "$curl_output" | jq -r '.status')
    download_page=$(echo "$curl_output" | jq -r '.data.downloadPage')
    
    echo | log
    if [ "$upload_status" == "ok" ]; then
      echo "Uploaded $file_name successfully!" | log
      echo "Time taken: $(format_time $duration)" | log
      echo "Download Page: $download_page" | log
      
      if [ "$delete_after_upload" = true ]; then
        rm "$file"
        echo "File deleted: $file_name" | log
      elif [ "$move_after_upload" = true ]; then
        mv "$file" "${directory}/completed/"
        echo "File moved to completed folder: $file_name" | log
      fi
    else
      echo "Failed to upload $file_name" | log
      echo "Error: $curl_output" | log
    fi
    
    echo "Overall progress: $((uploaded_size * 100 / total_size))% completed" | log
    echo "==========================================" | log
    echo | log
  fi
done < "$temp_file"

total_formatted_size=$(format_size "$total_size")
echo "All files uploaded. Total size: $total_formatted_size. Total time: $(format_time $SECONDS)" | log
