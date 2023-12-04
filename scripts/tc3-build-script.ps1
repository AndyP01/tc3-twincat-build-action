param(
  [string]$solutionPath,
  [string]$targetNetId,
  [string]$targetPlatform,
  [string]$json
)

# Print received parameters for logging
Write-Host "tc3-build-script Running"
Write-Host "Received parameters:"

Write-Host "Target NetId: $solutionPath"
Write-Host "Target NetId: $targetNetId"
Write-Host "Target NetId: $targetPlatform"
Write-Host "Json: $json"

# Try-Catch block for error handling
try {
  # Your logic here...

    

  # Simulating a failure
  #if ($simulateFail -eq "true") {
  #  throw "Simulated failure triggered."
  #}
}
catch {
  # Catching and displaying the error
  Write-Host "Error: $_"
  exit 1
}

# Successful execution
Write-Host "PowerShell script executed successfully."
exit 0
