function Get-Schema {
    [CmdletBinding()]
    param (
        # Provide ProviderNamespace from Get-AzResourceProvider
        [Parameter(Mandatory = $true)]
        [string]
        $ProviderNamespace,
        [switch]
        $latest = $false
    )

    begin {
        $api = 'https://api.github.com/'
        $organization = 'Azure'
        $repository = 'azure-resource-manager-schemas'
    }

    process {
        $provider = $ProviderNamespace
        $fileName = '{0}.json' -f $provider
        $searchQuery = ("search/code?q=org:{0}+repo:{1}+filename:{2}" -f $organization, $repository, $fileName)

        $URI = $api + $searchQuery
        try {
            Write-Verbose "[$(Get-Date) Get $URI]"
            $api = Invoke-RestMethod -Method Get -Uri $URI
        }
        catch {
            throw $_
        }

        if ($latest) {
            # TODO: refactor
            $schemas = Get-Object $api.items
            if ( ! $schemas) {
                throw "No schema found $provider"
            }
            elseif ($schemas.Length -eq 1) {
                $schemas
            }
            else {
                ($schemas)[-1]
            }
        }
        else {
            Get-Object $api.items
        }
    }

    end {
    }
}

function Get-Object($items) {
    foreach ($item in $items) {

        if (! ($item.Path -match 'schemas*')) {
            Continue
        }

        $apiVersion = ($item.Path -split '/')[-2]

        $base64Content = (Invoke-RestMethod -Method Get -Uri $item.git_url).content
        $content = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($base64Content))

        @{
            Name       = $item.name
            git_url    = $item.git_url
            apiVersion = $apiVersion
            content    = $content
        }
    }
}

Get-Schema -ProviderNamespace Microsoft.Storage -latest


