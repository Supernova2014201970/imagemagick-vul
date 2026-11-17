# 交付件清单

核对日期：2026-11-16。此清单依据当前磁盘内容生成；项目根目录的版本管理元数据 `.git/` 不计入交付清单。`src/` 单独汇总（目录名带 `-readonly` 后缀表示只读；不含 Git 元数据，按普通文件随仓库提交），其余文件逐项记录字节数与 SHA256。

## 1. 当前交付内容

| 项目 | 数量 | 字节数 |
| --- | --- | --- |
| 源码副本 `src/imagemagick-readonly/` | 2415 个文件 | 51284306 |
| 修复补丁 | 61 个文件 | 80558 |
| PoC 输入 | 63 个文件 | 696868 |
| 有效案例索引 | 63 条 | 见下方 cases.tsv |

当前目录没有镜像 tar、tar 校验文件或 `.dockerignore`。旧版 tar 的大小、哈希、镜像 ID 及运行耗时不代表当前目录，本清单不再沿用。源码身份、构建命令、脚本职责、结果判据与已知局限见 [README.md](README.md)。

## 2. 文件校验

下表覆盖源码目录和根目录 Git 元数据之外的全部现有文件。README 的校验值按本次更新后的内容计算；MANIFEST 自身排除哈希以避免自引用。报告重新生成或其他文件改变后，需要同步更新清单。

| 文件 | 字节 | SHA256 |
| --- | --- | --- |
| `image/Dockerfile` | 4133 | `6ecd0cd92d5b4b62a327baa1dd59a856aad4a6a31928708b8de292bb4334dae9` |
| `payload/cases.tsv` | 12193 | `328b5cf70704eb5a94e933d356c2ce87469222427e7d92f08d1f41ad9bd39a11` |
| `payload/patches/008465f1b8eb05752f8482e9cc2a073f0e978f09.patch` | 14046 | `5f529072eafa4758a2d0f3ca54717fe55b6e646f4ef541dfa3ed51a8afb37dc5` |
| `payload/patches/0100b8013536d7836566642d69d521fba1d15cf6.patch` | 485 | `9bf61a77f0075d8e8e87811e9f4b0e4d7ff42a507421e0c9c6dca5b78b92560a` |
| `payload/patches/02eee091d2023d91d15d271ac9e6fe049a6e4c5f.patch` | 699 | `ab37acee28b099bc884d15bdaa602b5de310147779b00f950151d25ea07b9b28` |
| `payload/patches/07e656c7089f3b3ae30a71a042fb903c83e077b6.patch` | 632 | `af87c86336b00bd482b7b78cbd9b6fed9d07069c732429247136fa6b7f762862` |
| `payload/patches/0897510362611886bfe296f8ab5d9aa1f82558cf.patch` | 678 | `f5dd0809a73fa437a3ee78c81ec6f72e47919f34e7419b239999bb236bdc13a8` |
| `payload/patches/11c7f47df7cbe2e672c8a975aa1c003d92f4fdc9.patch` | 436 | `7eead17d35f04a66d3bfa56f485d4a47313def0b41aba6847c97f99371ff42f7` |
| `payload/patches/147814adf1c657f647ee7e73027dbedde5ac2467.patch` | 548 | `da9114ab381e25b26fc857b2a39c6eca335f87303098cfc0d1477d0a56a617e1` |
| `payload/patches/164af31c8d4d5afd0a5a6a7e27078b5d579adc56.patch` | 670 | `ed2b540bb04e78e9382afd9a8ac4c5845577698c0d44899b6efa9a60b14e40cb` |
| `payload/patches/169a3ff38425613b156015c23056c4adf0dbf221.patch` | 446 | `3b954fec6caac0bf49672fa68d8d407bf262bd6a8f7c25abfdb7e62663c7b1bb` |
| `payload/patches/1f55115e43f7276a6d91bd4408dd4a6ef45d6be5.patch` | 2120 | `31faf2f40bccb77432a230639644d46b5bb1f3236f54b7ecab9357c4975c920f` |
| `payload/patches/21baa90e1854413d109512c3cda5242511e5a14a.patch` | 418 | `bcadfa744d59bf0639c9776d1bb5ce2b90d0c9588f2927345017ee297ba95397` |
| `payload/patches/21e1ac88739dbf99be45782de0dc299b162fcdf5.patch` | 424 | `ac607a96608972ca843e066b2367444ffd1a78f05962aeccdf6ebb652d495263` |
| `payload/patches/23246df8dfdebe0002bf9abfa0a5490238300ad9.patch` | 485 | `499a35ccf37a20fc11255752509c6ba2a36db842f41caa2e29f9193889c84bae` |
| `payload/patches/2cf74b529c34f2e5915c946e2f4a06f4c292f4c8.patch` | 4081 | `2fb6c7f87822fe9f51bea248d519c8456d16cb89b7715d6504d9809b83c2fb9c` |
| `payload/patches/2ebcbdbaee0a9bdfa0f11f9b47774668537ea709.patch` | 586 | `d44a9dd07f54b142e3a9426ca00c21f55acf6961d7a72c87cb799f43d84021b5` |
| `payload/patches/391d3afd588b94f9ee2c5e4a70f5e9197e5afb21.patch` | 6951 | `c7f673daa38b8e04ca87816ffa47b053a9394b828ae033b9201801f6f586d25e` |
| `payload/patches/3b30dbea8817d45471ec132014a3bc44e05fdf97.patch` | 1245 | `f6203649d96e5241e6e3564b72ba2c8c7756427e79227e7621c4a53b0c6951cf` |
| `payload/patches/3c8e8dbc5f8f617fa902cffaa90368beb96fd8a4.patch` | 625 | `292601ea865975293639f87413c419a30814117565250624a75e2df29662ac7f` |
| `payload/patches/3c96caf391336735dd15331267694d52a6d3ecd1.patch` | 633 | `d7bd9c23e4bb55944dd2282e688386ebf530783c28c600fb57ce21260cf65ec0` |
| `payload/patches/4435dbb1f398e3bf4ab1c1f8905d42b7701a7cca.patch` | 451 | `78a53994141b07c922cda39850358b306710bfffaf8427faf88ebdd72e777eb0` |
| `payload/patches/487f950075ae21b4634a04cb28c2f47f95d62963.patch` | 509 | `9373919fd18081fbaa625ca001c7d6dd97cbe3da45dc423885941942ecf95a56` |
| `payload/patches/4fc95b7c4291ec9216929c525cc3e6ed55b39149.patch` | 478 | `4dc09fbfdd48fd0234d0a18bd1001880bf474e6b7273cd17e95b1a08bde838f5` |
| `payload/patches/557cb22f90e3543cca8414a1dfa074e0e026e4c3.patch` | 775 | `f4787a3793f6937346a81026756eacf490efb449f690a77b32f6baa146dcabac` |
| `payload/patches/56a19e7ae07f40299f3afd4994d690f2c9b81993.patch` | 844 | `08c5e18dbf58089ebf89ee68b5dae0c10a760dfd5814f0882ab18e40e521b1bf` |
| `payload/patches/5960b92b652b51cc53852e7ba3c9b65abceb0452.patch` | 665 | `393bffbe546f5b884e27490721239edc49c49525eae580a13edc366b44c4c600` |
| `payload/patches/5f68b29b843b3c57f61b34e1db8f3144af458614.patch` | 456 | `6bb33c885fc498aa0e30319af80a468f72436eb0140051090173820a1bdfd651` |
| `payload/patches/60cb93d03a9fec83087f803fab877293f1ca12fd.patch` | 593 | `4d237f04fc766855d37c44bfce24446884b1e745620ff2a044420e2bbfcb3cce` |
| `payload/patches/614d7b140cd03a0d38f76ae55a7fcb2c9d76012a.patch` | 2273 | `20b20e886f2e423d0ffbbfe4d3586657e1a1776e196f1617a6e074d403c6cffb` |
| `payload/patches/686c45509c81d3ecae9cdb34225689b3be97de55.patch` | 515 | `2509da9a79a1f35e177b597388eed9b7f7c4dcf73ab7a52ccfb108d7b7e2721c` |
| `payload/patches/6d4a20030385c8e42f7a3fa89c84556b5fc896d7.patch` | 532 | `56201dfa2778ce92a4a59e3860248187ebf45edc1635561879c4181ceba5c2b6` |
| `payload/patches/6f7924965f38eeaa43901d6c7b3d7a9157ccd1e1.patch` | 581 | `a78ffeff1961ddafeaadfebafddac393a505db4fc633d41684f1fed66213fb07` |
| `payload/patches/73aad72d1d28170b38014168f523d0ee2941c21e.patch` | 831 | `93587121351d52dc42879db8629150cd6813d7a3eb276b34fb8a87cdefb79004` |
| `payload/patches/73c6cc1f8da1d7f3647056f293c5a10da019c9b7.patch` | 1121 | `7def3acfdf8cd9f49a7f8b33d8de6d11d93f654df060c72cbe2b3cfc7672bf21` |
| `payload/patches/771e54d106ce5ff043e7812b4182f3c08a748001.patch` | 902 | `729d8a7e25d82e0daaac9e43c68c9c42d61177c0d6c4715c154511a707519b60` |
| `payload/patches/78eaf41a792bb35a8b9e7ac4f72d86a8cb7d6d0a.patch` | 1446 | `8916fb8fb8ce597e8cd103a79faa8314128816354ec6ee74d8b11b3c303f757f` |
| `payload/patches/79de802e7586ab4339b7b81e3d3501d5fcffd57a.patch` | 855 | `a88af0b3fe45f42c788694b97aba93b968cae39aee6a58f2ec9a8451134170eb` |
| `payload/patches/79ef217ff11ad37e45946bb17ab1d4f3311066c7.patch` | 885 | `b72ffff80dfc31dc7059c35dd37ed2a58145833232b74d3c0436c91a6a5cddd9` |
| `payload/patches/7a03766efc1f45cf13cbd435902d86c3f321368e.patch` | 633 | `293c18ccde64f987f2b3474a0c27dbaf85e5872d1d1e9233e7d8c63f848c7428` |
| `payload/patches/7a98246a075d55f2eb5bad40028a28f3cfdd97c1.patch` | 2094 | `641bee448b252705b3867d81015187c3f83ab7ae1dab562157713e78edf3441f` |
| `payload/patches/820e6361927e3bfa346ce085311d001681863a23.patch` | 460 | `c4d9b9c9a8b88b8dc61c0abeb580f1ef5b59b2efe5b09185256ee76fa0fe6e4d` |
| `payload/patches/8239e79ee4c8cc34034838eefe4f34bab02c5fc7.patch` | 633 | `5344a9c44773e23ed635650cc7043f0415203d8324418049436b74f5aa699e3b` |
| `payload/patches/82c58c138e2ffc1f170db711b07627ee621c2a22.patch` | 659 | `01158ff05363c99a46b24666446c9f72add788209f8f2ae17c77c66a035281d0` |
| `payload/patches/8bb46b3381f8440fbf90bd88e1909dc83e089790.patch` | 488 | `92de369b3af2e2d858e908cc27ec135834158dd848a005e9d9525bf92e2b90eb` |
| `payload/patches/8e5432bdc67c377c620f5d8d3dedfb62854f567c.patch` | 448 | `4a0d91522d51455a7436ffd5eb55dba3be3e980be991f2f199efa5d333ff587a` |
| `payload/patches/990431dbe7688861ad46a7b8d6cb9d173b429cbd.patch` | 4091 | `8037871ab3bbe9f47347f9cd31ae53f89caf26f42c2f5a8d3ac7ac3b565e65c6` |
| `payload/patches/9998cd719775e90f9989fd1ecaa84647a56c1b57.patch` | 688 | `7f72d671b5f18ac7b3b9b1f555374f81065982f7e8fd2cba8d0b03b33c77fa1c` |
| `payload/patches/9e74769caca25bc62707772ef15de9a510609bf2.patch` | 474 | `f2e0fb02c4a97f8ed38625cbd43c5793eeb0ab146208e732eca8b36aa30b6d5b` |
| `payload/patches/a5136e6c737e76e613da9241d7ecb273d84787d0.patch` | 553 | `6b38a356eebbaf36359ff867dd7140aa25fb84c8224ddb085b57455c0d0a4fbc` |
| `payload/patches/a85ab26099152be3dab0bd377670abfc815b9fe7.patch` | 368 | `0470a8812af0fff65d582cbd72989abd8ae833fa367a029c66c9502d0b004fe2` |
| `payload/patches/af223b025da2ffb56a4e50160448e845f9b5e186.patch` | 557 | `98e9ab40f244df233d741b4829d6250d6abe714697c6527dbb51ece6c1da6d19` |
| `payload/patches/b78a613f16150d6db3b055731211f467756bc412.patch` | 546 | `e432fe54aa6ba76d958c6991a09089a20b3e558847f1586b69f5265048b08bc5` |
| `payload/patches/ba9e36555434ebe9da38a1341cfd9f304a326348.patch` | 6227 | `b3fd5ca874c6a71793eaa22ae285770aa002b772e9038dd5b131591bb1987963` |
| `payload/patches/bb4e7e8919573caf70bd5af3330e991ddbad0c92.patch` | 878 | `b4bac99bf042b07d541a20ea94e58bea1280449fa540154e4557506abc8b36c7` |
| `payload/patches/bf04de5d0e66f630dd0c184b478a299854f2d032.patch` | 887 | `71034fcb7232d90a47ed163fc1a2c5df1184ae7691b597a83ba08bf29006c4d9` |
| `payload/patches/c9a75ec387eb3c1f3c9584b97260d72512868b1b.patch` | 427 | `458839e0e4c1eac5becbd85c548542e7a3d3a97c8718a753490e4c3ba96cb368` |
| `payload/patches/ce433f8048b120b2a0413b4ac3ef59fca35a9788.patch` | 450 | `afdd165b9081fe803d2ce5db66d05d9350bdec8121225d099eff4ce7f075364f` |
| `payload/patches/e79350c54735fd1051bd0b153ef277a13a7b9618.patch` | 2004 | `9ddd28afa3cddb87bf2d41cde62037dc725096fa747cc2ebfa0fe816266b182a` |
| `payload/patches/ecd8728428d460b13821cc8e80aef671011329c7.patch` | 518 | `4754dd5954b27ee0ee73d914c48b1e4ab019079cf881edb2dc56ed1e2bb08a1e` |
| `payload/patches/f472c0ae74c136284adbbcfe25f628be2da8a02b.patch` | 4170 | `79b49d0c082f9ff87d80c62bd2d9a3dfb2f74b98d36f3b8b65954ae65db48aac` |
| `payload/patches/fda26c312b8d99e0cfaa82233741946c1206de81.patch` | 610 | `a8e7858f912183c03f4f8285b27e40ba3bb7338f3d8a97c35970724c249a7b81` |
| `payload/patches/ff0cea4290cb1421cb174f2f26ca03789377a6fb.patch` | 775 | `51dadedbf0c7909e1859d3cdf2bdce568d2ab16e46a504663af5ed4d55e4f1f4` |
| `payload/pocs/42518438/poc` | 1028 | `7cf8460742c9666b329cd71e4b944e73074b1a8869608c87dc0bc3c541fb05c1` |
| `payload/pocs/42518471/poc` | 13 | `61bd54c30bc8b0b6e5f8457676af965c41eaf54fc31e67444d33e5904ae035dc` |
| `payload/pocs/42518560/poc` | 43 | `d4406c320a09998edba683670d3f7c236978f57ce7ca00f722eb12af403d87b3` |
| `payload/pocs/42519182/poc` | 655416 | `41e65256a52649ae9e4cf2c0b7e6487470e2ef7276019b721dbbfa02707128f8` |
| `payload/pocs/42519416/poc` | 276 | `881f7fd0c44e237d8125f9ae545ff92a66e119df29af18f74b77293d415a71b5` |
| `payload/pocs/42519504/poc` | 54 | `8cffc42cc41664806f35ae8c00bfcba560a98569c6b25ca7b73716c04579b422` |
| `payload/pocs/42519749/poc` | 15 | `b5f168d74a22d17d06416f9de6abb08a9b21b32d616e95977b863d364d324dad` |
| `payload/pocs/42519760/poc` | 9060 | `827f29ca11ccc83f54646e627bdcca34396bbe29805dda69d8a31e701f2d4215` |
| `payload/pocs/42519915/poc` | 15 | `ddecec5a87903bdb71d448e0f7a736a8665f401098f24865bd2cac87140c6cc4` |
| `payload/pocs/42520316/poc` | 69 | `3a467251816c1e9b7ad330117cf2a0624ae605d3344e485fa7c66bf913185cd9` |
| `payload/pocs/42520493/poc` | 192 | `61767618c111520a2850864a14f2dbede1c2a3c54cb25c3fc4b329e3fc4e385f` |
| `payload/pocs/42520871/poc` | 34 | `7dd3e2d191d36fab3eb8de7c42e4d94b5d478cbb56f93653aa827b6b0e06210b` |
| `payload/pocs/42520948/poc` | 130 | `3ce6c44797659d43fdd5b468eff0be1c2f9e94fb2a15755c22e3465d9754de50` |
| `payload/pocs/42520971/poc` | 32 | `85e7eac2862f1cbd85bc18769c75172c3fdcd899ab468b9e973d59ec620d9991` |
| `payload/pocs/42521159/poc` | 42 | `bc40f3b08e7e089397f970758a4a7b7a51ec660865fdbc8ae43f419484facbf6` |
| `payload/pocs/42521170/poc` | 25 | `864d1307459d326a237a562ea40e50acefbfc02bdbe82fee96d3b3f31fa7dd11` |
| `payload/pocs/42521270/poc` | 146 | `b16e881f2fb1331ca0fe7529f44665ed0300ca3719512cc4beed3b6731914faf` |
| `payload/pocs/42521591/poc` | 20 | `50c678c0dc395c1f38887897c79bccb0e9ba7435bc9d52ec7692ce9589836bbe` |
| `payload/pocs/42521846/poc` | 922 | `861104eaec1c098f5d89176c15466cbdba367a6cee6cc3d9183322056bf8ddbd` |
| `payload/pocs/42521858/poc` | 14 | `d98cb6cb13afb3d7e106ad3879984ba6c621d6eeda7512f1d5425ff7976c1cd2` |
| `payload/pocs/42521880/poc` | 1031 | `a38a2ce6209acc9781874d20e0b50cd30bb65c453313157210ff58da2f8c7e0b` |
| `payload/pocs/42522269/poc` | 1 | `6e340b9cffb37a989ca544e6bb780a2c78901d3fb33738768511a30617afa01d` |
| `payload/pocs/42522303/poc` | 30 | `ce0fbe737d0c4f26ddebeebb0d69514e172d8ee5ca02b272fae5bcd424c580bc` |
| `payload/pocs/42522513/poc` | 54 | `e95394bd1ce615160448acf2fd7198c150d9147aff2c9836498283fca80f0305` |
| `payload/pocs/42522869/poc` | 26 | `952ef150d24256097c525ab1db429229ff50ad3f8d508eb71749856fa4b88206` |
| `payload/pocs/42523358/poc` | 124 | `59e5e7fe5b2c8f359cd3ecb9075f5ed1ea95916b0f73fa0061d41a554dbb008f` |
| `payload/pocs/42523502/poc` | 1024 | `02553b9e6b3306e018c207f09dd3fc31daeff62bf163716dff8ab856f6c13710` |
| `payload/pocs/42523812/poc` | 1408 | `415462394d68ce422e86bce3850cf23a59dfb61d5d1b7abfad727291535d639d` |
| `payload/pocs/42523868/poc` | 180 | `1e134f4159000db03971bd87a16480c8d1df2627d2c04fb94b62f72b607101fa` |
| `payload/pocs/42523879/poc` | 281 | `eb188c4d45fcabb3b776d7997b4b2f5ec43c113b3447d1aa1ec16e0340145d8f` |
| `payload/pocs/42524289/poc` | 35 | `627e811f50436fa94f2efa0913bb31e97b02ca65cd93eef3acd5a771d4031815` |
| `payload/pocs/42524701/poc` | 157 | `bb894add54be5c578e52bd0c3b018a5440f084cb3c2c07bf53302d7a7f4eaaed` |
| `payload/pocs/42525613/poc` | 96 | `f91c066c99ca6b6cf08722a3fbfdb791799fc83c2712fb4cc0d7020b92acc092` |
| `payload/pocs/42525647/poc` | 14 | `50ac6c23a09037a5f021d418a823ae768bae00e8b2ccb62604c0ecbf1411d3f2` |
| `payload/pocs/42525669/poc` | 18 | `323068740e02c8063149c29670f204e44ac38ab07044c9b8b943432e2fe749e0` |
| `payload/pocs/42525880/poc` | 5124 | `2340f454f5a74ad6cc42d7dd473edef809b20dcad6ba714ec6573cb62b5ceda0` |
| `payload/pocs/42526335/poc` | 103 | `4f9cadd2aecc626785e7c92b089b946a2b563fcaed058be71a9508f5db9d4a3f` |
| `payload/pocs/42526424/poc` | 101 | `129b5284e827f67f906720ec375064e9d0cab26c34a492de2403a86be62b70ce` |
| `payload/pocs/42526757/poc` | 297 | `d6275a7b247673e7bd4e4c2f14573d74e2d1c7c74ae49e3cecc772e42d47281c` |
| `payload/pocs/42527322/poc` | 95 | `f3cf58dac3046fee315236068e6c1413009a6fc705bc8cc6f5be2f4ce75df94b` |
| `payload/pocs/42527699/poc` | 185 | `b310217519fad9439b9a0986e31c5dda802f23e71b8a9bb83a03d95df311c97b` |
| `payload/pocs/42527789/poc` | 4140 | `d29e9d4338a0e05bce1622c6f24725554fe125ae07a2794205d3c72e3cfc4bcf` |
| `payload/pocs/42528177/poc` | 4108 | `33c1f4a8e73cc7e11b6d190b18b2dacfc16b7279de2c03464ae09b285b0a8da0` |
| `payload/pocs/42528200/poc` | 130 | `bfaaeb82715113616e2f8aa5cd53cb9b3cb56b21d5a5b5611acc8f051400e340` |
| `payload/pocs/42528610/poc` | 74 | `d6f888d98a9be771809f23b45d325c227b1b823ac1f96ff15bfcc6af54faedaa` |
| `payload/pocs/42529799/poc` | 81 | `5c2688bab71f1b8c0e7352f93909b96347e6c83fb46e2ab0cbabd4324cd55950` |
| `payload/pocs/42530943/poc` | 59 | `379623c12815df1fcda00ab7b27eb9fcbb5e04c911487a797ee62babc5bc8023` |
| `payload/pocs/42530977/poc` | 34 | `9f4a70bfaba4815691c17ced1f9e8c2dc4cf10fc9a8ede18679e5004bff10f3e` |
| `payload/pocs/42531054/poc` | 64 | `d479fa454dcd4eaf88a46d6cca7d10637ee1deed343b42e1dd6d822b040cc159` |
| `payload/pocs/42531466/poc` | 132 | `d6b3abcff45d52ab4f2cd687c525542fbf1bec9efafce368c20624dd90fbe10a` |
| `payload/pocs/42532777/poc` | 1 | `36a9e7f1c95b82ffb99743e0c5c4ce95d83c9a430aac59f84ef3cbfab6145068` |
| `payload/pocs/42533154/poc` | 1024 | `1f2dda93695b030b431827e984236dc82c16e1e60b000572a6b2c0c4599f8a5d` |
| `payload/pocs/42533821/poc` | 1490 | `eb0eea6fcb0299166e28a17416915f5f1140b07f6dc1545ebd70b894e303918d` |
| `payload/pocs/42533954/poc` | 6144 | `b161618e9d6f793f9c9e5eb268d5aac35d42907bcf7d7f9071acba2cb625fe7d` |
| `payload/pocs/42533966/poc` | 640 | `6c5e43486b8461889c0600768073e9632b0762ff1a3ec8f093df4495d2d3d719` |
| `payload/pocs/42534188/poc` | 31 | `3b16c1136c8eacd0c61138ce43ac1790418975f0a18a127846c427d74e361f1b` |
| `payload/pocs/42534522/poc` | 66 | `a3efffdab7e4d87d56dbceb9775fcb95bd3fb815fdbb7e203739c206632cfb9e` |
| `payload/pocs/42534621/poc` | 314 | `0c84f66ea2e57898238099c120c4a6c656a2d1487bb3beec2e62ee5a359a1476` |
| `payload/pocs/42534921/poc` | 59 | `2e6c165a078e4f4acf2df3fa6dec1b4e5d1a9dd21a5437cb38f750d2424cb6c1` |
| `payload/pocs/42535088/poc` | 68 | `a0247d74eaf2ea2f2a941426224268f826b255440b71714bc3cdfa016d4026ac` |
| `payload/pocs/42535232/poc` | 18 | `619860351263b9dc7949571cbd771fd47bc98622e124218dd78ef9834d237cec` |
| `payload/pocs/42535688/poc` | 164 | `59d72c5bfe0d53814257e31b6ee6201571338b253418e8632000924afc66109e` |
| `payload/pocs/42537011/poc` | 97 | `01215294ed857c185b370958fb78f21be3515bc125dde81fbdd824b50a119312` |
| `payload/vulnerabilities.json` | 71520 | `ee117b4edb99c7d29f77cb595a7ea3cf25832604634cc12e248750819653b1ab` |
| `README.md` | 16403 | `a746ce25694cbb251b9aada4187d0f06f0ace152367494d044c67b8d6f4a501f` |
| `SPECIFICATION.md` | 9788 | `6a9815099aad6bbc8f7d90e6dd51d4d5f7551c18a682c3f0a07197d3a77d9d38` |
| `reports/verify-one-by-one.json` | 8564 | `2d990e36b7f9a91b895dc0ee753afb35499514d4c1b20a175e7c125abef12273` |
| `reports/verify-one.json` | 116 | `a545298ed997051b1ff1b34d6e8f8c1f2a6dbb5d0e0e9decb2abafe96d893e15` |
| `reports/verify.json` | 4910 | `ac9a6bfe2adba6a58103445b93a175084901975593e65c468891c52726179506` |
| `scripts/build.sh` | 1228 | `b56a6e76948f9a1f7ff9d6535d7a5ebae160c668858d3612d385327bc55e6fe7` |
| `scripts/hand_repro.cc` | 2807 | `bcf7c2a0b4997a9549327c7881e791f66fd113eb1beb14d8f5c4d28b2914e653` |
| `scripts/lib.sh` | 7983 | `04272e99f086971835c32cf72ac68f87d00655da022ebf8af68950ecd974204c` |
| `scripts/verify-one-by-one.sh` | 2227 | `ce61088cb2088e577dc5c792f3148601c4f5c7e7e42820b4bc5e9f6dbec15ec9` |
| `scripts/verify-one.sh` | 3207 | `b7379e5d61b055a948b1ae64705f04cf61635e3f65655edd0e9361fe5c238376` |
| `scripts/verify.sh` | 2297 | `baacfd7bc15cee3a0454ed5026e066a272806e97ac91e60f51bbe9e8ad959a8d` |

## 3. 校验方法

在项目目录下，用 PowerShell 检查指定文件并与表格比对：

```powershell
Get-FileHash -Algorithm SHA256 -LiteralPath .\README.md
Get-ChildItem .\scripts -File | Get-FileHash -Algorithm SHA256
Get-ChildItem .\payload\patches -File -Filter *.patch | Measure-Object
Get-ChildItem .\payload\pocs -Recurse -File -Filter poc | Measure-Object
```

Linux 下可执行 `sha256sum README.md scripts/* reports/* image/Dockerfile`；其余文件按表中路径逐项检查。本表的 SHA256 是对文件原始字节计算，换行符变化也会改变结果。

## 4. 已有报告与本次核对范围

| 报告 | pass 数 | fail 数 | results 数 |
| --- | --- | --- | --- |
| `reports/verify.json` | 0 | 63 | 63 |
| `reports/verify-one.json` | 0 | 1 | 1 |
| `reports/verify-one-by-one.json` | 63 | 0 | 63 |

本次核对了案例数量、PoC/补丁引用路径、报告 JSON 统计和文件校验值。报告是 2026-11-16 在既有镜像内用本目录脚本对 `/src/imagemagick` 重跑得到的：基线 63 条全部崩溃，逐补丁 63 条全部不再崩溃。镜像没有重建。当前基线验证会混淆 ERROR 与 CRASH，且批量脚本不检查案例总数，详见 README 第 5 节。

## 5. 镜像交付布局

Dockerfile 的目标是保留 `/src/imagemagick` 的真实基线检出与历史，将 payload、scripts、reports 复制进去，并预编译 ASan、MSan 两个复现程序（随包案例不使用 UBSan）。构建时检查 61 个补丁、63 个 PoC、63 条案例、两个可执行程序和空的 `/work`，不运行完整 PoC 集。

`verify-one-by-one.sh` 每次仅应用当前案例的补丁并测试当前 PoC；报告不证明其他 PoC 在该补丁下的结果。缓存按 `(源码指纹, sanitizer)` 区分，源码指纹使用提交 ID 和普通 `git diff`，不包含已暂存及未跟踪的修改。三个验证脚本都可用 `--tree DIR` 指向其他源码目录。
