# Shahin AI Deployment Monitor & Auto-Correction Script
# Monitors deployment every 10 minutes and applies corrections if needed

param(
    [int]$IntervalMinutes = 10,
    [int]$DurationHours = 12,
    [string]$ProjectPath = ".",
    [switch]$AutoCorrect = $true
)

# Configuration
$LogFile = "deployment-monitor.log"
$ErrorLogFile = "deployment-errors.log"
$MaxRetries = 3
$VercelProjectName = "shahin-ai-business-analysis"

# Function to log messages
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"
    Write-Host $LogEntry
    Add-Content -Path $LogFile -Value $LogEntry
}

# Function to check deployment status
function Test-DeploymentStatus {
    try {
        Write-Log "Checking deployment status..."
        
        # Get latest deployment info
        $deploymentInfo = vercel ls --json | ConvertFrom-Json
        $latestDeployment = $deploymentInfo[0]
        
        if ($latestDeployment.state -eq "READY") {
            Write-Log "Deployment is READY: $($latestDeployment.url)" "SUCCESS"
            
            # Test the actual website
            $response = Invoke-WebRequest -Uri $latestDeployment.url -Method Head -TimeoutSec 30
            if ($response.StatusCode -eq 200) {
                Write-Log "Website is responding correctly (HTTP $($response.StatusCode))" "SUCCESS"
                return $true
            } else {
                Write-Log "Website returned HTTP $($response.StatusCode)" "WARNING"
                return $false
            }
        } else {
            Write-Log "Deployment state: $($latestDeployment.state)" "WARNING"
            return $false
        }
    }
    catch {
        Write-Log "Error checking deployment: $($_.Exception.Message)" "ERROR"
        Add-Content -Path $ErrorLogFile -Value "$(Get-Date): $($_.Exception.Message)"
        return $false
    }
}

# Function to auto-correct deployment issues
function Invoke-AutoCorrection {
    param([int]$AttemptNumber = 1)
    
    Write-Log "Starting auto-correction attempt #$AttemptNumber..." "WARNING"
    
    try {
        # Check git status
        $gitStatus = git status --porcelain
        if ($gitStatus) {
            Write-Log "Found uncommitted changes, committing..." "INFO"
            git add -A
            git commit -m "Auto-correction: Fix deployment issues - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        }
        
        # Push to GitHub
        Write-Log "Pushing to GitHub..." "INFO"
        git push origin master
        
        # Wait a moment
        Start-Sleep -Seconds 5
        
        # Redeploy to Vercel
        Write-Log "Redeploying to Vercel..." "INFO"
        vercel --prod --yes
        
        # Wait for deployment to complete
        Write-Log "Waiting for deployment to complete..." "INFO"
        Start-Sleep -Seconds 30
        
        # Test again
        if (Test-DeploymentStatus) {
            Write-Log "Auto-correction successful!" "SUCCESS"
            return $true
        } else {
            Write-Log "Auto-correction attempt #$AttemptNumber failed" "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "Auto-correction failed: $($_.Exception.Message)" "ERROR"
        Add-Content -Path $ErrorLogFile -Value "$(Get-Date): Auto-correction failed: $($_.Exception.Message)"
        return $false
    }
}

# Function to send notification (placeholder for future enhancement)
function Send-Notification {
    param([string]$Message, [string]$Type = "INFO")
    Write-Log "NOTIFICATION [$Type]: $Message" "NOTIFICATION"
    # Future: Add email, Slack, or other notification methods here
}

# Main monitoring loop
function Start-DeploymentMonitoring {
    $StartTime = Get-Date
    $EndTime = $StartTime.AddHours($DurationHours)
    $TotalChecks = 0
    $SuccessfulChecks = 0
    $FailedChecks = 0
    $CorrectionAttempts = 0
    
    Write-Log "Starting deployment monitoring for $DurationHours hours with $IntervalMinutes minute intervals" "INFO"
    Write-Log "Monitoring will end at: $($EndTime.ToString('yyyy-MM-dd HH:mm:ss'))" "INFO"
    
    while ((Get-Date) -lt $EndTime) {
        $TotalChecks++
        Write-Log "=== Check #$TotalChecks ===" "INFO"
        
        if (Test-DeploymentStatus) {
            $SuccessfulChecks++
            Write-Log "Deployment check passed ✓" "SUCCESS"
        } else {
            $FailedChecks++
            Write-Log "Deployment check failed ✗" "ERROR"
            
            if ($AutoCorrect -and $CorrectionAttempts -lt $MaxRetries) {
                $CorrectionAttempts++
                if (Invoke-AutoCorrection -AttemptNumber $CorrectionAttempts) {
                    Send-Notification "Auto-correction successful after deployment failure" "SUCCESS"
                } else {
                    Send-Notification "Auto-correction failed - manual intervention may be required" "ERROR"
                }
            } else {
                Send-Notification "Deployment failed and auto-correction is disabled or max retries reached" "ERROR"
            }
        }
        
        # Calculate next check time
        $NextCheck = (Get-Date).AddMinutes($IntervalMinutes)
        Write-Log "Next check scheduled for: $($NextCheck.ToString('HH:mm:ss'))" "INFO"
        Write-Log "Statistics: $SuccessfulChecks successful, $FailedChecks failed, $CorrectionAttempts corrections" "INFO"
        
        # Wait for the interval (unless it's the last iteration)
        if ((Get-Date).AddMinutes($IntervalMinutes) -lt $EndTime) {
            Start-Sleep -Seconds ($IntervalMinutes * 60)
        }
    }
    
    # Final summary
    Write-Log "=== MONITORING COMPLETE ===" "INFO"
    Write-Log "Total checks: $TotalChecks" "INFO"
    Write-Log "Successful: $SuccessfulChecks" "INFO"
    Write-Log "Failed: $FailedChecks" "INFO"
    Write-Log "Auto-corrections: $CorrectionAttempts" "INFO"
    $successRate = if ($TotalChecks -gt 0) { [math]::Round(($SuccessfulChecks / $TotalChecks) * 100, 2) } else { 0 }
    Write-Log "Success rate: $successRate%" "INFO"
    
    Send-Notification "Deployment monitoring completed. Success rate: $successRate%" "INFO"
}

# Initialize logging
Write-Log "Shahin AI Deployment Monitor Started" "INFO"
Write-Log "Parameters: Interval=$IntervalMinutes min, Duration=$DurationHours hours, AutoCorrect=$AutoCorrect" "INFO"

# Change to project directory
if (Test-Path $ProjectPath) {
    Set-Location $ProjectPath
    Write-Log "Changed to project directory: $(Get-Location)" "INFO"
} else {
    Write-Log "Project path not found: $ProjectPath" "ERROR"
    exit 1
}

# Verify required tools
try {
    $null = Get-Command git -ErrorAction Stop
    $null = Get-Command vercel -ErrorAction Stop
    Write-Log "Required tools (git, vercel) are available" "INFO"
} catch {
    Write-Log "Required tools not found. Please install git and vercel CLI" "ERROR"
    exit 1
}

# Start monitoring
Start-DeploymentMonitoring

Write-Log "Deployment monitoring script completed" "INFO"