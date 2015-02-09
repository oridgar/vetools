function Reload-veTools ()
{
  <#
  .SYNOPSIS
  Describe the function here
  .DESCRIPTION
  Describe the function in more detail
  .EXAMPLE
  Give an example of how to use it
  .EXAMPLE
  Give another example of how to use it
  .PARAMETER computername
  The computer name to query. Just one.
  .PARAMETER logname
  The name of a file to write failed computer names to. Defaults to errors.txt.
  .LINK 
  https://code.google.com/p/vetools/wiki/Main
  #>
	if ($(Get-Module veSettings) -ne $null) {
		Remove-Module veSettings
	}
	if ($(Get-Module veTools) -ne $null) {
		Remove-Module veTools
	}
	Import-Module veSettings
	Import-Module veTools
}