# Quick Deploy Script for Shahin AI
# Performs immediate deployment with error checking and corrections

param(
    [string]$CommitMessage = "Quick deploy: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
    [switch]$Force = $false,
    [switch]$SkipTests = $false
)

# Configuration
$LogFile = "quick-deploy.log"
$ProjectName = "Shahin AI Business Analysis"

# Function to log messages
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"
    Write-Host $LogEntry -ForegroundColor $(
        switch ($Level) {
            "SUCCESS" { "Green" }
            "WARNING" { "Yellow" }
            "ERROR" { "Red" }
            default { "White" }
        }
    )
    Add-Content -Path $LogFile -Value $LogEntry
}

# Function to check prerequisites
function Test-Prerequisites {
    Write-Log "Checking prerequisites..." "INFO"
    
    try {
        # Check git
        $gitVersion = git --version
        Write-Log "Git available: $gitVersion" "SUCCESS"
        
        # Check vercel
        $vercelVersion = vercel --version
        Write-Log "Vercel CLI available: $vercelVersion" "SUCCESS"
        
        # Check if we're in a git repository
        $gitStatus = git status 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Not in a git repository"
        }
        Write-Log "Git repository detected" "SUCCESS"
        
        return $true
    }
    catch {
        Write-Log "Prerequisites check failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Function to perform git operations
function Invoke-GitOperations {
    Write-Log "Starting git operations..." "INFO"
    
    try {
        # Check for changes
        $gitStatus = git status --porcelain
        if (-not $gitStatus -and -not $Force) {
            Write-Log "No changes to commit. Use -Force to deploy anyway." "WARNING"
            return $false
        }
        
        if ($gitStatus) {
            Write-Log "Found changes to commit:" "INFO"
            git status --short | ForEach-Object { Write-Log "  $_" "INFO" }
            
            # Add all changes
            Write-Log "Adding all changes..." "INFO"
            git add -A
            
            # Commit changes
            Write-Log "Committing changes..." "INFO"
            git commit -m $CommitMessage
            
            if ($LASTEXITCODE -ne 0) {
                throw "Git commit failed"
            }
            Write-Log "Changes committed successfully" "SUCCESS"
        }
        
        # Push to GitHub
        Write-Log "Pushing to GitHub..." "INFO"
        git push origin master
        
        if ($LASTEXITCODE -ne 0) {
            throw "Git push failed"
        }
        Write-Log "Pushed to GitHub successfully" "SUCCESS"
        
        return $true
    }
    catch {
        Write-Log "Git operations failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Function to deploy to Vercel
function Invoke-VercelDeploy {
    Write-Log "Starting Vercel deployment..." "INFO"
    
    try {
        # Deploy to production
        Write-Log "Deploying to Vercel production..." "INFO"
        $deployOutput = vercel --prod --yes 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            throw "Vercel deployment failed: $deployOutput"
        }
        
        # Extract deployment URL from output
        $deploymentUrl = $deployOutput | Where-Object { $_ -match "https://.*\.vercel\.app" } | Select-Object -Last 1
        if ($deploymentUrl) {
            Write-Log "Deployment successful: $deploymentUrl" "SUCCESS"
            return $deploymentUrl
        } else {
            Write-Log "Deployment completed but URL not found in output" "WARNING"
            return $true
        }
    }
    catch {
        Write-Log "Vercel deployment failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Function to test deployment
function Test-Deployment {
    param([string]$Url)
    
    if (-not $Url) {
        Write-Log "No URL provided for testing, getting latest deployment..." "INFO"
        try {
            $deploymentInfo = vercel ls --json | ConvertFrom-Json
            $Url = $deploymentInfo[0].url
        }
        catch {
            Write-Log "Could not get deployment URL for testing" "WARNING"
            return $false
        }
    }
    
    Write-Log "Testing deployment at: $Url" "INFO"
    
    try {
        # Test main page
        $response = Invoke-WebRequest -Uri $Url -Method Head -TimeoutSec 30
        if ($response.StatusCode -eq 200) {
            Write-Log "Main page test: PASSED (HTTP $($response.StatusCode))" "SUCCESS"
        } else {
            Write-Log "Main page test: FAILED (HTTP $($response.StatusCode))" "ERROR"
            return $false
        }
        
        # Test key pages
        $testPages = @("/dashboard", "/architecture", "/regulations", "/grc-analysis")
        foreach ($page in $testPages) {
            try {
                $pageResponse = Invoke-WebRequest -Uri "$Url$page" -Method Head -TimeoutSec 15
                Write-Log "Page $page`: PASSED (HTTP $($pageResponse.StatusCode))" "SUCCESS"
            }
            catch {
                Write-Log "Page $page`: FAILED ($($_.Exception.Message))" "WARNING"
            }
        }
        
        return $true
    }
    catch {
        Write-Log "Deployment test failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Main execution
Write-Log "=== $ProjectName Quick Deploy Started ===" "INFO"
Write-Log "Commit message: $CommitMessage" "INFO"
Write-Log "Force deploy: $Force" "INFO"
Write-Log "Skip tests: $SkipTests" "INFO"

# Check prerequisites
if (-not (Test-Prerequisites)) {
    Write-Log "Prerequisites check failed. Aborting deployment." "ERROR"
    exit 1
}

# Perform git operations
if (-not (Invoke-GitOperations)) {
    Write-Log "Git operations failed. Aborting deployment." "ERROR"
    exit 1
}

# Deploy to Vercel
$deploymentResult = Invoke-VercelDeploy
if (-not $deploymentResult) {
    Write-Log "Vercel deployment failed. Check logs for details." "ERROR"
    exit 1
}

# Test deployment (unless skipped)
if (-not $SkipTests) {
    if (Test-Deployment -Url $deploymentResult) {
        Write-Log "Deployment testing completed successfully" "SUCCESS"
    } else {
        Write-Log "Deployment testing failed, but deployment may still be functional" "WARNING"
    }
} else {
    Write-Log "Deployment testing skipped" "INFO"
}

Write-Log "=== Quick Deploy Completed Successfully ===" "SUCCESS"
Write-Log "Your site should be live at the deployment URL shown above" "INFO"

# Show final status
Write-Log "Getting final deployment status..." "INFO"
try {
    vercel ls | Select-Object -First 5
} catch {
    Write-Log "Could not retrieve deployment list" "WARNING"
}

exit 0