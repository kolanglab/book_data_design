# さらに学ぶために

本書は入門書として、言語処理系に現れるデータ構造の「気持ち」をつかむことを
目標にしてきました。ここから先へ進みたい読者のために、テーマ別に道しるべを
示します。いずれも本書中で引用した、実在する文献です。

## 処理系づくりを通して学ぶ

手を動かして処理系を一つ作りきると、本書の各章がひとつにつながります。

- Nystrom, *Crafting Interpreters* [](#cite:nystrom2021) は、ツリーウォーク型
  インタプリタとバイトコード仮想機械の**両方**を、ゼロから作る過程を
  ていねいに解説します。第3章（構文木）・第8章（オブジェクト）・
  第4章（値表現）の話が、実装として一本につながります。Web 上で全文が
  公開されています。
- Abelson, Sussman, *Structure and Interpretation of Computer Programs*
  [](#cite:abelson1996) は、「評価器」を題材に、プログラムの意味とは何かを
  根本から問い直す古典です。第3章で触れた「環境のもとで式を評価する」
  という視点の源流です。

## コンパイラの理論と技法

字句解析・構文解析・最適化といった、処理系の前段を体系的に学ぶなら、

- Aho, Lam, Sethi, Ullman, *Compilers: Principles, Techniques, and Tools*
  [](#cite:aho2006)（通称 Dragon Book）が定番です。シンボルテーブル
  （第2章）の管理や、正規表現からオートマトンへの変換（第9章）も、
  ここで厳密に扱われています。

## データ構造とアルゴリズムの土台

本書で何度も顔を出した、ならし計算量・ハッシュ法・探索の理論的な背景は、

- Cormen, Leiserson, Rivest, Stein, *Introduction to Algorithms*
  [](#cite:cormen2009) が網羅的です。第6章の可変長配列のならし計算量、
  第7章の再ハッシュの分析がここにあります。
- Knuth, *The Art of Computer Programming, Vol. 3* [](#cite:knuth1998) は
  ソートと探索、とりわけハッシュ法の徹底的な分析で知られます。
  数値計算（多倍長整数など）は同 Vol. 2 [](#cite:knuth1997) が扱います。

これらに加えて、本書で参照した個別テーマの原典 —— ロープ [](#cite:boehm1995)、
スキップリスト [](#cite:pugh1990)、HAMT [](#cite:bagwell2001)、
インラインキャッシュ [](#cite:deutsch1984) とその多態版
[](#cite:holzle1991)、SELF のマップ [](#cite:chambers1989)、Ruby の
Object Shapes [](#cite:seaton2021) [](#cite:issroff2022)、浮動小数点数の
印字 [](#cite:steele1990)、正規表現とオートマトン [](#cite:thompson1968)
[](#cite:cox2007) —— は、いずれも短く読みやすいものが多く、一次資料に
あたる練習にも最適です。巻末の参考文献から、ぜひたどってみてください。
