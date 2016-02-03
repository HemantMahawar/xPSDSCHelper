configuration Example_ProcessAndFile
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    WindowsProcess notepad
    {
        Ensure    = 'Present'
        Path      = 'C:\windows\system32\notepad.exe'
        Arguments = ''
    }

    File temp
    {
        Ensure          = 'Present' 
        DestinationPath = 'c:\temp.ps1'
        Contents        = 'Hello World'
    }
}
Example_ProcessAndFile
