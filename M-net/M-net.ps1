Get-ChildItem -filter *.pdf | ForEach-Object {
    $filename = $_.Name
    
    $textContent = pdftotext -layout ${filename} - | Out-String

    $invoiceNumber = ${textContent} -replace "(?s).*Rechnungsnummer\W+([0-9]+).*", '$1'
    $invoiceDate =   ${textContent} -replace "(?s).*Rechnungsdatum\W+([0-9][0-9])\.([0-9][0-9])\.([0-9][0-9][0-9][0-9]).*", '$3-$2-$1'
    $invoiceAmount = ${textContent} -replace "(?s).*Bruttorechnungsbetrag\W+([0-9]+,[0-9][0-9]).*", '$1'

    if ([string]::IsNullOrWhiteSpace($invoiceNumber)) {
        # Write-Host "Ignoring   ${filename}"
        Return
    }

    $newFilename = "${invoiceDate} 01 Rechnung ${invoiceNumber} ${invoiceAmount}€.pdf"

    Write-Host "Renaming '${filename}' to '${newFilename}'"
    Rename-Item -Path "${filename}" -NewName ${newFilename}
}

