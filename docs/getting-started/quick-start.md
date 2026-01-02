# Quick Start

Fastest way to get TimeBeam running locally. This guide assumes you have basic development tools installed (Java, Maven, Xcode, Git).

## ⚡ Backend Quick Start

### 1. Start PostgreSQL (using Docker)
```bash
cd back-end
docker-compose up -d
```

This starts PostgreSQL on port 5432.

### 2. Set environment variables
```bash
export SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/timebeam
export SPRING_DATASOURCE_USERNAME=timebeam
export SPRING_DATASOURCE_PASSWORD=timebeam
export JWT_SECRET=change-me-to-a-secure-random-string-very-long
```

### 3. Run backend
```bash
cd back-end
mvn spring-boot:run
```

Backend API will be available at: **http://localhost:8080**

✅ **Backend is ready!**

---

## 🍎 Frontend Quick Start

### 1. Open Xcode
```bash
cd apple/TimeBeam
open TimeBeam.xcodeproj
```

### 2. Select simulator
In Xcode, choose a simulator (e.g., iPhone 15 Pro).

### 3. Build and run
Press **Cmd+R** in Xcode or click the Play button.

✅ **Frontend is ready!**

---

## 🎉 Verify Everything Works

### Test Timer
1. Tap the Start button on the timer
2. Verify the timer counts down
3. Tap Pause to pause the timer
4. Tap Reset to reset the timer

### Test Analytics
1. Tap the Analytics tab
2. Verify charts display correctly
3. Check daily and weekly statistics

### Test Settings
1. Tap the Settings tab
2. Verify timer settings are configurable
3. Check Google Sign-In option (if configured)

### Test API Communication
1. Open developer tools in browser
2. Navigate to `http://localhost:8080/swagger-ui.html` (if OpenAPI enabled)
3. Try calling API endpoints directly

---

## 📚 Next Steps

### For Backend Developers
- Read [Backend API Reference](../implementation-guides/backend/api-reference.md)
- Review [Backend Code Style](../codestyle/java.md)
- Check [Testing Standards](../codestyle/testing-backend.md)

### For Frontend Developers
- Read [iOS Implementation Checklist](../implementation-guides/ios/client-implementation-checklist.md)
- Review [Frontend Code Style](../codestyle/swift.md)
- Check [Testing Standards](../codestyle/testing-frontend.md)
- Follow [Timer Sync Implementation Guide](../implementation-guides/ios/timer-sync-implementation.md)

### For Both
- Review [Architecture Overview](../architecture/overview.md)
- Check [Code Style & Standards](../codestyle/)
- Understand [MVP Feature Checklist](../features/mvp-checklist.md)
- Read [AGENTS Configuration](../../AGENTS.md)

---

## 🐛 Quick Troubleshooting

### Backend Issues

**API not responding:**
- Check if backend is running: `curl http://localhost:8080/actuator/health`
- Verify PostgreSQL is running: `docker-compose ps`
- Check port 8080 is not in use: `lsof -i:8080`

**Database connection error:**
- Verify PostgreSQL container is running: `docker ps | grep postgres`
- Check database URL format
- Verify username/password in environment variables

### Frontend Issues

**App fails to build:**
- Clean build folder: Product > Clean Build Folder
- Verify Xcode version (15+)
- Check for missing dependencies

**App crashes on launch:**
- Check Xcode console for error messages
- Verify Info.plist configuration
- Review app entitlements

**Google Sign-In not working:**
- Verify Google Sign-In SDK is configured
- Check Client IDs in Xcode project
- Review OAuth consent screen configuration

---

## 💡 Development Tips

### Backend
- Use `mvn spring-boot:run` for development (auto-reload on changes)
- Run `mvn test` frequently during development
- Check logs in `back-end/logs/timebeam.log` for debugging

### Frontend
- Use SwiftUI preview for rapid UI iteration
- Test on multiple simulator sizes
- Use breakpoints in Xcode for debugging
- Check logs for AppLogger output

### Both
- Commit frequently with descriptive messages
- Use feature branches for new development
- Write tests as you develop features
- Follow [Code Style & Standards](../codestyle/)

---

**Want more details?** Check out:
- [Complete Setup Guide](setup-guide.md)
- [Project Overview](project-overview.md)
- [All Documentation](../)

**Happy coding!** 🚀
