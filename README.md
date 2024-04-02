# PSBhdCE

[![PowerShell Gallery][psgallery-badge]][psgallery]

A PowerShell module for interfacing with Bloodhound Community Edition API

## Usage

### Install

```PowerShell
PS> Install-Module PSBhdCE
```

### Import

```PowerShell
PS> Import-Module PSBhdCE
```

### Connect

```PowerShell
PS> Connect-BhdCe -Instance "https://<your appliance uri>" -Credential $([PSCredential]::New($TokenID,[securestring](ConvertTo-SecureString $TokenKey -AsPlainText -Force)))
```

Enter your instance URI in the Instance parameters, for the credentials, specify the Token Id in the username and Token Key in the password

### Example for unattended

```PowerShell
PS> # Save credentials
PS> Get-Credential | Export-CliXml "$($ENV:USERPROFILE)\bhdce.xml"
PS> # Use those save credentials (same computer, same windows session)
PS> Connect-BhdCe -ServerUri "https://<your appliance uri>" -Credential $(Import-Clixml "$($ENV:USERPROFILE)\bhdce.xml")
```

### Send a file for ingestion

Send collected Sharphound file (zip a/o json) to the File ingestor

```PowerShell
PS> Send-FileToBhdCe -FileInfo $(gci C:\tmp)
```

```PowerShell
PS> Send-FileToBhdCe -File "C:\tmp\20240329132555_BloodHound.zip"
```

[psgallery-badge]:      https://img.shields.io/powershellgallery/dt/PSBhdCE.svg
[psgallery]:            https://www.powershellgallery.com/packages/PSBhdCE