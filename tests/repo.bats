load test_helper

@test "gitignore excludes secret and local files" {
  for f in .zshrc.local key.pem .DS_Store my-token api_secret.txt; do
    run git -C "$REPO" check-ignore -q "$f"; [ "$status" -eq 0 ] || { echo "not ignored: $f"; false; }
  done
}

@test "pre-commit rejects a staged secret and passes a clean file" {
  tmp=$(mktemp -d); git -C "$tmp" init -q
  # The token is generated during the test; no token-like string lives in the repo.
  echo "token = ghp_$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 36)" > "$tmp/leak.txt"
  git -C "$tmp" add leak.txt
  run sh -c "cd '$tmp' && '$REPO/.githooks/pre-commit'"; [ "$status" -ne 0 ]
  git -C "$tmp" rm -q --cached leak.txt; echo "hello" > "$tmp/ok.txt"; git -C "$tmp" add ok.txt
  run sh -c "cd '$tmp' && '$REPO/.githooks/pre-commit'"; [ "$status" -eq 0 ]
  rm -rf "$tmp"
}

@test "bootstrap hooks sets core.hooksPath" {
  run "$REPO/bootstrap.sh" hooks; [ "$status" -eq 0 ]
  [ "$(git -C "$REPO" config core.hooksPath)" = ".githooks" ]
}

@test "unknown step prints usage and exits 2" {
  run "$REPO/bootstrap.sh" no-such-step; [ "$status" -eq 2 ]; [[ "$output" == *"clt brew link runtimes hooks"* ]]
}

@test "design docs are not in the repo or its history" {
  [ -z "$(git -C "$REPO" ls-files docs/superpowers)" ]
  [ -z "$(git -C "$REPO" log --all --format=%H -- docs/superpowers)" ]
}

@test "no Turkish text in tracked files" {
  # The only allowed exception is the author's name. Lines marked turkish-check in this file hold the patterns.
  letters='[çğıöşüÇĞİÖŞÜ]'                                                              # turkish-check
  stems='dosya|klasör|klasor|olarak|yalnızca|yalnizca|varsayılan|varsayilan|kurulum|tekrar|değil|degil|bulundu|merhaba|ornek|örnek|eksik|calistir|çalıştır|ayarlar|kullan' # turkish-check
  words='için|icin|yok|yeni|eski|tamam|ayar|bir|ile'                                     # turkish-check
  self='^tests/repo\.bats:[0-9]+:.*turkish-check'
  out=$(cd "$REPO" && git ls-files -z | xargs -0 grep -nIE "$letters" 2>/dev/null | grep -v 'Aydın Şentürk' | grep -vE "$self" || true)
  out2=$(cd "$REPO" && { git ls-files -z | xargs -0 grep -nIiE "$stems"; git ls-files -z | xargs -0 grep -nIiwE "$words"; } 2>/dev/null | grep -vE "$self" || true)
  [ -z "$out$out2" ] || { printf '%s\n%s\n' "$out" "$out2" | grep -v '^$' | cut -c1-120 | head -15; echo "files: $(printf '%s\n%s\n' "$out" "$out2" | cut -d: -f1 | sort -u | grep -v '^$' | wc -l)"; false; }
}
