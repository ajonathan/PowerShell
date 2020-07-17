<#
    .DESCRIPTION    
        Creates and exports Root and Client Certificate.
        The script uses openssl in the default directory "C:\Program Files\OpenSSL-Win64\bin"

    .NOTES
        CREATED WITH: Visual Studio Code
        AUTHOR: Jonathan
        LAST UPDATED: 07/17/2020
        FILENAME: 

    .PARAMETER OpenSslDir
        The dir where openssl.exe exist

    .PARAMETER RootCertName
        The name of the root certificate

    .PARAMETER ChildCertName
        The name of the client certificate

    .EXAMPLE
        ./Create-RootAndClientCertificate.ps1
#>
    
[CmdletBinding (DefaultParametersetName="first")]
param 
(
    # First parameter
    [Parameter (ParameterSetName="first", Mandatory=$false)]
    [string]
    $OpenSslDir = "C:\Program Files\OpenSSL-Win64\bin",

    # Second parameter
    [Parameter (Mandatory=$false)]
    [bool]
    $RootCertName = "P2SRootcert",

    # Thired parameter
    [Parameter (Mandatory=$false)]
    [bool]
    $ChildCertName = "P2SChildCert"
)
begin 
{ 
    $passwd = Read-Host 'Write Certificate Password?'
    $dir = Get-Location
}
process 
{
    try 
    {
        $rootCert = New-SelfSignedCertificate -Type Custom -KeySpec Signature `
            -Subject "CN=$RootCertName" -KeyExportPolicy Exportable `
            -HashAlgorithm sha256 -KeyLength 2048 `
            -CertStoreLocation "Cert:\CurrentUser\My" -KeyUsageProperty Sign -KeyUsage CertSign
    
        $clientCert = New-SelfSignedCertificate -Type Custom -DnsName $ChildCertName -KeySpec Signature `
            -Subject "CN=$ChildCertName" -KeyExportPolicy Exportable `
            -HashAlgorithm sha256 -KeyLength 2048 `
            -CertStoreLocation "Cert:\CurrentUser\My" `
            -Signer $rootCert -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")
    
        $clientCert
    
        $pwdSecure = ConvertTo-SecureString `
            -String $passwd `
            -Force `
            -AsPlainText
    
        Export-PfxCertificate -Cert $clientCert -FilePath "$dir\P2SClientCert.pfx" -Password $pwdSecure
        Export-Certificate -Cert $rootCert -FilePath "$dir\P2SRootCert.cer" -Type CERT
        
        Write-host "Write Certificate Password again?"
        & "C:\Program Files\OpenSSL-Win64\bin\openssl.exe" pkcs12 -in "$dir\P2SClientCert.pfx" -nodes -out "$dir\profileinfo.txt"
    }
    catch 
    {
        Write-host $_.Exception.Message
    }
}
end {}