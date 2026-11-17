# ImageMagick ARVO 漏洞数据集

本项目提供一套 ImageMagick 漏洞基线、63 个 PoC 和 61 个独立修复补丁，用于源码构建、漏洞复现和单补丁验证。基线是上游真实提交 `13ffeabe9abd6c262a8b6bfaeb1e145a420f8e3a`（2018-01-16，`7.0.7-21-82-g13ffeab`）。镜像保留该检出的 `.git` 历史；修复版在验证时复制源码、应用指定补丁后生成，不常驻第二棵源码树。

本文于 2026-11-16 按当前目录和脚本实现更新。文件大小与 SHA256 见 [MANIFEST.md](MANIFEST.md)。可复用的仓库命名、目录、数据格式与验收要求见 [漏洞数据仓库规约](SPECIFICATION.md)。本次在既有镜像内用更新后的脚本重跑了基线与逐补丁验证，`reports/` 是这批运行的结果；镜像本身没有重建。

## 1. 目录结构

```text
imagemagick-vul/
├── README.md
├── MANIFEST.md
├── image/Dockerfile           镜像构建定义
├── src/imagemagick/           本地源码副本
├── payload/
│   ├── cases.tsv              案例索引：63 条、8 列
│   ├── vulnerabilities.json   漏洞信息、源码片段和补丁路径
│   ├── patches/*.patch        61 份独立补丁
│   └── pocs/<localId>/poc     63 个输入文件
├── scripts/                  构建、复现与报告入口
└── reports/                  已有基线、单案例及逐补丁验证报告
```

当前目录未附 `imagemagick-vul.tar`、其校验文件或 `.dockerignore`。可以从 Dockerfile 构建镜像；离线 tar 需要另行导出。Docker 构建不复制本地 `src/`，但当前没有 `.dockerignore` 排除它，因此它仍可能进入构建上下文。

## 2. 构建与运行

需要启动支持 Linux 容器的 Docker，并能拉取指定基础镜像。以下命令在项目根目录执行（PowerShell 和 Bash 均可逐行运行）：

```bash
docker pull n132/arvo:42518038-vul@sha256:fce885bd28185e1f08512fad0085714b32526187f7041fb7941965e8fd8de124
docker build -f image/Dockerfile -t imagemagick-vul:13ffeab .
docker run -dit --name imvul --security-opt seccomp=unconfined imagemagick-vul:13ffeab
docker exec imvul /opt/imdt/build.sh
docker exec imvul /opt/imdt/verify.sh --report /tmp/baseline-report
docker exec imvul /opt/imdt/verify-one.sh 42518438 --report /tmp/one-before
docker exec imvul /opt/imdt/verify-one.sh 42518438 --patched --report /tmp/one-after
docker exec imvul /opt/imdt/verify-one-by-one.sh --report /tmp/patched-report
```

三个验证脚本都接受 `--tree DIR`，用于测试 `/src/imagemagick` 之外的另一份源码（默认取自 `$IMDT_TREE`，再默认 `/src/imagemagick`）；原始目录只读，`--patched` 只复制后再应用补丁。

MSan 的执行路径使用 `setarch x86_64 -R`，上述容器参数放开 seccomp 限制以支持它。镜像中的工具链来自 2018 年时期的 ARVO / OSS-Fuzz 环境，包括 Clang 6.0 和 MSan 插桩版 libc++。

导出测试报告：

```bash
docker cp imvul:/tmp/baseline-report/verify.json ./reports/verify.json
docker cp imvul:/tmp/patched-report/verify-one-by-one.json ./reports/verify-one-by-one.json
```

可选的离线镜像导出和加载：

```bash
docker save -o imagemagick-vul.tar imagemagick-vul:13ffeab
docker load -i imagemagick-vul.tar
```

构建成功后镜像保存在本机 Docker 中，不要求额外保留 tar。只有在基础镜像已缓存时，才可以不依赖远端拉取来重建。

## 3. Dockerfile 做什么

1. 使用 digest 固定的 `n132/arvo:42518038-vul` 基础镜像。
2. 复制 `payload/` 到 `/payload`、`scripts/` 到 `/opt/imdt`、`reports/` 到 `/opt/imdt/reports`。
3. 清理旧 fuzz 工具、旧输出和临时目录，把 `/src/imagemagick` 恢复到指定基线提交，检查日期和工作区。
4. 用 `ensure_repro` 编译 ASan、MSan 两个基线复现程序，保留 `/out` 产物，清空 `/work`。随包案例不使用 UBSan，`lib.sh` 仍接受 `undefined` 以便测试其他源码。
5. 断言源码、补丁、PoC、案例数和复现程序的布局。构建阶段不逐个运行 63 个 PoC。
6. 默认工作目录为 `/opt/imdt`，默认启动 `/bin/bash`。

```text
/src/imagemagick      基线源码与 .git
/payload             案例、PoC、补丁和漏洞信息
/opt/imdt            脚本及 hand_repro.cc；reports/ 中有随包报告
/out                 repro-<源码指纹>-<sanitizer>
/work                初始为空；运行时用于副本和构建
```

Dockerfile 开头注释中的构建示例漏写了 `-f image/Dockerfile`，应使用第 2 节命令。`utilities/magick -version` 与 `git describe` 的版本字符串可能不同，源码身份以固定提交为准。

## 4. scripts/ 的分工

| 文件 | 职责与产物 |
| --- | --- |
| `build.sh` | 普通编译指定目录，生成 `<DIR>/utilities/magick`，不加 sanitizer，不运行 PoC |
| `lib.sh` | 共用路径、sanitizer 配置、源码指纹、插桩编译 `ensure_repro` 和单次执行 `run_poc` |
| `verify-one.sh` | 查找一个案例，选择原始源码或补丁副本，编译/复用复现程序，运行 PoC，写单案例报告 |
| `verify.sh` | 遍历案例，调用不带 `--patched` 的 `verify-one.sh`，汇总基线报告 |
| `verify-one-by-one.sh` | 遍历案例，每次调用 `verify-one.sh --patched`，汇总各自补丁的验证报告 |
| `hand_repro.cc` | C++ 驱动：读取 PoC，指定 coder，调用 ImageMagick 读图并写回内存 |

```text
build.sh → configure + make（普通编译）
verify.sh → verify-one.sh --tree DIR
verify-one-by-one.sh → verify-one.sh --patched --tree DIR
verify-one.sh → lib.sh / ensure_repro → 插桩库 + hand_repro.cc
              → lib.sh / run_poc → 执行、判定
```

### 4.1 普通编译

```bash
build.sh [DIR]
```

默认目录 `/src/imagemagick`。没有 `Makefile` 才运行配置，然后执行 `make -j$(nproc)`。配置参数为 `--disable-shared --disable-docs --disable-openmp --without-perl`，不执行 `make install`。日志为 `/tmp/plain-configure.log` 和 `/tmp/plain-make.log`。

重复执行是增量编译；已有 `Makefile` 时沿用现有配置，不重新检查配置参数。此过程会在源码目录留下构建文件。PoC 验证使用另外编译的插桩程序，不使用这个 `utilities/magick`。

### 4.2 lib.sh：插桩编译与运行

`TREE` 默认 `/src/imagemagick`，可用环境变量 `IMDT_TREE` 或三个验证脚本的 `--tree DIR` 覆盖；`PAYLOAD`、`OUT`、`WORK` 分别默认 `/payload`、`/out`、`/work`。

`ensure_repro <srcdir> <address|undefined|memory>` 计算源码指纹，命中 `/out` 缓存则返回程序路径；否则复制源码（排除 `.git`）到 `/work/build-<fp>-<san>/src`，清理旧普通构建产物，执行配置、插桩编译、安装静态库和链接驱动。配置检测先使用普通参数，插桩在 make 阶段加入；MSan 额外链接 `/usr/msan/lib`。最后用 `nm` 检查 sanitizer 符号。

指纹是 `<提交前8位>-<sha256(git diff)前8位>`，干净基线为 `13ffeabe-e3b0c442`。它不包含已暂存修改、未跟踪文件、驱动内容或工具链配置；这些变化不能保证使缓存失效。自定义源码测试时应确保目标修改体现在普通 `git diff` 中，并处理不适用的缓存。

`run_poc` 设置对应运行时选项，调用 `<binary> <coder> <poc>`，依据第 5 节判定结果。非零退出且没有摘要时最多运行 10 次。ASan、UBSan、MSan 分开编译，缓存按源码指纹和 sanitizer 区分；随包案例只用到 ASan 与 MSan，镜像只预编译这两个。

### 4.3 单案例验证

```bash
verify-one.sh <pocId> [--patched] [--report DIR] [--keep] [--tree DIR]
```

从 `cases.tsv` 读取格式、sanitizer、PoC 和补丁路径。默认直接测试 `--tree` 指定（缺省 `$TREE`）的源码；`--patched` 则复制它到 `/work/one-<ID>`，通过 `git apply --check` 后应用该案例的单个补丁，再编译和测试。源目录本身只读，脚本不会改动它，也不会自动重置 `$TREE`，因此做基线验证前应保证其内容符合预期。

补丁测试默认清理源码副本及对应构建目录，`--keep` 保留它们；`/out` 中的程序缓存仍保留。默认报告为相对当前工作目录的 `reports/verify-one.json`，后续运行会覆盖。

### 4.4 两种批量验证

```bash
verify.sh [--report DIR] [--tree DIR]
verify-one-by-one.sh [--report DIR] [--tree DIR]
```

前者测试所有基线案例，后者每次从原始源码重新复制、只应用当前案例对应补丁，再运行当前 PoC。补丁不累计，也不对每个补丁运行其他全部 PoC。因此逐补丁报告不能证明“其他漏洞全部仍然存在”或补丁没有回归影响。

同一补丁可能对应多个案例；缓存复用以 `(源码指纹, sanitizer)` 为单位，不能简单保证只有 61 次编译。耗时取决于机器和缓存，旧文档的约 100 分钟仅是历史参考。当前命令不支持 `--no-build`。

### 4.5 手写驱动

`hand_repro.cc` 接收 coder 和 PoC 路径，将文件读入内存，以指定格式执行 `image.read` 和 `image.write`，输出仅留在内存。捕获的 `Magick::Exception` 正常返回，图像解析失败不自动算漏洞。文件读取或内存分配等失败返回 2。

驱动设置 ImageMagick 内存申请/资源限制；这不是操作系统对整个进程的内存硬上限。驱动不施加任何宽高限制：此前有 5 个案例只能靠 `Magick++/fuzz/utils.cc` 里的 `width(2048)`/`height(2048)` 才不崩溃，它们不是源码缺陷修复，已从数据集中移除。

驱动头部提到 `build-san.sh` 和旧产物路径是遗留注释，实际编译入口是 `lib.sh` 的 `ensure_repro`。

## 5. 结果、报告和退出码

`run_poc` 的原始分类如下：

| 分类 | 判据 |
| --- | --- |
| `CRASH` | 输出存在以 `SUMMARY: ` 开头的行 |
| `CLEAN` | 没有上述摘要，且退出码为 0 |
| `ERROR` | 没有摘要、非零退出，重试后仍无法确认 |

报告内每条记录的 `pass=true` 表示 CLEAN。顶层 `pass`、`fail` 是数量，不是布尔值。`alert` 来自案例表，不与实际摘要匹配；当前单案例及汇总 JSON 不保存真实 sanitizer 摘要。

| 命令/模式 | 报告名 | 正常基线上的预期统计 | 最后退出条件 |
| --- | --- | --- | --- |
| `verify.sh` | `verify.json` | `pass: 0, fail: 63`；终端 `clean=0 crash=63` | `clean == 0` |
| `verify-one.sh ID` | `verify-one.json` | `pass: 0, fail: 1`；条目 `pass=false` | 条目 `pass=false` |
| `verify-one.sh ID --patched` | `verify-one.json` | `pass: 1, fail: 0`；条目 `pass=true` | 条目 `pass=true` |
| `verify-one-by-one.sh` | `verify-one-by-one.json` | `pass: 63, fail: 0` | `fail == 0` |

前置步骤失败也可能导致脚本非零退出。基线模式成功退出表示符合“漏洞仍在”的预期，不表示漏洞被修复。

当前实现存在这些判定局限：

- `verify-one.sh` 将 ERROR 也转成 `pass=false` 并显示为 CRASH，所以基线单案例可能把无法确认的运行当成符合预期。
- `verify.sh` 忽略子脚本退出码，缺失 RESULT 也计入 crash。因此 `clean=0` 本身不能证明每条都确实产生 sanitizer 报告。
- 逐补丁批量脚本将缺失 RESULT 计为失败，但两个批量脚本都不校验处理数量；零条有效记录也可能成功退出。验收时必须同时核对案例数、日志和报告。
- CLEAN 只说明当前 PoC 在当前条件下正常退出且未出现指定摘要，不证明不存在其他漏洞，也不表示成功解码。

本次仅同步文档，没有修复上述脚本行为。

## 6. 数据与已有报告

`cases.tsv` 的列为 `localId coder sanitizer alert expect_frame poc patch fix_commit`。63 个案例关联 61 个唯一补丁，其中 `60cb93d0` 和 `78eaf41a` 各对应 2 条，其余 59 个补丁各对应 1 条。补丁按 fix commit 命名，内容可能经过适配，因此上游 `git show` 不能代替随包补丁文件。

`vulnerabilities.json` 包含 project、repo、baseline、paths 和 vulnerabilities；各漏洞提供 id、type、location、code_snippet、description 和 patch 路径。

当前随包报告是 2026-11-16 用本目录脚本在既有镜像上重跑的结果（`--tree /src/imagemagick`），记录如下；它们不包含运行日期、环境及实际摘要：

| 文件 | 顶层 pass | 顶层 fail | 结果数 |
| --- | --- | --- | --- |
| `reports/verify.json` | 0 | 63 | 63 |
| `reports/verify-one.json` | 0 | 1 | 1 |
| `reports/verify-one-by-one.json` | 63 | 0 | 63 |

Windows 上本地源码副本的可执行权限可能与 Linux 有差异。需要构建时优先使用镜像中的固定工具链和源码。文件清单描述当前磁盘内容；不沿用旧镜像 ID、tar 大小和未经本次确认的性能数据。

## 7. 漏洞分布

统计依据为 `payload/vulnerabilities.json` 与 `payload/cases.tsv`，统计单位是案例 ID，共 63 个案例、63 个 PoC、61 个唯一补丁。这里的案例数不等同于独立漏洞根因数；一个补丁可以对应多个案例。下列分布按当前基线统计，不按报告中的成功或失败次数统计。

### 7.1 按 CWE 类型

每个案例按元数据中的主 CWE 计一次；占比以 63 个案例为分母，四舍五入至一位小数（合计因舍入为 100.1%）。

| CWE | 类型 | 案例数 | 占比 |
| --- | --- | --- | --- |
| CWE-457 | Use of Uninitialized Variable | 43 | 68.3% |
| CWE-787 | Out-of-bounds Write | 10 | 15.9% |
| CWE-125 | Out-of-bounds Read | 8 | 12.7% |
| CWE-121 | Stack-based Buffer Overflow | 2 | 3.2% |
| 合计 | — | 63 | 100.0% |

### 7.2 按检测器

按案例表的 sanitizer 字段统计；检测器类别与 CWE 是两个维度，不能将二者相加。当前没有案例使用 UBSan，`lib.sh` 仍支持 `undefined`。

| 检测器 | 案例数 | 占比 |
| --- | --- | --- |
| `memory` | 43 | 68.3% |
| `address` | 20 | 31.7% |
| 合计 | 63 | 100.0% |

### 7.3 按源码模块

按 `location.file` 规范化掉开头的 `./` 后的首级目录统计，每个案例计一次。这是元数据记录位置的分布，不代表补丁修改文件或根因位置的分布。

| 模块 | 案例数 | 占比 |
| --- | --- | --- |
| `MagickCore` | 52 | 82.5% |
| `coders` | 11 | 17.5% |
| 合计 | 63 | 100.0% |

### 7.4 按输入格式

按案例表的 coder 原值统计，不合并不同格式标识。格式数量不等同于独立漏洞数量。

| coder | 案例数 |
| --- | --- |
| `MIFF` | 9 |
| `MVG` | 7 |
| `PDB` | 3 |
| `VIFF` | 3 |
| `WPG` | 3 |
| `DCM` | 2 |
| `EPS` | 2 |
| `EPSI` | 2 |
| `GIF` | 2 |
| `HDR` | 2 |
| `PALM` | 2 |
| `PCX` | 2 |
| `PICT` | 2 |
| `PSD` | 2 |
| `SUN` | 2 |
| `TXT` | 2 |
| `CIN` | 1 |
| `DPX` | 1 |
| `DXT5` | 1 |
| `MAC` | 1 |
| `MAT` | 1 |
| `PCDS` | 1 |
| `PES` | 1 |
| `PNM` | 1 |
| `PS` | 1 |
| `RLE` | 1 |
| `SCR` | 1 |
| `SIX` | 1 |
| `SIXEL` | 1 |
| `TIM` | 1 |
| `WBMP` | 1 |
| `XCF` | 1 |
| 合计 | 63 |

### 7.5 案例与补丁对应分布

| 每个补丁对应的案例数 | 补丁数 | 覆盖案例数 | 补丁提交前缀 |
| --- | --- | --- | --- |
| 1 | 59 | 59 | 其余补丁 |
| 2 | 2 | 4 | `60cb93d0`、`78eaf41a` |
| 合计 | 61 | 63 | — |

逐补丁报告仅测试各案例自己的 PoC，不证明补丁对其他所有案例的影响。

### 7.6 已移除的 5 个案例

`42518038`、`42518649`、`42518894`、`42519338`、`42519771` 连同补丁 `e8be814f` 一并移除。上游对该组的“修复”只改了 fuzz harness：在 `Magick++/fuzz/utils.cc` 里加 `ResourceLimits::width(2048)`/`height(2048)`，库代码一行未动，崩溃只因为超限输入在读取阶段被拒。它们不满足“单个补丁修掉源码缺陷”的契约，计入本数据集会得到假阳性结论。

其中 `42518038` 连内存安全缺陷都不成立：`MagickCore/compress.c:835` 的 `entry=MBTable+((runlength/64)-1)` 在 `runlength ≥ 1856` 时下标超出 `MBTable[28]`，但下一行的 `if (runlength >= 1792)` 会把 `entry` 换成 `EXTable`，越界指针从不被解引用——UBSan 报的是指针算术 UB，没有越界访问。这也是它不随 2048 上限消失的原因：宽度 1856–2048 的图像仍会触发同一处 UB。
