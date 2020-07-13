Get-ChildItem -filter "*.pdf" | Where-Object { $_.LastWriteTime -ge "2020-04-01" } | ForEach-Object {
    $filename = $_.Name

    $textContent = pdftotext -enc UTF-8 -bom -q ${filename} - | Out-String

    if (${textContent} -NotMatch "SIXT share") {
        # Write-Host "Ignoring ${filename}"
        Return
    }
    Write-Host "File $filename"

    $invoiceNumber = ${textContent} -replace "(?s).*?\r\n([0-9A-Z/]+?) Pullach,.*", '$1'
    $invoiceDate = ${textContent} -replace "(?s).*?\r\n[0-9A-Z/]+? Pullach, ([0-9][0-9])\.([0-9][0-9])\.([0-9][0-9][0-9][0-9]).*", '$3-$2-$1'
    $invoiceAmount = ${textContent} -replace "(?s).+\r\n([0-9]+),\s?([0-9][0-9]) EUR\r\n.+", ' $1,$2€'
    if ($invoiceAmount.Length -lt 6 -or $invoiceAmount.Length -gt 8) {
        $invoiceAmount = ""
    }

    if ([string]::IsNullOrWhiteSpace($invoiceNumber)) {
        # Write-Host "Ignoring ${filename}"
        Return
    }

    $invoiceNumberClean = ${invoiceNumber} -replace "/", "_"

    $index = 0;
    do {
        ${index}++
    }
    while (Test-Path "${invoiceDate} 0${index}*")

    $newFilename = "${invoiceDate} 0${index} Rechnung SIXT share ${invoiceNumberClean}${invoiceAmount}.pdf"

    if (${newFilename} -eq ${filename}) {
        # Write-Output "File has correct name. Ignoring ${filename}"
        Return
    }  


    # Write-Host "Number: $invoiceNumber"
    # Write-Host "Date:   $invoiceDate"
    # Write-Host "Amount: $invoiceAmount"
    # Write-Host "OLD:    $filename"
    # Write-Host "NEW:    $newFilename"

    Write-Host "Renaming '${filename}' to '${newFilename}'"
    Rename-Item -Path "${filename}" -NewName ${newFilename}
}

