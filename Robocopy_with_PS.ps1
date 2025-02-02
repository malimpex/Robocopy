################################################################################################################
#	Robocopy with PowerShell												                                                                                        ###
################################################################################################################
#	Firma: Malimpex IT Solution GmbH
#	Script Name: Robocopy_with_PS.ps1
#	Description: 
#	Author: Marcel.Luginbuhl@malimpex.net
#   Created: 02.02.2025
#   Last Modified: 


$sourcePath 1 = "C:\Pfad\mein Ordner
$sourcePath 2 = "C:\Pfad\mein Ordner
$destinationPath 1 = "D:\Ordner1\*.*"
$destinationPath 2 = "D:\Ordner2\Code hier eingeben\"
$filetransfer = 'C:\filetransferlog.txt'
robocopy $sourcePath 1 $destinationPath 1 /E /DCOPY:DAT /COPYALL /LOG:$filetransfer /MIR /TEE /W:3 /ZB /V /timfix /sl /r:7 /COPY:DAT #/BYTES
robocopy $sourcePath 2 $destinationPath 2 /E /DCOPY:DAT /COPYALL /LOG:$filetransfer /MIR /TEE /W:3 /ZB /V /timfix /sl /r:7 /COPY:DAT

