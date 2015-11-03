function Export-xDscConfiguration
{
    param
    (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ciminstance[]]$ConfigurationObject,

        [Parameter(Mandatory)]
        [string]$Path,

        [switch]$Passthru
    )

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

    if($configurationName -eq $null) {$configurationName = "#Name"}

    $output = & {
    "Configuration $configurationName `n{"
        foreach($object in $ConfigurationObject)
        {
            New-DscResourceSyntax -ResourceObject $object
        }
    "}"
    }

    # TODO: Validate file extension
    # TODO: Validate folder, if specified and create it
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
            New-DscLCMSyntax -LCMObject $object -UseV2Syntax:$IsV2MetaResource
        }
    "}"
    }

    # TODO: Validate file extension
    # TODO: Validate folder, if specified and create it
    Set-Content -Value $output -Path $Path
    if($Passthru) {$output}
}

function New-DscResourceSyntax
{
    param
    (
        [Parameter(Mandatory)]
        [ciminstance]$ResourceObject
    )

    # FriendlyName of the class
    if($ResourceObject.CimClass.CimClassQualifiers['FriendlyName'])
    {
        $resourceTypeName = $ResourceObject.CimClass.CimClassQualifiers['FriendlyName'].value
    }
    # If no friendly name, then use class name
    else
    {
        $resourceTypeName = $ResourceObject.CimClass.CimClassName
 
        # Handle File resource special
        if($resourceTypeName -eq 'MSFT_FileDirectoryConfiguration'){$resourceTypeName = 'File'}
    }

    # Find list of properties that are not 'Read' properties
    $resourceClassProperties = $ResourceObject.CimClass.CimClassProperties
    $resourceProperties = @()
    $resourceProperties += $resourceClassProperties |?{$_.qualifiers.Name -contains 'key'}
    $resourceProperties += $resourceClassProperties |?{$_.qualifiers.Name -contains 'required'}
    $resourceProperties += $resourceClassProperties |?{$_.qualifiers.Name -contains 'write'}

    $resourceInstanceName = $ResourceObject.CimInstanceProperties['ResourceId']
    if($resourceInstanceName -eq $null) {$resourceInstanceName = '#InstanceName'}
    else{$resourceInstanceName = $resourceInstanceName.Value.Split(']')[1]}

    # Properties that user never specifies
    $propertiesToSkip = 'ConfigurationName','ModuleName','ModuleVersion','PsDscRunAsCredential','ResourceId'
    $resourceProperties = $resourceProperties | ?{$propertiesToSkip -notcontains $_}

    "`t$resourceTypeName $resourceInstanceName `n`t{"
    Get-ResourcePropertiesSyntax -ResourceObject $ResourceObject -ResourceProperties $resourceProperties
    "`t}`n"
}

function New-DscLCMSyntax
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
    "`t$lcmResourceName `n`t{"
    Get-ResourcePropertiesSyntax -ResourceObject $LCMObject -ResourceProperties $lcmProperties
    "`t}"
}

function Get-ResourcePropertiesSyntax
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