# Advanced PowerShell Script for Installing DBeaver and Configuring PostgreSQL Connection

# Variables
$downloadUrl = "https://dbeaver.io/files/dbeaver-ce-latest-x86_64-setup.exe"
$installerPath = "C:\Temp\dbeaver-installer.exe"
$dbeaverConfigDir = "$env:APPDATA\DBeaverData\workspace6\.dbeaver"
$logFile = "C:\Temp\DBeaverInstallLog.txt"

# Function to Log Messages
function Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp : $message" | Out-File -Append -FilePath $logFile
    Write-Host $message
}

# Prompt User for Database Details
$dbHost = Read-Host "Enter your PostgreSQL Host"
$dbPort = Read-Host "Enter your PostgreSQL Port (default 5432)" -DefaultValue "5432"
$dbName = Read-Host "Enter your PostgreSQL Database Name"
$dbUser = Read-Host "Enter your PostgreSQL Username"
$dbPassword = Read-Host "Enter your PostgreSQL Password" -AsSecureString

# Convert Secure Password to Plain Text (use cautiously in production environments)
$passwordPlainText = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($dbPassword))

# Ensure Temp directory exists
if (-not (Test-Path "C:\Temp")) {
    New-Item -ItemType Directory -Path "C:\Temp" | Out-Null
    Log "Created Temp directory."
}

# Download DBeaver Installer
try {
    Log "Downloading DBeaver installer..."
    Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing
    Log "DBeaver installer downloaded successfully."
} catch {
    Log "Error downloading DBeaver installer: $_"
    throw
}

# Install DBeaver Silently
try {
    Log "Installing DBeaver silently..."
    Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait
    Log "DBeaver installed successfully."
} catch {
    Log "Error during DBeaver installation: $_"
    throw
}

# Create PostgreSQL Connection Configuration
try {
    Log "Configuring PostgreSQL connection for DBeaver..."
    $configXml = @"
<project xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <name>Connections</name>
  <version>1</version>
  <connection-type>
    <type-id>postgresql</type-id>
    <host>$dbHost</host>
    <port>$dbPort</port>
    <database>$dbName</database>
    <username>$dbUser</username>
    <password>$passwordPlainText</password>
    <secure-storage>false</secure-storage>
  </connection-type>
</project>
"@

    # Ensure DBeaver config directory exists
    if (-not (Test-Path $dbeaverConfigDir)) {
        New-Item -ItemType Directory -Path $dbeaverConfigDir -Force | Out-Null
        Log "Created DBeaver configuration directory."
    }

    # Write Configuration File
    $configPath = Join-Path $dbeaverConfigDir "Connections.xml"
    $configXml | Out-File -FilePath $configPath -Encoding UTF8
    Log "PostgreSQL connection configured successfully."
} catch {
    Log "Error configuring PostgreSQL connection: $_"
    throw
}

# Cleanup Installer
try {
    Log "Cleaning up installer..."
    Remove-Item $installerPath -Force
    Log "Installer cleaned up successfully."
} catch {
    Log "Error during cleanup: $_"
    throw
}

Log "DBeaver installation and configuration completed successfully!"
