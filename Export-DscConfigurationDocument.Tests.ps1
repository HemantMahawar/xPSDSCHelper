$here                      = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module $here\Export-DscConfigurationDocument.psm1 -Force

$exampleFolder            = "$here\Example_ProcessAndFile"
$mofOutputFile            = . $here\Example_ProcessAndFile.ps1
                          
$metaDefaultExampleFolder = "$here\Example_MetaDefault"                           
$metaDefaultOutputFile    = . $here\Example_MetaDefault.ps1
                          
$metaPartialExampleFolder = "$here\Example_MetaPartial"                           
$metaPartialOutputFile    = . $here\Example_MetaPartial.ps1
                          
$metaPullExampleFolder    = "$here\Example_MetaPull"                           
$metaPullOutputFile       = . $here\Example_MetaPull.ps1
                          
$scriptOutputFileName     = "$here\Example_ConfigurationScript.ps1"
$metaScriptOutputFileName = "$here\Example_MetaConfigurationScript.ps1"


try
{
    Describe 'Export-xDscConfiguration input validation' {
    }

    Describe 'Export-xDscLocalConfigurationManager input validation' {
    }

    Describe 'Export-xDsc*Configuration* output file extension validation' {
    }

    Describe 'Export-xDscConfiguration with configuration document' {
    
        $result1 = Export-xDscConfiguration -ConfigurationDocumentPath $exampleFolder\localhost.mof -OutputPath $scriptOutputFileName -Passthru
        It 'produces an output file'{
            Test-Path $scriptOutputFileName | Should be $true
        }

        $result2 = "$exampleFolder\localhost.mof" | Export-xDscConfiguration -OutputPath $scriptOutputFileName -Passthru
        It 'produces an output file with input from pipeline' {
            Test-Path $scriptOutputFileName | Should be $true
        }

        It 'produces same result in pipeline and non-pipeline case' {
            Compare-Object $result1 $result2 | Should be $null
        }

        It 'produces same content in memory and on disk' {
            Compare-Object $result1 (Get-Content $scriptOutputFileName) | Should be $null
        }

        It 'has configuration keyword in the output' {
           $result1[0].Contains('Configuration') | Should be $true
        }

        It 'has resource friendly names in the output' {
           $result1[2].Contains('WindowsProcess') | Should be $true
           $result1[8].Contains('File') | Should be $true
        }

        if($PSVersionTable.PSVersionTable -like "4.*")
        {
            It 'does not have configuration name in the output' {
                $true
            }

            It 'does not have resource instance name in the output' {
                $true
            }
        }
        else
        {
            It 'has configuration name in the output' {
                $result1[0].Contains('Example_ProcessAndFile') | Should be $true
            }

            It 'has resource instance name in the output' {
                $result1[2].Contains('notepad') | Should be $true
                $result1[8].Contains('temp') | Should be $true
            }
        }

        It 'does not have OMI_ConfigurationDocument in the output' {
            $result1 | ? {$_.Contains('OMI_ConfigurationDocument')} | Should be $null
        }
    }

    Describe 'Export-xDscConfiguration with configuration object' {

        # Invoke the example configuration
        Start-DscConfiguration -Path $exampleFolder -Force -Wait

        $result1 = Export-xDscConfiguration -ConfigurationObject (Get-DscConfiguration) -OutputPath $scriptOutputFileName -Passthru
        It 'produces an output file'{
            Test-Path $scriptOutputFileName | Should be $true
        }

        $result2 = Get-DscConfiguration | Export-xDscConfiguration -OutputPath $scriptOutputFileName -Passthru
        It 'produces an output file with input from pipeline' {
            Test-Path $scriptOutputFileName | Should be $true
        }

        It 'produces same result in pipeline and non-pipeline case' {
            Compare-Object $result1 $result2 | Should be $null
        }

        It 'produces same content in memory and on disk' {
            Compare-Object $result1 (Get-Content $scriptOutputFileName) | Should be $null
        }

        It 'has configuration keyword in the output' {
           $result1[0].Contains('Configuration') | Should be $true
        }

        It 'has resource friendly names in the output' {
           $result1[2].Contains('WindowsProcess') | Should be $true
           $result1[8].Contains('File') | Should be $true
        }

        if($PSVersionTable.PSVersionTable -like "4.*")
        {
            It 'does not have configuration name in the output' {
                $true
            }

            It 'does not have resource instance name in the output' {
                $true
            }
        }
        else
        {
            It 'has configuration name in the output' {
                $result1[0].Contains('Example_ProcessAndFile') | Should be $true
            }

            It 'has resource instance name in the output' {
                $result1[2].Contains('notepad') | Should be $true
                $result1[8].Contains('temp') | Should be $true
            }
        }

        It 'does not have OMI_ConfigurationDocument in the output' {
            $result1 | ? {$_.Contains('OMI_ConfigurationDocument')} | Should be $null
        }
    }

    Describe 'Export-xDscLocalConfigurationManager with Default meta document' {
        $result1 = Export-xDscLocalConfigurationManager -LCMDocumentPath $metaDefaultExampleFolder\localhost.meta.mof -OutputPath $metaScriptOutputFileName -Passthru
        It 'produces an output file'{
            Test-Path $metaDefaultOutputFileName | Should be $true
        }

        $result2 = "$metaDefaultExampleFolder\localhost.meta.mof" | Export-xDscLocalConfigurationManager -OutputPath $metaScriptOutputFileName -Passthru
        It 'produces an output file with input from pipeline' {
            Test-Path $scriptOutputFileName | Should be $true
        }

        It 'produces same result in pipeline and non-pipeline case' {
            Compare-Object $result1 $result2 | Should be $null
        }

        It 'produces same content in memory and on disk' {
            Compare-Object $result1 (Get-Content $metaScriptOutputFileName) | Should be $null
        }

        <#
        It 'has configuration keyword in the output' {
           $result1[0].Contains('Configuration') | Should be $true
        }

        It 'has resource friendly names in the output' {
           $result1[2].Contains('WindowsProcess') | Should be $true
           $result1[8].Contains('File') | Should be $true
        }

        if($PSVersionTable.PSVersionTable -like "4.*")
        {
            It 'does not have configuration name in the output' {
                $true
            }

            It 'does not have resource instance name in the output' {
                $true
            }
        }
        else
        {
            It 'has configuration name in the output' {
                $result1[0].Contains('Example_ProcessAndFile') | Should be $true
            }

            It 'has resource instance name in the output' {
                $result1[2].Contains('notepad') | Should be $true
                $result1[8].Contains('temp') | Should be $true
            }
        }

        It 'does not have OMI_ConfigurationDocument in the output' {
            $result1 | ? {$_.Contains('OMI_ConfigurationDocument')} | Should be $null
        }
        #>
    }

    Describe 'Export-xDscLocalConfigurationManager with Default meta object' {
    }

    Describe 'Export-xDscLocalConfigurationManager with Pull meta document' {
    }

    Describe 'Export-xDscLocalConfigurationManager with Partial meta document' {
    }


}

# Clean-up after running tests
Finally
{
    Remove-Item (Split-Path $mofOutputFile) -Recurse -Force
    Remove-Item $scriptOutputFileName
    Remove-DscConfigurationDocument -Stage Current,Pending
}
