# $VerbosePreference = "Continue"
$VerbosePreference = "Ignore"

Get-ChildItem -filter "*.pdf" | ForEach-Object {
    $filename = $_.Name

    $textContent = pdftotext -enc UTF-8 -bom -layout -q ${filename} - | Out-String

    if (${textContent} -notmatch "miles-mobility.com") {
        Write-Verbose "Ignoring ${filename}"
        Return
    }

    Write-Verbose "Processing file $filename"

    $documentType = if ($textContent -match "Rechnungsstorno") { "Storno " } else { "" }
    $documentLabel = "${documentType}MILES"

    $invoiceNumber = ${textContent} -replace "(?s).+Rechnungsnummer:\s+([A-Z0-9]+).*", '$1'
 
    if ( 
        $textContent -cmatch "(?s).+Fahrtkosten\s+(\d+)\.(\d{2})\s*€.+" -or
        $textContent -cmatch "(?s).+Summe\s+(\d+)\.(\d{2})€.+" -or
        $textContent -cmatch "(?s).+Bezahlt.+:\s+(\d+)\.(\d{2})\s*€.+" 
    ) {
        $euro = $matches[1]
        $cent = $matches[2]
        $invoiceAmount = "${euro},${cent}€"
    }
    else {
        $invoiceAmount = $null
    }

    if ( $textContent -cmatch "(?s).+Rechnungsdatum:\s+(\d{1,2})\s+(\S+)\s+(\d{4}).*") {

        $invoiceDay = "{0:00}" -f [int]$matches[1]
        $invoiceMonthText = $matches[2]
        $invoiceYear = $matches[3]

        $invoiceMonth = switch ($invoiceMonthText) {
            "Januar" { "01" }
            "Februar" { "02" }
            "März" { "03" }
            "April" { "04" }
            "Mai" { "05" }
            "Juni" { "06" }
            "Juli" { "07" }
            "August" { "08" }
            "September" { "09" }
            "Oktober" { "10" }
            "November" { "11" }
            "Dezember" { "12" }
            Default { "ERROR" }
        }

        $invoiceDate = "${invoiceYear}-${invoiceMonth}-${invoiceDay}"
    }

    Write-Verbose "Number:  $invoiceNumber"
    Write-Verbose "Date:    $invoiceDate"
    Write-Verbose "Amount:  $invoiceAmount"

    if ([string]::IsNullOrWhiteSpace($invoiceNumber)) {
        Write-Verbose "Invalid data. Ignoring $filename"
        Return
    }

    $index = 0;
    do {
        ${index}++
    }
    while (Test-Path "${invoiceDate} 0${index}*")

    $newFilename = "${invoiceDate} 0${index} ${documentLabel} ${invoiceNumber} ${invoiceAmount}.pdf"

    Write-Verbose "OLD:    $filename"
    Write-Verbose "NEW:    $newFilename"

    if ($newFilename -eq $filename) {
        Write-Verbose "File has correct name. Ignoring $filename"
        Return
    }

    if ($newFilename -eq $filename) {
        return
    }

    Write-Output "Renaming '$filename' to '$newFilename'"
    Rename-Item -Path "$filename" -NewName $newFilename
}
