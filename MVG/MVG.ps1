Get-ChildItem -filter *.pdf  | Where-Object {$_.LastWriteTime -ge "2022-10-01"} | ForEach-Object <# -Parallel #> {
    $filename = $_.Name
    
    $textContent = pdftotext -enc UTF-8 -bom -q ${filename} - | Out-String

    if (${textContent} -NotMatch "MVG") {
        Write-Output "Not from MVG. Ignoring ${filename}"
        Return
    }

    if ( ${textContent} -cmatch "(?s).*Rechnungsnummer:\W*([0-9]+).*") {
        $invoiceNumber = $matches[1]
    }
    if ( ${textContent} -cmatch "(?s).*Kaufdatum: (\d{2})\.(\d{2}).(\d{4}).*") {
        $purchaseDay = $matches[1]
        $purchaseMonth = $matches[2]
        $purchaseYear = $matches[3]

        $purchaseDate = ${purchaseYear} + "-" + ${purchaseMonth} + "-" + ${purchaseDay}

        Write-Output "Purchase date: $purchaseDate"
    }
    
    if ( ${textContent} -cmatch "(?s).*Rechnungssumme.*\W+(\d+,\d{2})\W+EUR.*") { 
        $invoiceAmount = $matches[1] 

        Write-Output "Invoice amount: $invoiceAmount"
    }
    
    # Write-Output "${filename}: ${invoiceNumber} ${purchaseDate} ${InvoiceAmount}"
    if (-not ${invoiceNumber} -or -not ${purchaseDate} -or -not ${invoiceAmount}) {
        Write-Output "Invalid invoice data. Ignoring ${filename}"
        Return
    }

    $index = 0;
    do {
        ${index}++

        $newFilename = "${purchaseDate} 0${index} MVG ${invoiceNumber} ${invoiceAmount}€.pdf"

        if (${newFilename} -eq ${filename}) {
            Write-Output "File has correct name. Ignoring ${filename}"
            Return
        }  
    }
    while (Test-Path "${purchaseDate} 0${index}*")

    Write-Output "Renaming '${filename}' to '${newFilename}'"
    Rename-Item -Path "${filename}" -NewName ${newFilename}
}

