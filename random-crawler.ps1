param ([string]$query, [int]$depth = 2,
       [int]$minSearchResultsIndex = 1, [int]$maxSearchResultsIndex = 3,
       [int]$minCrawlIndex = 5, [int]$maxCrawlIndex = 15)

$useragent = "Opera/9.80 (J2ME/MIDP; Opera Mini/4.2.14912/870; U; id) Presto/2.4.15";

Function GetLinksFromPage {
    param ([string]$url)
    write-host "crawling $url ..."
    #$links = ((iwr -uri $url -useragent $script:useragent -method "Get").links.href | where { $_.contains("://") })
    $links = (iwr -uri $url -useragent $script:useragent -method "Get").links.href
    write-host "found $($links.length) links"
    return $links
}

Function GetAbsoluteLinkFromRelative {
    param ([string]$url, [string]$lasturl)

    $uricreationworked = $false
    try {
        $uri = new-object system.uri $url
        $uricreationworked = $true
    }
    catch {
    }
    if (-not $uricreationworked) {
        write-host "relative url found, referrer was $lasturl"
        $lasturihost = (new-object system.uri $lasturl).host
        $lasturischeme = (new-object system.uri $lasturl).scheme
        $url = "${lasturischeme}://$lasturihost$url"
    }
    return $url
}

$oldLinks = @()
$oldLinkIndexes = @()
$links = (GetLinksFromPage "http://duckduckgo.com/?q=$query")
if ($maxSearchResultsIndex -ge $links.length) {
    $minSearchResultsIndex = $links.length - ($maxSearchResultsIndex - $minSearchResultsIndex)
    if ($minSearchResultsIndex -lt 0) {
        $minSearchResultsIndex = 0
    }
    $maxSearchResultsIndex = $links.length
}
$searchResultsIndex = Get-Random -minimum $minSearchResultsIndex -maximum $maxSearchResultsIndex
write-host "crawling link number $searchResultsIndex..."
$link = $links[$searchResultsIndex]
$oldLinks += $link
$depthIndex = 0
while ($depthIndex -lt $depth) {
    if ([string]::isnullorwhitespace($link)) {
        write-host "failed at $($oldLinks[$depthIndex - 1]) and index $($oldLinkIndexes[$depthIndex - 1])"
        return
    }

    write-host "um link before $link"
    $link = GetAbsoluteLinkFromRelative $link $oldLinks[$depthIndex - 1]
    write-host "um link $link"
    $oldLinks += $link
    $links = (GetLinksFromPage $link)

    if ($maxCrawlIndex -ge $links.length) {
        $minCrawlIndex = $links.length - ($maxCrawlIndex - $minCrawlIndex)
        if ($minCrawlIndex -lt 0) {
            $minCrawlIndex = 0
        }
        $maxCrawlIndex = $links.length
    }
    $linkIndex = Get-Random -minimum $minCrawlIndex -maximum $maxCrawlIndex
    $link = $links[$searchResultsIndex]

    $oldLinkIndexes += $linkIndex.ToString()
    write-host "crawling link number $linkIndex..."

    $depthIndex++
}
$link = GetAbsoluteLinkFromRelative $link $oldLinks[$depthIndex - 1]
write-host "outputting link $link..."
(iwr -uri $link -useragent $useragent -method "Get").parsedhtml.body.outertext | less
return

