Write-Verbose "Import AzureAD module because is not on default VSTS agent"
$azureAdModulePath = $PSScriptRoot + "\AzureAD\2.0.1.16\AzureAD.psd1"
Import-Module $azureAdModulePath 

# Workaround to use AzureAD in this task. Get an access token and call Connect-AzureAD
$serviceNameInput = Get-VstsInput -Name ConnectedServiceNameSelector -Require
$serviceName = Get-VstsInput -Name $serviceNameInput -Require
$endPointRM = Get-VstsEndpoint -Name $serviceName -Require

$appId = $endPointRM.Auth.Parameters.ServicePrincipalId
$secret = $endPointRM.Auth.Parameters.ServicePrincipalKey
$tenantId = $endPointRM.Auth.Parameters.TenantId

$adTokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/token"
$resource = "https://graph.windows.net/"

$body = @{
    grant_type    = "client_credentials"
    client_id     = $appId
    client_secret = $secret
    resource      = $resource
}

$response = Invoke-RestMethod -Method 'Post' -Uri $adTokenUrl -ContentType "application/x-www-form-urlencoded" -Body $body
$token = $response.access_token

Write-Verbose "Login to AzureAD with same application as endpoint"
Connect-AzureAD -AadAccessToken $token -AccountId $appId -TenantId $tenantId