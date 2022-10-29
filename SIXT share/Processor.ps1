Get-ChildItem -filter "*.pdf" | Where-Object { $_.LastWriteTime -ge "2020-12-01" } | ForEach-Object {
    $filename = $_.Name

    $textContent = pdftotext -enc UTF-8 -bom -q ${filename} - | Out-String

    if (${textContent} -NotMatch "SIXT share") {
        Write-Verbose "Ignoring ${filename}"
        Return
    }
    Write-Verbose "Processing file $filename"

    pause

    $documentType = if ($textContent -notmatch "Rechnungsstorno") {"Rechnung"} else {"Storno"}
    $invoiceNumber = ${textContent} -replace "(?s).+?Rechnungsnr.\s+([0-9A-Z/]+).*", '$1'
    $invoiceDate = ${textContent} -replace "(?s).+?Rechnungsdatum:\s+(?:Pullach, )([0-9][0-9])\.([0-9][0-9])\.([0-9][0-9][0-9][0-9]).*", '$3-$2-$1'
    $invoiceAmount = ${textContent} -replace "(?s).+Übergabe:.+([0-9]+),\s?([0-9][0-9]) EUR\r\n.+", ' $1,$2€'
    $invoiceAmount = ${textContent} -replace "(?s).+\r\n([0-9]+),\s?([0-9][0-9]) EUR\r\n.+", ' $1,$2€'
    if ($invoiceAmount.Length -lt 6 -or $invoiceAmount.Length -gt 8) {
        $invoiceAmount = ""
    }

    if ([string]::IsNullOrWhiteSpace($invoiceNumber)) {
        Write-Verbose "Ignoring ${filename}"
        Return
    }

    $invoiceNumberClean = ${invoiceNumber} -replace "/", "_"

    $index = 0;
    do {
        ${index}++
    }
    while (Test-Path "${invoiceDate} 0${index}*")

    $newFilename = "${invoiceDate} 0${index} ${documentType} SIXT share ${invoiceNumberClean}${invoiceAmount}.pdf"

    if (${newFilename} -eq ${filename}) {
        Write-Verbose "File has correct name. Ignoring ${filename}"
        Return
    }


    Write-Verbose "Number: $invoiceNumber"
    Write-Verbose "Date:   $invoiceDate"
    Write-Verbose "Amount: $invoiceAmount"
    Write-Verbose "OLD:    $filename"
    Write-Verbose "NEW:    $newFilename"

    if ($newFilename -eq $filename) {
        return
    }

    Write-Output "Renaming '${filename}' to '${newFilename}'"
    Rename-Item -WhatIf -Path "${filename}" -NewName ${newFilename}
}
