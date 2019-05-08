Get-ChildItem -filter *.pdf | ForEach-Object {
    $filename = $_.Name
    
    $textContent = pdftotext.exe -enc UTF-8 -bom ${filename} - | Out-String

    if ( ${textContent} -cmatch "(?s).*Rechnungsnummer:\W*(MVG)?([A-Z0-9]+).*") {
        $invoiceNumber = $matches[1] + $matches[2]
    }
    if ( ${textContent} -cmatch "(?s).*Rechnungsnummer:\W*(?:MVG)?([0-9][0-9][0-9][0-9])([0-9][0-9])([0-9][0-9]).*") {
    
        $invoiceYear = $matches[1]
        $invoiceMonth = $matches[2]
        $invoiceDay = $matches[3]

        $invoiceDate = ${invoiceYear} + "-" + ${invoiceMonth} + "-" + ${invoiceDay}
    }
    
    if ( ${textContent} -cmatch "(?s).*Summe\W*([0-9]+,[0-9][0-9]).*") { 
        $invoiceAmount = $matches[1] 
    }
    
    # Write-Host "${filename}: ${invoiceNumber} ${InvoiceDate} ${InvoiceAmount}"
    if (-not ${invoiceNumber} -or -not ${invoiceDate} -or -not ${invoiceAmount}) {
        Write-Host "Invalid data. Ignoring ${filename}"
        Return
    }

    $index = 0;
    do {
        ${index}++

        $newFilename = "${invoiceDate} 0${index} Rechnung ${invoiceNumber} ${invoiceAmount}€.pdf"

        if (${newFilename} -eq ${filename}) {
            Write-Host "File has correct name. Ignoring ${filename}"
            Return
        }  
    }
    while (Test-Path "${invoiceDate} 0${index}*")

    Write-Host "Renaming '${filename}' to '${newFilename}'"
    Rename-Item -Path "${filename}" -NewName ${newFilename}
}

