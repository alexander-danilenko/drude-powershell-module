<# Copyright (C) Alex Danilenko. All rights reserved. #>

requires -version 3.0

Function Check-ForDockerComposeFile(){
    $file_found = Test-Path ".\docker-compose.yml";
    
    if($file_found -eq $false){
        Write-Host -ForegroundColor Red -Object "Sorry, but docker-compose.yml file is not found in current directory."
    }

    return $file_found
}

# ================================================================================================== #

<#
.Synopsis
   Start container from docker-compose.yml in current folder.
.DESCRIPTION
   Should be executed in folder with docker-compose.yml. 
   Executes "docker-compose -d"
.EXAMPLE
   Start-Drude
.EXAMPLE
   dsh-up
#>
Function Start-Drude(){
    [cmdletbinding()]
    [Alias("dsh-up", "fin-up")]
    param (
      [Parameter(Position=0)][string]$cliContainer = "cli"
    )

    if(Check-ForDockerComposeFile -eq $true){
        Write-Host -ForegroundColor Green -Object "Starting all containers..."
        docker-compose up -d --remove-orphans

        #Write-Verbose "Resetting user id in $cliContainer container ..."
        #$host_uid = $(id -u)
        #$container_uid = Invoke-DrudeBashCommand "id -u"

        #if($host_uid -ne $container_uid) {
        #    Write-Verbose "Host UID ($host_uid) do not matches container UID ($container_uid)."
        #    Write-Host -ForegroundColor Yellow "Changing User ID in $cliContainer container $container_uid to $host_uid for matching host user id. It's one time operation so please be patient, it may take a while..."
        #    Invoke-DrudeBashCommand "usermod -u $host_uid -o docker" -container $cliContainer -user "root"
        #    Invoke-DrudeBashCommand "chown -R docker:users /var/www" -container $cliContainer -user "root"
        #} else {
        #    Write-Verbose "Host UID already ($host_uid) matches container UID ($container_uid)."
        #}

        Write-Verbose "Create ~/.phpstorm_helpers/phpcs_temp.tmp for being able to use PhpSniffer in PHPStorm."
        Invoke-DrudeBashCommand "mkdir /home/docker/.phpstorm_helpers/phpcs_temp.tmp -p -m 777" -container $cliContainer -user "root"
    }
}

# ================================================================================================== #

<#
.Synopsis
   Stops containers described in docker-compose.yml in current folder.
.DESCRIPTION
   Should be executed in folder with docker-compose.yml. 
   Executes "docker-compose stop"
.EXAMPLE
   Stop-Drude
#>
Function Stop-Drude(){
    [cmdletbinding()]
    [Alias("dsh-down","dsh-stop", "fin-down","fin-stop")]
    param ()

    if(Check-ForDockerComposeFile -eq $true){
        Write-Host -ForegroundColor Green -Object "Stopping all containers..."
        docker-compose stop
    }
}

# ================================================================================================== #

<#
.Synopsis
   Restarts containers described in docker-compose.yml in current folder.
.DESCRIPTION
   Should be executed in folder with docker-compose.yml. 
   Executes "docker-compose stop; docker-compose up -d"
.EXAMPLE
   Restart-Drude
#>
Function Restart-Drude(){
    [cmdletbinding()]
    [Alias("dsh-restart", "fin-restart")]
    param ()

    Stop-Drude
    Start-Drude
}

<#
.Synopsis
   Prints status of containers described in docker-compose.yml in current folder.
.DESCRIPTION
   Should be executed in folder with docker-compose.yml. 
   Executes "docker-compose ps"
.EXAMPLE
   Get-DrudeStatus 
.EXAMPLE
   Get-DrudeStatus cli
#>
Function Get-DrudeStatus(){
    [cmdletbinding()]
    [Alias("dsh-status", "dsh-ps", "fin-status", "fin-ps")]
    param (
        [Parameter(Position=0)][string]$container = ""
    )

    if(Check-ForDockerComposeFile -eq $true){
        docker-compose ps $container
    }
}

<#
.Synopsis
   Initiates interactive bash shell session with cli container described in docker-compose.yml in current folder.
.DESCRIPTION
   Should be executed in folder with docker-compose.yml. 
.EXAMPLE
   Invoke-DrudeBash 
.EXAMPLE 
   dsh-bash
.EXAMPLE
   Invoke-DrudeBash web
.EXAMPLE
   dsh-bash web
#>
Function Invoke-DrudeBash(){
    [cmdletbinding()]
    [Alias("dsh-bash", "fin-bash")]
    param (
        [Parameter(Position=0)][string]$container = "cli"
    )

    if(Check-ForDockerComposeFile -eq $true){
        Write-Verbose "docker exec -it $(docker-compose ps -q $container) bash"
        docker exec -it $(docker-compose ps -q $container) bash
    }
    [Console]::ResetColor()
}

# ================================================================================================== #

<#
.Synopsis
   Executes command in needed container's interactive bash shell.
.DESCRIPTION
   Should be executed in folder with docker-compose.yml. 
.EXAMPLE
   Invoke-DrudeBashCommand "cat /etc/hosts" 
.EXAMPLE
   dsh-exec "cat /etc/hosts" 
.EXAMPLE 
   Invoke-DrudeBashCommand "cat /etc/hosts" cli
.EXAMPLE 
   dsh-exec "cat /etc/hosts" cli
#>
Function Invoke-DrudeBashCommand(){
    [cmdletbinding()]
    [Alias("dsh-exec", "fin-exec")]
    param (
        [Parameter(Position=0,Mandatory=$true)][string]$command = "ls -la",
        [Parameter(Position=1)][string]$container = "cli",
        [string]$user = "docker"
    )

    if(Check-ForDockerComposeFile -eq $true){
        Write-Verbose "docker exec -u $user -it $(docker-compose ps -q $container) bash -c `"$command`""
        docker exec -u $user -it $(docker-compose ps -q $container) bash -c "$command"
    }
    [Console]::ResetColor()
}

<#
.Synopsis
   Executes drush command for needed site in needed docroot folder.
.DESCRIPTION
   Should be executed in folder with docker-compose.yml. 
.EXAMPLE
   Invoke-DrudeDrushCommand "cc all" default
.EXAMPLE
   dsh-drush "cc all" default
#>
Function Invoke-DrudeDrushCommand(){
    [cmdletbinding()]
    [Alias("dsh-drush", "fin-drush")]
    param (
        [Parameter(Position=0)][string]$command = "status",
        [Parameter(Position=1)][string]$site = "default",
        [Parameter(Position=2)][string]$docroot = "/var/www/docroot",
        [Parameter(Position=3)][string]$cliContainer = "cli"
    )

    if(Check-ForDockerComposeFile -eq $true){
        Write-Verbose "docker exec -it $(docker-compose ps -q $cliContainer) bash -c `"cd $docroot && cd sites/$site && drush $command`""
        docker exec -it $(docker-compose ps -q $cliContainer) bash -c "cd $docroot && cd sites/$site && drush $command"
        [Console]::ResetColor()
    }
    [Console]::ResetColor()
}

<#
.Synopsis
   Prints logs for all or needed container described in docker-compose.yml in current folder.
.DESCRIPTION
   Should be executed in folder with docker-compose.yml. 
.EXAMPLE
   Get-DrudeLogs
.EXAMPLE
   dsh-logs
.EXAMPLE
   Get-DrudeLogs cli
.EXAMPLE
   dsh-logs cli
#>
Function Get-DrudeLogs(){
    [cmdletbinding()]
    [Alias("dsh-logs", "fin-logs")]
    param (
        [Parameter(Position=0)][string]$container = ""
    )

    if(Check-ForDockerComposeFile -eq $true){
        docker-compose logs -f $container
    }
    [Console]::ResetColor()
}

<#
.Synopsis
   Drops all containers described in docker-compose.yml in current folder.
.DESCRIPTION
   Should be executed in folder with docker-compose.yml.
   WARNING! This action may result to lose your data like databases. 
.EXAMPLE
   Clear-Drude
.EXAMPLE
   dsh-destroy
#>
Function Clear-Drude(){
    [cmdletbinding()]
    [Alias("dsh-destroy", "fin-destroy")]
    param (
      [string]$arguments = "--remove-orphans"
    )

    if(Check-ForDockerComposeFile -eq $true){
        Write-Host -ForegroundColor Cyan -Object "You are going to remove ALL CONTAINERS and their contents (like database tables, caches, manually installed packages, etc.)."
        Write-Host -ForegroundColor Red -Object "This operation cannot be undone and may result to lost of data!"
        
        $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
            "Deletes all containers and their contents."
        $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
            "Keeps all as it is."
        $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
        $result = $host.ui.PromptForChoice($title, "Are you sure?", $options, 0) 

        switch ($result){
            0 {
                docker-compose down $arguments

                Write-Host -ForegroundColor Cyan -Object "Do you want to remove all downloaded docker images?"
                Write-Host -ForegroundColor Red -Object "WARNING! This operation cannot be undone and will result to lost of data of all projects in your system!"

                $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
                    "Yes, Delete all docker images."
                $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
                    "Keeps all as it is."
                $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
                $result2 = $host.ui.PromptForChoice($title, "", $options, 1) 

                switch($result2) {
                    0 {
                        docker rmi $(docker images -q)
                    }
                }
            }
        }
    }
    [Console]::ResetColor()
}

<#
.Synopsis
   Drops all containers described in docker-compose.yml in current folder and starts containers from scratch.
.DESCRIPTION
   Should be executed in folder with docker-compose.yml.
   WARNING! This action may result to lose your data like databases. 
.EXAMPLE
   Reset-Drude
.EXAMPLE
   dsh-reset
#>
Function Reset-Drude(){
    [cmdletbinding()]
    [Alias("dsh-reset", "fin-reset")]
    param (
      [string]$arguments = "--remove-orphans"
    )

    if(Check-ForDockerComposeFile -eq $true){
        Write-Host -ForegroundColor Cyan -Object "You are going to remove ALL CONTAINERS and their contents (like database tables, caches, manually installed packages, etc.)."
        Write-Host -ForegroundColor Red -Object "This operation cannot be undone and may result to lost of data!"

        $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
            "Deletes all containers and their contents."
        $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
            "Keeps all as it is."
        $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
        $result = $host.ui.PromptForChoice($title, "Are you sure?", $options, 0) 

        switch ($result){
          0 {
            docker-compose down $arguments
            Start-Drude
            [Console]::ResetColor()
          }
        }
    }
    [Console]::ResetColor()
}

<#
.Synopsis
   Run behat tests in needed folder.
.DESCRIPTION
   Should be executed in folder with docker-compose.yml.
   Next files should exist:
   - .\tests\behat\composer.json
   - .\tests\behat\behat.yml
.EXAMPLE
   Invoke-DrudeBehat
.EXAMPLE
   dsh-behat
.EXAMPLE
   dsh-behat "--tags=@drush"
#>
Function Invoke-DrudeBehat(){
    [cmdletbinding()]
    [Alias("dsh-behat", "fin-behat")]
    param (
      [Parameter(Position=0)][string]$behatParams = '',
      [string]$folder = "tests/behat"
    )

    if(Check-ForDockerComposeFile -eq $true){
        $behat_folder_found   = Test-Path $folder
        $behat_yml_found      = Test-Path "$folder/behat.yml"
        $behat_binary_bound   = Test-Path "$folder/bin/behat"
        
        $error = '';
        if($behat_folder_found -eq $false) {
            $error = "$folder folder is not found."
        } 

        if ($behat_yml_found -eq $false) {
            $error = "File $folder/behat.yml is not found. Usually it means that you need to copy behat.yml.dist to behat.yml"
        } 

        if($error -ne ''){
            Write-Host -ForegroundColor Red -Object $error
        } else {
            if($behat_binary_bound -eq $false){
                Write-Host -ForegroundColor Yellow -Object "Behat is not installed. Installing..."
            }
            Invoke-DrudeBashCommand -container cli -command "cd $folder && composer install --prefer-source --no-interaction && ./bin/behat -p docker $behatParams"
        }
    }
    [Console]::ResetColor()
}


<#
.Synopsis
   Initialize new project based on DWND.
.DESCRIPTION
   Downloads and unpacks zip archive from GitHub to needed folder.
.EXAMPLE
   Initialize-DrudeDwnd
.EXAMPLE
   Initialize-DrudeDwnd folderName
.EXAMPLE
   dsh-init-dwnd
.EXAMPLE
   dsh-init-dwnd folderName
#>
Function Initialize-DrudeDwnd(){
    [cmdletbinding()]
    [Alias("dsh-init-dwnd", "fin-init-dwnd")]
    param (
      [Parameter(Position=0)][string]$folder = 'dwnd'
    )
        $currentFolder        = Resolve-Path ".\"
        $zip_file_url         = "https://github.com/fat763/dwnd/archive/master.zip"
        $unzipped_folder_name = "dwnd-master"
        $zip_tmp_filename     = "dwnd-temp.zip"

        $end_zip_tmp    = Join-Path $currentFolder -ChildPath $zip_tmp_filename
        $end_folder     = Join-Path $currentFolder -ChildPath $folder
        $end_folder_tmp = Join-Path $currentFolder -ChildPath $unzipped_folder_name
        
        $folder_already_exists = Test-Path ".\$folder"
        if($folder_already_exists -eq $true) {
            Write-Host -ForegroundColor Red -Object "Folder $end_folder already exists. Aborting..."
        } else {
            Write-Host -ForegroundColor Yellow -Object "You are going to downlowd DWND template project to $end_folder"
            $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
                "Yes, download to $end_folder."
            $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
                "Nope, nope nope."
            $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
            $result = $host.ui.PromptForChoice($title, "Are you sure?", $options, 0) 

            switch ($result){
                0 {
                    # This code is just copy-pasted. I would be really appreciated if somebody can refactor this.
                    (New-Object Net.WebClient).DownloadFile($zip_file_url.ToString(), $end_zip_tmp.ToString());(new-object -com shell.application).namespace($currentFolder.ToString()).CopyHere((new-object -com shell.application).namespace($end_zip_tmp.ToString()).Items(),16)
        
                    Remove-Item -Path "$end_zip_tmp" -Force -ErrorAction Stop
                    Rename-Item -Path "$end_folder_tmp" $folder -Force -ErrorAction Stop

                    Write-Host -ForegroundColor Green -Object "DWND template project was downloaded to: $end_folder"
                }
            }
        }
    [Console]::ResetColor()
}
