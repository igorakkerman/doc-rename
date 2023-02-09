[CmdletBinding()]
Param()

Get-ChildItem -filter *.pdf | ForEach-Object {
    Clear-Variable -name ("invoice*", "ride*", "ticket*")

    $filename = $_.Name
        
    $textContent = pdftotext.exe -layout -enc UTF-8 -bom ${filename} - | Out-String
    
    if ( $textContent -cnotmatch "Bahn") {
        return
    }

    if ( ${textContent} -cmatch "Datum (\d{2})\.(\d{2})\.(\d{4}).+\W([A-Z0-9]{6})\W.*") {
        $invoiceYear = $matches[3]
        $invoiceMonth = $matches[2]
        $invoiceDay = $matches[1]

        $invoiceDate = ${invoiceYear} + "-" + ${invoiceMonth} + "-" + ${invoiceDay}

        $ticketNumber = $matches[4]
    }

    if ( ${textContent} -cmatch "Betrag\W*(\d+,\d{2})€") { 
        $invoiceAmount = $matches[1] 
    }
    
    if ( ${textContent} -cmatch "Halt.*\n([A-Za-zÄÖÜäöüß]+).*\n([A-Za-zÄÖÜäöüß]+)") { 
        $rideFrom = $matches[1]
        $rideTo = $matches[2]
    }

    if (-not ${ticketNumber} -or -not ${invoiceDate} -or -not ${invoiceAmount} -or -not ${rideFrom} -or -not ${rideTo}) {
        Write-Host "Invalid data. Ignoring ${filename}"
        Return
    }

    if ($filename -Match "${invoiceDate} \d{2} Ticket Bahn ${rideFrom}-${rideTo} ${ticketNumber} ${invoiceAmount}€.pdf") {
        Write-Verbose "File has correct name: $filename"
        Return
    }

    $index = 0;
    do {
        $index++
        $indexTwoDigits = $('{0:d2}' -f $index)
    }
    while (Test-Path "${invoiceDate} $indexTwoDigits*")

    $newFilename = "${invoiceDate} $indexTwoDigits Ticket Bahn ${rideFrom}-${rideTo} ${ticketNumber} ${invoiceAmount}€.pdf"

    Write-Host "Renaming '${filename}' to '${newFilename}'"
    Rename-Item -Path "${filename}" -NewName ${newFilename}
}    

$null = Read-Host "Fertig."
