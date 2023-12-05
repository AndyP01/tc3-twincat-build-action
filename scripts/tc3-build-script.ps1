#param(
#  [string]$solutionPath,
#  [string]$targetNetId,
#  [string]$targetPlatform
)
# TODO pass in:
#   shell version, e.g. TcXaeShell.DTE.15.0
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

function CheckSolutionIsValid {

}

# Print received parameters for logging
Write-Host "tc3-build-script Running"
#Write-Host "Received parameters:"

#Write-Host "Target NetId: solutionPath"
#Write-Host "Target NetId: targetNetId"
#Write-Host "Target NetId: targetPlatform"

Write-Host "Target NetId: $env:solutionPath"
Write-Host "Target NetId: $env:targetNetId"
Write-Host "Target NetId: $env:targetPlatform"

AddMessageFilterClass('') # Call function
[EnvDteUtils.MessageFilter]::Register() # Call static Register Filter Method

# Try-Catch block for error handling
try {
  # Your logic here...

  

  # Input checks
  if ($solutionPath.IsNullOrEmpty) {
    throw "Solution not found."
  }


# Open solution
#dte = new-object -ComObject "TcXaeShell.DTE.15.0"
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
  #if ($null -ne $dte) {
  #  $dte.Quit()
  #}
}

# Successful execution
Write-Host "PowerShell script executed successfully."
exit 0
