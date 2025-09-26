# Shahin AI CLI Automation Setup

This document explains how to use the automated deployment monitoring and correction scripts for the Shahin AI Business Analysis platform.

## 📋 Prerequisites

Before using the automation scripts, ensure you have:

1. **PowerShell 7+** installed on Windows
2. **Git** installed and configured
3. **Vercel CLI** installed and authenticated (`npm install -g vercel`)
4. **Repository access** to the Shahin AI project

## 🚀 Quick Start

### 1. Immediate Deployment
For quick deployments and fixes:

```powershell
# Basic quick deploy
.\quick-deploy.ps1

# Deploy with custom commit message
.\quick-deploy.ps1 -CommitMessage "Fix navigation issues"

# Force deploy even without changes
.\quick-deploy.ps1 -Force

# Deploy without running tests
.\quick-deploy.ps1 -SkipTests
```

### 2. Continuous Monitoring (12 Hours)
For automated monitoring every 10 minutes for 12 hours:

```powershell
# Start 12-hour monitoring with auto-corrections
.\deploy-monitor.ps1

# Custom interval and duration
.\deploy-monitor.ps1 -IntervalMinutes 5 -DurationHours 6

# Monitoring without auto-corrections
.\deploy-monitor.ps1 -AutoCorrect:$false
```

## 📊 Script Features

### Deploy Monitor (`deploy-monitor.ps1`)

**Features:**
- ✅ Monitors deployment status every 10 minutes
- ✅ Automatically detects and fixes deployment issues
- ✅ Comprehensive logging with timestamps
- ✅ Error tracking and retry mechanisms
- ✅ Success rate statistics
- ✅ Configurable monitoring duration and intervals

**Parameters:**
- `-IntervalMinutes`: Check interval (default: 10)
- `-DurationHours`: Total monitoring time (default: 12)
- `-ProjectPath`: Project directory path (default: current)
- `-AutoCorrect`: Enable auto-corrections (default: true)

**Auto-Correction Actions:**
1. Commits any uncommitted changes
2. Pushes to GitHub repository
3. Redeploys to Vercel production
4. Verifies deployment success
5. Retries up to 3 times if needed

### Quick Deploy (`quick-deploy.ps1`)

**Features:**
- ✅ Rapid deployment with error checking
- ✅ Automatic git operations (add, commit, push)
- ✅ Vercel production deployment
- ✅ Multi-page deployment testing
- ✅ Colored console output for easy reading

**Parameters:**
- `-CommitMessage`: Custom commit message
- `-Force`: Deploy even without changes
- `-SkipTests`: Skip deployment testing

**Tested Pages:**
- Main page (/)
- Dashboard (/dashboard)
- Architecture (/architecture)
- Regulations (/regulations)
- GRC Analysis (/grc-analysis)

## 📝 Log Files

The scripts generate detailed logs:

- `deployment-monitor.log`: Main monitoring log
- `deployment-errors.log`: Error-specific log
- `quick-deploy.log`: Quick deployment log

## 🔧 Usage Examples

### Example 1: Start 12-Hour Monitoring
```powershell
# Navigate to project directory
cd "d:\Dev\ShahinGTM\Master templat\www.shahin-ai.com"

# Start monitoring
.\deploy-monitor.ps1
```

### Example 2: Quick Fix and Deploy
```powershell
# Make your code changes, then:
.\quick-deploy.ps1 -CommitMessage "Fix layer navigation bug"
```

### Example 3: Custom Monitoring Schedule
```powershell
# Monitor every 5 minutes for 6 hours
.\deploy-monitor.ps1 -IntervalMinutes 5 -DurationHours 6
```

### Example 4: Emergency Deploy
```powershell
# Force deploy without changes (useful for redeployment)
.\quick-deploy.ps1 -Force -CommitMessage "Emergency redeploy"
```

## 🚨 Troubleshooting

### Common Issues:

1. **"Not in a git repository"**
   - Ensure you're in the correct project directory
   - Check that `.git` folder exists

2. **"Vercel CLI not found"**
   - Install: `npm install -g vercel`
   - Authenticate: `vercel login`

3. **"Git push failed"**
   - Check your GitHub credentials
   - Ensure you have push permissions

4. **"Deployment test failed"**
   - Check your internet connection
   - Verify the deployment URL is accessible

### Log Analysis:
- Check `deployment-monitor.log` for detailed monitoring history
- Review `deployment-errors.log` for specific error messages
- Use `quick-deploy.log` to debug deployment issues

## 📈 Monitoring Dashboard

While the scripts run, you can monitor:

1. **Console Output**: Real-time status updates
2. **Log Files**: Detailed operation history
3. **Vercel Dashboard**: Visual deployment status
4. **GitHub Actions**: Repository activity

## 🔄 Best Practices

1. **Before Starting Monitoring:**
   - Ensure your code is in a stable state
   - Test manually first with quick-deploy
   - Check that all dependencies are installed

2. **During Monitoring:**
   - Don't manually deploy while monitoring is active
   - Monitor the log files for any issues
   - Keep your computer running for the full duration

3. **After Monitoring:**
   - Review the final statistics
   - Check error logs for any patterns
   - Update your code based on any issues found

## 🛡️ Security Notes

- Scripts only operate on your local repository
- No sensitive data is logged
- All operations use your existing git/Vercel credentials
- Logs are stored locally only

## 📞 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review the log files for specific errors
3. Ensure all prerequisites are met
4. Test with quick-deploy first before using monitoring

---

**Happy Deploying! 🚀**