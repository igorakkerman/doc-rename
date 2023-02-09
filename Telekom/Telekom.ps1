[CmdletBinding()]
Param()

Get-ChildItem -filter *.pdf  | Where-Object { $_.LastWriteTime -ge "2022-10-01" } | ForEach-Object <# -Parallel #> {
    Clear-Variable -Name ("invoice*", "*filename")

    $filename = $_.Name
    
    $textContent = pdftotext -enc UTF-8 -layout -bom -q ${filename} - | Out-String

    if (${textContent} -NotMatch "Telekom Deutschland GmbH") {
        Write-Output "Not from Telekom. Ignoring ${filename}"
        Return
    }

    if ( ${textContent} -cmatch "(?s).*Rechnungsnummer\s+(\d+)\s(\d+)\s(\d+)\s(\d+).*") {
        $invoiceNumber = $matches[1] + $matches[2] + $matches[3] + $matches[4]
    }
    if ( ${textContent} -cmatch "(?s).*Datum\s+(\d{2})\.(\d{2}).(\d{4}).*") {
        $invoiceDay = $matches[1]
        $invoiceMonth = $matches[2]
        $invoiceYear = $matches[3]

        $invoiceDate = ${invoiceYear} + "-" + ${invoiceMonth} + "-" + ${invoiceDay}

        Write-Verbose "Invoice date: $invoiceDate"
    }
    
    if ( ${textContent} -cmatch "(?s).*Zu zahlender Betrag\s+(\d+,\d{2})\s*€.*") { 
        $invoiceAmount = $matches[1]

        Write-Verbose "Invoice amount: $invoiceAmount"
    }
    
    # Write-Output "${filename}: ${invoiceNumber} ${invoiceDate} ${InvoiceAmount}"
    if (-not ${invoiceNumber} -or -not ${invoiceDate} -or -not ${invoiceAmount}) {
        Write-Output "Invalid invoice data. Ignoring ${filename}"
        Return
    }

    $newFilename = "${invoiceDate} 01 Telekom ${invoiceNumber} ${invoiceAmount}€.pdf"
    
    if ($newFilename -eq $filename) {
        Write-Verbose "File has correct name: $filename"
        Return
    }

    Write-Output "Renaming '${filename}' to '${newFilename}'"
    Rename-Item -Path "${filename}" -NewName ${newFilename}
}

New-Item -ItemType Directory -Force signature | Out-Null
Move-Item *.ads signature
