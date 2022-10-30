# $VerbosePreference = "Continue"

Get-ChildItem -filter "*.pdf" | Where-Object { $_.LastWriteTime -ge "2020-12-01" } | ForEach-Object {
    $filename = $_.Name

    $textContent = pdftotext -enc UTF-8 -bom -simple -q ${filename} - | Out-String

    if (${textContent} -notmatch "SIXT share") {
        Write-Verbose "Ignoring ${filename}"
        Return
    }
    Write-Verbose "Processing file $filename"

    $documentType = if ($textContent -match "Rechnungsstorno") {"Storno "} else {""}
    $documentLabel = "${documentType}SIXT share"

    $invoiceNumber = ${textContent} -replace "(?s).+?Rechnungsnr.\s+(\d+).*", '$1'
    $rideDate = ${textContent} -replace "(?s).+?Übergabe:\s+(\d{2})\.(\d{2})\.(\d{4}).*", '$3-$2-$1'
    $invoiceAmount = ${textContent} -replace "(?s).+Summe Brutto\s+(\d+)\.(\d{2})\s+EUR.*", '$1,$2€'

    Write-Verbose "Number: $invoiceNumber"
    Write-Verbose "Date:   $rideDate"
    Write-Verbose "Amount: $invoiceAmount"

    if ([string]::IsNullOrWhiteSpace($invoiceNumber)) {
        Write-Verbose "Ignoring ${filename}"
        Return
    }

    $index = 0;
    do {
        ${index}++
    }
    while (Test-Path "${rideDate} 0${index}*")

    $newFilename = "${rideDate} 0${index} ${documentLabel} ${invoiceNumber} ${invoiceAmount}.pdf"

    if (${newFilename} -eq ${filename}) {
        Write-Verbose "File has correct name. Ignoring ${filename}"
        Return
    }

    Write-Verbose "OLD:    $filename"
    Write-Verbose "NEW:    $newFilename"

    if ($newFilename -eq $filename) {
        return
    }

    Write-Output "Renaming '${filename}' to '${newFilename}'"
    Rename-Item -Path "${filename}" -NewName ${newFilename}
}

