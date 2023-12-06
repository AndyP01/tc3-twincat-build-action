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

function CheckSolutionPathIsValid([string]$filePath) {
  if ([string]::IsNullOrEmpty($filePath)) {
    return $false
  }

  if (Test-Path $filePath -PathType Leaf -IsValid) {
    return $true
  }
  
   return $false
}

function CheckTargetNetIdIsValid([string]$targetNetId) {
  #TODO
  return $true
}

function CheckTargetPlatformIsValid([string]$platform) {
  #TODO
  return $true
}

function CheckVSShellIsValid([string]$shell, [string[]]$shells) {
  #TODO
  # check if shell is available as a valid COM object?
  # provide named params

  $found = $false

  foreach ($s in $shells) {
    $s
    if ($s -eq $shell) {
      $found = $true
      Write-Host "Found: $s"
    }
  }

  if (-Not ($found)) {
    return $false
  }
  return $true
}

# Echo received parameters for logging
Write-Host "tc3-build-script Running"

Write-Host "Solution path: $env:SOLUTION_PATH"
Write-Host "Target NetId: $env:TARGET_NETID"
Write-Host "Target platform: $env:TARGET_PLATFORM"
Write-Host "Visual Studio shell version: $env:VS_SHELL"

$vs_shells = @(
  'VisualStudio.DTE.10.0', # VS2010
  'VisualStudio.DTE.11.0', # VS2012
  'VisualStudio.DTE.12.0', # VS2013
  'VisualStudio.DTE.14.0', # VS2015
  'VisualStudio.DTE.15.0', # VS2017
  'TcXaeShell.DTE.15.0'    # TwinCAT XAE Shell
)

$dte = $null
$solution = $null
$projects = $null

# Create COM message filter
AddMessageFilterClass('') # Call function
[EnvDteUtils.MessageFilter]::Register() # Call static Register Filter Method

# Try-Catch block for error handling
try {
  
  # Input checks
  #if (-Not (CheckSolutionPathIsValid($env:SOLUTION_PATH))) {
  #  throw "Solution not found."
  #}

  if (-Not (CheckTargetNetIdIsValid $env:TARGET_NETID)) {
    throw "Target NetId is invalid."
  }

  if (-Not (CheckTargetPlatformIsValid $env:TARGET_PLATFORM)) {
    throw "Target platform is invalid."
  }

  if (-Not (CheckVSShellIsValid $env:VS_SHELL $vs_shells)) {
    throw "VS Shell requested is invalid."
  }


  # Open solution
  #$dte = new-object -ComObject $env:VS_SHELL
  #$dte.SuppressUI = $true
  #$dte.MainWindow.Visible = $false

  #$solution = $dte.Solution
  #$solution.Open($solutionPath)

  #$projects = $solution.Projects

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
