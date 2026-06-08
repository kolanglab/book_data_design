# さらに学ぶために

本書は入門書として、言語処理系に現れるデータ構造の「気持ち」をつかむことを
目標にしてきました。ここから先へ進みたい読者のために、テーマ別に道しるべを
示します。いずれも本書中で引用した、実在する文献です。

## 処理系づくりを通して学ぶ

手を動かして処理系を一つ作りきると、本書の各章がひとつにつながります。

- Nystrom, *Crafting Interpreters* [](#cite:nystrom2021) は、ツリーウォーク型
  インタプリタとバイトコード仮想機械の**両方**を、ゼロから作る過程を
  ていねいに解説します。構文木・値の表現・オブジェクトとクロージャ・GC の
  各章の話が、実装として一本につながります。Web 上で全文が公開されています。
- Abelson, Sussman, *Structure and Interpretation of Computer Programs*
  [](#cite:abelson1996) は、「評価器」を題材に、プログラムの意味とは何かを
  根本から問い直す古典です。環境のもとでの評価、ストリーム（遅延評価の章）の
  源流です。
- Aho, Lam, Sethi, Ullman, *Compilers: Principles, Techniques, and Tools*
  [](#cite:aho2006)（通称 Dragon Book）は、字句解析・構文解析・最適化を
  体系的に扱う定番です。シンボルテーブルの管理や正規表現からオートマトンへの
  変換も、ここで厳密に扱われています。

## データ構造とアルゴリズムの土台

- Cormen, Leiserson, Rivest, Stein, *Introduction to Algorithms*
  [](#cite:cormen2009) は、ならし計算量・ハッシュ法・木構造の理論的背景を
  網羅します。
- Knuth, *The Art of Computer Programming* は、ハッシュ法と探索が
  Vol. 3 [](#cite:knuth1998)、多倍長演算と乱数が Vol. 2
  [](#cite:knuth1997) です。
- Okasaki, *Purely Functional Data Structures* [](#cite:okasaki1998) は、
  不変・永続データ構造（リスト・キュー・木）と遅延評価によるならし解析の
  教科書です。第II部後半の世界観の理論的支柱です。

## メモリ管理と GC

- Jones, Hosking, Moss, *The Garbage Collection Handbook*
  [](#cite:jones2011) が現代 GC の決定版です。入門には Wilson の
  サーベイ [](#cite:wilson1992) も今なお有用です。
- 原典として、世代仮説の Ungar [](#cite:ungar1984)、コピー GC の
  Cheney [](#cite:cheney1970)、保守的 GC の Boehm-Weiser
  [](#cite:boehm1988)、CRuby の世代別化を論じた Sasada
  [](#cite:sasada2019) はいずれも読みやすい論文です。

## 動的言語の高速化

- 値の表現の整理は Gudeman [](#cite:gudeman1993)、JavaScript 各処理系の
  実態は Wingo の解説 [](#cite:wingo2011) と V8 公式ブログ
  [](#cite:bynens2017) [](#cite:v8pointer2020) が読みやすい資料です。
- インラインキャッシュの原典 Deutsch–Schiffman [](#cite:deutsch1984)、
  その多態版 PIC [](#cite:holzle1991)、マップ（シェイプ）の SELF
  [](#cite:chambers1989) は、現代 JIT の三大古典です。Ruby の Object
  Shapes は Seaton の講演 [](#cite:seaton2021) と提案チケット
  [](#cite:issroff2022) を参照。
- ハッシュ表の現代史は、CPython のコンパクト辞書 [](#cite:hettinger2012)、
  CRuby の改修 [](#cite:makarov2016)、SwissTable の講演
  [](#cite:kulukundis2017)、Go の移行記事 [](#cite:pratt2025) で
  追いかけられます。

## 個別テーマの原典

ロープ [](#cite:boehm1995)、スキップリスト [](#cite:pugh1990)、
赤黒木 [](#cite:guibas1978)、重み平衡木 [](#cite:adams1993)、
B木 [](#cite:bayer1972)、
HAMT [](#cite:bagwell2001)、フィンガーツリー [](#cite:hinze2006)、
簡潔データ構造の起点 [](#cite:jacobson1989) と実用的な教科書
[](#cite:navarro2016)、FM-index [](#cite:ferragina2000)、
浮動小数点数の印字 [](#cite:steele1990) [](#cite:loitsch2010)
[](#cite:adams2018)、SipHash [](#cite:aumasson2012)、
正規表現とオートマトン [](#cite:thompson1968) [](#cite:cox2007)
[](#cite:cox2009)、Lua の実装 [](#cite:ierusalimschy2005)、
遅延評価の実装（STG）[](#cite:peytonjones1992) と思想
[](#cite:hughes1989)、コレクションの格納戦略 [](#cite:bolz2013) ——
いずれも短く読みやすいものが多く、一次資料にあたる練習にも最適です。

## 個性派言語たち（第III部）の原典

- APL は Iverson の原著 [](#cite:iverson1962)、Prolog の WAM は
  Warren のテクニカルノート [](#cite:warren1983)。
- Smalltalk は「青本」こと Goldberg–Robson [](#cite:goldberg1983) が
  言語と実装の両方を扱う古典です。
- Tcl は Ousterhout の原著 [](#cite:ousterhout1994)、Icon は
  Griswold 夫妻の言語書 [](#cite:griswold1996)。Erlang/BEAM の内部は
  *The BEAM Book* [](#cite:stenman2024) が無償で読めます。

## 実物のソースコードへ

最後に、最良の教材は実物です。CRuby の `st.c`・`gc.c`・`shape.c`、
CPython の `dictobject.c`・`listobject.c`・`unicodeobject.c`
（PEP 393 [](#cite:pep393)、PEP 412 [](#cite:pep412) と併読）、
JVM の仕様書 [](#cite:lindholm2014)、Go・Rust の標準ライブラリ。
本書で見た構造たちが、コメント付きの生きたコードとして待っています。
