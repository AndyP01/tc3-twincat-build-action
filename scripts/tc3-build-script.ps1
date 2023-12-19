cd $PSScriptRoot
. .\MessageFilter.ps1

###########################################
function CheckSolutionPathIsValid {
  param (
    [Parameter(Mandatory)]
    [string]$Path
  )
  
  if ([string]::IsNullOrEmpty($Path)) {
    return $false
  }
  if ( -Not (Test-Path $Path -PathType Leaf -IsValid)) {
    return $false
  }
  return $true
}

###########################################
function CheckTargetNetIdIsValid {
   param (
    [Parameter(Mandatory)]
    [string]$NetId
  )
  
  if ([string]::IsNullOrEmpty($NetId)) {
    return $false
  }
  if ( -Not ($NetId -match '^(\d{1,3}\.){5}\d{1,3}$')) { # check for a.b.c.d.e.f
    return $false
  }
  return $true
}

###########################################
function CheckTargetPlatformIsValid {
   param (
    [Parameter(Mandatory)]
    [string]$Platform
   )
   
   if ([string]::IsNullOrEmpty($Platform)) {
    return $false
  }
  return $true
}

###########################################
function CheckVSShellIsValid {
  param (
    [Parameter(Mandatory)]
    [string]$Shell
  )
  
  $progId = $null
  $Path32Bit = "REGISTRY::HKEY_CLASSES_ROOT\CLSID"
  $Path64Bit = "REGISTRY::HKEY_CLASSES_ROOT\WOW6432NODE\CLSID"

  # search registry to check if shell is available as a valid COM object
  $paths = @($Path32Bit)
  
  if (Test-Path -Path $Path64Bit) {
    $paths += $Path64Bit
  }

  $progId = get-childitem -Path $paths -include PROGID -recurse | foreach {$_.GetValue("")} | where { $_ -eq $Shell }

  if ($null -eq $progId) {
    return $false
  }
  return $true
}

###########################################
# Echo received parameters for logging
Write-Host "tc3-build-script Running"

Write-Host "Solution path: $env:SOLUTION_PATH"
Write-Host "Target NetId: $env:TARGET_NETID"
Write-Host "Target platform: $env:TARGET_PLATFORM"
Write-Host "Visual Studio shell version: $env:VS_SHELL"
Write-Host "Visual Studio UI silent mode: $env:VS_SILENT"

# Create COM message filter
AddMessageFilterClass
[EnvDteUtils.MessageFilter]::Register() # Call static Register Filter Method

# Try-Catch block for error handling
try {
  
  # Input checks
  if (-Not (CheckSolutionPathIsValid -Path $env:SOLUTION_PATH)) {
    throw "Solution not found."
  }

  if (-Not (CheckTargetNetIdIsValid -NetId $env:TARGET_NETID)) {
    throw "Target NetId is invalid."
  }

  if (-Not (CheckTargetPlatformIsValid -Platform $env:TARGET_PLATFORM)) {
    throw "Target platform is invalid."
  }

  if (-Not (CheckVSShellIsValid -Shell $env:VS_SHELL)) {
    throw "VS Shell requested is invalid."
  }

  Write-Host "Open VS instance."
  $dte = new-object -ComObject $env:VS_SHELL

  $settings = $dte.GetObject("TcAutomationSettings")
  $settings.SilentMode = $env:VS_SILENT
  $dte.UserControl = $false

  Write-Host "Open solution."
  $solution = $dte.Solution
  $solution.Open($env:SOLUTION_PATH)

  $project = $solution.Projects.Item(1)
  $systemManager = $project.Object

  Write-Host "Set target platform."
  $configManager = $systemManager.ConfigurationManager
  if ($configManager.TargetPlatforms -ccontains $env:TARGET_PLATFORM) {
    $configManager.ActiveTargetPlatform = $env:TARGET_PLATFORM
  }
  else {
    throw "Target platform not found."
  }

  Write-Host "Set target Net Id."
  $systemManager.SetTargetNetId($env:TARGET_NETID)

  Write-Host "Configure boot project."
  $plcProject = $systemManager.LookupTreeItem("TIPC^Main")
  $plcProject.BootProjectAutoStart = $true
  $plcProject.GenerateBootProject($true)

  Write-Host "Build solution."
  $solution.SolutionBuild.Build($true) #Optional. Determines whether Build(Boolean) retains control until the build operation is complete. Default value is false.

  if($solution.SolutionBuild.LastBuildInfo -eq 0)
  {
    Write-Host "Build succeeded."
  }
  else {
    throw "Build failed."
  }

  Write-Host "Activate configuration."
  $systemManager.ActivateConfiguration()

  Start-Sleep -s 2

  Write-Host "Restart TwinCAT."
  $systemManager.StartRestartTwinCAT() 

  Start-Sleep -s 2

  # TODO check for activation errors, like no licenses
  # TODO No licenses brings up dialog boxes even is UI has been suppressed. How to avoid and deal with this?
  # TODO check test results, upload artifact of compiled library if passing, etc

  Write-Host "Close solution."
  $solution.Close()

  # Only call quit from finally block? Calling it twice causes an exception if it has already been disposed.
  # TODO Create a Cleanup function that is called here and from within Finally block?
  #$dte.Quit()

}
catch {
  # Catching and displaying the error
  Write-Host "Error: $_"
  exit 1
}
finally {
  # Clean up dte object.
  if ($null -ne $dte) {
    $dte.Quit()
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($dte) | Out-Null
  }
}

[EnvDTEUtils.MessageFilter]::Revoke()

# Successful execution
Write-Host "PowerShell script executed successfully."
exit 0
