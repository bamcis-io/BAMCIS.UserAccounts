#
# Module manifest for module 'BAMCIS.UserAccounts'
#
# Generated by: Michael Haken
#
# Generated on: 3/4/2018
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'BAMCIS.UserAccounts.psm1'

# Version number of this module.
ModuleVersion = '1.0.0.0'

# ID used to uniquely identify this module
GUID = '50822a46-4717-4809-b744-f282e6d86dbc'

# Author of this module
Author = 'Michael Haken'

# Company or vendor of this module
CompanyName = 'BAMCIS'

# Copyright statement for this module
Copyright = '(c) 2018 BAMCIS. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Provides cmdlets to interact with local and domain user accounts and groups.'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '3.0'

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @("BAMCIS.Logging")

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module
FunctionsToExport = @(
	"Get-UserProfiles", "Get-AccountSid", "Get-AccountTranslatedNTName", "Get-LocalGroupMembers", "Add-DomainMemberToLocalGroup", "Set-LocalAdminPassword", "Test-IsLocalAdmin"
)

# Cmdlets to export from this module
# CmdletsToExport = @()

# Variables to export from this module
# VariablesToExport = @()

# Aliases to export from this module
# AliasesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess
PrivateData = @{
	PSData = @{
		Title = "BAMCIS Users and Groups"

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = @("User", "Sid", "LocalGroup")

        # A URL to the license for this module.
        LicenseUri = 'https://github.com/bamcis-io/BAMCIS.UserAccounts/blob/master/LICENSE'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/bamcis-io/BAMCIS.UserAccounts'

        # A URL to an icon representing this module.
        # IconUri = ''

        # ReleaseNotes of this module
        ReleaseNotes = '*1.0.0.0
Initial Release. This module has been separated from the HostUtilities module to provide a lighter weight module that is more reusable across other modules.
'
    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}