[CmdletBinding()]
Param()

# $VerbosePreference = "Continue"
# $VerbosePreference = "Ignore"

Get-ChildItem -filter *.pdf | ForEach-Object {
    Clear-Variable -Name ("invoice*", "*filename")

    $filename = $_.Name

    $textContent = pdftotext -enc UTF-8 -simple -bom -q ${filename} - | Out-String

    if (${textContent} -NotMatch "contentpass") {
        Write-Verbose "Not contentpass. Ignoring ${filename}"
        Return
    }

    Write-Verbose "File: $filename"

    if ( ${textContent} -cmatch "(?s)(?<!Nächstes )Rechnungsdatum— ([A-Za-zäöüÄÖÜ]+) (\d{1,2}), (\d{4})") {
        $invoiceMonthText = $matches[1]
        $invoiceDay = "{0:00}" -f [int]$matches[2]
        $invoiceYear = $matches[3]

        $invoiceMonth = switch ($invoiceMonthText) {
            "Jan" { "01" }
            "Feb" { "02" }
            "Mar" { "03" }; "Mär" { "03" }
            "Apr" { "04" }
            "May" { "05" }; "Mai" { "05" }
            "Jun" { "06" }
            "Jul" { "07" }
            "Aug" { "08" }
            "Sep" { "09" }
            "Oct" { "10" }; "Okt" { "10" }
            "Nov" { "11" }
            "Dec" { "12" }; "Dez" { "12" }
            Default { "ERROR" }
        }

        $invoiceDate = ${invoiceYear} + "-" + ${invoiceMonth} + "-" + ${invoiceDay}
        Write-Verbose "Invoice date: $invoiceDate"
    }

    if ( ${textContent} -cmatch "(?s)Rechnung #— (\d+)") {
        $invoiceNumber = $matches[1]
        Write-Verbose "Invoice number: $invoiceNumber"
    }

    if ( ${textContent} -cmatch "(?s)Rechnungsbetrag— € (\d+,\d{2})") {
        $invoiceAmount = $matches[1]
        Write-Verbose "Invoice amount: $invoiceAmount"
    }

    if (-not ${invoiceNumber} -or -not ${invoiceDate} -or -not ${invoiceAmount}) {
        Write-Output "Invalid invoice data. Ignoring ${filename}"
        Return
    }

    $newFilename = "${invoiceDate} 01 Contentpass ${invoiceNumber} ${invoiceAmount}€.pdf"

    if ($newFilename -eq $filename) {
        Write-Verbose "File has correct name: $filename"
        Return
    }

    Write-Output "Renaming '${filename}' to '${newFilename}'"
    Rename-Item -Path "${filename}" -NewName ${newFilename}
}
