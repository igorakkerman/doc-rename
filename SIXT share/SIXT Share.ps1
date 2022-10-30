# $VerbosePreference = "Continue"

Get-ChildItem -filter "*.pdf" | ForEach-Object {
    $filename = $_.Name

    $textContent = pdftotext -enc UTF-8 -bom -simple -q ${filename} - | Out-String

    if (${textContent} -match "SIXT share") {
        Write-Verbose "Old document version. Ignoring ${filename}"
        Return
    }

    if (${textContent} -notmatch "Sixt GmbH & Co") {
        Write-Verbose "Ignoring ${filename}"
        Return
    }
    Write-Verbose "Processing file $filename"

    $documentType = if ($textContent -notmatch "Rechnungsstorno") {"Storno"} else {$null}
    $invoiceNumber = ${textContent} -replace "(?s).+?Rechn.\W+Nr.:\s+(\d+).*", '$1'
    $invoiceDate = ${textContent} -replace "(?s).+Pullach,\W+(\d{2})\.(\d{2}).(\d{4}).*", '$3-$2-$1'
    $invoiceAmount = ${textContent} -replace "(?s).+Endbetrag.+(\d+),(\d{2})\W+EUR.+", ' $1,$2€'

    Write-Verbose "Number: $invoiceNumber"
    Write-Verbose "Date:   $invoiceDate"
    Write-Verbose "Amount: $invoiceAmount"

    if ([string]::IsNullOrWhiteSpace($invoiceNumber)) {
        Write-Verbose "Invalid data. Ignoring ${filename}"
        Return
    }

    $index = 0;
    do {
        ${index}++
    }
    while (Test-Path "${invoiceDate} 0${index}*")

    $newFilename = "${invoiceDate} 0${index} ${documentType -not -eq $null ? "$documentType " : ""}SIXT share ${invoiceNumber}${invoiceAmount}.pdf"

    Write-Verbose "OLD:    $filename"
    Write-Verbose "NEW:    $newFilename"

    if (${newFilename} -eq ${filename}) {
        Write-Verbose "File has correct name. Ignoring ${filename}"
        Return
    }

    if ($newFilename -eq $filename) {
        return
    }

    Write-Output "Renaming '${filename}' to '${newFilename}'"
    Rename-Item -Path "${filename}" -NewName ${newFilename}
}
