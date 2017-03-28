[DscLocalConfigurationManager()]
Configuration Example_MetaPartial
{
	PartialConfiguration p1
    {
        ExclusiveResources = 'PSDesiredStateConfiguration\File'
        RefreshMode        = 'Push'
    }
    PartialConfiguration p2
    {
        DependsOn = '[PartialConfiguration]p1'
    }

}
Example_MetaPartial
