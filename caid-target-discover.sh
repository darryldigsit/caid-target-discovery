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
