# macOS Battery Cycle History Checker

This guide shows how to check your MacBook's battery cycle count history using built-in macOS system databases.

## Quick Check: Current Cycle Count

To see your current battery cycle count:

```bash
system_profiler SPPowerDataType | grep -i "cycle count"
```

## Historical Cycle Data

macOS maintains detailed battery history in system databases. Here's how to access it:

### Method 1: Manual Database Query

The battery data is stored in SQLite databases at `/var/db/powerlog/Library/BatteryLife/`:

```bash
# Query current database for cycle history
sqlite3 /var/db/powerlog/Library/BatteryLife/CurrentPowerlog.PLSQL \
  'SELECT datetime(timestamp, "unixepoch", "localtime") as date, CycleCount 
   FROM PLBatteryAgent_EventNone_BatteryConfig 
   ORDER BY timestamp;'
```

### Method 2: Use the Provided Script

Download and run the `battery_history.sh` script for a cleaner output:

```bash
./battery_history.sh
```

## Understanding the Output

The output shows:
- **Date/Time**: When the cycle count was recorded
- **Cycle Count**: The battery cycle count at that time

A cycle count increases when you use 100% of your battery's capacity (doesn't have to be in one session).

## Battery Cycle Guidelines

- **MacBook Air/Pro (2020+)**: Up to 1000 cycles
- **Older MacBooks**: Typically 300-1000 cycles depending on model
- **Good health**: Cycle count well below the maximum for your model

## Files and Locations

- Current data: `/var/db/powerlog/Library/BatteryLife/CurrentPowerlog.PLSQL`
- Archived data: `/var/db/powerlog/Library/BatteryLife/Archives/`
- Data retention: Several weeks to months depending on system activity

## Notes

- The database contains detailed power management telemetry
- Data is readable without special permissions
- Historical data may be compressed in archive files
- Cycle count updates may not be immediate after each charge cycle

## Troubleshooting

If you get permission errors:
- The files should be readable by all users
- Try running from Terminal.app (not third-party terminals)

If no data appears:
- Your Mac may be very new (less than a few days old)
- Check if `/var/db/powerlog/Library/BatteryLife/` exists

## Related Commands

```bash
# Battery health percentage
system_profiler SPPowerDataType | grep -i "maximum capacity"

# Full power profile
system_profiler SPPowerDataType

# List available powerlog archives
ls -la /var/db/powerlog/Library/BatteryLife/Archives/
```