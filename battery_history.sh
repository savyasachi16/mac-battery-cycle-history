#!/bin/bash

# macOS Battery Cycle History Checker
# Displays battery cycle count history from system databases

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Database paths
CURRENT_DB="/var/db/powerlog/Library/BatteryLife/CurrentPowerlog.PLSQL"
ARCHIVE_DIR="/var/db/powerlog/Library/BatteryLife/Archives"

print_header() {
    echo -e "${BLUE}=== macOS Battery Cycle History ===${NC}\n"
}

check_current_cycle() {
    echo -e "${YELLOW}Current Battery Cycle Count:${NC}"
    if command -v system_profiler >/dev/null 2>&1; then
        current_cycles=$(system_profiler SPPowerDataType | grep -i "cycle count" | awk '{print $3}' || echo "Unknown")
        echo -e "  ${GREEN}$current_cycles cycles${NC}\n"
    else
        echo -e "  ${RED}system_profiler not available${NC}\n"
    fi
}

query_database() {
    local db_path="$1"
    local db_name="$2"
    
    if [[ ! -f "$db_path" ]]; then
        return 1
    fi
    
    # Try to query the database
    local result
    result=$(sqlite3 "$db_path" \
        'SELECT datetime(timestamp, "unixepoch", "localtime") as date, CycleCount 
         FROM PLBatteryAgent_EventNone_BatteryConfig 
         ORDER BY timestamp;' 2>/dev/null || echo "")
    
    if [[ -n "$result" ]]; then
        echo -e "${YELLOW}$db_name:${NC}"
        echo "$result" | while IFS='|' read -r date cycles; do
            if [[ -n "$date" && -n "$cycles" ]]; then
                echo -e "  ${GREEN}$date${NC} - ${BLUE}$cycles cycles${NC}"
            fi
        done
        echo
        return 0
    fi
    
    return 1
}

query_compressed_archive() {
    local archive_path="$1"
    local archive_name="$2"
    
    if [[ ! -f "$archive_path" ]]; then
        return 1
    fi
    
    # Try to decompress and query
    local result
    result=$(gunzip -c "$archive_path" 2>/dev/null | \
            sqlite3 - \
            'SELECT datetime(timestamp, "unixepoch", "localtime") as date, CycleCount 
             FROM PLBatteryAgent_EventNone_BatteryConfig 
             ORDER BY timestamp LIMIT 20;' 2>/dev/null || echo "")
    
    if [[ -n "$result" ]]; then
        echo -e "${YELLOW}$archive_name (archived):${NC}"
        echo "$result" | while IFS='|' read -r date cycles; do
            if [[ -n "$date" && -n "$cycles" ]]; then
                echo -e "  ${GREEN}$date${NC} - ${BLUE}$cycles cycles${NC}"
            fi
        done
        echo
        return 0
    fi
    
    return 1
}

show_historical_data() {
    echo -e "${YELLOW}Historical Cycle Count Data:${NC}\n"
    
    local found_data=false
    
    # Query current database
    if query_database "$CURRENT_DB" "Current Database"; then
        found_data=true
    fi
    
    # Query archived databases if they exist
    if [[ -d "$ARCHIVE_DIR" ]]; then
        # Process uncompressed archives first
        for archive in "$ARCHIVE_DIR"/*.PLSQL; do
            if [[ -f "$archive" ]]; then
                archive_name=$(basename "$archive" .PLSQL)
                if query_database "$archive" "$archive_name"; then
                    found_data=true
                fi
            fi
        done
        
        # Process compressed archives
        for archive in "$ARCHIVE_DIR"/*.PLSQL.gz; do
            if [[ -f "$archive" ]]; then
                archive_name=$(basename "$archive" .PLSQL.gz)
                if query_compressed_archive "$archive" "$archive_name"; then
                    found_data=true
                fi
            fi
        done
    fi
    
    if [[ "$found_data" == false ]]; then
        echo -e "${RED}No historical cycle data found.${NC}"
        echo -e "${YELLOW}This might happen if:${NC}"
        echo "  - Your Mac is very new (less than a few days old)"
        echo "  - The powerlog system hasn't recorded cycle changes yet"
        echo "  - There are permission issues accessing the database"
    fi
}

show_summary() {
    echo -e "${YELLOW}Battery Health Tips:${NC}"
    echo "• Cycle count increases when you use 100% of battery capacity"
    echo "• Modern MacBooks support 1000+ cycles before significant degradation"
    echo "• Check Apple's specifications for your specific model"
    echo -e "\n${YELLOW}Database Locations:${NC}"
    echo "• Current: $CURRENT_DB"
    echo "• Archives: $ARCHIVE_DIR"
}

main() {
    print_header
    check_current_cycle
    show_historical_data
    echo
    show_summary
}

# Handle command line arguments
case "${1:-}" in
    -h|--help)
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  -h, --help    Show this help message"
        echo "  -c, --current Show only current cycle count"
        echo ""
        echo "This script displays your MacBook's battery cycle count history"
        echo "using data from macOS system databases."
        exit 0
        ;;
    -c|--current)
        print_header
        check_current_cycle
        exit 0
        ;;
    *)
        main
        ;;
esac