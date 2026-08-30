$repoPath = "C:\Users\napon\Desktop\WildforceX"
$targetFile = Join-Path $repoPath "data.json"
$lastHash = (Get-FileHash $targetFile -Algorithm SHA256).Hash

Write-Host "Watching $targetFile for changes..."
Write-Host "GitHub Pages will update after automatic push to origin/main."

while ($true) {
    try {
        if (Test-Path $targetFile) {
            $currentHash = (Get-FileHash $targetFile -Algorithm SHA256).Hash

            if ($currentHash -ne $lastHash) {
                $lastHash = $currentHash
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

                Set-Location $repoPath
                git add --force data.json

                git diff --cached --quiet -- data.json
                if ($LASTEXITCODE -eq 1) {
                    git commit -m "Auto update sensor data $timestamp" | Out-Null

                    $pushSucceeded = $false
                    for ($attempt = 1; $attempt -le 3; $attempt++) {
                        git push origin main
                        if ($LASTEXITCODE -eq 0) {
                            $pushSucceeded = $true
                            break
                        }

                        git pull --rebase origin main | Out-Null
                    }

                    if ($pushSucceeded) {
                        Write-Host "[$timestamp] Pushed data.json to GitHub"
                    }
                    else {
                        Write-Host "[$timestamp] Push failed after retries"
                    }
                }
            }
        }
    }
    catch {
        Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Push failed: $($_.Exception.Message)"
    }

    Start-Sleep -Seconds 1
}
