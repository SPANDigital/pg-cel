# Installation Guide

This guide provides detailed installation instructions for the pg-cel PostgreSQL extension across different platforms.

## Prerequisites

- PostgreSQL 14, 15, 16, or 17
- Administrative/sudo access for installation
- Compatible operating system (Linux or macOS)

## Download

Visit the [Releases page](https://github.com/SPANDigital/pg-cel/releases) and download the appropriate package for your platform and PostgreSQL version:

- `pg-cel-linux-pg15.tar.gz` - Linux with PostgreSQL 15
- `pg-cel-linux-pg16.tar.gz` - Linux with PostgreSQL 16
- `pg-cel-macos-pg15.tar.gz` - macOS with PostgreSQL 15
- `pg-cel-macos-pg16.tar.gz` - macOS with PostgreSQL 16

## Installation

### Linux (Ubuntu/Debian)

1. **Extract the package:**
   ```bash
   tar -xzf pg-cel-linux-pg16.tar.gz
   ```

2. **Find PostgreSQL directories:**
   ```bash
   pg_config --pkglibdir   # Extension library directory
   pg_config --sharedir    # Share directory
   ```

3. **Install the extension files:**
   ```bash
   # Copy the shared library
   sudo cp pg_cel.so $(pg_config --pkglibdir)/
   
   # Copy the control and SQL files
   sudo cp pg_cel.control $(pg_config --sharedir)/extension/
   sudo cp pg_cel--1.0.sql $(pg_config --sharedir)/extension/
   ```

4. **Set correct permissions:**
   ```bash
   sudo chmod 755 $(pg_config --libdir)/pg_cel.so
   sudo chmod 644 $(pg_config --sharedir)/extension/pg_cel.control
   sudo chmod 644 $(pg_config --sharedir)/extension/pg_cel--1.0.sql
   ```

### macOS

1. **Extract the package:**
   ```bash
   tar -xzf pg-cel-macos-pg16.tar.gz
   ```

2. **Install the extension files:**
   ```bash
   # Copy the shared library (could be .dylib or .so)
   if [ -f pg_cel.dylib ]; then
     sudo cp pg_cel.dylib $(pg_config --pkglibdir)/
   elif [ -f pg_cel.so ]; then
     sudo cp pg_cel.so $(pg_config --pkglibdir)/
   fi
   
   # Copy the control and SQL files
   sudo cp pg_cel.control $(pg_config --sharedir)/extension/
   sudo cp pg_cel--1.0.sql $(pg_config --sharedir)/extension/
   ```

3. **Set correct permissions:**
   ```bash
   # For dylib
   [ -f $(pg_config --pkglibdir)/pg_cel.dylib ] && sudo chmod 755 $(pg_config --pkglibdir)/pg_cel.dylib
   # For so
   [ -f $(pg_config --pkglibdir)/pg_cel.so ] && sudo chmod 755 $(pg_config --pkglibdir)/pg_cel.so
   
   sudo chmod 644 $(pg_config --sharedir)/extension/pg_cel.control
   sudo chmod 644 $(pg_config --sharedir)/extension/pg_cel--1.0.sql
   ```

## Enable the Extension

1. **Connect to your PostgreSQL database:**
   ```bash
   psql -U your_username -d your_database
   ```

2. **Create the extension:**
   ```sql
   CREATE EXTENSION pg_cel;
   ```

3. **Verify installation:**
   ```sql
   SELECT cel_eval('2 + 3') AS result;
   ```
   
   Expected output:
   ```
    result 
   --------
    5
   (1 row)
   ```

## Configuration (Optional)

You can configure cache sizes in your `postgresql.conf`:

```
# pg-cel configuration
pg_cel.program_cache_size_mb = 256  # Default: 256MB
pg_cel.json_cache_size_mb = 128     # Default: 128MB
```

After modifying the configuration, restart PostgreSQL:

```bash
# Linux (systemd)
sudo systemctl restart postgresql

# macOS (Homebrew)
brew services restart postgresql@16
```

## Testing

Run a few test queries to ensure everything is working:

```sql
-- Basic arithmetic
SELECT cel_eval('2 + 3 * 4') AS arithmetic;

-- String operations with JSON
SELECT cel_eval_json('"Hello " + name', '{"name": "World"}') AS greeting;

-- Boolean logic
SELECT cel_eval_bool('age >= 18 && verified', '{"age": 25, "verified": true}') AS is_adult;

-- Cache statistics
SELECT cel_cache_stats();
```

## Troubleshooting

### Extension not found
- Verify files are in the correct directories using `pg_config --libdir` and `pg_config --sharedir`
- Check file permissions (executable for .so/.dylib, readable for .control/.sql)
- Restart PostgreSQL service

### Permission denied
- Ensure you have administrative privileges when copying files
- Check that PostgreSQL can read the extension files

### Version mismatch
- Ensure you downloaded the package matching your PostgreSQL version
- Check your PostgreSQL version with `SELECT version();`

### Build from source (alternative)
If pre-built packages don't work, you can build from source:

```bash
git clone https://github.com/your-username/pg-cel.git
cd pg-cel
./build.sh install
```

## Uninstalling

To remove the extension:

1. **Drop the extension from databases:**
   ```sql
   DROP EXTENSION IF EXISTS pg_cel;
   ```

2. **Remove files:**
   ```bash
   # Linux
   sudo rm $(pg_config --libdir)/pg_cel.so
   sudo rm $(pg_config --sharedir)/extension/pg_cel.control
   sudo rm $(pg_config --sharedir)/extension/pg_cel--1.0.sql
   
   # macOS
   rm $(pg_config --libdir)/pg_cel.dylib
   rm $(pg_config --sharedir)/extension/pg_cel.control
   rm $(pg_config --sharedir)/extension/pg_cel--1.0.sql
   ```

## Support

For issues, questions, or contributions, please visit our [GitHub repository](https://github.com/your-username/pg-cel).
