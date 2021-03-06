#---------------------------------
# Description 
#---------------------------------

param (
    [string] $subname,
    #[string] $groupEnvironment
    [string] $testGroup,
    [string] $tenantId,
    [string] $appId,
    [string] $thumb
)

#Subscription
#$subname = "yoursubhere"
#$groupEnvironment = 'DEV'

# Define group
# $testGroup = ('format'+ '_' + $groupEnvironment + '_' + 'SRE')


# if multiple subs
# $subs = @($subname1, $subname2)



function AssignPIM{

    Param(
        [Parameter(Mandatory=$true, Position=1)]
        [System.String]
        $RoleName,

        [Parameter(Mandatory=$false, Position=2)]
        [System.String]
        $ResourceType='subscription',

        [Parameter(Mandatory=$true, Position=3)]
        [System.String]
        $ResourceName,

        [Parameter(Mandatory=$false, Position=4)]
        [System.String]
        $ADGroupName,

        [Parameter(Mandatory=$true, Position=5)]
        [ValidateSet('Eligible','Active')]
        [System.String]
        $AssignmentType,
        
        [Parameter(Mandatory=$false, Position=6)]
        [System.String]
        $Justification
    )

    #Get group
    $ADGroup = Get-AzureADGroup -SearchString $ADGroupNAme

    # Get resource details
    $PIMResourceFilter = "type eq '" + $ResourceType + "' and displayname eq '" + $ResourceName + "'"
    $PIMResource = Get-AzureADMSPrivilegedResource -ProviderId AzureResources -Filter $PIMResourceFilter

    #get role details
    $PIMRoleFilter = "displayname eq '" + $RoleName + "'"
    $PIMRole = Get-AzureADMSPrivilegedRoleDefinition -ProviderId AzureResources -ResourceId $PIMResource.Id -Filter $PIMRoleFilter

    #get role settings
    $PIMRoleSettingsFilter = "ResourceId eq '" + $PIMResource.Id + "' and RoleDefinitionId eq '" + $PIMRole.Id + "'"
    $PIMRoleSettings = Get-AzureADMSPrivilegedRoleSetting -ProviderId AzureResources -Filter $PIMRoleSettingsFilter

    #update settings to allow permanent assignment
    $RoleNewSetting = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedRuleSetting
    $RoleNewSetting.RuleIdentifier = "ExpirationRule"
    $RoleNewSetting.Setting = '{"maximumGrantPeriod":"180.00:00:00","maximumGrantPeriodInMinutes":259200,"permanentAssignment":true}'

    Set-AzureADMSPrivilegedRoleSetting -ProviderId AzureResources -Id $PIMRoleSettings.Id -AdminElegibleSettings $RoleNewSetting -AdminMemberSettings $RoleNewSetting

    #assign role permanently
    $AssignmentSchedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
    $AssignmentSchedule.Type = "Once"
    $AssingmentSchedule.StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

    Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId AzureResources -Schedule $AssignmentSchedule `
    -ResourceId $PIMResource.Id -RoleDefinitionId $PIMRole.Id -SubjectId $ADGroup.ObjectId -AssignmentState $AssignmentType -Type "AdminAdd" -Reason $Justification

}

Connect-AzureAD -TenantId $tenantId -ApplicationId  $appId -CertificateThumbprint $thumb
#example
AssignPIM -RoleName "Reader" -ResourceName $subname -ADGroupName $testGroup -AssignmentType Eligible -Justification "ticket123456"

#if multiple roles
#foreach ($sub in $subs) {
    #AssignPIM -RoleName "Reader" -ResourceName $sub -ADGroupName $testGroup -Assignment -AssignmentType Eligible -Justification "ticket123456"
    #AssignPIM -RoleName "customDevops" -ResourceName $sub -ADGroupName $testGroup -Assignment -AssignmentType Eligible -Justification "ticket123456"
    #AssignPIM -RoleName "VM Contributor" -ResourceName $sub -ADGroupName $testGroup -Assignment -AssignmentType Eligible -Justification "ticket123456"
#}
