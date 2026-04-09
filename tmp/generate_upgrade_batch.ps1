$ErrorActionPreference = 'Stop'
$root = 'C:\Users\steven\Desktop\Cursor\Shooter'
$auth = ((Get-Content "$env:USERPROFILE\.cursor\mcp.json" | ConvertFrom-Json).mcpServers.spritecook.headers.Authorization)
$cardPayload = [ordered]@{
  prompt = 'sleek tall fantasy pixel upgrade card frame, dark obsidian gunmetal body with restrained silver corners, open center area, subtle lower rarity plaque space, elegant minimalist roguelite card, not ornate, transparent background, no text'
  width = 248
  height = 340
  variations = 1
  pixel = $true
  bg_mode = 'transparent'
  theme = 'dark fantasy roguelite UI'
  style = 'minimalist sleek pixel HUD chrome'
  smart_crop = $false
  mode = 'ui'
  resolution = '1K'
} | ConvertTo-Json -Depth 4
Set-Content -Path tmp\upgrade_card_frame_request.json -Value $cardPayload
$raw = node scripts\spritecook_http.mjs call generate_game_art @tmp\upgrade_card_frame_request.json
$json = $raw | ConvertFrom-Json
$card = $json.structuredContent.assets[0]
Invoke-WebRequest -Uri $card.download_pixel_url -Headers @{ Authorization = $auth } -OutFile (Join-Path $root 'art\ui\chrome\upgrade_card_frame.png')
$cardRef = $card.id
$jobs = @(
  @{
    File='upgrade_card_selected_glow.png'
    Width=248
    Height=340
    Prompt='selected overlay for sleek fantasy pixel upgrade card, soft cyan white magical edge glow hugging a tall minimal card silhouette, transparent center, understated but premium, no interior art, transparent background'
  },
  @{
    File='upgrade_icon_mount.png'
    Width=120
    Height=112
    Prompt='minimalist fantasy pixel upgrade card icon mount, dark metal crest with silver bevel and tiny gem apex, open center for a large upgrade icon, sleek and symmetrical, transparent background, no text'
  }
)
$results = @([pscustomobject]@{ file='upgrade_card_frame.png'; id=$card.id; width=$card.width; height=$card.height })
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
    reference_asset_id = $cardRef
  } | ConvertTo-Json -Depth 4
  $tmp = Join-Path $root ('tmp\' + [IO.Path]::GetFileNameWithoutExtension($job.File) + '.json')
  Set-Content -Path $tmp -Value $payload
  $raw2 = node scripts\spritecook_http.mjs call generate_game_art "@$tmp"
  $json2 = $raw2 | ConvertFrom-Json
  $asset = $json2.structuredContent.assets[0]
  Invoke-WebRequest -Uri $asset.download_pixel_url -Headers @{ Authorization = $auth } -OutFile (Join-Path $root ('art\ui\chrome\' + $job.File))
  $results += [pscustomobject]@{ file=$job.File; id=$asset.id; width=$asset.width; height=$asset.height }
}
$results | ConvertTo-Json -Depth 4 | Set-Content -Path (Join-Path $root 'tmp\spritecook_upgrade_batch_results.json')
$results | Format-Table -AutoSize
