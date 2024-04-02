# Classes for parameter validation
class BhdCeApiVersionDetails {
    [string]$current_version
    [string]$deprecated_version
}

class BhdCeApiVersion {
    [string]$server_version
    [BhdCeApiVersionDetails]$API
}