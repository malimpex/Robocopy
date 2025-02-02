################################################################################################################
#	Robocopy Backup with PowerShell												                                                                                        ###
################################################################################################################
#	Firma: Malimpex IT Solution GmbH
#	Script Name: Robocopy_with_backup.ps1
#	Description: 
#	Author: Marcel.Luginbuhl@malimpex.net
#   Created: 02.02.2025
#   Last Modified: 


cls
# Konfiguration # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

# Array für Seriennummern möglicher Sicherungsplatten. Hierrüber wird der Laufwerksbuchstabe des Sicherungsdatenträgers bestimmt.
# Wird kein Datenträger mit passender Seriennummer gefunden, wird eine Fehlermeldung ausgegeben.
$HDDSerials = @()
$HDDSerials += 123456789
$HDDSerials += -123456789

# Array für Beschreibungen der Sicherungsdatenträger (wird in der Konsole angezeigt)
$HDDLong = @()
$HDDLong += 'Western Digital Black 1TB vollverschlüsselt'  
$HDDLong += 'Western Digital Purple 3TB vollverschlüsselt'  

# Array für Kurzbeschreibungen der Sicherungsdatenträger (wird im Superlog angezeigt)
$HDDShort = @()
$HDDShort += 'WD_Black_1TB'  
$HDDShort += 'WD_Purple_3TB'  

# Parameter für Robocopy und Unterfunktionen
$RC_Paramset_Shadow = '/MIR /R:0 /W:0 /FP /NP /NC /NDL /NJH /NJS /BYTES' # Ermittlung des Kopieraufwandes und eigentlicher Kopiervorgang  
$RC_Paramset_Log = '/MIR /R:0 /W:0 /FP /NP /BYTES'                       # Erstellung des "lesbaren" Logs  
$RC_LogSearch = '(?<=\s+)\d+(?=\s+)'                                     # RegEx zum extrahieren der Dateigrößen aus den ShadowLogs  
$RC_Superlog = 'L:\00 Software\99 Sicherungen\Sicherungsstatus.csv'      # Superlog: Hier werden die Summarys aller Sicherungen als .csv gesichert  

# Array der zu sichernden Pfade. Auf dem Sicherungslaufwerk wird aus dem Pfad der jeweils letzte Ordner als Ziel gesetzt
# Beispiel: '\\Server\Freigabe\Ordner 1' wird zu 'X:\Ordner 1' 
$Sicherungspfade = @()
$Sicherungspfade += '\\Server\Daten\00 Software'  
$Sicherungspfade += '\\Server\Daten\01 Dokumente'  
$Sicherungspfade += '\\Server\Daten\02 Geocaching'  
$Sicherungspfade += '\\Server\Daten\03 Bilder'  
$Sicherungspfade += '\\Server\Daten\05 Musik'  

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

# Ziel-HDD ermitteln anhand der Seriennummer des Datenträgers
$ZielHDD = $null
Write-Host -ForegroundColor white "Ermittle Sicherungslaufwerk ... "  
$FSO = New-Object -com  Scripting.FileSystemObject
$FSO.Drives | foreach {
    $Drive = $_
    if($ZielHDD -eq $null) {
        $i = 0
        $HDDSerials | foreach {
            if($_ -eq ($FSO.GetDrive($Drive.path).SerialNumber)) {
                $ZielHDD = $Drive.path
                $Platte = $HDDShort[$i]
                Write-Host -ForegroundColor Gray " - Laufwerk:     " -NoNewline  
                write-host -ForegroundColor green "$($Drive.path)\"  
                write-host -ForegroundColor gray " - Beschreibung: " -NoNewline  
                write-host -ForegroundColor green $HDDLong[$i]
            }
            $i++
        }
    }
}


# Keine Ziel-HDD gefunden? Abbruch!
if($ZielHDD -eq $null) {
    write-host -ForegroundColor red "   ... Es konnte kein Sicherungslaufwerk gefunden werden!"  
    write-host -ForegroundColor red "   ... Abbruch."  
    write-host ''  
    break
} else {
    $TempDatei = "$ZielHDD\copyjob.tmp"  
}

# Robocopy
write-host ''  
$Sicherungspfade | Foreach {
    $Sicherung = $_
    $LogDatei = "$ZielHDD\$(get-date -uformat "%Y-%m-%d")"  
 
    # Zielverzeichnis aus Quelle ermitteln
    $ZielVerzeichnis = $_.split("\")  
    $ZielVerzeichnis = $Zielverzeichnis[$Zielverzeichnis.length-1]

    # Ausgabe
    write-host -ForegroundColor White "Sicherung von " -NoNewline  
    write-host -ForegroundColor yellow $Sicherung -NoNewline
    write-host -ForegroundColor white " nach " -NoNewline  
    write-host -ForegroundColor yellow "$ZielHDD\$ZielVerzeichnis"   
    write-host -ForegroundColor gray " - Ermittle Kopieraufwand ..."  

    # Robocopy Shadowmode
    $Args = '"{0}" "{1}" /L {2} /LOG:"{3}"' -f $_, "$ZielHDD\$ZielVerzeichnis", $RC_Paramset_Shadow, $TempDatei  
    Start-Process -Wait -FilePath robocopy -ArgumentList $Args -WindowStyle Hidden
    
    # Logdatei einlesen
    $Staging = Get-Content -Path "$TempDatei"  
    
    # Dateien (Zeilen) zählen
    $FileCount = $Staging.count -1
    if($FileCount -ne 0) {
        
        # Dateigrößen (Bytes) addieren
        [LONG]$BytesTotal = 0  
        [RegEx]::Matches(($Staging -join "`n"), $RC_LogSearch) | % { $BytesTotal = 0 } { $BytesTotal += $_.Value }  
    
        # Ausgabe
        write-host -ForegroundColor gray "   ... $filecount Dateien"  
        Write-host -ForegroundColor gray "   ... $([math]::round(($BytesTotal/1024/1024/1024),3)) GB"  
    
        # Temp-Datei löschen
        Remove-Item $Tempdatei -Force

        # Finales Logfile bestimmen
        $LogDatei = "$LogDatei - $ZielVerzeichnis.txt"    

        #Richtiges Log erstellen
        write-host -ForegroundColor Gray " - Erstelle lesbares Log ..."  
        $Args = '"{0}" "{1}" /L {2} /LOG:"{3}"' -f $_, "$ZielHDD\$ZielVerzeichnis", $RC_Paramset_Log, $LogDatei  
        Start-Process -Wait -FilePath robocopy -ArgumentList $Args -WindowStyle Hidden
        write-host -ForegroundColor Gray "   ... Log erstellt"  

        # Robocopy im Originalmodus
        Write-Host -ForegroundColor gray " - Sicherung läuft ..."  
        $Args = '"{0}" "{1}" {2} /LOG:"{3}"' -f $_, "$ZielHDD\$ZielVerzeichnis", $RC_Paramset_Shadow, $TempDatei  
        $RC = Start-Process -FilePath robocopy -ArgumentList $Args -WindowStyle Hidden -PassThru
        Start-Sleep -Milliseconds 500

        # Prozessfortschritt anzeigen
        while (!$RC.HasExited) {
            Start-Sleep -Milliseconds 500
            [LONG]$BytesCopied = 0
            $Staging = Get-Content -Path $TempDatei
            if(($Staging.count) -ne 0 ) { # Bei großen Verzeichnissen und wenig Änderungen kann es zu lange dauern bis ein Datensatz im Log steht. Das führt zu einer Fehlermeldung. Daher dieser Workarround.
                $BytesCopied = [Regex]::Matches($Staging, $RC_LogSearch) | ForEach-Object -Process { $BytesCopied += $_.Value; } -End { $BytesCopied }
                if($BytesTotal -ne 0 ) {
                    Write-Progress -Activity "Sicherung von ""$Sicherung"" nach ""$ZielVerzeichnis""" -Status "$($Staging.Count -1) von $FileCount Dateien bzw. $([math]::round($BytesCopied/1024/1024/1024,3)) GB von $([math]::round($BytesTotal/1024/1024/1024,3)) GB kopiert.." -PercentComplete (($BytesCopied/$BytesTotal)*100)  
                }
            }
        }
        write-progress -Activity "Sicherung von ""$Sicherung"" nach ""$ZielVerzeichnis""" -Completed  

        # Temp-Datei löschen
        Remove-Item $Tempdatei -Force
            
        # Ausgabe  
        write-host -ForegroundColor gray " - Sicherung abgeschlossen: " -NoNewline  
        if([math]::round(($BytesCopied/$BytesTotal)*100,0) -eq 100) {
            Write-Host -ForegroundColor green "$([math]::round(($BytesCopied/$BytesTotal)*100,1))% kopiert"  
        } else {
            Write-Host -ForegroundColor red "$([math]::round(($BytesCopied/$BytesTotal)*100,1))% kopiert"  
        }
        Write-host -ForegroundColor gray "   ... $($Staging.Count -1) Dateien"  
        Write-host -ForegroundColor gray "   ... $([math]::round(($BytesCopied/1024/1024/1024),3)) GB"  
        write-host ''  

        # Sicherung in Superlog schreiben
        "$Platte;$(get-date -UFormat "%d-%m-%Y");$Sicherung;$FileCount;$BytesTotal;$ZielVerzeichnis;$($Staging.count -1);$BytesCopied" | out-file $RC_Superlog -Append  
    } else {
        # Sicherung in Superlog schreiben
        write-host -ForegroundColor gray "   ... " -NoNewline  
        write-host -ForegroundColor green "Sicherung ist aktuell"  
        write-host ''  
        "$Platte;$(get-date -UFormat "%d-%m-%Y");$Sicherung;$FileCount;;;;" | out-file $RC_Superlog -Append  
    }
}
#Ende
write-host -ForegroundColor White "Alle Sicherungen wurden abgeschlossen."  
write-host -ForegroundColor DarkGray "Fenster schließt sich in 30 Sekunden."  
Start-Sleep -Seconds 30
