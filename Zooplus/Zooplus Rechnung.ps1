function Parse($textContent, $matchRegex, $replaceRegex) {
    return $textContent | 
       Where-Object {$_ -match "${matchRegex}"} | 
       ForEach-Object {$_ -replace "${matchRegex}", "${replaceRegex}"}
}

Get-ChildItem -filter *.pdf | ForEach-Object {
    $filename = $_.Name
    
    $textContent = pdftotext ${filename} -
    $invoiceNumber = Parse ${textContent} '.+Rechnungsnummer : ([0-9]+).*' '$1'
    $invoiceDate = Parse ${textContent} '.+Rechnungsdatum : ([0-9][0-9])\.([0-9][0-9])\.([0-9][0-9][0-9][0-9]).*' '$3-$2-$1'
    $invoiceAmount = Parse ${textContent} '.*Rechnungsbetrag ([0-9]+,[0-9][0-9]).*' '$1'
    
    if ([string]::IsNullOrWhiteSpace($invoiceNumber)) {
        # Write-Host "Ignoring   ${filename}"
        Return
    }

    $newFilename = "${invoiceDate} 01 Rechnung ${invoiceNumber} ${invoiceAmount}€.pdf"

    Write-Host "'${filename}' becomes '${newFilename}'"
    Rename-Item -Path "${filename}" -NewName ${newFilename}
}

pause
