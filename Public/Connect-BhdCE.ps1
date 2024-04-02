function Connect-BhdCE {
    <#
    .SYNOPSIS

    Set internal variables for connexion.

    .DESCRIPTION

    Set internal variables for connexion.

    .PARAMETER  Instance
        
    System.Uri
    This is the fully qualified URI of your Bloodhound CE instance. ex: https://bhce.local"

    .PARAMETER Credential

    System.Management.Automation.PSCredential
    This is the credentials you will use to authenticate. TokenID in Username and TokenKey in Password

    .EXAMPLE

    PS>Connect-BhdCE -Instance 'https://bhce.local' -Credential (Get-Credential)
        
    .INPUTS
        
    System.Uri
    System.Management.Automation.PSCredential

    .OUTPUTS
        
    void
    #>
    [CmdletBinding(DefaultParameterSetName = 'Credential')]
    Param (
        [Parameter(
            HelpMessage = 'The fully qualified URI of the server. Do not include the API path.',
            Mandatory = $true,
            Position = 0,
            ParameterSetName = 'Credential'
        )]
        [System.Uri]
        $Instance,

        [Parameter(
            HelpMessage = 'This is the credentials you will use to authenticate. TokenID in Username and TokenKey in Password',
            Mandatory = $true,
            Position = 1,
            ParameterSetName = 'Credential'
        )]
        [PSCredential]
        $Credential
    )
    Begin {
        # Remove any module-scope variables in case the user is reauthenticating
        Remove-Variable -Scope Script -Name _BhdCeInstance,_BhdCeCreds -Force -ErrorAction SilentlyContinue | Out-Null
    }
    Process {
        Try {
            [BhdCeApiVersion]$(Invoke-BhdCeRequest -URI 'api/version' -Instance $instance -Credential $Credential | Select-Object -ExpandProperty data -ErrorAction Stop) | Out-Null
        } Catch  {
            Remove-Variable -Scope Script -Name _BhdCeInstance,_BhdCeCreds -Force -ErrorAction SilentlyContinue | Out-Null
            Write-Error "Error during connexion"
            throw $_
        }
    }
    End {}
}