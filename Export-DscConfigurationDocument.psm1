function Export-xDscConfiguration
{
    [CmdletBinding(DefaultParameterSetName)]
    param
    (
        [Parameter(ParameterSetName='ConfigurationObject', Mandatory, ValueFromPipeline)]
        [ciminstance[]]$ConfigurationObject,

        [Parameter(ParameterSetName='ConfigurationDocument', Mandatory, ValueFromPipeline)]
        [string]$ConfigurationDocumentPath,

        [Parameter(Mandatory)]
        [string]$Path,

        [switch]$Passthru
    )

#region input validation

    # If $Path has something before it, check if that exists, if not create it else must be working directory
    $PathRoot = Split-Path $Path
    if(($PathRoot -ne ([String]::Empty)) -and (-not (Test-Path -Path $PathRoot)))
    {
        New-Item -ItemType Directory -Path $PathRoot
    }

    # if the $PATH file extension is not .ps1, throw
    if((Split-Path $Path -Leaf).split('.')[1] -ne 'ps1')
    {
        Throw 'Only .ps1 files are supported for the -Path parameter'
    }
 
#endregion

    # TODO: Handle mof from multiple configurations

    # Only find the non-read properties in the helper function
    $InspectQualifier = $true

    # If we are dealing with output of Get-DscConfiguration cmdlet
    if($PSCmdlet.ParameterSetName -eq 'ConfigurationObject')
    {
        # If it derives from OMI_BaseResource, it contains Real resources
        if($ConfigurationObject[0].CimClass.CimSuperClassName -eq 'OMI_BaseResource')
        {
            $configurationName = $ConfigurationObject[0].ConfigurationName
        }

        # If it is MSFT_DSCMetaConfiguration, it conatins Meta resource
        elseif($ConfigurationObject[0].CimClass.CimClassName -eq 'MSFT_DSCMetaConfiguration')
        {
            Write-Error -Message 'Not supported. For converting output of Get-DscLocalConfigurationManager, please user Export-xDscLocalConfigurationManager cmdlet'
        }
        
        # Something that code doesn't handle yet
        else
        {
            $ConfigurationObject[0].PSObject.TypeNames
            throw "Don't know how to handle this type hierarchy"
        }
    }

    # If we are dealing with Configuration document (MOF)
    elseif($PSCmdlet.ParameterSetName -eq 'ConfigurationDocument')
    {
        # Resolve any relative path or variable usage
        $ConfigurationDocumentPath = Resolve-Path $ConfigurationDocumentPath

        # Check if $ConfigurationDocumentPath exist
        if(-not (Test-Path -Path $ConfigurationDocumentPath))
        {
            Throw "$ConfigurationDocumentPath is not a valid path. Please provide correct input and try again"
        }

        # Get objects from reading the mof file
        $ConfigurationObject = [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::ImportInstances($ConfigurationDocumentPath,4)

        # If the objects have configurationName property, use it else (in PS v4) assign a dummy
        $configurationName = $ConfigurationObject[0].ConfigurationName

        # Don't filter based on qualifiers, as the objects will not have it
        $InspectQualifier = $false
    }

    # ConfigurationName will be $null for DSC in PS 4.0
    if($configurationName -eq $null) {$configurationName = '#Name'}

    $output = & {
    "Configuration $configurationName"
    "{"
        foreach($object in $ConfigurationObject)
        {
            Write-DscResourceSyntax -ResourceObject $object -UseQualifier:$InspectQualifier
        }
    "}"
    }

    Set-Content -Value $output -Path $Path
    if($Passthru) {$output}
}

function Export-xDscLocalConfigurationManager
{
    param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ciminstance]$LocalConfigurationManagerObject,

        [Parameter(Mandatory)]
        [string]$Path,

        [switch]$Passthru
    )

    # If it is MSFT_DSCMetaConfiguration, it conatins Meta resource
    if($LocalConfigurationManagerObject[0].CimClass.CimClassName -eq 'MSFT_DSCMetaConfiguration')
    {
        $IsV2MetaResource = $LocalConfigurationManagerObject[0].CimClass.CimClassProperties.name -contains 'PartialConfigurations'
    }

    # If it derives from OMI_BaseResource, it contains Real resources
    elseif($InputObject[0].CimClass.CimSuperClassName -eq 'OMI_BaseResource')
    {
        Write-Error -Message 'Not supported. For converting output of Get-DscConfiguration, please user Export-xDscConfiguration cmdlet'
    }
        
    # Something that code doesn't handle yet
    else
    {
        $InputObject[0].PSObject.TypeNames
        throw "Don't know how to handle this type"
    }

    $output = & {
    if($IsV2MetaResource){"[DscLocalConfigurationManager()]"}
    "Configuration #Name `n{"
        foreach($object in $LocalConfigurationManagerObject)
        {
            Write-DscLCMSyntax -LCMObject $object -UseV2Syntax:$IsV2MetaResource
        }
    "}"
    }

    # TODO: Validate file extension
    # TODO: Validate folder, if specified and create it
    Set-Content -Value $output -Path $Path
    if($Passthru) {$output}
}

function Write-DscResourceSyntax
{
    param
    (
        [Parameter(Mandatory)]
        [ciminstance]$ResourceObject,

        [Switch]$UseQualifier
    )

    # Get the resource ID of the resource
    $resourceId = ($ResourceObject.CimInstanceProperties | ?{$_.Name -eq 'ResourceId'}).Value

    # If resource ID is found, derive the TypeName and InstanceName from it
    if($resourceId)
    {
        # Get the resource typename and instance name
        $resourceTypeName = $resourceId.Split('[]')[1]
        $resourceInstanceName = $resourceId.Split(']')[1]
    }

    # If no resource ID, use CimClassQualifiers to find it.
    # There is no $resourceId in DSC in PS 4.0 and OMI_ConfigurationDocument doesn't have it either
    if(-not $resourceId)
    {
        $resourceTypeName = ($ResourceObject.CimClass.CimClassQualifiers | ?{$_.Name -eq 'FriendlyName'}).Value

        # If no friendly name, then use class name
        if(-not $resourceTypeName) {$resourceTypeName = $ResourceObject.CimClass.CimClassName}

        # Handle File resource special
        if($resourceTypeName -eq 'MSFT_FileDirectoryConfiguration'){$resourceTypeName = 'File'}

        $resourceInstanceName = '#InstanceName'
    }

    # We don't need to include OMI_ConfigurationDocument as user never specify them in authoring
    if($resourceTypeName -ne 'OMI_ConfigurationDocument')
    {
        # Find list of properties that are not 'Read' properties
        $resourceClassProperties = $ResourceObject.CimClass.CimClassProperties
        $resourceProperties = @()

        # This is needed to not add 'read' properties in the configuration script.
        # Only applicable in Get-DscConfiguration scenario, not in MOF one 
        if($UseQualifier)
        {
            $resourceProperties += $resourceClassProperties |?{$_.qualifiers.Name -contains 'key'}
            $resourceProperties += $resourceClassProperties |?{$_.qualifiers.Name -contains 'required'}
            $resourceProperties += $resourceClassProperties |?{$_.qualifiers.Name -contains 'write'}
        }
        else
        {
            $resourceProperties = $resourceClassProperties
        }

        # Properties that user never specifies but added by the compiler
        # TODO: Extract PSDscRunAsCredential from the list and have code for it
        $propertiesToSkip = 'ConfigurationName','ModuleName','ModuleVersion','PsDscRunAsCredential','ResourceId','SourceInfo'
        $resourceProperties = $resourceProperties | ?{$propertiesToSkip -notcontains $_}

        "`t$resourceTypeName $resourceInstanceName"
        "`t{"
        Write-ResourcePropertiesSyntax -ResourceObject $ResourceObject -ResourceProperties $resourceProperties
        "`t}"
    }
}

function Write-DscLCMSyntax
{
    param
    (
        [Parameter(Mandatory)]
        [ciminstance]$LCMObject,

        [Switch]$UseV2Syntax
    )

    $lcmProperties = $LCMObject.CimClass.CimClassProperties |?{$_.qualifiers.Name -notcontains 'read'}
    if($UseV2Syntax){$lcmResourceName = 'Settings'}
    else{$lcmResourceName = 'LocalConfigurationManager'}

    #TODO: Handle PartialCfg, *Managers etc
    "`t$lcmResourceName"
    "`t{"
    Write-ResourcePropertiesSyntax -ResourceObject $LCMObject -ResourceProperties $lcmProperties
    "`t}"
}

function Write-ResourcePropertiesSyntax
{
    param
    (
        [Parameter(Mandatory)]
        [ciminstance]$ResourceObject,

        [Parameter(Mandatory)]
        $ResourceProperties
    )
    
    $largestPropertyLength = ($resourceProperties.Name | Sort length -Descending | select -First 1).length

    foreach($property in $ResourceProperties.Name)
    {
        $propertyValue = ($ResourceObject.CimInstanceProperties["$Property"]).Value
        $propertyType = ($ResourceObject.CimInstanceProperties["$Property"]).CimType

        if($propertyValue -ne $null)
        {
            switch ($propertyType)
            {
                'string' {"`t`t{0,-$largestPropertyLength} = '{1}'" -f $property,$propertyValue}
                'stringArray' {"`t`t{0,-$largestPropertyLength} = '{1}'" -f $property,($propertyValue -join "','")}
                'boolean' {"`t`t{0,-$largestPropertyLength} = `${1}" -f $property,$propertyValue}
                Default {"`t`t{0,-$largestPropertyLength} = {1}" -f $property,$propertyValue}
            }
        }
    }
}

Export-ModuleMember -Function Export-xDscConfiguration,Export-xDscLocalConfigurationManager