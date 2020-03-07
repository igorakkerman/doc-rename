Get-ChildItem -filter *.pdf | ForEach-Object {
    $filename = $_.Name

    $textContent = pdftotext -layout -enc UTF-8 -bom -q ${filename} - | Out-String

    if (${textContent} -NotMatch "SIXT share") {
        Write-Host "Ignoring ${filename}"
        Return
    }

    $invoiceNumber = ${textContent} -replace "(?s).*Rechnungsnr.\W+([0-9A-Z/]+).*", '$1'
    $invoiceDate =   ${textContent} -replace "(?s).*Übergabe:\W+([0-9][0-9])\.([0-9][0-9])\.([0-9][0-9][0-9][0-9]).*", '$3-$2-$1'
    if ($invoiceDate.Length -ne 10) {
        $invoiceDate = ${textContent} -replace "(?s).*Rechnungsdatum:\W+Pullach, ([0-9][0-9])\.([0-9][0-9])\.([0-9][0-9][0-9][0-9]).*", '$3-$2-$1'
    }
    $invoiceAmount = ${textContent} -replace "(?s).*SIXT share Fahrt\W*\r\n\W*([0-9]+),\W*([0-9][0-9]) EUR.*", ' $1,$2€'
    if ($invoiceAmount.Length -lt 5 -or $invoiceAmount.Length -gt 7) {
        $invoiceAmount = ""
    }

    if ([string]::IsNullOrWhiteSpace($invoiceNumber)) {
        Write-Host "Ignoring   ${filename}"
        Return
    }

    $invoiceNumberClean = ${invoiceNumber} -replace "/", "_"

    $newFilename = "${invoiceDate} 01 Rechnung SIXT share ${invoiceNumberClean}${invoiceAmount}.pdf"

    # Write-Host "Number: $invoiceNumber"
    # Write-Host "Date:   $invoiceDate"
    # Write-Host "Amount: $invoiceAmount"
    # Write-Host "OLD:    $filename"
    # Write-Host "NEW:    $newFilename"

    Write-Host "Renaming '${filename}' to '${newFilename}'"
    Rename-Item -Path "${filename}" -NewName ${newFilename}
}

