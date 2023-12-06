# TODO pass in:
#   shell is visible or suppressed

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

function CheckSolutionPathIsValid {
  param (
    [string]$FilePath
  )

  if ([string]::IsNullOrEmpty($FilePath)) {
    return $false
  }

  if (Test-Path $FilePath -PathType Leaf -IsValid) {
    return $true
  }
  
   return $false
}

function CheckTargetNetIdIsValid {
  #TODO
  return $true
}

function CheckTargetPlatformIsValid {
  #TODO
  return $true
}

function CheckVSShellIsValid {
  #TODO
  return $true
}

# Echo received parameters for logging
Write-Host "tc3-build-script Running"

Write-Host "Solution path: $env:SOLUTION_PATH"
Write-Host "Target NetId: $env:TARGET_NETID"
Write-Host "Target platform: $env:TARGET_PLATFORM"
Write-Host "Visual Studio shell version: $env:VS_SHELL"

# Create COM message filter
AddMessageFilterClass('') # Call function
[EnvDteUtils.MessageFilter]::Register() # Call static Register Filter Method


# Try-Catch block for error handling
try {
  
  # Input checks
  if (CheckSolutionPathIsValid($env:SOLUTION_PATH) -ne $true) {
    throw "Solution not found."
  }

  if (CheckTargetNetIdIsValid($env:TARGET_NETID) -ne $true) {
    throw "Target NetId is invalid."
  }

  if (CheckTargetPlatformIsValid($env:TARGET_PLATFORM) -ne $true) {
    throw "Target platform is invalid."
  }

  if (CheckVSShellIsValid($env:VS_SHELL) -ne $true) {
    throw "VS Sgell requested is invalid."
  }


  # Open solution
  #dte = new-object -ComObject $env:vsShell
  #$dte.SuppressUI = $true
  #$dte.MainWindow.Visible = $false

  #$solution = $dte.Solution
  #$solution.Open($solutionPath)

  #$projects = $solution.Projects

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
finally {
  # Clean up dte object.
  #if ($null -ne $dte) {
  #  $dte.Quit()
  #}
}

[EnvDTEUtils.MessageFilter]::Revoke()

# Successful execution
Write-Host "PowerShell script executed successfully."
exit 0
