Add-Type -AssemblyName System.Net.HttpListener
$port = 5500
$listener = [System.Net.HttpListener]::new()
$prefix = "http://localhost:$port/"
$listener.Prefixes.Add($prefix)
$listener.Start()
Write-Output "PREVIEW_URL=$prefix"

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        try {
            $path = $context.Request.Url.AbsolutePath.TrimStart('/')
            if ([string]::IsNullOrWhiteSpace($path)) { $path = 'index.html' }
            $file = [System.IO.Path]::Combine((Get-Location).Path, $path)

            if (Test-Path -LiteralPath $file) {
                $bytes = [System.IO.File]::ReadAllBytes($file)
                $ext = [System.IO.Path]::GetExtension($file).ToLowerInvariant()
                switch ($ext) {
                    '.html' { $context.Response.ContentType = 'text/html; charset=utf-8' }
                    '.css'  { $context.Response.ContentType = 'text/css; charset=utf-8' }
                    '.js'   { $context.Response.ContentType = 'application/javascript; charset=utf-8' }
                    '.svg'  { $context.Response.ContentType = 'image/svg+xml' }
                    default { $context.Response.ContentType = 'application/octet-stream' }
                }
                $context.Response.StatusCode = 200
                $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
            } else {
                $msg = [Text.Encoding]::UTF8.GetBytes('404 Not Found')
                $context.Response.StatusCode = 404
                $context.Response.OutputStream.Write($msg, 0, $msg.Length)
            }
        } catch {
            $err = [Text.Encoding]::UTF8.GetBytes('500 Internal Server Error')
            $context.Response.StatusCode = 500
            $context.Response.OutputStream.Write($err, 0, $err.Length)
        } finally {
            $context.Response.OutputStream.Close()
        }
    }
} finally {
    $listener.Stop()
    $listener.Close()
}