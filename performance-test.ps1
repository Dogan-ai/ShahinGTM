# Shahin AI Performance Testing & Status Update Script
# Comprehensive website performance analysis and status reporting

param(
    [string]$Url = "https://shahin-ai-business-analysis-csbu8c5nt-dogan-consult.vercel.app",
    [string]$OutputFile = "performance-report.json",
    [switch]$UpdateStatus = $true,
    [switch]$Verbose = $false
)

# Performance test results
$PerformanceResults = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    TestUrl = $Url
    Metrics = @{}
    Status = @{}
    Recommendations = @()
    OverallScore = 0
}

# Function to log messages
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"
    
    $Color = switch ($Level) {
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "METRIC" { "Cyan" }
        default { "White" }
    }
    
    Write-Host $LogEntry -ForegroundColor $Color
    
    if ($Verbose) {
        Add-Content -Path "performance-test.log" -Value $LogEntry
    }
}

# Function to test page load performance
function Test-PageLoad {
    param([string]$TestUrl)
    
    Write-Log "Testing page load performance for: $TestUrl" "INFO"
    
    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $response = Invoke-WebRequest -Uri $TestUrl -Method GET -TimeoutSec 30
        $stopwatch.Stop()
        
        $loadTime = $stopwatch.ElapsedMilliseconds
        $contentSize = $response.Content.Length
        $statusCode = $response.StatusCode
        
        Write-Log "Load Time: ${loadTime}ms" "METRIC"
        Write-Log "Content Size: $([math]::Round($contentSize / 1024, 2))KB" "METRIC"
        Write-Log "Status Code: $statusCode" "METRIC"
        
        # Performance scoring
        $loadScore = switch ($loadTime) {
            { $_ -le 1000 } { 100 }
            { $_ -le 2000 } { 90 }
            { $_ -le 3000 } { 80 }
            { $_ -le 4000 } { 70 }
            { $_ -le 5000 } { 60 }
            default { 40 }
        }
        
        $sizeScore = switch ($contentSize) {
            { $_ -le 50KB } { 100 }
            { $_ -le 100KB } { 90 }
            { $_ -le 200KB } { 80 }
            { $_ -le 500KB } { 70 }
            { $_ -le 1MB } { 60 }
            default { 40 }
        }
        
        return @{
            LoadTime = $loadTime
            ContentSize = $contentSize
            StatusCode = $statusCode
            LoadScore = $loadScore
            SizeScore = $sizeScore
            Success = $true
        }
    }
    catch {
        Write-Log "Page load test failed: $($_.Exception.Message)" "ERROR"
        return @{
            LoadTime = -1
            ContentSize = -1
            StatusCode = -1
            LoadScore = 0
            SizeScore = 0
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# Function to test multiple pages
function Test-MultiplePages {
    $pages = @(
        @{ Name = "Home"; Path = "" }
        @{ Name = "Dashboard"; Path = "/dashboard" }
        @{ Name = "Architecture"; Path = "/architecture" }
        @{ Name = "Regulations"; Path = "/regulations" }
        @{ Name = "GRC Analysis"; Path = "/grc-analysis" }
    )
    
    $pageResults = @{}
    $totalScore = 0
    $successfulTests = 0
    
    foreach ($page in $pages) {
        $testUrl = $Url + $page.Path
        Write-Log "Testing $($page.Name) page..." "INFO"
        
        $result = Test-PageLoad -TestUrl $testUrl
        $pageResults[$page.Name] = $result
        
        if ($result.Success) {
            $pageScore = ($result.LoadScore + $result.SizeScore) / 2
            $totalScore += $pageScore
            $successfulTests++
            
            Write-Log "$($page.Name): Score $([math]::Round($pageScore, 1))/100" "SUCCESS"
        } else {
            Write-Log "$($page.Name): FAILED" "ERROR"
        }
    }
    
    $averageScore = if ($successfulTests -gt 0) { $totalScore / $successfulTests } else { 0 }
    
    return @{
        Pages = $pageResults
        AverageScore = $averageScore
        SuccessfulTests = $successfulTests
        TotalTests = $pages.Count
    }
}

# Function to analyze HTML structure
function Test-HTMLStructure {
    param([string]$TestUrl)
    
    Write-Log "Analyzing HTML structure..." "INFO"
    
    try {
        $response = Invoke-WebRequest -Uri $TestUrl -Method GET
        $html = $response.Content
        
        # Check for performance-related elements
        $hasViewport = $html -match 'name="viewport"'
        $hasMetaDescription = $html -match 'name="description"'
        $hasTitle = $html -match '<title>'
        $hasCanonical = $html -match 'rel="canonical"'
        $hasManifest = $html -match 'rel="manifest"'
        $hasServiceWorker = $html -match 'serviceWorker'
        $hasLazyLoading = $html -match 'loading="lazy"'
        
        # Count external resources
        $cssCount = ([regex]::Matches($html, '<link[^>]*rel="stylesheet"')).Count
        $jsCount = ([regex]::Matches($html, '<script[^>]*src=')).Count
        $imgCount = ([regex]::Matches($html, '<img[^>]*src=')).Count
        
        Write-Log "Viewport meta tag: $hasViewport" "METRIC"
        Write-Log "Meta description: $hasMetaDescription" "METRIC"
        Write-Log "Title tag: $hasTitle" "METRIC"
        Write-Log "Canonical URL: $hasCanonical" "METRIC"
        Write-Log "PWA Manifest: $hasManifest" "METRIC"
        Write-Log "CSS files: $cssCount" "METRIC"
        Write-Log "JS files: $jsCount" "METRIC"
        Write-Log "Images: $imgCount" "METRIC"
        
        # Calculate SEO/Performance score
        $seoScore = 0
        if ($hasViewport) { $seoScore += 15 }
        if ($hasMetaDescription) { $seoScore += 15 }
        if ($hasTitle) { $seoScore += 15 }
        if ($hasCanonical) { $seoScore += 10 }
        if ($hasManifest) { $seoScore += 15 }
        if ($hasServiceWorker) { $seoScore += 10 }
        if ($hasLazyLoading) { $seoScore += 10 }
        if ($cssCount -le 3) { $seoScore += 5 }
        if ($jsCount -le 5) { $seoScore += 5 }
        
        return @{
            HasViewport = $hasViewport
            HasMetaDescription = $hasMetaDescription
            HasTitle = $hasTitle
            HasCanonical = $hasCanonical
            HasManifest = $hasManifest
            HasServiceWorker = $hasServiceWorker
            HasLazyLoading = $hasLazyLoading
            CSSCount = $cssCount
            JSCount = $jsCount
            ImageCount = $imgCount
            SEOScore = $seoScore
            Success = $true
        }
    }
    catch {
        Write-Log "HTML structure analysis failed: $($_.Exception.Message)" "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
            SEOScore = 0
        }
    }
}

# Function to test security headers
function Test-SecurityHeaders {
    param([string]$TestUrl)
    
    Write-Log "Testing security headers..." "INFO"
    
    try {
        $response = Invoke-WebRequest -Uri $TestUrl -Method HEAD
        $headers = $response.Headers
        
        $securityHeaders = @{
            "Strict-Transport-Security" = $headers.ContainsKey("Strict-Transport-Security")
            "X-Content-Type-Options" = $headers.ContainsKey("X-Content-Type-Options")
            "X-Frame-Options" = $headers.ContainsKey("X-Frame-Options")
            "X-XSS-Protection" = $headers.ContainsKey("X-XSS-Protection")
            "Content-Security-Policy" = $headers.ContainsKey("Content-Security-Policy")
            "Referrer-Policy" = $headers.ContainsKey("Referrer-Policy")
        }
        
        $securityScore = 0
        foreach ($header in $securityHeaders.GetEnumerator()) {
            if ($header.Value) {
                $securityScore += 16.67
                Write-Log "$($header.Key): ✓ Present" "SUCCESS"
            } else {
                Write-Log "$($header.Key): ✗ Missing" "WARNING"
            }
        }
        
        return @{
            Headers = $securityHeaders
            SecurityScore = [math]::Round($securityScore, 1)
            Success = $true
        }
    }
    catch {
        Write-Log "Security headers test failed: $($_.Exception.Message)" "ERROR"
        return @{
            Success = $false
            Error = $_.Exception.Message
            SecurityScore = 0
        }
    }
}

# Function to generate recommendations
function Get-Recommendations {
    param($Results)
    
    $recommendations = @()
    
    # Performance recommendations
    if ($Results.PageTests.AverageScore -lt 80) {
        $recommendations += "Consider optimizing page load times - current average score: $([math]::Round($Results.PageTests.AverageScore, 1))"
    }
    
    # SEO recommendations
    if (-not $Results.HTMLStructure.HasLazyLoading) {
        $recommendations += "Implement lazy loading for images to improve performance"
    }
    
    if ($Results.HTMLStructure.CSSCount -gt 3) {
        $recommendations += "Consider combining CSS files to reduce HTTP requests"
    }
    
    if ($Results.HTMLStructure.JSCount -gt 5) {
        $recommendations += "Consider combining or minifying JavaScript files"
    }
    
    # Security recommendations
    if ($Results.SecurityHeaders.SecurityScore -lt 90) {
        $recommendations += "Improve security headers implementation - current score: $($Results.SecurityHeaders.SecurityScore)"
    }
    
    return $recommendations
}

# Function to create status badge
function Create-StatusBadge {
    param([int]$Score)
    
    $color = switch ($Score) {
        { $_ -ge 90 } { "brightgreen" }
        { $_ -ge 80 } { "green" }
        { $_ -ge 70 } { "yellowgreen" }
        { $_ -ge 60 } { "yellow" }
        { $_ -ge 50 } { "orange" }
        default { "red" }
    }
    
    $status = switch ($Score) {
        { $_ -ge 90 } { "excellent" }
        { $_ -ge 80 } { "good" }
        { $_ -ge 70 } { "fair" }
        { $_ -ge 60 } { "needs improvement" }
        default { "poor" }
    }
    
    return @{
        Score = $Score
        Color = $color
        Status = $status
        BadgeUrl = "https://img.shields.io/badge/Performance-$Score%25-$color"
    }
}

# Main execution
Write-Log "Starting Shahin AI Performance Test" "INFO"
Write-Log "Target URL: $Url" "INFO"

# Run all tests
Write-Log "=== RUNNING PERFORMANCE TESTS ===" "INFO"

# Test multiple pages
$pageTests = Test-MultiplePages
$PerformanceResults.Metrics["PageTests"] = $pageTests

# Test HTML structure
$htmlStructure = Test-HTMLStructure -TestUrl $Url
$PerformanceResults.Metrics["HTMLStructure"] = $htmlStructure

# Test security headers
$securityHeaders = Test-SecurityHeaders -TestUrl $Url
$PerformanceResults.Metrics["SecurityHeaders"] = $securityHeaders

# Calculate overall score
$overallScore = ($pageTests.AverageScore + $htmlStructure.SEOScore + $securityHeaders.SecurityScore) / 3
$PerformanceResults.OverallScore = [math]::Round($overallScore, 1)

# Generate recommendations
$PerformanceResults.Recommendations = Get-Recommendations -Results $PerformanceResults.Metrics

# Create status badge
$statusBadge = Create-StatusBadge -Score $PerformanceResults.OverallScore
$PerformanceResults.Status = $statusBadge

# Display results
Write-Log "=== PERFORMANCE TEST RESULTS ===" "SUCCESS"
Write-Log "Overall Score: $($PerformanceResults.OverallScore)/100" "METRIC"
Write-Log "Status: $($statusBadge.Status)" "METRIC"
Write-Log "Page Load Average: $([math]::Round($pageTests.AverageScore, 1))/100" "METRIC"
Write-Log "SEO Score: $($htmlStructure.SEOScore)/100" "METRIC"
Write-Log "Security Score: $($securityHeaders.SecurityScore)/100" "METRIC"

if ($PerformanceResults.Recommendations.Count -gt 0) {
    Write-Log "=== RECOMMENDATIONS ===" "WARNING"
    foreach ($rec in $PerformanceResults.Recommendations) {
        Write-Log "• $rec" "WARNING"
    }
}

# Save results to JSON
$PerformanceResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputFile -Encoding UTF8
Write-Log "Results saved to: $OutputFile" "SUCCESS"

# Update status if requested
if ($UpdateStatus) {
    Write-Log "Performance badge URL: $($statusBadge.BadgeUrl)" "INFO"
}

Write-Log "Performance test completed!" "SUCCESS"

# Return results for further processing
return $PerformanceResults