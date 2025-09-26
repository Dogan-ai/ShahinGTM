# Shahin AI - Start 12-Hour Deployment Monitoring
# Simple startup script for easy monitoring activation

param(
    [int]$Hours = 12,
    [int]$Minutes = 10,
    [switch]$NoAutoCorrect = $false
)

# Configuration
$ScriptTitle = "Shahin AI Deployment Monitor"
$ProjectPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Function to display banner
function Show-Banner {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                    SHAHIN AI DEPLOYMENT MONITOR             ║" -ForegroundColor Cyan
    Write-Host "║                     Automated Monitoring System             ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "🚀 Starting automated deployment monitoring..." -ForegroundColor Green
    Write-Host "📊 Duration: $Hours hours" -ForegroundColor Yellow
    Write-Host "⏱️  Interval: $Minutes minutes" -ForegroundColor Yellow
    Write-Host "🔧 Auto-correction: $(-not $NoAutoCorrect)" -ForegroundColor Yellow
    Write-Host "📁 Project: $ProjectPath" -ForegroundColor Yellow
    Write-Host ""
}

# Function to check prerequisites
function Test-Prerequisites {
    Write-Host "🔍 Checking prerequisites..." -ForegroundColor Blue
    
    $issues = @()
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        $issues += "PowerShell 5.0 or higher required"
    }
    
    # Check Git
    try {
        $null = Get-Command git -ErrorAction Stop
        Write-Host "  ✅ Git: Available" -ForegroundColor Green
    } catch {
        $issues += "Git not found"
        Write-Host "  ❌ Git: Not found" -ForegroundColor Red
    }
    
    # Check Vercel CLI
    try {
        $null = Get-Command vercel -ErrorAction Stop
        Write-Host "  ✅ Vercel CLI: Available" -ForegroundColor Green
    } catch {
        $issues += "Vercel CLI not found"
        Write-Host "  ❌ Vercel CLI: Not found" -ForegroundColor Red
    }
    
    # Check if in git repository
    try {
        $null = git status 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ Git Repository: Detected" -ForegroundColor Green
        } else {
            $issues += "Not in a git repository"
            Write-Host "  ❌ Git Repository: Not detected" -ForegroundColor Red
        }
    } catch {
        $issues += "Git repository check failed"
        Write-Host "  ❌ Git Repository: Check failed" -ForegroundColor Red
    }
    
    # Check monitoring script exists
    $monitorScript = Join-Path $ProjectPath "deploy-monitor.ps1"
    if (Test-Path $monitorScript) {
        Write-Host "  ✅ Monitor Script: Found" -ForegroundColor Green
    } else {
        $issues += "deploy-monitor.ps1 not found"
        Write-Host "  ❌ Monitor Script: Not found" -ForegroundColor Red
    }
    
    if ($issues.Count -gt 0) {
        Write-Host ""
        Write-Host "❌ Prerequisites check failed:" -ForegroundColor Red
        foreach ($issue in $issues) {
            Write-Host "   • $issue" -ForegroundColor Red
        }
        Write-Host ""
        Write-Host "Please fix these issues before starting monitoring." -ForegroundColor Yellow
        return $false
    }
    
    Write-Host "  ✅ All prerequisites met!" -ForegroundColor Green
    return $true
}

# Function to show monitoring options
function Show-MonitoringOptions {
    Write-Host ""
    Write-Host "📋 Monitoring Configuration:" -ForegroundColor Cyan
    Write-Host "   Duration: $Hours hours ($($Hours * 60) minutes total)" -ForegroundColor White
    Write-Host "   Check Interval: $Minutes minutes" -ForegroundColor White
    Write-Host "   Total Checks: $([math]::Floor(($Hours * 60) / $Minutes))" -ForegroundColor White
    Write-Host "   Auto-Correction: $(-not $NoAutoCorrect)" -ForegroundColor White
    Write-Host "   End Time: $((Get-Date).AddHours($Hours).ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor White
    Write-Host ""
}

# Function to confirm start
function Confirm-Start {
    Write-Host "⚠️  Important Notes:" -ForegroundColor Yellow
    Write-Host "   • Keep this PowerShell window open during monitoring" -ForegroundColor White
    Write-Host "   • Logs will be saved to deployment-monitor.log" -ForegroundColor White
    Write-Host "   • You can stop monitoring anytime with Ctrl+C" -ForegroundColor White
    Write-Host "   • Auto-correction will commit and deploy changes if needed" -ForegroundColor White
    Write-Host ""
    
    do {
        $response = Read-Host "🚀 Start monitoring now? (Y/N)"
        $response = $response.ToUpper()
    } while ($response -notin @('Y', 'YES', 'N', 'NO'))
    
    return $response -in @('Y', 'YES')
}

# Function to start monitoring
function Start-Monitoring {
    Write-Host ""
    Write-Host "🎯 Starting deployment monitoring..." -ForegroundColor Green
    Write-Host "📝 Monitor logs: deployment-monitor.log" -ForegroundColor Blue
    Write-Host "📝 Error logs: deployment-errors.log" -ForegroundColor Blue
    Write-Host ""
    Write-Host "Press Ctrl+C to stop monitoring at any time" -ForegroundColor Yellow
    Write-Host ""
    
    # Build parameters for monitor script
    $monitorParams = @{
        IntervalMinutes = $Minutes
        DurationHours = $Hours
        ProjectPath = $ProjectPath
    }
    
    if ($NoAutoCorrect) {
        $monitorParams.AutoCorrect = $false
    }
    
    # Start the monitoring script
    try {
        & (Join-Path $ProjectPath "deploy-monitor.ps1") @monitorParams
    } catch {
        Write-Host "❌ Monitoring failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Check the error logs for more details." -ForegroundColor Yellow
    }
}

# Main execution
try {
    # Show banner
    Show-Banner
    
    # Check prerequisites
    if (-not (Test-Prerequisites)) {
        Write-Host "Press any key to exit..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
    
    # Show monitoring options
    Show-MonitoringOptions
    
    # Confirm start
    if (Confirm-Start) {
        Start-Monitoring
    } else {
        Write-Host "❌ Monitoring cancelled by user." -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "✅ Monitoring session completed." -ForegroundColor Green
    Write-Host "📊 Check deployment-monitor.log for detailed results." -ForegroundColor Blue
    
} catch {
    Write-Host "❌ Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please check your setup and try again." -ForegroundColor Yellow
} finally {
    Write-Host ""
    Write-Host "Press any key to exit..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# End of script