# Robocopy
Robocopy with PowerShell

These examples should help you get started with using Robocopy in PowerShell. 
Feel free to adjust the paths and options according to your specific needs. 
If you have any more specific requirements or questions, I'm here to help! 

# Define source and destination directories
$source = "C:\SourceDirectory"
$destination = "D:\DestinationDirectory"

# Use Robocopy to mirror directories (delete files in destination that are not in source)
robocopy $source $destination /MIR
