param ([string]$query, [int]$depth = 2,
       [int]$minSearchResultsIndex = 0, [int]$maxSearchResultsIndex = 3,
       [int]$minCrawlIndex = 5, [int]$maxCrawlIndex = 15)

Function GetLinkFromPage {
    param ([string]$url, [int]$index)
    ((iwr -uri $url -useragent $useragent -method "Get").links.href | where { $_.contains("://") })[$index]
}

$oldLinks = @()
$oldLinkIndexes = @()
$searchResultsIndex = Get-Random -minimum $minSearchResultsIndex -maximum $maxSearchResultsIndex
$link = GetLinkFromPage "http://duckduckgo.com/?q=$query" $searchResultsIndex
$oldLinks += $link
$depthIndex = 0
while ($depthIndex -lt $depth) {
    if ([string]::isnullorwhitespace($link)) {
        write-host "failed at $($oldLinks[$depthIndex - 1]) and index $($oldLinkIndexes[$depthIndex - 1])"
        return
    }
    $linkIndex = Get-Random -minimum $minCrawlIndex -maximum $maxCrawlIndex

    write-host "crawling $link..."
    $oldLinks += $link
    $oldLinkIndexes += $linkIndex.ToString()

    $link = GetLinkFromPage $link $linkIndex
    $depthIndex++
}
(iwr -uri $link -useragent $useragent -method "Get").parsedhtml.body.outertext | less
return

