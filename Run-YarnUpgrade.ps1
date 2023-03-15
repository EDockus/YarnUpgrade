# Set the Azure DevOps organization URL, project name, and repository name
$orgUrl = "https://dev.azure.com/Organization"
$projectName = "projectName"
$repoName = "reponame"

# Set the name of the new branch to create
$newBranchName = "yarn-upgrade-$(get-date -Format 'yyyyMMddhhmmss')"

# Set the base branch to merge into (e.g. master)
$baseBranch = "dev"

# Authenticate with Azure DevOps using a personal access token (PAT)
$pat = "AZDOPAT"
$authHeader = @{Authorization = "Basic $([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat")))"}
$base64AuthInfo= [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($pat)"))

# Clone the repository
git clone --depth 1 --branch $baseBranch "https://$([System.UriEscapeDataString($pat)]):@dev.azure.com/$projectName/$repoName.git"

# Change the working directory to the cloned repository
Set-Location -Path ".\$repoName"

# Create a new branch and switch to it
git checkout -b $newBranchName

# Run yarn upgrade to update dependencies
yarn upgrade --latest

# Commit the changes
git add yarn.lock
git commit -m "Update dependencies"

# Push the changes to Azure DevOps
git push origin $newBranchName

# Create a pull request to merge the changes into the base branch
$body = @{
    sourceRefName = "refs/heads/$newBranchName"
    targetRefName = "refs/heads/$baseBranch"
    title = "Update dependencies"
    description = "Update dependencies using yarn upgrade"
    reviewers = @()
} | ConvertTo-Json

Invoke-RestMethod -Uri "$orgUrl/$projectName/_apis/git/repositories/$repoName/pullrequests?api-version=6.0" `
                  -Method Post `
                  -ContentType "application/json" `
                  -Body $body `
                  -Headers @{
                      Authorization = $authHeader.Authorization
                      Accept = "application/json"
                  }

# Change back to the original working directory and remove the cloned repository
Set-Location -Path ".."
Remove-Item -Recurse -Force $repoName
