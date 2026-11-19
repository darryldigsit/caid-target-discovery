# Cisco AI Defense – AI Validation Target Discovery

Helper scripts that find the **Request Body Template** and **Path to Model Response** values for an AI Validation (red teaming) target in Cisco AI Defense.

## What the script does

1. Asks for your AI endpoint URL, auth header, and (optionally) a sample request body.
2. Sends **one short test prompt** – `Reply with only the word PONG` – to *your* endpoint, once per request format it tries.
3. Reads the JSON reply, finds the field that holds the model's answer, and prints the values to paste into Cisco AI Defense.

It installs nothing, writes no files, and contacts only the URL you enter. Your auth value is never printed.

## Before you start

| You need | Where to get it |
|---|---|
| **Endpoint URL** | The API URL your app calls, e.g. `https://chat.example.com/api/chat` |
| **Auth header** | Your API docs or key portal. Enter it as `Name: value` (examples below) |
| **Sample body** *(recommended for custom apps)* | Browser DevTools (steps below) |

### Auth header examples

| AI service | Enter this |
|---|---|
| OpenAI / OpenAI-compatible | `Authorization: Bearer sk-proj-abc123...` |
| Azure OpenAI | `api-key: 0a1b2c3d...` |
| Custom app with API key | `x-api-key: abc123...` (use the header name your API expects) |
| No authentication | Press **Enter** |

> Use a dedicated, revocable key for the evaluation. Rotate it when testing ends.

### Get a sample body from your app (custom apps)

1. Open your chat app in Chrome or Edge, press **F12**, select the **Network** tab.
2. Send any chat message in the app.
3. Click the new request → **Payload** tab → **view source**. Copy the JSON.
4. Replace your message text with `{{prompt}}`, keep it on **one line**:

```json
{"lane": "unguarded", "model": "gpt-4o-mini", "prompt": "{{prompt}}"}
```

The **Headers** tab of the same request shows the auth header name (`Authorization`, `x-api-key`, ...).

## Run it

Use the **copy** button on the block, paste into the window, press **Enter**, answer the prompts.

### Windows (PowerShell)

```powershell
& {
[Net.ServicePointManager]::SecurityProtocol=3072
$u=Read-Host 'Target endpoint URL'
$a=Read-Host 'Auth header, e.g. Authorization: Bearer abc123 (Enter if none)'
$b=Read-Host 'Sample body with {{prompt}} as the user message (Enter to auto-detect)'
$h=@{};if($a -match '^\s*([^:]+):\s*(.+)$'){$h[$matches[1].Trim()]=$matches[2].Trim()}
if($b){$c=@($b)}else{$m=Read-Host 'Model name (Enter for gpt-4o-mini)';if(!$m){$m='gpt-4o-mini'}
$c=@('{"model":"'+$m+'","messages":[{"role":"user","content":"{{prompt}}"}]}')
$c+='prompt','query','input','message','question'|ForEach-Object{'{"'+$_+'":"{{prompt}}"}'}}
$K='content','text','response','output','answer','reply','result','completion','generated_text'
function W($v,$p){if($v -is [string]){[void]$L.Add([pscustomobject]@{p=$p.TrimStart('.');v=$v})}
elseif($v -is [array]){for($i=0;$i -lt $v.Count;$i++){W $v[$i] "$p.$i"}}
elseif($v -is [Management.Automation.PSCustomObject]){
foreach($x in $v.PSObject.Properties){W $x.Value "$p.$($x.Name)"}}}
foreach($t in $c){try{$d=$t.Replace('{{prompt}}','Reply with only the word PONG')
$q=@{Uri=$u;Method='Post';Headers=$h;ContentType='application/json';Body=$d}
$w=Invoke-WebRequest @q -UseBasicParsing -TimeoutSec 60
$j=$w.Content|ConvertFrom-Json;if($j.error -or $j.detail){continue}
$L=[Collections.ArrayList]@();W $j ''
$x=$L|Where-Object{$_.v -match 'pong'}|Sort-Object{$_.v.Length}|Select-Object -First 1
if(!$x){$x=$L|Where-Object{$K -contains ($_.p -split '\.')[-1]}|
Sort-Object{-$_.v.Length}|Select-Object -First 1}
if($x){$OK=$t;$RP=$x.p;break}}catch{}}
if($OK){"`n=== Paste into Cisco AI Defense ===";"Target Endpoint URL: $u"
"Request Body Template: $OK";"Path to Model Response: $RP"
if($h.Count){"HTTP Auth Header Key: $($h.Keys)"
'HTTP Auth Header Value: the text you entered after the colon'}}
else{'No working format found. Check the URL and auth header, or rerun and paste a sample body.'}
}
```

### macOS (Terminal)

```bash
{
printf 'Target endpoint URL: ';read -r U
printf 'Auth header, e.g. Authorization: Bearer abc123 (Enter if none): ';read -r A
printf 'Sample body with {{prompt}} as the user message (Enter to auto-detect): ';read -r B
H=(-H 'Content-Type: application/json');[ -n "$A" ] && H+=(-H "$A")
if [ -n "$B" ];then C=("$B");else printf 'Model name (Enter for gpt-4o-mini): ';read -r M
C=('{"model":"'"${M:-gpt-4o-mini}"'","messages":[{"role":"user","content":"{{prompt}}"}]}'
'{"prompt":"{{prompt}}"}' '{"query":"{{prompt}}"}' '{"input":"{{prompt}}"}'
'{"message":"{{prompt}}"}' '{"question":"{{prompt}}"}');fi
JS='function run(a){var o;try{o=JSON.parse(a[0])}catch(e){return ""}
if(!o||o.error||o.detail){return ""}var L=[];
(function w(v,p){if(typeof v=="string"){L.push([p,v])}
else if(v&&typeof v=="object"){for(var k in v){w(v[k],p.concat(k))}}})(o,[]);
var x=L.filter(function(e){return /pong/i.test(e[1])})
.sort(function(m,n){return m[1].length-n[1].length})[0];
var K=["content","text","response","output","answer","reply","result","completion","generated_text"];
if(!x){x=L.filter(function(e){return K.indexOf(String(e[0][e[0].length-1]))>=0})
.sort(function(m,n){return n[1].length-m[1].length})[0]}return x?x[0].join("."):""}'
PH='{{prompt}}';X=''
for T in "${C[@]}";do D=${T//"$PH"/Reply with only the word PONG}
R=$(curl -sf -m 60 -X POST "$U" "${H[@]}" -d "$D")
X=$(osascript -l JavaScript -e "$JS" "$R" 2>/dev/null);[ -n "$X" ] && break;done
if [ -n "$X" ];then printf '\n=== Paste into Cisco AI Defense ===\n'
printf 'Target Endpoint URL: %s\nRequest Body Template: %s\n' "$U" "$T"
printf 'Path to Model Response: %s\n' "$X"
[ -n "$A" ] && printf 'HTTP Auth Header Key: %s\n' "${A%%:*}" &&
echo 'HTTP Auth Header Value: the text you entered after the colon'
else echo 'No working format found. Check the URL and auth header, or rerun and paste a sample body.';fi
}
```

> Linux, or macOS with PowerShell 7 installed: run the PowerShell block in `pwsh`.

## Example output

```
=== Paste into Cisco AI Defense ===
Target Endpoint URL: https://chat.example.com/api/chat
Request Body Template: {"lane": "unguarded", "model": "gpt-4o-mini", "prompt": "{{prompt}}"}
Path to Model Response: response
HTTP Auth Header Key: Authorization
HTTP Auth Header Value: the text you entered after the colon
```

## Field mapping

| Cisco AI Defense field | Script output |
|---|---|
| Target Endpoint URL | Target Endpoint URL |
| Request Body Template | Request Body Template |
| Path to Model Response | Path to Model Response |
| HTTP Auth Header Key | HTTP Auth Header Key |
| HTTP Auth Header Value | What you typed after the colon (e.g. `Bearer sk-proj-abc123...`) |

## Troubleshooting

| Message | Fix |
|---|---|
| `No working format found` | Rerun and paste a sample body from your app (see above). |
| Same message with a sample body | Check the URL, the auth header, and that this computer can reach the endpoint. |
| Path looks wrong | Confirm with your app team which JSON field holds the answer text. |
