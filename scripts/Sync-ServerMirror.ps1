<#
    Pulls the live server's deployable state down to a local mirror, and pushes reviewed files back.

      scripts\Sync-ServerMirror.ps1 -Pull
      scripts\Sync-ServerMirror.ps1 -Push -Files 'mods\a.jar','config\b.properties'
      scripts\Sync-ServerMirror.ps1 -Push -Remove 'mods\superseded-helper.jar'

    Why this exists: `Y:` was a CloudMounter SFTP mount and that trial expired, so Deploy-LiveServer
    has no filesystem to write to. Every deploy since has been ad-hoc WinSCP commands typed once and
    shredded afterwards, because they carried the password inline - which means the one step that
    touches the live server is the only step with no script behind it.

    **No credential ever appears here.** WinSCP stores the session; this names it. Save the site once
    in the WinSCP GUI with "Save password" ticked and pass its name, or set NBIDAL18_WINSCP_SESSION.
    Nothing in this file, in the repo, or in the shell history is a secret, so it does not have to be
    destroyed after use.

    Pull writes into a mirror that Deploy-LiveServer can then run against with -DriveRoot, so the
    existing refusals - the digest check, the Server List Ping, the hash-verified backups - all still
    apply. This moves bytes; it decides nothing.
#>
[CmdletBinding(DefaultParameterSetName = 'Pull')]
param(
    [Parameter(ParameterSetName = 'Pull')]  [switch] $Pull,
    [Parameter(ParameterSetName = 'Push')]  [switch] $Push,
    [Parameter(ParameterSetName = 'Push')]  [string[]] $Files,
    # Deleting is named separately from copying and is never inferred. A superseded helper has to
    # go - two jars claiming one mod id and the loader picks one - but nothing here should ever
    # work out on its own what the server no longer needs.
    [Parameter(ParameterSetName = 'Push')]  [string[]] $Remove,
    [string] $Session = $env:NBIDAL18_WINSCP_SESSION,
    [string] $MirrorRoot,
    [string] $RemoteRoot = '/'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $Session) {
    throw "No WinSCP session named. Pass -Session 'name' or set NBIDAL18_WINSCP_SESSION. Save the site in the WinSCP GUI first, with its password, so nothing has to be typed here."
}

$repo = Split-Path -Parent $PSScriptRoot
$packRoot = Split-Path -Parent $repo
if (-not $MirrorRoot) { $MirrorRoot = Join-Path $packRoot '_server-payload-cache' }

$winscp = @(
    "$env:LOCALAPPDATA\Programs\WinSCP\WinSCP.com",
    "$env:ProgramFiles\WinSCP\WinSCP.com",
    "${env:ProgramFiles(x86)}\WinSCP\WinSCP.com"
) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $winscp) { throw 'WinSCP.com not found. Install WinSCP, or add its folder here.' }

# WinSCP reads the script from a file; building it as one string keeps the quoting in one place.
$lines = [Collections.Generic.List[string]]::new()
$lines.Add('option batch abort')
$lines.Add('option confirm off')
# WinSCP parses a session name as a URL token, so a literal "+" arrives as a space and the site
# is not found - "Gamehostbros Vanilla+" became "Gamehostbros Vanilla ". Percent-encode the three
# characters it interprets, "%" first so the escapes are not re-escaped.
$encoded = $Session.Replace('%', '%25').Replace('+', '%2B').Replace(' ', '%20')
# WinSCP prints a hint suggesting an inline sftp:// URL instead of a saved site. That is exactly
# what this avoids: the URL carries the password, the site name does not.
$lines.Add("open `"$encoded`"")

if ($Pull) {
    if (-not (Test-Path -LiteralPath $MirrorRoot)) { New-Item -ItemType Directory -Path $MirrorRoot | Out-Null }
    # Only what a deploy reads or replaces. The world, playerdata and logs are deliberately absent:
    # they are large, they are not ours to move, and nothing here should ever be in a position to
    # write them back.
    foreach ($item in @('mods', 'config')) {
        $local = Join-Path $MirrorRoot $item
        if (-not (Test-Path -LiteralPath $local)) { New-Item -ItemType Directory -Path $local | Out-Null }
        # -criteria=either (time or size), not size alone. The integrity policy is 352 bytes before
        # and after a release and the MOTD line keeps its length, so a size comparison skips exactly
        # the two files a deploy changes, and the mirror then reports our own writes back to us as
        # if they were the server's. That is how a rehearsal's output was once mistaken for the
        # live policy.
        #
        # Not -criteria=checksum: that makes WinSCP run a hashing command over SSH, and this host is
        # SFTP-only - it answers "Server refused to start a shell/command" and the pull fails.
        $lines.Add("synchronize local -delete -criteria=either `"$local`" `"$RemoteRoot$item`"")
    }
    # Fetched unconditionally rather than left to the directory sync. These two are what a deploy
    # is judged by, they are small, and both keep their byte count across a release - so any
    # criteria-based comparison is exactly the wrong tool for them.
    foreach ($file in @('server.properties', 'config/nbidal18-integrity.properties')) {
        # Built by splitting on the separator and joining part by part: no literal backslash, and
        # no regex, both of which have bitten this repo before.
        $target = $MirrorRoot
        foreach ($part in $file.Split([char]47)) { $target = Join-Path $target $part }
        $lines.Add("get `"$RemoteRoot$file`" `"$target`"")
    }
    Write-Host ("pull      mods, config and server.properties -> {0}" -f $MirrorRoot)
}

if ($Push) {
    if (-not $Files -and -not $Remove) { throw 'Push needs -Files or -Remove: reviewed paths, relative to the mirror root.' }
    foreach ($rel in $Files) {
        $local = Join-Path $MirrorRoot $rel
        if (-not (Test-Path -LiteralPath $local -PathType Leaf)) { throw "Not in the mirror: $local" }
        # No literal backslash on purpose: this file is written from a shell where one collapses.
        $remote = $RemoteRoot + $rel.Replace([IO.Path]::DirectorySeparatorChar, [char]47)
        $lines.Add("put `"$local`" `"$remote`"")
        Write-Host ("push      {0}" -f $rel)
    }
    foreach ($rel in $Remove) {
        $remote = $RemoteRoot + $rel.Replace([IO.Path]::DirectorySeparatorChar, [char]47)
        $lines.Add("rm `"$remote`"")
        Write-Host ("remove    {0}" -f $rel)
    }
}

$lines.Add('exit')

$scriptFile = Join-Path ([IO.Path]::GetTempPath()) ("nbidal18-winscp-" + [guid]::NewGuid().ToString('N').Substring(0, 8) + '.txt')
[IO.File]::WriteAllText($scriptFile, ($lines -join "`r`n"), (New-Object Text.UTF8Encoding($false)))
try {
    # No /ini=nul here: the saved session lives in WinSCP's own configuration, so telling it to
    # ignore that is telling it the session does not exist.
    & $winscp /script=$scriptFile
    if ($LASTEXITCODE -ne 0) {
        throw "WinSCP exited $LASTEXITCODE. Check the session name matches one saved in the WinSCP GUI."
    }
}
finally {
    # The script file names a session, never a password - removed for tidiness, not for secrecy.
    Remove-Item -LiteralPath $scriptFile -Force -ErrorAction SilentlyContinue
}

Write-Host 'OK        transfer complete'
