Function Get-UserProfiles {
	<#
		.SYNOPSIS
			Gets all of the user profiles on the system.

		.DESCRIPTION
			The Get-UserProfiles cmdlet uses the Win32_UserProfile WMI class to get user profile paths. It ignores special profiles like the local system.

		.EXAMPLE
			Get-UserProfiles

			Gets all of the user profiles on the system as an array of path strings.

		.INPUTS
			None

		.OUTPUTS
			System.String[]

		.NOTES
			AUTHOR: Michael Haken
			LAST UPDATE: 4/25/2016
	#>
	[CmdletBinding()]
	[OutputType([System.String[]])]
	Param(
	)

	Begin {}

	Process {
		Write-Output -InputObject (Get-WmiObject -Class Win32_UserProfile | Where-Object {$_.Special -eq $false} | Select-Object -ExpandProperty LocalPath)
	}

	End {		
	}
}

Function Get-AccountSid {
	<#
		.SYNOPSIS
			Gets the SID of a given username.

		.DESCRIPTION
			The cmdlet gets the SID of a username, which could a service account, local account, or domain account. The cmdlet returns null if the username could not be translated.

		.PARAMETER UserName
			The name of the user or service account to get the SID of.

		.PARAMETER ComputerName
			If the account is local to another machine, such as an NT SERVICE account or a true local account, specify the computer name the account is on.

		.PARAMETER Credential
			The credentials used to connect to the remote machine.
			
		.INPUTS
			None

		.OUTPUTS
			System.Security.Principal.SecurityIdentifier

        .EXAMPLE
			Get-AccountSid -UserName "Administrator"

			Gets the SID for the Administrator account.

		.EXAMPLE
			Get-AccountSid -UserName "NT AUTHORITY\Authenticated Users"

			Gets the SID for the Authenticated Users group.

		.EXAMPLE
			Get-AccountSid -UserName "NT AUTHORITY\System"

			Gets the SID for the SYSTEM account. The user name could also just be "System".

		.EXAMPLE
			Get-AccountSid -UserName "NT SERVICE\MSSQLSERVER" -ComputerName SqlServer

			Gets the SID for the virtual MSSQLSERVER service principal.

		.NOTES
			AUTHOR: Michael Haken
			LAST UPDATE: 2/23/2017
	#>
	[CmdletBinding()]
	[OutputType([System.Security.Principal.SecurityIdentifier])]
	Param(
		[Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]$UserName,

		[Parameter(Position = 1)]
		[ValidateNotNull()]
		[System.String]$ComputerName = [System.String]::Empty,

		[Parameter()] 
		[ValidateNotNull()]
		[System.Management.Automation.Credential()]
		[System.Management.Automation.PSCredential]$Credential = [System.Management.Automation.PSCredential]::Empty  
	)

	Begin {	
	}

	Process{
		Write-Log -Message "Getting SID for $UserName." -Level VERBOSE

		[System.String]$Domain = [System.String]::Empty
		[System.String]$Name = [System.String]::Empty

		if ($UserName.IndexOf("\") -ne -1) 
		{
			[System.String[]]$Parts = $UserName.Split("\")
			$Domain = $Parts[0]

			#If the UserName is something like .\john.doe, change the computer name
			if ($Domain -iin $script:LocalNames)
			{
				#Use an empty string for the domain name on the local computer
				$Domain = [System.String]::Empty
			}

			$Name = $Parts[1]			
		}
		elseif ($UserName.IndexOf("@") -ne -1) 
		{
			[System.String[]]$Parts = $UserName.Split("@")
			$Domain = $Parts[1]
			$Name = $Parts[0]
		}
		else 
		{
			try 
			{
				$Domain = Get-ADDomain -Current LocalComputer -ErrorAction Stop | Select-Object -ExpandProperty Name
			}
			catch [Exception] 
			{
				#Use an empty string for the domain name on the local computer
				$Domain = [System.String]::Empty
			}

			$Name = $UserName
		}

		if ([System.String]::IsNullOrEmpty($ComputerName) -or $ComputerName -iin $script:LocalNames) 
		{
			try 
			{
				$User = New-Object -TypeName System.Security.Principal.NTAccount($Domain, $Name)
				$UserSid = $User.Translate([System.Security.Principal.SecurityIdentifier])
			}
			catch [Exception]
			{
				Write-Log -Message "Exception translating $Domain\$Name." -ErrorRecord $_ -Level VERBOSEERROR
				$UserSid = $null
			}
		}
		else 
		{
			$Session = New-PSSession -ComputerName $ComputerName -Credential $Credential
				
			$UserSid = Invoke-Command -Session $Session -ScriptBlock { 
				try
				{
					$User = New-Object -TypeName System.Security.Principal.NTAccount($args[0], $args[1])
					Write-Output -InputObject $User.Translate([System.Security.Principal.SecurityIdentifier])
				}
				catch [Exception]
				{
					Write-Log -Message "Exception translating $($args[0])\$($args[1])" -ErrorRecord $_ -Level VERBOSEERROR
					Write-Output -InputObject $null

				}
			} -ArgumentList @($Domain, $Name)

			Remove-PSSession -Session $Session
		}
		
		Write-Output -InputObject $UserSid
	}

	End {		
	}
}

Function Get-AccountTranslatedNTName {
	<#
		.SYNOPSIS
			Gets the full NT Account name of a given username.

		.DESCRIPTION
			The cmdlet gets the SID of a username, which could a service account, local account, or domain account and then translates that to an NTAccount. The cmdlet returns null if the username
			could not be translated.

		.PARAMETER UserName
			The name of the user or service account to get the SID of.

		.PARAMETER ComputerName
			If the account is local to another machine, such as an NT SERVICE account or a true local account, specify the computer name the account is on.

		.PARAMETER Credential
			The credentials used to connect to the remote machine.
			
		.INPUTS
			None

		.OUTPUTS
			System.String

        .EXAMPLE
			Get-AccountTranslatedNTName -UserName "Administrator"

			Gets the NT account name for the Administrator account, which is BUILTIN\Administrator.

		.EXAMPLE
			Get-AccountTranslatedNTName -UserName "Authenticated Users"

			Gets the NT account name for the Authenticated Users group, which is NT AUTHORITY\Authenticated Users.

		.EXAMPLE
			Get-AccountTranslatedNTName -UserName "System"

			Gets the NT account name for the SYSTEM account, which is NT AUTHORITY\System

		.EXAMPLE
			Get-AccountTranslatedNTName -UserName "MSSQLSERVER" -ComputerName SqlServer

			Gets the NT account name for the virtual MSSQLSERVER service principal, which is NT SERVICE\MSSQLSERVER.

		.NOTES
			AUTHOR: Michael Haken
			LAST UPDATE: 2/23/2017
	#>
	[CmdletBinding()]
	[OutputType([System.String])]
	Param(
		[Parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true)]
		[ValidateNotNullOrEmpty()]
		[System.String]$UserName,

		[Parameter(Position=1)]
		[ValidateNotNull()]
		[System.String]$ComputerName = [System.String]::Empty,

		[Parameter()] 
		[ValidateNotNull()]
		[System.Management.Automation.Credential()]
		[System.Management.Automation.PSCredential]$Credential = [System.Management.Automation.PSCredential]::Empty  
	)

	Begin {	
	}

	Process{
		Write-Log -Message "Getting NT Account for $UserName." -Level VERBOSE

		[System.Security.Principal.SecurityIdentifier]$UserSid = Get-AccountSid -UserName $UserName.Trim() -ComputerName $ComputerName -Credential $Credential

		[System.String]$NTName = [System.String]::Empty

		if ($UserSid -ne $null)
		{
			if ([System.String]::IsNullOrEmpty($ComputerName) -or $ComputerName -iin $script:LocalNames) 
			{
				try
				{
					[System.Security.Principal.NTAccount]$NTAccount = $UserSid.Translate([System.Security.Principal.NTAccount])
					$NTName = $NTAccount.Value.Trim()
				}
				catch [Exception]
				{
					Write-Log -Message "Exception translating SID $($UserSid.Value) for $UserName to NTAccount." -ErrorRecord $_ -Level VERBOSEERROR
					$NTName = $null
				}
			}
			else 
			{
				$Session = New-PSSession -ComputerName $ComputerName -Credential $Credential
				
				$NTName = Invoke-Command -Session $Session -ScriptBlock { 
					try
					{
						[System.Security.Principal.NTAccount]$NTAccount = ([System.Security.Principal.SecurityIdentifier]$args[0]).Translate([System.Security.Principal.NTAccount])
						Write-Output -InputObject $NTAccount.Value.Trim()
					}
					catch [Exception]
					{
						Write-Log -Message "Exception translating SID $($args[0].Value) to NTAccount." -ErrorRecord $_ -Level VERBOSEERROR
						Write-Output -InputObject $null
					}
				} -ArgumentList @($UserSid)

				Remove-PSSession -Session $Session
			}
		}
		else
		{
			$NTName = $null
		}

		Write-Output -InputObject $NTName
	}

	End {		
	}
}

Function Get-LocalGroupMembers {
	<#
		.SYNOPSIS
			Gets the members of a local group

		.DESCRIPTION
			This cmdlet gets the members of a local group on the local or a remote system. The values are returned as DirectoryEntry values in the format WinNT://Domain/Name.

		.PARAMETER LocalGroup
			The local group on the computer to enumerate.

		.PARAMETER ComputerName
			The name of the computer to query. This defaults to the local computer.

		.INPUTS
			System.String

		.OUTPUTS
			System.String[]

        .EXAMPLE
			Get-LocalGroupMembers -LocalGroup Administrators 

			Gets the membership of the local administrators group on the local machine.

		.NOTES
			AUTHOR: Michael Haken
			LAST UPDATE: 8/25/2016
	#>  
	[CmdletBinding()]
	[OutputType([System.String[]])]
	Param(
		[Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
		[ValidateNotNullOrEmpty()]
		[System.String]$LocalGroup,		

		[Parameter(Position = 1)]
		[ValidateNotNullOrEmpty()]
		[System.String]$ComputerName = $env:COMPUTERNAME
	)

	Begin {
	}

	Process {
		$Group = [ADSI]"WinNT://$ComputerName/$LocalGroup,group"	
									
		$Members = $Group.Invoke("Members", $null) | Select-Object @{Name = "Name"; Expression = {$_[0].GetType().InvokeMember("ADSPath", "GetProperty", $null, $_, $null)}} | Select-Object -ExpandProperty Name				

		Write-Output -InputObject $Members
	}

	End {		
	}
}

Function Add-DomainMemberToLocalGroup {
	<#
		.SYNOPSIS
			Adds a domain user or group to a local group.

		.DESCRIPTION
			This cmdlet adds a domain user or group to a local group on a specified computer. The cmdlet returns true if the member is added or is already a member of the group.

			The cmdlet uses the current computer domain to identify the domain member.

		.PARAMETER LocalGroup
			The local group on the computer that will have a member added.

		.PARAMETER Member
			The domain user or group to add.

		.PARAMETER MemberType
			The type of the domain member, User or Group. This defaults to User.

		.PARAMETER ComputerName
			The name of the computer on which to add the local group member. This defaults to the local computer.

		.INPUTS
			None

		.OUTPUTS
			System.Boolean

        .EXAMPLE
			Add-DomainMemberToLocalGroup -LocalGroup Administrators -Member "Exchange Trusted Subsystem" -MemberType Group

			Adds the domain group to the local administrators group on the local machine.

		.NOTES
			AUTHOR: Michael Haken
			LAST UPDATE: 8/25/2016
	#>  
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	Param(
		[Parameter(Mandatory = $true, Position = 0)]
		[ValidateNotNullOrEmpty()]
		[System.String]$LocalGroup,

		[Parameter(Mandatory = $true, Position = 1)]
		[ValidateNotNullOrEmpty()]
		[System.String]$Member,

		[Parameter(Position = 2)]
		[ValidateSet("Group", "User")]
		[System.String]$MemberType = "User",

		[Parameter(Position = 3)]
		[ValidateNotNullOrEmpty()]
		[System.String]$ComputerName = $env:COMPUTERNAME
	)

	Begin {
	}

	Process {
		$Success = $false

		$Domain = Get-ComputerDomain
		$Domain = $Domain.Substring(0, $Domain.IndexOf("."))

		$Group = [ADSI]"WinNT://$ComputerName/$LocalGroup,group"	
		
		if ($Group.Path -ne $null)	
		{					
			$Members = $Group.Invoke("Members", $null) | Select-Object @{Name = "Name"; Expression = {$_[0].GetType().InvokeMember("ADSPath", "GetProperty", $null, $_, $null)}} | Select-Object -ExpandProperty Name		
			$NewMember = [ADSI]"WinNT://$Domain/$Member,$MemberType"
							
			$Path = $NewMember.Path.Remove($NewMember.Path.LastIndexOf(","))
			
			if ($Members -inotcontains $Path)
			{
				try {
					$Group.Add($NewMember.Path)
					Write-Log -Message "Successfully added $Member to $($Group.Name)" -Level VERBOSE
					$Success = $true
				}
				catch [Exception] {
					Write-Log -ErrorRecord $_ -Level ERROR
				}
			}
			else
			{
				Write-Log -Message "$($NewMember.Name) already a member of $($Group.Name)." -Level VERBOSE
				$Success = $true
			}
		}
		else
		{
			Write-Log -Message "$LocalGroup local group could not be found." -Level VERBOSE
		}

		Write-Output -InputObject $Success
	}

	End {
		
	}
}

Function Set-LocalAdminPassword {
	<#
		.SYNOPSIS
			Sets the local administrator password.

		.DESCRIPTION
			Sets the local administrator password and optionally enables the account if it is disabled.

			If the password is not specified, the user will be prompted to enter the password when the cmdlet is run. The admin account is
			identified by matching its SID to *-500, which should be unique for the local machine.

		.PARAMETER Password
			The new password for the local administrator account.

		.PARAMETER EnableAccount
			Specify to enable the local administrator account if it is disabled.

		.INPUTS
			System.Security.SecureString
		
		.OUTPUTS
			None

		.EXAMPLE 
			Set-LocalAdminPassword -EnableAccount

			The cmdlet will prompt the user to enter the new password.

		.NOTES
			AUTHOR: Michael Haken
			LAST UPDATE: 10/23/2017
	#>
	[CmdletBinding()]
	[OutputType()]
    Param (
        [Parameter(Position=0 , ValueFromPipeline=$true)]
		[ValidateNotNull()]
        [System.Security.SecureString]$Password,

		[Parameter()]
		[Switch]$EnableAccount
    )
    Begin {       
    }
    
    Process {
		$HostName = $env:COMPUTERNAME 
        $Computer = [ADSI]"WinNT://$HostName,Computer" 

		while ($Password -eq $null) 
		{
			$Password = Read-Host -AsSecureString -Prompt "Enter the new administrator password"
		}

		$Name = Get-LocalUser| Where-Object {$_.SID.Value -match "S-1-5-21-.*-500"} | Select-Object -ExpandProperty Name -First 1

		Write-Log -Message "The local admin account is $Name" -Level VERBOSE
        $User = [ADSI]"WinNT://$HostName/$Name,User"
        $PlainTextPass = Convert-SecureStringToString -SecureString $Password
                
		Write-Log -Message "Setting password." -Level VERBOSE
        $User.SetPassword($PlainTextPass)
                
		if ($EnableAccount) 
		{
			#The 0x0002 flag specifies that the account is disabled
			#The binary AND operator will test the value to see if the bit is set, if it is, the account is disabled.
			#Doing a binary OR would add the value to the flags, since it would not be present, the OR would add it
			if ($User.UserFlags.Value -band "0x0002") 
			{
				Write-Log -Message "The account is current disabled with user flags $($User.UserFlags.Value)" -Level VERBOSE
				#The binary XOR will remove the flag, which enables the account, the XOR means that if both values have the bit set, the result does not
				#If only 1 value has the bit set, then it will remain set, so we need to ensure that the bit is actually set with the -band above for the XOR to actually
				#remove the disabled value
				$User.UserFlags = $User.UserFlags -bxor "0x0002"
				$User.SetInfo()
			}
		}
    }
    
    End {        
    }       
}

Function Test-IsLocalAdmin {
	<#
		.SYNOPSIS
			Tests is the current user has local administrator privileges.

		.DESCRIPTION
			The Test-IsLocalAdmin cmdlet tests the user's current Windows Identity for inclusion in the BUILTIN\Administrators role.

		.INPUTS
			None

		.OUTPUTS
			System.Boolean

		.EXAMPLE
			Test-IsLocalAdmin

			This command returns true if the current is running the session with local admin credentials and false if not.

		.NOTES
			AUTHOR: Michael Haken	
			LAST UPDATE: 2/27/2016

		.FUNCTIONALITY
			The intended use of this cmdlet is to test for administrative credentials before running other commands that require them.
	#>
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	Param()

	Begin {}

	Process {
		Write-Output -InputObject ([System.Security.Principal.WindowsPrincipal][System.Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
	}

	End {}
 }