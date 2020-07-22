
Function getOutputFileName {
    $parentfolder = Split-Path -Parent $PSCommandPath
    $filename = "VM"
    $extension = ".txt"
    $outfile = $parentfolder + "\" + $filename + "-" + [DateTime]::Now.ToString("yyyyMMdd-HHmmss") + $extension
    return $outfile
}
$outputlog = getOutputFileName
Login-AzureRmAccount

$subId = Read-Host -Prompt "Enter your Subscription Id!"

Select-AzureRmSubscription -SubscriptionId $subId

#Switch to the CosmicDev subscription 
#Select-AzureRmSubscription -SubscriptionId 66d1bf86-261e-4624-af80-9c37a77b5f4a

$AppName = Read-Host -Prompt "Enter the name of your Azure active Directory Application to be registered in Active Directory"


$App = New-AzureRmADApplication -DisplayName $AppName -HomePage "https://www.microsoft.com" -IdentifierUris "http://test$AppName"
$App

Write-Host "Application created in Azure with App Id : " $App.ApplicationId


Sleep -Seconds 20

[Reflection.Assembly]::LoadWithPartialName("System.Web")
$Key = [System.Web.Security.Membership]::GeneratePassword(15,2)


$AppId = New-AzureRmADServicePrincipal –ApplicationId $App.ApplicationId -Password $Key
$AppId

Write-Host "Application created and registered in Azure with App Id "
Write-Host "Application Id : " $App.ApplicationId
Write-Host "Object Id : " $AppId.Id
Write-Host "Please copy  the Application Id and Object Id  as it will be required later"

Sleep -Seconds 20

Start-Process -FilePath https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FJitendraMishra2010%2FCRMArchival%2Fmaster%2FWebSite.json


#New-AzureRmRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $AppId.ApplicationId




