
Function getOutputFileName {
    $parentfolder = Split-Path -Parent $PSCommandPath
    $filename = "VM"
    $extension = ".txt"
    $outfile = $parentfolder + "\" + $filename + "-" + [DateTime]::Now.ToString("yyyyMMdd-HHmmss") + $extension
    return $outfile
}
function Create-AesManagedObject($key, $IV) {  

    $aesManaged = New-Object "System.Security.Cryptography.AesManaged"
    $aesManaged.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aesManaged.Padding = [System.Security.Cryptography.PaddingMode]::Zeros
    $aesManaged.BlockSize = 128
    $aesManaged.KeySize = 256

    if ($IV) {
        if ($IV.getType().Name -eq "String") {
            $aesManaged.IV = [System.Convert]::FromBase64String($IV)
        }
        else {
            $aesManaged.IV = $IV
        }
    }

    if ($key) {
        if ($key.getType().Name -eq "String") {
            $aesManaged.Key = [System.Convert]::FromBase64String($key)
        }
        else {
            $aesManaged.Key = $key
        }
    }

    $aesManaged
}


function Create-AesKey() {
    $aesManaged = Create-AesManagedObject 
    $aesManaged.GenerateKey()
    [System.Convert]::ToBase64String($aesManaged.Key)
}

Function pause ($message)
{
    # Check if running Powershell ISE
    if ($psISE)
    {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.MessageBox]::Show("$message")
    }
    else
    {
        Write-Host "$message" -ForegroundColor Yellow
        $x = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

$outputlog = getOutputFileName
#Login-AzureRmAccount


Set-ExecutionPolicy -Scope Process -ExecutionPolicy Unrestricted -Force;
Install-PackageProvider -Name Nuget -MinimumVersion 2.8.5.201 -Scope CurrentUser -Force
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

Install-Module -Name AzureADPreview -Scope CurrentUser

$Host.PrivateData.ConsolePaneForegroundColor = "DarkCyan"


Connect-AzureAD
$AppName = Read-Host -Prompt "Enter the name of your Azure active Directory Application to be registered in Active Directory"

$WebApp = New-AzureADApplication -DisplayName $AppName -HomePage "https://www.microsoft.com" -IdentifierUris "https://test$AppName" 


#$WebApp

[Reflection.Assembly]::LoadWithPartialName("System.Web")
$Key = [System.Web.Security.Membership]::GeneratePassword(15,2)

$keyValue = Create-AesKey 
$psadCredential = New-Object Microsoft.Open.AzureAD.Model.PasswordCredential  

$startDate = Get-Date

$psadCredential.StartDate = $startDate  

$psadCredential.EndDate = $startDate.AddYears(5)  

$psadCredential.KeyId = [guid]::NewGuid()  

$psadCredential.Value = $KeyValue 


New-AzureADServicePrincipal -AppId $WebApp.AppId -PasswordCredentials $psadCredential 
Write-Host "Application created and registered in Azure with App Id "
Write-Host "Key Vault Application Id : " $WebApp.AppId
Write-Host "Secret Key : " $keyValue
Write-Host "Object Id : " $WebApp.ObjectId

$Host.PrivateData.ConsolePaneForegroundColor = "White"

 
#Microsoft Graph Permissions
	$svcprincipal = Get-AzureADServicePrincipal -Filter "DisplayName eq 'Windows Azure Active Directory'"

#Write-Host "Service Principal : " $svcprincipal.AppId

	### Microsoft Graph
	$reqGraph = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
	$reqGraph.ResourceAppId = $svcprincipal.AppId

	##Delegated Permissions
	$delPermission1 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "311a71cc-e848-46a1-bdf8-97ff7156d8e6","Scope" #Access Directory as the signed in user



$svcprincipal2 = Get-AzureADServicePrincipal -Filter "DisplayName eq 'Microsoft.CRM'"

#Write-Host "Service Principal : " $svcprincipal2.AppId

	### Microsoft Graph
	$reqGraph2 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
	$reqGraph2.ResourceAppId = $svcprincipal2.AppId

	##Delegated Permissions
	$delPermission2 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "78ce3f0f-a1ce-49c2-8cde-64b5c0896db4","Scope" #Access Directory as the signed in user



$reqGraph.ResourceAccess = $delPermission1
$reqGraph2.ResourceAccess = $delPermission2

$App = New-AzureADApplication -DisplayName $AppName -PublicClient $true -RequiredResourceAccess $reqGraph,$reqGraph2
#$App

Write-Host "Native Application Id : " $App.AppId

#New-AzureRmRoleAssignment -RoleDefinitionName Contributor -ServicePrincipalName $AppId.ApplicationId

Write-Host "Please copy  the Key vault Application Id, Secret Key, Object Id and Native Application Id  as it will be required later"
pause "Please confirm if you have copied the Key vault Application Id, Secret Key, Object Id and Native Application Id as it will be required later"


Start-Process -FilePath https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FJitendraMishra2010%2FCRMArchival%2Fmaster%2FWebSite.json



