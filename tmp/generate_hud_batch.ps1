$ErrorActionPreference = 'Stop'
$root = 'C:\Users\steven\Desktop\Cursor\Shooter'
$auth = ((Get-Content "$env:USERPROFILE\.cursor\mcp.json" | ConvertFrom-Json).mcpServers.spritecook.headers.Authorization)
$ref = '0d91d637-43a7-4a19-8fdc-aee4f9ad6284'
$jobs = @(
  @{
    File='hud_ability_orb_frame.png'
    Width=48
    Height=48
    Prompt='compact minimalist fantasy pixel HUD ability slot frame, small circular medallion ring with subtle octagonal silhouette, dark gunmetal and silver bevel, tiny ruby and sapphire pin accents, clean transparent center opening for an icon, sleek and understated, no bulky ornaments, transparent background'
  },
  @{
    File='hud_level_ring_frame.png'
    Width=60
    Height=60
    Prompt='small minimalist fantasy pixel level medallion ring, compact circular frame with subtle silver bevel and one tiny blue crystal accent, dark gunmetal body, clean center opening for a level number, sleek understated roguelite HUD element, transparent background'
  },
  @{
    File='hud_xp_frame.png'
    Width=720
    Height=14
    Prompt='ultra thin minimalist fantasy pixel experience bar frame, dark gunmetal track with silver edges and faint cyan crystal pins, long clean center opening for fill, sleek unobtrusive HUD element, no text, no large ornaments, transparent background'
  },
  @{
    File='hud_top_strip_frame.png'
    Width=560
    Height=28
    Prompt='thin minimalist fantasy pixel top objective strip frame, dark gunmetal horizontal bar with subtle silver bevel and tiny gem endcaps, clean center panel for text, sleek readable roguelite HUD strip, no title text, transparent background, no bulky ornament'
  }
)
$results = @()
foreach ($job in $jobs) {
  $payload = [ordered]@{
    prompt = $job.Prompt
    width = $job.Width
    height = $job.Height
    variations = 1
    pixel = $true
    bg_mode = 'transparent'
    theme = 'dark fantasy roguelite UI'
    style = 'minimalist sleek pixel HUD chrome'
    smart_crop = $false
    mode = 'ui'
    resolution = '1K'
    reference_asset_id = $ref
  } | ConvertTo-Json -Depth 4
  $tmp = Join-Path $root ('tmp\' + [IO.Path]::GetFileNameWithoutExtension($job.File) + '.json')
  Set-Content -Path $tmp -Value $payload
  $raw = node scripts\spritecook_http.mjs call generate_game_art "@$tmp"
  $json = $raw | ConvertFrom-Json
  $asset = $json.structuredContent.assets[0]
  Invoke-WebRequest -Uri $asset.download_pixel_url -Headers @{ Authorization = $auth } -OutFile (Join-Path $root ('art\ui\chrome\' + $job.File))
  $results += [pscustomobject]@{ file=$job.File; id=$asset.id; width=$asset.width; height=$asset.height }
}
$results | ConvertTo-Json -Depth 4 | Set-Content -Path (Join-Path $root 'tmp\spritecook_hud_batch_results.json')
$results | Format-Table -AutoSize
