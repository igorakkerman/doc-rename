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

    $documentType = if ($textContent -match "Rechnungsstorno") {"Storno "} else {""}
    $documentLabel = "${documentType}SIXT share"

    $invoiceNumber = ${textContent} -replace "(?s).+?Rechn.\s+Nr.:\s+(\d+).*", '$1'
    $invoiceDate = ${textContent} -replace "(?s).+Pullach,\s+(\d{2})\.(\d{2}).(\d{4}).*", '$3-$2-$1'
    $invoiceAmount = ${textContent} -replace "(?s).+Endbetrag.+(\d+),(\d{2})\s+EUR.+", ' $1,$2€'

    Write-Verbose "Number: $invoiceNumber"
    Write-Verbose "Date:   $invoiceDate"
    Write-Verbose "Amount: $invoiceAmount"

    if ([string]::IsNullOrWhiteSpace($invoiceNumber)) {
        Write-Verbose "Invalid data. Ignoring ${filename}"
        Return
    }

    if ($filename -Match "${invoiceDate} \d\d ${documentLabel} ${invoiceNumber}${invoiceAmount}.pdf") {
        Write-Verbose "File has correct name: $filename"
        Return
    }

    $index = 0;
    do {
        $index++
        $indexTwoDigits = $('{0:d2}' -f $index)
    }
    while (Test-Path "${invoiceDate} $indexTwoDigits*")

    $newFilename = "${invoiceDate} $indexTwoDigits ${documentLabel} ${invoiceNumber}${invoiceAmount}.pdf"

    Write-Verbose "OLD:    $filename"
    Write-Verbose "NEW:    $newFilename"

    Write-Output "Renaming '${filename}' to '${newFilename}'"
    Rename-Item -Path "${filename}" -NewName ${newFilename}
}
