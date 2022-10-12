# つくりかた
(いくらか決め打ちで作ってる部分がまあだあります。おそらく私の手元以外で動かないです)

1. つぶしてもいいgentoo環境imageをつくる。ext4 でフォーマットして、work/root0.8g に置く (8GiB推奨)
2. source host/firebox-host.sh する
3. run_emerge して環境をつくる
4. install_rinit して /init を生成
5. run_installer してファイルリストを作る
6. extract_touched_files してファイルを集める
7. configs/defconfig を使ってkernel build 
10. できた initrd と bzImage でブート
