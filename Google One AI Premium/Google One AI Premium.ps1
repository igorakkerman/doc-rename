[CmdletBinding()]
Param()

# $VerbosePreference = "Continue"
# $VerbosePreference = "Ignore"

Get-ChildItem -filter *.pdf  | Where-Object { $_.LastWriteTime -ge "2024-01-01" } | ForEach-Object <# -Parallel #> {
    Clear-Variable -Name ("invoice*", "*filename")

    $filename = $_.Name
    
    $textContent = pdftotext -enc UTF-8 -simple -bom -q ${filename} - | Out-String

    if (${textContent} -NotMatch "Google One AI Premium") {
        Write-Output "Not Google One AI Premium. Ignoring ${filename}"
        Return
    }

    Write-Verbose "File: $filename"

    if ( ${textContent} -cmatch "(?s)für[\w\s]+(\d{2})\.\s+([A-Za-z]+)\.\s+(\d{4}).*") {
        $invoiceDay = $matches[1]
        $invoiceMonthText = $matches[2]
        $invoiceYear = $matches[3]

        $invoiceMonth = switch ($invoiceMonthText) {
            "Jan" { "01" }
            "Feb" { "02" }
            "Mar" { "03" }
            "Apr" { "04" }
            "Mai" { "05" }
            "Jun" { "06" }
            "Jul" { "07" }
            "Aug" { "08" }
            "Sept" { "09" }
            "Okt" { "10" }
            "Nov" { "11" }
            "Dez" { "12" }
            Default { "ERROR" }
        }


        $invoiceDate = ${invoiceYear} + "-" + ${invoiceMonth} + "-" + ${invoiceDay}
        Write-Verbose "Invoice date: $invoiceDate"
    }
    
    
    if ( ${textContent} -cmatch "(?s).*Rechnungsnummer:\s+([0-9-]+).*") { 
        $invoiceNumber = $matches[1]
        Write-Verbose "Invoice number: $invoiceNumber"
    }

    if ( ${textContent} -cmatch "(?s).*Gesamtsumme in EUR\s+(\d+,\d{2})\s*€.*") { 
        $invoiceAmount = $matches[1]

        Write-Verbose "Invoice amount: $invoiceAmount"
    }
    
    # Write-Output "${filename}: ${invoiceNumber} ${invoiceDate} ${InvoiceAmount}"
    if (-not ${invoiceNumber} -or -not ${invoiceDate} -or -not ${invoiceAmount}) {
        Write-Output "Invalid invoice data. Ignoring ${filename}"
        Return
    }

    $newFilename = "${invoiceDate} 01 Google One AI Premium ${invoiceNumber} ${invoiceAmount}€.pdf"
    
    if ($newFilename -eq $filename) {
        Write-Verbose "File has correct name: $filename"
        Return
    }

    Write-Output "Renaming '${filename}' to '${newFilename}'"
    Rename-Item -Path "${filename}" -NewName ${newFilename}
}
