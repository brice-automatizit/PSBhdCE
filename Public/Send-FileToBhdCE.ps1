function Send-FileToBhdCE {
    <#
    .SYNOPSIS
    Send file to Bloodhound CE for ingestion

    .DESCRIPTION
    

    .PARAMETER File
    Provide File Path(s) for upload

    .PARAMETER FileInfo
    Provide FileInformation object(s) for upload

    .EXAMPLE
    PS> Send-FileToBhdCe -FileInfo $(gci C:\tmp)

    PS> Send-FileToBhdCe -File "C:\tmp\20240329132555_BloodHound.zip"    

    .NOTES
    
    #>
    [CmdletBinding(DefaultParameterSetName = 'none')]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'Files', ValueFromPipeline, Position = 0)]
        [string[]]
        $File,
        [Parameter(Mandatory, ParameterSetName = 'FilesInformation', ValueFromPipeline, Position = 0)]
        [System.IO.FileSystemInfo[]]
        $FileInfo
    )
    Begin {
        If (-not ($_BhdCeInstance -and $_BhdCeCreds)) {
            throw "Please run Connect-BhdCE before using this cmdlet"
        }
        $listFiles = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
    }
    Process {

        foreach ($path in ($File + $FileInfo)) {
            if ($path) {
                Try {
                    switch ($PSCmdlet.ParameterSetName) {
                        'Files' {
                            $infoFile = get-item -literalPath $path -ErrorAction Stop
                            break
                        }
                        'FilesInformation' {
                            $infoFile = get-item -literalPath $path.FullName -ErrorAction Stop
                            break
                        }
                    }
                    if ($infoFile.PSIsContainer) {
                        throw "Directory are not supported"
                    }
                    if ($infoFile.Extension -notin $(".json",".zip")) {
                        throw "Only json and zip files are supported"
                    }
                    $listFiles.Add($infoFile)
                } Catch {
                    Write-Warning "$($path) ignored : $_"
                }
            }
        }
    }
    End {
        If (-not $listFiles) {
            Write-Error "No accessible file supplied"
            return
        }

        Try {
            Write-Verbose "Trying to start an upload session"
            $id = Invoke-BhdCeRequest -URI 'api/v2/file-upload/start' -Method Post | Select-Object -ExpandProperty data -ErrorAction Stop | Select-Object -ExpandProperty id -ErrorAction Stop
        } Catch {
            throw "Error during start of an upload session: $_"
        }

        Write-Verbose "$($listFiles.Count) file(s) to process :"
        foreach ($objFile in $listFiles) {
            Try {
                Write-Verbose "Uploading $($objFile.FullName)"
                Invoke-BhdCeRequest -URI "api/v2/file-upload/$id" -Method Post -File $objFile.FullName
            } Catch {
                Write-Warning "Error during upload of $($objFile.FullName): $_"
            }
        }

        Try {
            Write-Verbose "Trying to close the upload session with id $($id)"
            Invoke-BhdCeRequest -URI "api/v2/file-upload/$($id)/end" -Method Post
        } Catch {
            throw "Error during closing the upload session: $_"
        }

    }
}
