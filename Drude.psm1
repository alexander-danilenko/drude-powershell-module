<# Copyright (C) Alex Danilenko. All rights reserved. #>

requires -version 3.0

Function Check-ForDockerComposeFile(){
    $file_found = Test-Path ".\docker-compose.yml";
    Write-Verbose "docker-compose.yml file found: $file_found"

    return $file_found
}

Function Check-DockerIsRunning() {
    $docker_for_windows_process_name = "Docker for Windows";
    $docker_is_running = Get-Process "$docker_for_windows_process_name" -ErrorAction Ignore;
    Write-Verbose "Docker is running: $docker_is_running"
    if($docker_is_running -eq $null) {
        return $false;
    } else {
        return $true;
    }
}

Function Check-DockerContainerIsRunning() {
    param(
        [Parameter(Position=0,Mandatory=$true)][string]$container
    )

    $container_status = ($(docker ps --filter id=$(docker-compose ps -q $container)) -match "Up ");
    Write-Verbose "$container container status output: $container_status"
    if($container_status -match "Up ") {
        return $true
    } else {
        Write-Verbose "$container container is not running."
        return $false
    }
}

Function Check-Drude() {
    param(
        [string]$container = ""
    )

    $docker_compose_found = Check-ForDockerComposeFile
    $docker_is_running = Check-DockerIsRunning
        
    if($docker_compose_found -eq $false) {
        Write-Host -ForegroundColor Red -Object "docker-compose.yml file is not found in current directory."
        break
    }
    if ($docker_is_running -eq $false) {
        Write-Host -ForegroundColor Red -Object "Docker for Windows is not running. Start Docker for Windows first."
        break
    } 
    if (($container -ne "") -and ($(Check-DockerContainerIsRunning($container)) -eq $false)) {
        Write-Host -ForegroundColor Red -Object "Container '$container' is not running."
        break
    }

    return $true
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
    [Alias("dsh-up")]
    param (
      [Parameter(Position=0)][string]$cliContainer = "cli"
    )
    
    if(Check-Drude -eq $true){
        Write-Host -ForegroundColor Green -Object "Starting all containers..."
        docker-compose up -d --remove-orphans

        #Write-Verbose "Resetting user id in $cliContainer container ..."
        #$host_uid = $(id -u)
        #$container_uid = Invoke-DrudeBashCommand "id -u"
        #
        #if($host_uid -ne $container_uid) {
        #    Write-Verbose "Host UID ($host_uid) do not matches container UID ($container_uid)."
        #    Write-Host -ForegroundColor Yellow "Changing User ID in $cliContainer container $container_uid to $host_uid for matching host user id. It's one time operation so please be patient, it may take a while..."
        #    Invoke-DrudeBashCommand "usermod -u $host_uid -o docker" -container $cliContainer -user "root"
        #    Invoke-DrudeBashCommand "chown -R docker:users /var/www" -container $cliContainer -user "root"
        #} else {
        #    Write-Verbose "Host UID already ($host_uid) matches container UID ($container_uid)."
        #}

        #Write-Verbose "Create ~/.phpstorm_helpers/phpcs_temp.tmp for being able to use PhpSniffer in PHPStorm."
        #Invoke-DrudeBashCommand "mkdir /home/docker/.phpstorm_helpers/phpcs_temp.tmp -p -m 777" -container $cliContainer -user "root"

        Invoke-DrudeBashCommand -command "sudo service php5-fpm restart"
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
    [Alias("dsh-down","dsh-stop")]
    param ()

    if(Check-Drude -eq $true){
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
    [Alias("dsh-restart")]
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
    [Alias("dsh-status", "dsh-ps")]
    param (
        [Parameter(Position=0)][string]$container = ""
    )

    if($(Check-Drude) -eq $true) {
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
    [Alias("dsh-bash")]
    param (
        [Parameter(Position=0)][string]$container = "cli"
    )

    if($(Check-Drude -container $container) -eq $true){
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
    [Alias("dsh-exec")]
    param (
        [Parameter(Position=0,Mandatory=$true)][string]$command = "ls -la",
        [Parameter(Position=1)][string]$container = "cli",
        [string]$user = "docker"
    )

    if($(Check-Drude -container $container) -eq $true){
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
    [Alias("dsh-drush")]
    param (
        [Parameter(Position=0)][string]$command = "status",
        [Parameter(Position=1)][string]$site = "default",
        [Parameter(Position=2)][string]$docroot = "/var/www/docroot",
        [Parameter(Position=3)][string]$cliContainer = "cli"
    )

    if($(Check-Drude -container $cliContainer) -eq $true){
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
    [Alias("dsh-logs")]
    param (
        [Parameter(Position=0)][string]$container = ""
    )

    if($(Check-Drude -container $container) -eq $true){
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
    [Alias("dsh-destroy")]
    param (
      [string]$arguments = "--remove-orphans"
    )

    if($(Check-Drude) -eq $true){
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
    [Alias("dsh-reset")]
    param (
      [string]$arguments = "--remove-orphans"
    )

    if($(Check-Drude) -eq $true){
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
    [Alias("dsh-behat")]
    param (
      [Parameter(Position=0)][string]$behatParams = '',
      [string]$folder = "tests/behat"
    )

    if($(Check-Drude) -eq $true){
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
   dsh-init
.EXAMPLE
   dsh-init folderName
#>
Function Initialize-DrudeDwnd(){
    [cmdletbinding()]
    [Alias("dsh-init")]
    param ()
        $currentFolder        = Resolve-Path ".\"
        $zip_file_url         = "https://github.com/fat763/dwnd/archive/master.zip"
        $zip_tmp_filename     = "$env:temp\dwnd-temp.zip"

        Write-Host -ForegroundColor Yellow -Object "You are going to downlowd DWND template project to $currentFolder"
        $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
            "Yes, download to $folder."
        $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
            "Nope, nope nope."
        $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
        $result = $host.ui.PromptForChoice($title, "Are you sure?", $options, 0) 

        switch ($result){
            0 {
                Invoke-WebRequest -Uri $zip_file_url -OutFile $zip_tmp_filename
                Expand-Archive -Path $zip_tmp_filename -DestinationPath $env:temp
                Move-Item -Path "$env:temp\dwnd-master\**" -Destination "$currentFolder\"

                Write-Host -ForegroundColor Green -Object "DWND template project was downloaded to: $currentFolder\"
            }
        }

    [Console]::ResetColor()
}
