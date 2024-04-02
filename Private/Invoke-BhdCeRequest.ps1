function Invoke-BhdCeRequest {

    [CmdletBinding()]
    Param (
        [Parameter(Position = 0)]
        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $Method = 'Get',

        [Parameter(
            Mandatory = $true,
            Position = 1
        )]
        [string]
        $URI,

        [Parameter(
            Mandatory = $false,
            Position = 2
        )]
        [string]
        $TokenKey,

        [Parameter(
            Mandatory = $false,
            Position = 3
        )]
        [string]
        $TokenID,

        [Parameter(
            Mandatory = $false,
            Position = 4
        )]
        [System.Uri]
        $Instance,

        [Parameter(
            Mandatory = $false,
            Position = 5
        )]
        [string]
        $Body = "",

        [Parameter(
            Mandatory = $false,
            Position = 6
        )]
        [string]
        $File = "",

        [Parameter(
            Mandatory = $false,
            Position = 7
        )]
        [PSCredential]
        $Credential
    )
    Begin {
        If ($Instance) {
            Set-Variable -Name _BhdCeInstance -Value $Instance -Option ReadOnly -Scope Script -Force
        }
        if ($TokenKey -and $TokenID) {
            Set-Variable -Name _BhdCeCreds -Value $([PSCredential]::New($TokenID,[securestring](ConvertTo-SecureString $TokenKey -AsPlainText -Force))) -Option ReadOnly -Scope Script -Force
        }
        if ($Credential) {
            Set-Variable -Name _BhdCeCreds -Value $Credential -Option ReadOnly -Scope Script -Force
        }
        If (-not ($_BhdCeInstance -and $_BhdCeCreds)) {
            throw "Please run Connect-BhdCE or provide at least once the Instance, TokenID and TokenKey parameters"
        }
    }
    Process {
        if (!$URI.StartsWith('/')) {
            $URI = $URI.Insert(0,'/')
        }
        #$URI = $URI.TrimStart("/")
        # Digester is initialized with HMAC-SHA-256 using the token key as the HMAC digest key.
        $digester = [System.Security.Cryptography.HMACSHA256]::New([Text.Encoding]::UTF8.GetBytes($_BhdCeCreds.GetNetworkCredential().Password))

        # OperationKey is the first HMAC digest link in the signature chain
        $operationKey = $digester.ComputeHash([Text.Encoding]::UTF8.GetBytes($Method.ToString().ToUpper() + $URI))

        # DateKey is the next HMAC digest link in the signature chain
        $digester.key = $operationKey 
        $datetimeFormatted = $(Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
        $dateKey = $digester.ComputeHash([Text.Encoding]::UTF8.GetBytes($datetimeFormatted.Substring(0,13)))

        # Body signing is the last HMAC digest link in the signature chain. 
        $digester.key = $dateKey
        if ($file -ne "") {
            $bodyBytes = [System.IO.File]::ReadAllBytes($File)
        } else {
            $bodyBytes = [Text.Encoding]::Default.GetBytes($body)
        }
        $bodyKey = $digester.ComputeHash($bodyBytes)

        # Perform the request with the signed and expected headers
        $HashArguments = @{
            URI = "$($_BhdCeInstance.AbsoluteUri.TrimEnd('/'))${URI}"
            Method = $method
            ContentType = "application/json;charset=utf-8" 
            Headers = @{
                "Authorization" = "bhesignature $($_BhdCeCreds.UserName)"
                "RequestDate" = $datetimeFormatted;
                "Signature" = [Convert]::ToBase64String($bodyKey);
                "Content-Type"= "application/json"
            }
        }
        if ($body -ne "") {
            $HashArguments.Add("Body",$body)
        }
        if ($file -ne "") {
            if ($(get-item $File | Select-Object -ExpandProperty Extension) -eq ".zip") {
                $HashArguments.ContentType = "application/x-zip-compressed" 
            }
            $HashArguments.Add("InFile",$file)
        }
        Try {
            Invoke-RestMethod @HashArguments
        } Catch {
            if ($_.ErrorDetails.Message -match "Server time is \d") {
                #TODO: handle server timezone
                Write-Error "Looks like a timezone issue. Try to change the Time parameter"
            }
            throw $_
        }
    }
    End {
    }

}