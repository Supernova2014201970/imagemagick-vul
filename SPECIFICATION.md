# 漏洞数据仓库规约

参考实例：`imagemagick-vul`

## 1. 仓库命名与基本原则

仓库名采用 `<project>-vul`，例如 `imagemagick-vul`、`libpng-vul`、`libxml2-vul`。

- 必须使用小写字母、数字和连字符，project 与元数据中的项目标识一致。

## 2. 标准目录

```text
<project>-vul/
├── README.md
├── MANIFEST.md
├── image/
│   └── Dockerfile
├── src/
│   └── <project>-readonly/
├── payload/
│   ├── vulnerabilities.json
│   ├── patches/
│   │   └── <fix_commit>.patch
│   └── pocs/
│       └── <case_id>/
│           └── poc
├── scripts/
│   ├── lib.sh
│   ├── build.sh
│   ├── verify-one.sh
│   ├── verify.sh
│   └── verify-one-by-one.sh
└── reports/
    ├── verify.json
    ├── verify-one.json
    └── verify-one-by-one.json

```

| 路径 | 要求与用途 |
| --- | --- |
| `README.md` | 必须，使用说明、环境条件和接口契约 |
| `MANIFEST.md` | 必须，文件清单、大小和校验值 |
| `image/Dockerfile` | 必须，定义可重建运行环境 |
| `src/<project>-readonly/` | 必须，只读的基线源码副本 |
| `payload/` | 必须，机器可读的案例、漏洞信息、PoC 和补丁 |
| `scripts/` | 必须，构建与验证入口 |
| `reports/` | 必须，发布前结果、日志及运行环境信息 |

`payload/cases.tsv`（案例索引）与 `scripts/hand_repro.cc`（复现驱动）是本包针对 ImageMagick 的实现，**不属于通用要求**：其他漏洞仓按自身的构建与复现方式组织，可以没有这两个文件，也可以用别的形式承载同样的信息。


## 3. 基线源码格式

`src/<project>-readonly/` 必须对应 `baseline.commit`，该字段使用完整提交 ID。

- 必须包含构建所需源码、配置文件及必要资源。
- 目录名以 `-readonly` 结尾，表示该副本只读：不得在其中构建、打补丁或修改文件。目录名是约定，不在文件系统上强制权限；需要构建或应用补丁时应复制出去再操作。
- 该副本不含 `.git`，作为普通文件随仓库提交，不用子模块（gitlink）记录；基线身份由 `baseline.commit`、`describe` 和 MANIFEST 的 `src/` 统计确定。
- 发布前必须保持基线工作区干净，不混入普通或插桩构建产物。
- 本地源码与镜像中基线的已跟踪文件内容必须一致；
- README、漏洞元数据和 Dockerfile 中的基线身份必须一致。


## 4. 漏洞元数据 vulnerabilities.json

顶层格式：

```json
{
  "project": "imagemagick",
  "repo": "https://github.com/imagemagick/imagemagick",
  "baseline": {
    "commit": "13ffeabe9abd6c262a8b6bfaeb1e145a420f8e3a",
    "describe": "7.0.7-21-82-g13ffeab",
    "date": "2018-01-16",
    "note": "基线说明"
  },
  "paths": {
    "cases": "cases.tsv",
    "pocs": "pocs/<localId>/poc",
    "patches": "patches/<fix_commit>.patch"
  },
  "vulnerabilities": []
}
```

每个漏洞案例的格式如下。示例中的通用路径和代码片段仅说明字段结构：

```json
{
  "id": "42518438",
  "type": {
    "crash_type": "Heap-buffer-overflow READ 1",
    "cwe": "CWE-125",
    "cwe_name": "Out-of-bounds Read"
  },
  "location": {
    "file": "源码相对路径",
    "line": 100,
    "function": "函数名",
    "stack": [
      {"function": "函数名", "file": "源码相对路径"},
      {"function": "调用者", "file": "源码相对路径"}
    ]
  },
  "code_snippet": {
    "before": "基线代码片段",
    "after": "应用随包补丁后的代码片段",
    "fix_summary": "修复原理"
  },
  "description": "触发条件、问题原因及修复方式",
  "patch": "patches/9998cd719775e90f9989fd1ecaa84647a56c1b57.patch"
}
```

要求：

- `id` 与 TSV 的 `localId` 必须一一对应，集合一致，不能重复或缺失。
- `patch` 必须与 TSV 一致；补丁正文不重复内嵌到 JSON 中。
- `before`、`after` 必须来自实际基线和应用随包补丁后的源码，不能仅按上游最新代码填写。
- `location` 只记录崩溃报告位置（sanitizer 栈顶），`location.line` 是基线中的行号；`code_snippet` 只给 `before`、`after`、`fix_summary`，不重复携带 `file`/`function`/`line`。片段出处就是 `patch` 所指补丁中对应 hunk 的位置，可能与 `location` 不同（崩溃点落在头文件内联函数、修复在被调函数里就是这种情形），需要点明时写在 `description` 或 `fix_summary` 里。
- `location.stack` 是同一份报告里的调用栈（sanitizer 的 `#N` 帧）：由内向外，只保留源码树内的业务代码帧——去掉 `LLVMFuzzerTestOneInput`、`main` 这类入口和 `*/fuzz/*`、`*_fuzzer.c`/`*_fuzzer.cc` 这类 fuzz 驱动文件，从第一个业务帧开始；路径按报告里的相对写法，最多 10 帧（截断时保留靠内一侧）。每帧只记 `function` 和 `file`，**不记行号**：行号会随修复漂移，而且同一函数里的不同分支在栈上没有区别。
- `stack` 里必须有一帧的 `function`、`file` 与 `location` 相同（通常是首帧；首帧定位不到源码行时 `location` 取其后的第一个可定位帧，首帧仍原样留在栈里）。栈的用途是把「`location` 相同」的案例分开：位置相同不代表同一个问题，同一个头文件内联函数可以由不同解码器的不同调用路径走到。
- 判断顺序：先看 `location.stack`；栈也完全相同的案例（同一函数里两处缺陷、或多条 PoC 走同一条调用链）以 `patch` 和 `description` 区分。栈只到函数/文件粒度，同一函数内的不同分支不会体现出来。未知时 `stack` 允许为 `null`。
- 未知的 CWE、源码位置、函数和片段允许使用 `null`，不得猜测填充；其他必需字段必须有效。
- `description` 必须区分源码缺陷修复、资源限制、测试驱动约束等不同修复方式。

## 5. PoC 与补丁

PoC 保存为 `payload/pocs/<case_id>/poc`，

补丁保存为 `payload/patches/<fix_commit>.patch`：

- 必须是可供 `git apply` 使用的 unified diff，路径相对于源码根目录。
- 必须在干净基线上通过 `git apply --check`，且能独立应用。
- 多个案例引用同一补丁时必须复用同一文件。

## 6. 脚本与复现接口

| 接口 | 职责 |
| --- | --- |
| `build.sh [--tree DIR]` | 普通构建指定源码并检查产物，不运行 PoC |
| `verify-one.sh ID [--tree DIR]` | 在指定源码（缺省基线）上测试一个案例 |
| `verify-one.sh ID --patched [--tree DIR]` | 复制指定源码、应用当前案例补丁，测试同一个 PoC |
| `verify.sh [--tree DIR]` | 遍历全部案例，汇总基线结果 |
| `verify-one-by-one.sh [--tree DIR]` | 遍历案例，分别验证各自补丁 |

通用要求：

- 普通编译与插桩编译必须使用独立产物，不得错误混用。
- 补丁验证必须复制源码，不能修改原始基线；各案例补丁不累计。
- 三个验证脚本必须能通过 `--tree DIR` 指向 `/src/<project>` 之外的源码目录，且不修改该目录。
- 不设命令分发层：脚本本身就是接口，交付文档与示例一律直接写 `build.sh`、`verify.sh`、`verify-one.sh`、`verify-one-by-one.sh`，不引入 `build`/`verify`/`verify-one` 这类包装命令或二级子命令。
- 脚本目录（本数据集为 `/opt/imdt`）必须加入 `PATH`，脚本带执行位，因此上表四条命令可直接按名调用，读者不需要拼全路径。

参考调用关系：

```text
build.sh → 普通 configure + make
verify.sh → verify-one.sh --tree DIR
verify-one-by-one.sh → verify-one.sh --patched --tree DIR
```

## 7. README 漏洞分布要求

README 必须包含“漏洞分布”章节，依据随包元数据与案例索引统计，不得仅给出总数或用测试运行次数替代案例数。必须写明统计所用文件、基线范围、统计单位、去重规则和占比的分母。

至少包含以下内容：

| 维度 | 必需内容与统计口径 |
| --- | --- |
| 总体规模 | 案例数、PoC 数、唯一补丁数；明确案例数不等于独立根因数 |
| 漏洞类型 | 按主 CWE 分组，列出 CWE 编号、名称、案例数及占比；未知类型单列，不能省略 |
| 检测方式 | 按 sanitizer 或项目对应检测方式分组，列出案例数及占比 |
| 源码模块 | 按 location.file 的目录/模块分组，明确路径规范化和模块划分规则；不能把报告位置直接称为根因位置 |
| 输入类别 | 按输入格式、协议或功能入口分组并列出案例数；项目不适用时明确说明 |
| 补丁对应关系 | 列出每个补丁对应案例数的分布，以及各组补丁数、覆盖案例数；共享补丁给出可追溯的提交或路径 |

各维度必须独立统计，不能跨维度相加。默认以案例 ID 去重，每个案例在同一维度只计入一个主分类；使用多标签时必须明确可能重复计数及其分母。比例必须注明舍入精度，分类总数应与总体规模核对。表格可合并长尾为“其他”，但必须给出其数量及合并规则。

资源限制、测试驱动约束等补丁应说明作用方式，不得将多个 PoC 的消失直接表述为多个独立根因被修复。分布必须随案例或补丁变化同步更新，并重新生成 MANIFEST 中受影响文件的校验值。

## 8. 报告格式与退出码

三份报告由脚本直接生成，顶层固定为 `pass`、`fail`、`results`，不设 `error` 计数，条目也不设 `status`。

| 报告 | 生成者 | 条目字段 | `pass` / `fail` 的口径 |
| --- | --- | --- | --- |
| `verify.json` | `verify.sh` | `poc`、`pass`、`alert` | CLEAN 条数 / 其余条数 |
| `verify-one.json` | `verify-one.sh` | `poc`、`pass`、`alert` | 该案例 CLEAN 时为 `1`/`0`，否则为 `0`/`1` |
| `verify-one-by-one.json` | `verify-one-by-one.sh` | `poc`、`patch`、`pass`、`alert` | `pass` 为 true 的条数 / 其余条数 |

`patch` 只记录补丁文件名（如 `9998cd71….patch`），不带 `patches/` 前缀。基线单案例示例：

```json
{
  "pass": 0,
  "fail": 1,
  "results": [
    {
      "poc": "42518438",
      "pass": false,
      "alert": "Heap-buffer-overflow READ 1"
    }
  ]
}
```

输出位置：`--report DIR` 未指定时写入**相对当前工作目录**的 `reports/`，文件名固定为 `verify.json`、`verify-one.json`、`verify-one-by-one.json`，同名文件直接覆盖。容器的默认工作目录是 `/opt/imdt`，所以不加 `--report` 就会写进随包报告目录 `/opt/imdt/reports/`；要保留随包报告就显式指定目录，例如 `--report /tmp/baseline-report`。

退出码：

| 命令 | `0` | 非 `0` |
| --- | --- | --- |
| `verify.sh` | 没有任何案例返回 CLEAN（`clean=0`） | 至少一条 CLEAN |
| `verify-one.sh <id>` | 该案例 CRASH（`pass=false`） | 该案例 CLEAN |
| `verify-one.sh <id> --patched` | 该案例 CLEAN（`pass=true`） | 该案例仍 CRASH，或补丁无法应用 |
| `verify-one-by-one.sh` | 全部 `pass=true`（`fail=0`） | 至少一条 `pass=false` |

判据只有 `pass` 一个维度：`pass=true` 表示该 PoC 没有打崩被测源码树。运行本身失败的情形——子进程异常退出、内存分配失败、MSan 运行时启动崩溃在重试后仍无输出——同样记为 `pass=false`，因此基线报告的 `fail`/`crash` 计数包含这类运行失败，无法与真实崩溃区分。两个批量脚本不校验子进程退出码，缺失 `RESULT` 行也按 `pass=false` 计入。所以 `clean=0` 或 `fail=0` 带来的退出码成立，并不证明每条记录都产生了 sanitizer 报告；验收时必须同时核对案例数、运行日志和报告条数。