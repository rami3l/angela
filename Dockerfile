FROM mcr.microsoft.com/dotnet/sdk:6.0-alpine AS angela-builder
WORKDIR /app

# Copy csproj and restore as distinct layers
COPY *.fsproj ./
RUN dotnet restore

# Copy everything else and build
COPY ./* ./
RUN dotnet publish -c Release -o out

# Build runtime image
FROM mcr.microsoft.com/dotnet/aspnet:6.0-alpine as angela
WORKDIR /app
COPY --from=angela-builder /app/out .
ENTRYPOINT ["dotnet", "Angela.dll"]
