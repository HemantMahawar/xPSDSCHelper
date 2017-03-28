[DscLocalConfigurationManager()]
Configuration Example_MetaPull
{
    Settings
    {
        ActionAfterReboot  = 'StopConfiguration'
		ConfigurationMode  = 'ApplyAndAutoCorrect'
		RebootNodeIfNeeded = $true
		RefreshMode        = 'PULL'
        CertificateID      = [GUID]::NewGuid()
    }

    ConfigurationRepositoryWeb PullServer
    {
        ServerURL               = 'http://microsoft.com'
        AllowUnsecureConnection = $true
        ConfigurationNames      = 'WebServer','SQLServer'
    }

    ResourceRepositoryWeb ModuleServer
    {
        ServerURL       = 'http://microsoft.com'
        RegistrationKey = [GUID]::NewGuid() 
    }

    ReportServerWeb ReportServer
    {
        ServerURL               = 'http://microsoft.com'
        AllowUnsecureConnection = $false
    }
}
Example_MetaPull
