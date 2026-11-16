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
│   └── <project>/
├── payload/
│   ├── vulnerabilities.json
│   ├── patches/
│   │   └── <fix_commit>.patch
│   └── pocs/
│       └── <case_id>/
│           └── poc
├── scripts/
│   ├── imdt
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
| `src/<project>/` | 必须，基线源码副本 |
| `payload/` | 必须，机器可读的案例、漏洞信息、PoC 和补丁 |
| `scripts/` | 必须，构建与验证入口 |
| `reports/` | 必须，发布前结果、日志及运行环境信息 |


## 3. 基线源码格式

`src/<project>/` 必须对应 `baseline.commit`，该字段使用完整提交 ID。

- 必须包含构建所需源码、配置文件及必要资源。
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
    "function": "函数名"
  },
  "code_snippet": {
    "file": "源码相对路径",
    "function": "函数名",
    "line": 100,
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
- `location.line` 和 `code_snippet.line` 是各自片段在基线中的位置。
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
| `build.sh [DIR]` | 普通构建指定源码并检查产物，不运行 PoC |
| `verify-one.sh ID` | 在基线上测试一个案例 |
| `verify-one.sh ID --patched` | 复制基线、应用当前案例补丁，测试同一个 PoC |
| `verify.sh` | 遍历全部案例，汇总基线结果 |
| `verify-one-by-one.sh` | 遍历案例，分别验证各自补丁 |
| `imdt` | 分发 `build`、`verify`、`verify-one` 命令 |

通用要求：

- 普通编译与插桩编译必须使用独立产物，不得错误混用。
- 补丁验证必须复制源码，不能修改原始基线；各案例补丁不累计。

参考调用关系：

```text
imdt build → build.sh → 普通 configure + make
imdt verify → verify.sh → verify-one.sh
verify-one-by-one.sh → verify-one.sh --patched
```

## 8. 报告格式与退出码

保留现有 `pass`、`fail`、`results` 字段，增加 `error` 数量和每条记录的 `status`。基线单案例示例：

```json
{
  "pass": 0,
  "fail": 1,
  "error": 0,
  "results": [
    {
      "poc": "42518438",
      "status": "CRASH",
      "pass": false,
      "alert": "Heap-buffer-overflow READ 1",
    }
  ]
}
```

补丁验证条目还必须保存 `patch`，统一使用相对 `payload/` 的完整路径。`