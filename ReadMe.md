#Description
This module implements set of PowerShell Desired State Configuration helper functions to make the experience better, whereever possible. The functions exported are:

###Export-xDscConfiguration
This function lets you reconstruct the DSC configuration script file from the output of `Get-DscConfiguration` command.

`
Export-xDscConfiguration [-ConfigurationObject] <ciminstance[]> [-Path] <string> [-Passthru]
`
- **ConfigurationObject**: Output of `Get-DscConfiguration` cmdlet. Supports value from pipeline.
- **Path**: Specify the full file path where the script file should be created.
- **Passthru**: If specified, additionally prints the output on console/host. Helpful to copy the content into a script directly

###Export-xDscLocalConfigurationManager
This function lets you reconstruct the DSC local configuration manager script file from the output of `Get-DscLocalConfigurationManager` command.

``
Export-xDscLocalConfigurationManager [-LocalConfigurationManagerObject] <ciminstance> [-Path] <string> [-Passthru]
``
- **LocalConfigurationManagerObject**: Output of `Get-DscLocalConfigurationManager` cmdlet. Supports value from pipeline.
- **Path**: Specify the full file path where the script file should be created.
- **Passthru**: If specified, additionally prints the output on console/host. Helpful to copy the content into a script directly

###Format-Equals (ISE Add-On)

Examples
---------

**Export-xDscConfiguration**

**Export-xDscLocalConfigurationManager**
