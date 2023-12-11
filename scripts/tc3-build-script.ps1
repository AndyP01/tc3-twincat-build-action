function AddMessageFilterClass { 
    $source = @'

namespace EnvDteUtils
{
using System; 
using System.Runtime.InteropServices; 

public class MessageFilter : IOleMessageFilter 
{ 
public static void Register() 
{ 
IOleMessageFilter newFilter = new MessageFilter(); 
IOleMessageFilter oldFilter = null; 
CoRegisterMessageFilter(newFilter, out oldFilter); 
} 

public static void Revoke() 
{ 
IOleMessageFilter oldFilter = null; 
CoRegisterMessageFilter(null, out oldFilter); 
} 

int IOleMessageFilter.HandleInComingCall(int dwCallType, System.IntPtr hTaskCaller, int dwTickCount, System.IntPtr lpInterfaceInfo)
{ 
return 0; 
} 

int IOleMessageFilter.RetryRejectedCall(System.IntPtr hTaskCallee, int dwTickCount, int dwRejectType) 
{ 
if (dwRejectType == 2) 
{ 
return 99; 
} 
return -1; 
} 

int IOleMessageFilter.MessagePending(System.IntPtr hTaskCallee, int dwTickCount, int dwPendingType) 
{ 
return 2; 
} 

[DllImport("Ole32.dll")] 
private static extern int CoRegisterMessageFilter(IOleMessageFilter newFilter, out IOleMessageFilter oldFilter); 
} 

[ComImport(), Guid("00000016-0000-0000-C000-000000000046"), InterfaceTypeAttribute(ComInterfaceType.InterfaceIsIUnknown)] 
interface IOleMessageFilter 
{ 
[PreserveSig] 
int HandleInComingCall(int dwCallType, IntPtr hTaskCaller, int dwTickCount, IntPtr lpInterfaceInfo);

[PreserveSig]
int RetryRejectedCall(IntPtr hTaskCallee, int dwTickCount, int dwRejectType);

[PreserveSig]
int MessagePending(IntPtr hTaskCallee, int dwTickCount, int dwPendingType);
}
}
'@
    Add-Type -TypeDefinition $source
}

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
Write-Host "Visual Studio display UI: $env:VS_UI"


# Create COM message filter
AddMessageFilterClass('') # Call function
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

  # Open solution
  $dte = new-object -ComObject $env:VS_SHELL
  $dte.SuppressUI = !$env:VS_UI
  $dte.MainWindow.Visible = $env:VS_UI

  $solution = $dte.Solution
  $solution.Open($env:SOLUTION_PATH)

  $project = $solution.Projects.Item(1)
  $systemManager = $project.Object

  $systemManager.ActivateConfiguration()
  $systemManager.StartRestartTwinCAT() 

  # Call quit from finally block? Calling it twice causes an exception.
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
    $dte = $null
  }
}

[EnvDTEUtils.MessageFilter]::Revoke()

# Successful execution
Write-Host "PowerShell script executed successfully."
exit 0
