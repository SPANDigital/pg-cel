# CI/CD Container Isolation Issue Analysis

## Problem Statement
The pg-cel extension builds and installs successfully on the GitHub Actions host, but the PostgreSQL service container cannot find the extension files due to container filesystem isolation.

## Root Cause
- GitHub Actions runs steps on the host filesystem
- PostgreSQL service container has its own isolated filesystem
- Extension files installed on host are not visible inside the container
- Service containers don't share volumes with the host by default

## Current Workflow Issues
1. **Build Step**: Runs on host, creates artifacts on host filesystem
2. **Install Step**: Installs to host PostgreSQL directories (not container)
3. **Test Step**: Connects to service container which can't see host-installed extension

## Solution Approaches

### Option 1: Use Docker Exec (Recommended)
Build and install the extension inside the service container using `docker exec`.

### Option 2: Custom Docker Image
Create a custom PostgreSQL image with pg-cel pre-installed.

### Option 3: Volume Mounting
Mount host directories into the service container (not directly supported by GitHub Actions).

### Option 4: Container-Based Workflow
Use a single Docker container for both PostgreSQL and testing.

## Implementation Plan: Docker Exec Approach

### Step 1: Build on Host
Keep the current build process on the host to leverage the existing toolchain.

### Step 2: Copy to Container
Use `docker cp` to copy build artifacts into the service container.

### Step 3: Install in Container
Use `docker exec` to run the install process inside the container.

### Step 4: Test in Container
Run tests against the service container with the extension installed.

## Workflow Changes Required

```yaml
- name: Copy extension to container
  run: |
    # Get the container ID
    CONTAINER_ID=$(docker ps --filter "ancestor=postgres:${{ matrix.postgres-version }}" --format "{{.ID}}")
    
    # Copy build artifacts to container
    docker cp pg_cel.so $CONTAINER_ID:/tmp/
    docker cp pg_cel.control $CONTAINER_ID:/tmp/
    docker cp pg_cel--*.sql $CONTAINER_ID:/tmp/

- name: Install extension in container
  run: |
    CONTAINER_ID=$(docker ps --filter "ancestor=postgres:${{ matrix.postgres-version }}" --format "{{.ID}}")
    
    # Install PostgreSQL dev tools in container
    docker exec $CONTAINER_ID apt-get update
    docker exec $CONTAINER_ID apt-get install -y postgresql-server-dev-${{ matrix.postgres-version }}
    
    # Install extension files
    docker exec $CONTAINER_ID cp /tmp/pg_cel.so $(pg_config --pkglibdir)/
    docker exec $CONTAINER_ID cp /tmp/pg_cel.control $(pg_config --sharedir)/extension/
    docker exec $CONTAINER_ID cp /tmp/pg_cel--*.sql $(pg_config --sharedir)/extension/
```

## Alternative: Dockerfile Approach

Create a custom Dockerfile that extends the official PostgreSQL image:

```dockerfile
FROM postgres:$PG_VERSION

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    postgresql-server-dev-$PG_VERSION \
    golang-1.24

# Copy source code
COPY . /src

# Build and install pg-cel
WORKDIR /src
RUN make && make install

# Clean up
RUN apt-get remove -y build-essential && apt-get autoremove -y
```

## Risk Assessment

### Docker Exec Approach
- **Pros**: Leverages existing build process, minimal workflow changes
- **Cons**: Requires container manipulation, potential security issues

### Custom Image Approach  
- **Pros**: Clean separation, reproducible, cacheable
- **Cons**: Requires maintaining Dockerfiles, longer build times

## Recommendation

Implement the **Docker Exec approach** as the immediate solution because:

1. **Minimal Changes**: Can reuse most of the existing workflow
2. **Fast Implementation**: Does not require creating and maintaining Dockerfiles
3. **Debugging**: Easier to debug and iterate on
4. **Flexibility**: Can still test against multiple PostgreSQL versions

The Custom Image approach can be considered for the future as a more robust long-term solution.

## Next Steps

1. Modify the GitHub Actions workflow to implement Docker Exec approach
2. Test the new workflow across all PostgreSQL versions (14, 15, 16, 17)
3. Verify BDD tests pass in the CI environment
4. Document the solution for future reference

## Timeline

- **Implementation**: 1-2 hours
- **Testing**: 1 hour per PostgreSQL version
- **Documentation**: 30 minutes
- **Total**: ~6 hours

This solution should resolve the container isolation issue and enable the BDD tests to run successfully in CI/CD.
