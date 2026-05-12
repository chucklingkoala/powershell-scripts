# PowerShell script to get share price data from Yahoo Finance API using ISIN or Ticker

param(
    [Parameter(Mandatory=$false)]
    [string]$ISIN,
    
    [Parameter(Mandatory=$false)]
    [string]$Ticker,
    
    [Parameter(Mandatory=$false)]
    [int]$Months = 12
)

function Convert-ISINtoTicker {
    param (
        [string]$ISIN
    )
    
    try {
        # Option 1: Use OpenFIGI API
        # The OpenFIGI API can map ISINs to various identifiers including ticker symbols
        $headers = @{
            "Content-Type" = "application/json"
        }
        
        $body = @(
            @{
                "idType" = "ID_ISIN"
                "idValue" = $ISIN
            }
        ) | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri "https://api.openfigi.com/v3/mapping" -Method Post -Headers $headers -Body $body
        
        if ($response -and $response[0].data -and $response[0].data.Count -gt 0) {
            # Extract ticker from response
            foreach ($item in $response[0].data) {
                if ($item.exchCode -eq "US" -or $item.exchCode -eq "NA") {
                    # Prefer US exchanges if available
                    return $item.ticker
                }
            }
            # If no US exchange, use the first result
            return $response[0].data[0].ticker
        }
        
        # Option 2: Try EODHD API (requires API key in production)
        # This is commented out as it requires an API key
        <#
        $apiKey = "YOUR_API_KEY" # Replace with your API key
        $url = "https://eodhd.com/api/exchange-symbol-list/US?api_token=$apiKey&fmt=json"
        $allSymbols = Invoke-RestMethod -Uri $url -Method Get
        
        # Find the entry with matching ISIN
        $matchingSymbol = $allSymbols | Where-Object { $_.ISIN -eq $ISIN }
        if ($matchingSymbol) {
            return $matchingSymbol.Code
        }
        #>
        
        # Option 3: Use a web scraping approach on a financial website
        # Note: This should be used as a last resort and might break if the website structure changes
        $url = "https://finance.yahoo.com/lookup?s=$ISIN"
        $response = Invoke-WebRequest -Uri $url -Method Get
        
        # Look for potential ticker symbols in the response
        if ($response.Content -match '"symbol":"([A-Z0-9\.]+)"') {
            return $matches[1]
        }
        
        Write-Error "Could not find ticker symbol for ISIN: $ISIN"
        return $null
    } catch {
        Write-Error "Error converting ISIN to ticker: $_"
        return $null
    }
}

function Get-YahooFinanceData {
    param (
        [string]$Ticker,
        [int]$Months = 12
    )

    try {
        # Calculate period start and end
        $endDate = Get-Date
        $startDate = $endDate.AddMonths(-$Months)
        
        # Convert to Unix timestamp (seconds since Jan 1, 1970)
        $unixTimeStart = [int][double]::Parse((Get-Date -Date $startDate -UFormat %s))
        $unixTimeEnd = [int][double]::Parse((Get-Date -Date $endDate -UFormat %s))
        
        # Construct Yahoo Finance API URL
        $interval = "1d" # daily data
        $url = "https://query1.finance.yahoo.com/v8/finance/chart/$Ticker" +
               "?period1=$unixTimeStart" +
               "&period2=$unixTimeEnd" +
               "&interval=$interval" +
               "&events=history"
               
        # Request data
        $response = Invoke-RestMethod -Uri $url -Method Get
        
        # Check if data was returned
        if ($response.chart.result -eq $null) {
            Write-Error "No data returned from Yahoo Finance for ticker: $Ticker"
            return $null
        }
        
        # Extract timestamp and price data
        $timestamps = $response.chart.result[0].timestamp
        $prices = $response.chart.result[0].indicators.quote[0]
        
        # Create result array
        $results = @()
        
        for ($i = 0; $i -lt $timestamps.Count; $i++) {
            # Convert timestamp to datetime
            $date = (Get-Date "1970-01-01").AddSeconds($timestamps[$i])
            
            # Create custom object with date and price data
            $dataPoint = [PSCustomObject]@{
                Date = $date.ToString("yyyy-MM-dd")
                Open = [math]::Round($prices.open[$i], 2)
                High = [math]::Round($prices.high[$i], 2)
                Low = [math]::Round($prices.low[$i], 2)
                Close = [math]::Round($prices.close[$i], 2)
                Volume = $prices.volume[$i]
            }
            
            $results += $dataPoint
        }
        
        return $results
    } catch {
        Write-Error "Error fetching data from Yahoo Finance: $_"
        return $null
    }
}

# Parameter validation
if (-not $ISIN -and -not $Ticker) {
    Write-Error "Either ISIN or Ticker parameter must be provided."
    return
}

# Main script execution
try {
    # Determine the ticker symbol to use
    $tickerToUse = $null
    
    if ($Ticker) {
        # If ticker is provided directly, use it
        $tickerToUse = $Ticker
        Write-Host "Using provided ticker symbol: $tickerToUse"
    } else {
        # Otherwise convert ISIN to ticker
        Write-Host "Converting ISIN $ISIN to ticker symbol..."
        $tickerToUse = Convert-ISINtoTicker -ISIN $ISIN
        
        if ($tickerToUse) {
            Write-Host "Found ticker symbol: $tickerToUse"
        } else {
            # Option for manual ticker input if automatic conversion fails
            Write-Host "Automatic ISIN to ticker conversion failed. Would you like to enter the ticker symbol manually? (Y/N)"
            $response = Read-Host
            if ($response -eq "Y" -or $response -eq "y") {
                $tickerToUse = Read-Host "Please enter the ticker symbol"
            } else {
                Write-Error "No valid ticker symbol available. Exiting script."
                return
            }
        }
    }
    
    if ($tickerToUse) {
        Write-Host "Retrieving price data for $tickerToUse for the past $Months months..."
        $priceData = Get-YahooFinanceData -Ticker $tickerToUse -Months $Months
        
        if ($priceData) {
            # Output to console
            Write-Host "Retrieved $(($priceData).Count) days of price data"
            
            # Export to CSV
            $outputFile = "$tickerToUse-price-data.csv"
            $priceData | Export-Csv -Path $outputFile -NoTypeInformation
            Write-Host "Data exported to: $outputFile"
            
            # Return data object
            return $priceData
        }
    }
} catch {
    Write-Error "Script execution failed: $_"
}