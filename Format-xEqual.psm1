﻿function Format-Equals
{
    $selectedText = $psise.CurrentFile.Editor.SelectedText
    [System.Management.Automation.Language.Token[]]$tokens = $null
    [System.Management.Automation.Language.ParseError[]]$parseErrors = $null

    # Parse the input to get scriptblock Ast
    $scriptAst = [System.Management.Automation.Language.Parser]::ParseInput($selectedText, [ref]$tokens, [ref]$parseErrors)
    # Bail out if there are parse errors
    if($parseErrors){throw $parseErrors.Message}

    # String array for the scriptblock
    # Will update this one with the result
    $scriptContentArray = $scriptAst.Extent.Text.Split("`n")

    if($PSVersionTable.PSVersionTable -like "4.*")
    {
        # Find the hashtable Ast of the scriptblock
        $hashtableAst = $scriptAst.FindAll(
                                        {param ($n)
                                            $n -as [System.Management.Automation.Language.HashtableAst] -and
                                            $n.Parent -is [System.Management.Automation.Language.CommandParameterAst]
                                        },$true
                                    )

        # Go over each object and update the scriptblock content
        $hashtableAst | % { 
            $columnPadding = ' '*$($_.Extent.StartColumnNumber)
            $htStartLineNumber = $_.Extent.StartLineNumber
            $longestPropertyLength  = ($_.keyvaluepairs.item1.Value | sort -Descending -Property Length | select -First 1).Length
            $_.keyValuePairs | % 
            {
                if([String]::IsNullOrEmpty($scriptContentArray[$htStartLineNumber]) -or [String]::IsNullOrWhiteSpace($scriptContentArray[$htStartLineNumber]))
                {
                    #If the scriptContentArray entry is blank/whitespaced line, skip it
                }
                else
                {
                    $scriptContentArray[$htStartLineNumber]= "$columnPadding`t{0,-$longestPropertyLength} = {1}" -f $_.item1,$_.item2
                }
                $htStartLineNumber++
            }
        }
    }
    elseif($PSVersionTable.PSVersion -like "5.*")
    {
        $hashtableAst = $scriptAst.FindAll(
                                        {param ($n)
                                            $n -as [System.Management.Automation.Language.DynamicKeywordStatementAst] #-and
                                            #$n.Parent -is [System.Management.Automation.Language.CommandParameterAst]
                                        },$true
                                    )
    }

    $psISE.CurrentFile.Editor.InsertText($scriptContentArray -join "`n")
    $psISE.CurrentFile.Editor.Select($scriptAst.Extent.StartLineNumber, $scriptAst.Extent.StartColumnNumber, $scriptAst.Extent.EndLineNumber,$scriptAst.Extent.EndColumnNumber)
}
 
 # Check if the host this module is imported from is ISE
 if($host.name -like '*PowerShell ISE*')
 {
    #========================================================== # Add ISE Add-ons. #===========================================
    # Add a new option in the Add-ons menu to align '=' for a configuration block 
    if (!($psISE.CurrentPowerShellTab.AddOnsMenu.Submenus | Where-Object { $_.DisplayName -eq "Align Configuration Elements" }))
    {
        $psISE.CurrentPowerShellTab.AddOnsMenu.Submenus.Add("Align Configuration Elements",{Format-Equals},"Ctrl+E") 
    }
}

Export-ModuleMember -Function ''  