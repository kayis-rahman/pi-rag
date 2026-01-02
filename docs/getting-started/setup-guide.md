# Setup Guide

Complete setup guide for TimeBeam development environment.

## Backend Setup (Java Spring Boot)

### Prerequisites
- Java 17 or later
- Maven 3.8+
- PostgreSQL 15+ (or use H2 for tests)
- Docker (optional, for containerized development)

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd time-beam
   ```

2. **Navigate to backend directory**
   ```bash
   cd back-end
   ```

3. **Install dependencies**
   ```bash
   mvn clean install
   ```

4. **Configure database**
   ```bash
   # Using PostgreSQL (recommended for development)
   export SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/timebeam
   export SPRING_DATASOURCE_USERNAME=postgres
   export SPRING_DATASOURCE_PASSWORD=your_password
   export JWT_SECRET=change-me-to-a-secure-random-string

   # Or use H2 in-memory database for quick testing
   # (configured in test scope)
   ```

5. **Build the project**
   ```bash
   mvn clean package -DskipTests
   ```

6. **Run the application**
   ```bash
   # Using Maven
   mvn spring-boot:run

   # Or run packaged JAR
   java -jar target/timebeam-backend-0.0.1-SNAPSHOT.jar
   ```

### Docker Setup (Alternative)

Using Docker Compose for easy local development:

```bash
cd back-end
docker-compose up --build
```

The backend will be available at `http://localhost:8080`.

### Verify Setup

1. Open browser to `http://localhost:8080`
2. Check API documentation at `http://localhost:8080/swagger-ui.html` (if OpenAPI is enabled)
3. Run tests: `mvn test`

### Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| SPRING_DATASOURCE_URL | JDBC connection string | jdbc:postgresql://localhost:5432/timebeam |
| SPRING_DATASOURCE_USERNAME | Database username | postgres |
| SPRING_DATASOURCE_PASSWORD | Database password | your_password |
| JWT_SECRET | Secret for JWT token signing | change-me-to-a-long-secure-random-string |
| JWT_EXPIRATION_MS | Token lifetime in milliseconds | 86400000 (24 hours) |

### Troubleshooting

**Issue: Database connection fails**
- Check PostgreSQL is running: `pg_isready` or Docker status
- Verify connection string format
- Check firewall settings

**Issue: Maven build fails**
- Verify Java version: `java -version` (should be 17+)
- Clean Maven cache: `mvn clean`
- Check network connectivity to Maven Central

**Issue: Application starts but API returns 401**
- Verify JWT_SECRET is set
- Check token generation in auth endpoints
- Review application.yml for security configuration

## Frontend Setup (iOS/macOS/watchOS)

### Prerequisites
- macOS 13+ (for iOS development)
- Xcode 15+
- Apple Developer Account (for device testing and App Store deployment)
- iOS Simulator or physical device

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd time-beam
   ```

2. **Open Xcode project**
   ```bash
   cd apple/TimeBeam
   open TimeBeam.xcodeproj
   ```

3. **Install dependencies**
   - Xcode will automatically install dependencies when you open the project
   - Verify dependencies in Package.swift or Xcode project settings

4. **Configure Google Sign-In** (if not already done)
   - Follow [Google Sign-In Implementation Guide](../implementation-guides/ios/google-sign-in.md)
   - Set up Google Cloud Console
   - Configure OAuth consent screen
   - Add Client IDs to Xcode project

5. **Build and run**
   - Select target scheme (TimeBeam iOS, TimeBeam macOS, or TimeBeam Watch App)
   - Press Cmd+R to build and run

### Simulator Setup

1. Select simulator in Xcode (e.g., iPhone 15)
2. Wait for app to install and launch
3. Verify timer functionality works
4. Test settings and Google Sign-In

### Device Setup (for testing)

1. Connect your iOS/macOS/watchOS device
2. Trust developer certificate in Settings (if prompted)
3. Select your device as run target in Xcode
4. Build and run on device

### Verify Setup

1. Check that timer starts, pauses, and resets correctly
2. Verify Google Sign-In flow works end-to-end
3. Test navigation between screens
4. Check analytics display correctly
5. Test notification permissions

### Troubleshooting

**Issue: Xcode fails to build**
- Clean build folder: Product > Clean Build Folder
- Check for missing dependencies in project settings
- Update Xcode to latest version
- Restart Xcode

**Issue: Google Sign-In fails**
- Verify Google Sign-In SDK is properly integrated
- Check Client IDs in Xcode project settings
- Review OAuth configuration in Google Cloud Console
- Check network connectivity

**Issue: App crashes on launch**
- Check Info.plist configuration
- Verify app entitlements
- Review crash logs in Xcode console
- Check for missing required capabilities

## Shared Development (Both Frontend and Backend)

### Running Both Applications

1. **Start backend first** (in one terminal)
   ```bash
   cd back-end
   mvn spring-boot:run
   # or: docker-compose up
   ```

2. **Start frontend** (in another terminal/tab)
   - Open Xcode project
   - Select target and press Cmd+R

3. **Verify connectivity**
   - Frontend should successfully call backend APIs
   - Check logs for any connection errors

### Common Issues

**Issue: CORS errors when frontend calls backend**
- Add backend URL to frontend configuration
- Verify backend allows frontend origin in CORS configuration
- Check backend security settings

**Issue: Authentication fails**
- Verify JWT token is being sent correctly
- Check token expiration time
- Verify backend JWT_SECRET matches frontend (if applicable)

## Development Workflow

1. **Create feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make changes** following code style guidelines

3. **Run tests locally**
   ```bash
   # Backend
   cd back-end && mvn test

   # Frontend
   cd apple/TimeBeam && xcodebuild test
   ```

4. **Commit and push changes**
   ```bash
   git add .
   git commit -m "Description of your changes"
   git push origin feature/your-feature-name
   ```

5. **Create pull request** following project guidelines

## Next Steps

- Read [Project Overview](project-overview.md) for high-level understanding
- Review [Code Style & Standards](../codestyle/) before making changes
- Explore [Features Checklist](../features/mvp-checklist.md) for development priorities
- Check [AGENTS Configuration](../../AGENTS.md) for agent usage patterns

---

**Need help?** Check [Troubleshooting](#troubleshooting) sections or consult [Documentation Style Guide](../contributing/style-guide.md).
