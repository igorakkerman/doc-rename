Get-ChildItem -filter *.pdf | ForEach-Object {
    $filename = $_.Name
    
    $textContent = pdftotext -enc UTF-8 -bom -q ${filename} - | Out-String

    if (${textContent} -NotMatch "MVG") {
        Write-Host "Ignoring ${filename}"
        Return
    }

    if ( ${textContent} -cmatch "(?s).*Rechnungsnummer:\W*(MVG)?([A-Z0-9-]+).*") {
        $invoiceNumber = $matches[1] + $matches[2]
    }
    if ( ${textContent} -cmatch "(?s).*Bestellung vom ([0-9]+)\. ([A-Za-zä]+) ([0-9][0-9][0-9][0-9]).*") {
    
        $invoiceDay = "{0:00}" -f [int]$matches[1]
        $invoiceMonthText = $matches[2]
        $invoiceYear = $matches[3]

        $invoiceMonth = switch ($invoiceMonthText) {
            "Januar" { "01" }
            "Februar" { "02" }
            "März" { "03" }
            "April" { "04" }
            "Mai" { "05" }
            "Juni" { "06" }
            "Juli" { "07" }
            "August" { "08" }
            "September" { "09" }
            "Oktober" { "10" }
            "November" { "11" }
            "Dezember" { "12" }
            Default { "ERROR" }
        }

        $invoiceDate = ${invoiceYear} + "-" + ${invoiceMonth} + "-" + ${invoiceDay}
    }
    
    if ( ${textContent} -cmatch "(?s).*Brutto Gesamt:.*(?:Summe)?\W+([0-9]+,[0-9][0-9]).*") { 
        $invoiceAmount = $matches[1] 
    }
    
    # Write-Host "${filename}: ${invoiceNumber} ${InvoiceDate} ${InvoiceAmount}"
    if (-not ${invoiceNumber} -or -not ${invoiceDate} -or -not ${invoiceAmount}) {
        Write-Output "Invalid data. Ignoring ${filename}"
        Return
    }

    $index = 0;
    do {
        ${index}++

        $newFilename = "${invoiceDate} 0${index} Rechnung ${invoiceNumber} ${invoiceAmount}€.pdf"

        if (${newFilename} -eq ${filename}) {
            Write-Output "File has correct name. Ignoring ${filename}"
            Return
        }  
    }
    while (Test-Path "${invoiceDate} 0${index}*")

    Write-Output "Renaming '${filename}' to '${newFilename}'"
    Rename-Item -Path "${filename}" -NewName ${newFilename}
}

