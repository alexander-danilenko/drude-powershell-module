# Drude Powershell Module

![Drude Powershell Module Preview image](http://armarium.org/u/2016/09/07/d18823bd8b993399fc7ed440c5125824.png)

**Drude Powershell module** is just a collection of PowerShell functions that works the same as in original [Drude](https://github.com/blinkreaction/drude). 

Module is available in PowershellGallery: https://www.powershellgallery.com/packages/Drude

It means that you don't need to install any additional software for install/update/uninstall Drude PowerShell module. Pretty cool, hah?

Just remember, **Drude PowerShell module and all this repo contents are not official parts of Drude!** It's just workaround for Windows 10 users who suffered long enough.

## Drude Powershell Module
### Installation
You need to allow PowerShell modules to run in your system. For allowing it - just open `powershell as Administrator` and execute next: 

```powershell 
Set-ExecutionPolicy RemoteSigned
```

Install Drude PowerShell module

```powershell 
Install-Module Drude
```

### Update
Wanna some cool and tasty new features? 
```powershell 
Update-Module Drude
```

### Uninstall
Hate this thing? Just remove it!
```powershell 
Uninstall-Module Drude
```

### Commands
You can get list of commands using next command in PowerShell:
```powershell
Get-Command dsh-*
```

**Note**: All commands should be executed in folder with `docker-compose.yml`.

### Getting help
All commands are documented and you can see example of usage just use default PowerShell help: 
```powershell 
Get-Help dsh-bash -examples
```

## Links
- [DWND - Drude on Windows Native Docker](https://github.com/fat763/dwnd) - Project template for using with Drude Powershell module.  
- [Docker official site](https://www.docker.com/)
- [Docker official documentation](https://docs.docker.com/)
- [Drude](https://github.com/blinkreaction/drude) - Drupal Docker Environment. Source of inspiration for author of this Powershell Module. 


- - -
### MIT License

Copyright (c) 2016 Alexander Danilenko.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
