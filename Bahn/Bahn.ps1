
function Main {
    Get-ChildItem -filter *.pdf | ForEach-Object {
        $filename = $_.Name
        
        $textContent = pdftotext.exe -layout -enc UTF-8 -bom ${filename} - | Out-String
    
        Process-Document $filename
    }    
}
function Process-Document($filename) {
    if ( ${textContent} -cmatch "Datum ([0-9][0-9])\.([0-9][0-9])\.([0-9][0-9][0-9][0-9])\W+([A-Z0-9]{6})") {
        $invoiceYear = $matches[3]
        $invoiceMonth = $matches[2]
        $invoiceDay = $matches[1]

        $invoiceDate =  ${invoiceYear} + "-" + ${invoiceMonth} + "-" + ${invoiceDay}

        $ticketNumber = $matches[4]
    }

    if ( ${textContent} -cmatch "Betrag\W*([0-9]+,[0-9][0-9])€") { 
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

    $index = 0;
    do {
        ${index}++

        $newFilename = "${invoiceDate} 0${index} Ticket Bahn ${rideFrom}-${rideTo} ${ticketNumber} ${invoiceAmount}€.pdf"

        if (${newFilename} -eq ${filename}) {
            Write-Host "File has correct name. Ignoring ${filename}"
            Return
        }  
    }
    while (Test-Path "${invoiceDate} 0${index}*")

    Write-Host "Renaming '${filename}' to '${newFilename}'"
    Rename-Item -Path "${filename}" -NewName ${newFilename}
 
}

Main