Get-ChildItem -filter *.pdf | ForEach-Object {
    $filename = $_.Name

    $textContent = pdftotext -enc UTF-8 -bom -q ${filename} - | Out-String

    if (${textContent} -NotMatch "drive-now.com") {
        Write-Host "Ignoring ${filename}"
        Return
    }

    $invoiceNumber = ${textContent} -replace "(?s).*Rech.Nr:\W+([0-9A-Z/]+).*", '$1'
    $invoiceDate =   ${textContent} -replace "(?s).*Übergabe:\W+([0-9][0-9])\.([0-9][0-9])\.([0-9][0-9][0-9][0-9]).*", '$3-$2-$1'
    $invoiceAmount = ${textContent} -replace "(?s).*\W([0-9]+,[0-9][0-9]) EUR.*", '$1'


    if ([string]::IsNullOrWhiteSpace($invoiceNumber)) {
        Write-Host "Ignoring   ${filename}"
        Return
    }

    $invoiceNumberClean = ${invoiceNumber} -replace "/", ""

    $newFilename = "${invoiceDate} 01 Rechnung DriveNow ${invoiceNumberClean} ${invoiceAmount}€.pdf"

    # Write-Host "Number: $invoiceNumber"
    # Write-Host "Date:   $invoiceDate"
    # Write-Host "Amount: $invoiceAmount"
    # Write-Host "OLD:    $filename"
    # Write-Host "NEW:    $newFilename"

    Write-Host "Renaming '${filename}' to '${newFilename}'"
    Rename-Item -Path "${filename}" -NewName ${newFilename}
}

