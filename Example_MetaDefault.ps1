[DscLocalConfigurationManager()]
Configuration Example_MetaDefault
{
	Settings
	{
		ActionAfterReboot              = 'ContinueConfiguration'
		AllowModuleOverwrite           = $False
		ConfigurationMode              = 'ApplyAndMonitor'
		ConfigurationModeFrequencyMins = 15
		DebugMode                      = 'NONE'
		RebootNodeIfNeeded             = $False
		RefreshFrequencyMins           = 30
		RefreshMode                    = 'PUSH'
		StatusRetentionTimeInDays      = 10
	}
}
Example_MetaDefault
