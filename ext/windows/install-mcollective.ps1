# run this powershell in installshield http://helpnet.flexerasoftware.com/installshield19helplib/helplibrary/CAPowerShell.htm
# Add-Member -PassThru -MemberType Property -TypeName @{Installed = $_; Gem = $gem}

# stop in case there's an error!
$ErrorActionPreference = "Stop"

Function Unzip(
    $zip,
    $targetPath
) {
    if (Test-Path $targetPath) {
        Write-Warning "Target path $targetPath already exists"
    }

    if (! (Test-Path $zip)) {
        throw "Could not find zip: $zip"
    }

    [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zip, $targetPath)
}

Function Write-Happy(
    [string] $string
) {
    Write-Host -ForegroundColor Green $string
}

Function Check-Ruby() {
    if ( ! (Get-Command "ruby")) {
        Write-Error "First install ruby"
    } else {
        Write-Happy "Ruby is installed"
    }
}

Function Check-Gems() {
    
    Write-Happy "Check-Gems: Gathering Part"

    $toinstall = "stomp", "win32-process", "win32-service", "sys-admin", "windows-api" | % {
        new-object PSObject -Property @{
            Gem = $_;
            Installed = $(gem list -d $_).Split([Environment].NewLine) -contains $_
        }
    } | % { 
        Write-Host "The gem $($_.Gem) is installed: $($_.Installed)" ; $_
    } | where {
        -not $_.Installed
    }
    
    Write-Happy -ForegroundColor Green "Check-Gems: Installation Part."

    $toinstall | % { 
        Write-Host "Installing $($_.Gem)" -ForegroundColor Yellow
       gem install $_.Gem --no-rdoc --no-ri
    }
}

Function Get-MCollective {
    if ( ! (Get-Command "git")) {
        throw "missing git.exe"
    }

    if ( Test-Path $env:SystemDrive\marionette-collective ) {
        throw "mcollective folder already exist, please remove before running installer"
    }

    Write-Happy "Downloading MCollective"
    cd $env:SystemDrive\
    git clone git://github.com/puppetlabs/marionette-collective.git
    cd marionette-collective
    git checkout 2.3.0
    cp -Recurse .\ext\windows\* .\bin
    
    if ( ! (Test-Path .\plugins)) {
        mkdir .\plugins
    }
}

Function Check-Configuration() {
    Write-Warn "TODO - write mcollective configuration"
}

Function Check-Service() {
    cd $env:SystemDrive\marionette-collective\bin
    & .\register_service.bat
}

Check-Ruby
Check-Gems
Get-MCollective
Check-Configuration
# Check-Service