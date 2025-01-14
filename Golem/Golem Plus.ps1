[CmdletBinding()]
Param()

Get-ChildItem -filter *.pdf  | Where-Object { $_.LastWriteTime -ge "2024-01-01" } | ForEach-Object <# -Parallel #> {
    Clear-Variable -Name ("invoice*", "*filename")

    $filename = $_.Name
    
    $textContent = pdftotext -enc UTF-8 -simple -bom -q ${filename} - | Out-String

    if (${textContent} -NotMatch "Golem Plus") {
        Write-Output "Not Golem Plus. Ignoring ${filename}"
        Return
    }

    Write-Verbose $filename

    if ( ${textContent} -cmatch "(?s)(\d{2})\.(\d{2}).(\d{4})\s+(PI-\d+).*") {
        $invoiceDay = $matches[1]
        $invoiceMonth = $matches[2]
        $invoiceYear = $matches[3]

        $invoiceDate = ${invoiceYear} + "-" + ${invoiceMonth} + "-" + ${invoiceDay}
        Write-Verbose "Invoice date: $invoiceDate"

        $invoiceNumber = $matches[4]
        Write-Verbose "Invoice number: $invoiceNumber"
    
    }
    
    if ( ${textContent} -cmatch "(?s).*Rechnungsbetrag \(brutto\):\s+(\d+,\d{2})\s*€.*") { 
        $invoiceAmount = $matches[1]

        Write-Verbose "Invoice amount: $invoiceAmount"
    }
    
    # Write-Output "${filename}: ${invoiceNumber} ${invoiceDate} ${InvoiceAmount}"
    if (-not ${invoiceNumber} -or -not ${invoiceDate} -or -not ${invoiceAmount}) {
        Write-Output "Invalid invoice data. Ignoring ${filename}"
        Return
    }

    $newFilename = "${invoiceDate} 01 Golem Plus ${invoiceNumber} ${invoiceAmount}€.pdf"
    
    if ($newFilename -eq $filename) {
        Write-Verbose "File has correct name: $filename"
        Return
    }

    Write-Output "Renaming '${filename}' to '${newFilename}'"
    Rename-Item -Path "${filename}" -NewName ${newFilename}
}
