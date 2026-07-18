# Build Stage
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy the project file
COPY ["ParkingManagement.csproj", "."]

# Restore NuGet packages
RUN dotnet restore "ParkingManagement.csproj"

# Copy entire project
COPY . .

# Build the application
RUN dotnet build "ParkingManagement.csproj" -c Release -o /app/build

# Publish Stage
FROM build AS publish
RUN dotnet publish "ParkingManagement.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime Stage
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

# Install curl for healthcheck
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Copy published files
COPY --from=publish /app/publish .

# Expose port
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8080/Website/Index || exit 1

# Run the application
ENTRYPOINT ["dotnet", "ParkingManagement.dll"]
