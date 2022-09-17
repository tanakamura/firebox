# つくりかた
(いくらか決め打ちで作ってる部分がまあだあります。おそらく私の手元以外で動かないです)

1. つぶしてもいいgentoo環境をつくる
2. そこへmount.shが動くように調整してchrootする
3. gen-installer.sh を動かしてfirefoxと依存パッケージをビルド
4. chroot ぬける
5. find-required-files-host.sh で再度chroot
6. その中でfind-required-files.shを動かす
7. chroot ぬける
8. geninitrd_root.sh
9. geninitrd_cpio.sh
