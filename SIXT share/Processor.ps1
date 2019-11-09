Get-ChildItem -filter *.pdf | ForEach-Object {
    $filename = $_.Name

    $textContent = pdftotext -layout -enc UTF-8 -bom -q ${filename} - | Out-String

    if (${textContent} -NotMatch "SIXT share") {
        Write-Host "Ignoring ${filename}"
        Return
    }

    $invoiceNumber = ${textContent} -replace "(?s).*Rechnungsnr.\W+([0-9A-Z/]+).*", '$1'
    $invoiceDate =   ${textContent} -replace "(?s).*Übergabe:\W+([0-9][0-9])\.([0-9][0-9])\.([0-9][0-9][0-9][0-9]).*", '$3-$2-$1'
#     $invoiceAmount = ${textContent} -replace "(?s).*\W([0-9]+,[0-9][0-9]) EUR.*", '$1'


    if ([string]::IsNullOrWhiteSpace($invoiceNumber)) {
        Write-Host "Ignoring   ${filename}"
        Return
    }

    $invoiceNumberClean = ${invoiceNumber} -replace "/", "_"

    $newFilename = "${invoiceDate} 01 Rechnung SIXT share ${invoiceNumberClean} €.pdf"

    Write-Host "Number: $invoiceNumber"
    Write-Host "Date:   $invoiceDate"
    # Write-Host "Amount: $invoiceAmount"
    Write-Host "OLD:    $filename"
    Write-Host "NEW:    $newFilename"

    Write-Host "Renaming '${filename}' to '${newFilename}'"
    Rename-Item -Path "${filename}" -NewName ${newFilename}
}

